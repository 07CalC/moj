local api = vim.api
local M = {}

local width, height = 40, 20
local bird = { x = 10, y = 10, velocity = 0 }
local pipes = {}
local score = 0
local gravity = 0.7
local flap_power = -3
local pipe_speed = 1
local pipe_interval = 30
local tick = 0
local running = true
local buf, win
local ns = api.nvim_create_namespace("moj-flappy")

local function color_hex(n)
	return string.format("#%06x", n)
end

local function resolve_hl(name)
	local id = vim.fn.hlID(name)
	local trans = vim.fn.synIDtrans(id)
	return vim.fn.synIDattr(trans, "fg#"), vim.fn.synIDattr(trans, "bg#")
end

local function create_pipe()
	local gap_y = math.random(4, height - 6)
	table.insert(pipes, {
		x = width - 1,
		gap_y = gap_y,
		gap_size = 5,
	})
end

local function get_grid()
	local grid = {}
	for _ = 1, height do
		table.insert(grid, string.rep(" ", width))
	end

	-- Pipes
	for _, pipe in ipairs(pipes) do
		if pipe.x >= 1 and pipe.x <= width then
			for y = 1, height do
				if y < pipe.gap_y or y > pipe.gap_y + pipe.gap_size then
					local row = grid[y]
					grid[y] = row:sub(1, pipe.x) .. "|" .. row:sub(pipe.x + 2)
				end
			end
		end
	end

	-- Bird
	local y = math.floor(bird.y)
	if y >= 1 and y <= height then
		local row = grid[y]
		grid[y] = row:sub(1, bird.x) .. "@" .. row:sub(bird.x + 2)
	end

	-- Score
	grid[1] = "Flappy Score: " .. score .. "  (Space/k to flap, q to quit)"
	return grid
end

local function render()
	if not api.nvim_buf_is_valid(buf) then
		return
	end
	local grid = get_grid()
	api.nvim_buf_set_lines(buf, 0, -1, false, grid)
end

local function update()
	bird.velocity = bird.velocity + gravity
	bird.y = bird.y + bird.velocity * 0.3

	tick = tick + 1
	if tick % pipe_interval == 0 then
		create_pipe()
	end

	for _, pipe in ipairs(pipes) do
		pipe.x = pipe.x - pipe_speed
	end

	-- Remove off-screen pipes
	while #pipes > 0 and pipes[1].x < 0 do
		table.remove(pipes, 1)
		score = score + 1
	end

	-- Collision check
	for _, pipe in ipairs(pipes) do
		if math.floor(bird.x) == pipe.x or math.floor(bird.x) == pipe.x + 1 then
			if bird.y < pipe.gap_y or bird.y > pipe.gap_y + pipe.gap_size then
				running = false
				return
			end
		end
	end

	if bird.y < 1 or bird.y > height then
		running = false
	end
end

local function game_loop()
	if not running then
		vim.on_key(nil, ns)
		api.nvim_buf_set_lines(buf, height / 2, height / 2, false, {
			"💥 Game Over! Score: " .. score .. "  (press q to quit)",
		})
		return
	end

	update()
	render()
	vim.defer_fn(game_loop, 60)
end

local function close_game()
	if api.nvim_win_is_valid(win) then
		api.nvim_win_close(win, true)
	end
end

local function on_key(key)
	if not running then
		if key == "q" then
			close_game()
		elseif key == "s" then
			M.start()
		end
		return
	end

	if key == " " or key == "k" then
		bird.velocity = flap_power
	elseif key == "q" then
		running = false
		close_game()
	end
end

function M.start()
	buf = api.nvim_create_buf(false, true)
	win = api.nvim_open_win(buf, true, {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		border = "rounded",
	})

	local fg, bg = resolve_hl("Normal")
	api.nvim_set_hl(0, "MojFlappy", {
		fg = fg or "#ffffff",
		bg = bg or "NONE",
	})

	api.nvim_win_set_option(win, "winhighlight", "Normal:MojFlappy")
	api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	-- Reset state
	bird = { x = 10, y = 10, velocity = 0 }
	pipes = {}
	score = 0
	tick = 0
	running = true

	vim.on_key(on_key, ns)
	render()
	game_loop()
end

return M
