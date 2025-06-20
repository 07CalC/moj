local api = vim.api
local M = {}

local width, height = 40, 20
local snake, dir, food, score, running = {}, "right", nil, 0, true
local timer_interval = 100
local buf, win = nil, nil
local ns = api.nvim_create_namespace("moj-snake")
local unpack = unpack or table.unpack
local opposites = {
	up = "down",
	down = "up",
	left = "right",
	right = "left",
}

local function color_hex(n)
	return string.format("#%06x", n)
end

local function resolve_hl(name)
	local id = vim.fn.hlID(name)
	local trans = vim.fn.synIDtrans(id)
	return vim.fn.synIDattr(trans, "fg#"), vim.fn.synIDattr(trans, "bg#")
end

local function get_empty_grid()
	local grid = {}
	for _ = 1, height do
		table.insert(grid, string.rep(" ", width))
	end
	return grid
end

local function set_char(grid, x, y, ch)
	if y + 1 > 0 and y + 1 <= #grid and x + 1 > 0 and x + 1 <= #grid[1] then
		local row = grid[y + 1]
		grid[y + 1] = row:sub(1, x) .. ch .. row:sub(x + 2)
	end
end

local function random_food()
	while true do
		local x = math.random(1, width - 2)
		local y = math.random(1, height - 2)
		if y == 0 then
			y = 1
		end

		local valid = true
		for _, seg in ipairs(snake) do
			if seg[1] == x and seg[2] == y then
				valid = false
				break
			end
		end
		if valid then
			return { x, y }
		end
	end
end

local function render()
	if not api.nvim_buf_is_valid(buf) then
		return
	end

	local grid = get_empty_grid()

	set_char(grid, food[1], food[2], "@")
	for i, seg in ipairs(snake) do
		local ch = (i == 1) and "O" or "o"
		set_char(grid, seg[1], seg[2], ch)
	end

	grid[1] = "Score: " .. tostring(score) .. "  (Press 'q' to quit)"

	api.nvim_buf_set_lines(buf, 0, -1, false, grid)
end

local function move_snake()
	local head = { unpack(snake[1]) }
	if dir == "up" then
		head[2] = head[2] - 1
	elseif dir == "down" then
		head[2] = head[2] + 1
	elseif dir == "left" then
		head[1] = head[1] - 1
	elseif dir == "right" then
		head[1] = head[1] + 1
	end

	-- if head[1] < 0 or head[1] >= width or head[2] < 0 or head[2] >= height then
	-- 	running = false
	-- 	return
	head[1] = (head[1] + width) % width
	head[2] = (head[2] + height) % height

	for _, seg in ipairs(snake) do
		if seg[1] == head[1] and seg[2] == head[2] then
			running = false
			return
		end
	end

	table.insert(snake, 1, head)
	if head[1] == food[1] and head[2] == food[2] then
		score = score + 1
		food = random_food()
	else
		table.remove(snake)
	end
end

local function close_game()
	if api.nvim_win_is_valid(win) then
		api.nvim_win_close(win, true)
	end
end

local function game_loop()
	if not running then
		api.nvim_buf_set_lines(buf, math.floor(height / 2), math.floor(height / 2), false, {
			"💀 Game Over! Final Score: \n" .. score .. "\n  (press 'q' to quit)",
		})
		return
	end
	move_snake()
	render()
	vim.defer_fn(game_loop, timer_interval)
end

local function on_key(key)
	if not running then
		if key == "q" then
			close_game()
		elseif key == "r" then
			M.start()
		end
		return
	end

	local new_dir = nil

	if key == "h" or key == "Left" then
		new_dir = "left"
	elseif key == "l" or key == "Right" then
		new_dir = "right"
	elseif key == "k" or key == "Up" then
		new_dir = "up"
	elseif key == "j" or key == "Down" then
		new_dir = "down"
	elseif key == "q" then
		running = false
		close_game()
		return
	end

	if new_dir and new_dir ~= opposites[dir] then
		dir = new_dir
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

	api.nvim_set_hl(0, "MojSnake", {
		fg = fg or "#ffffff",
		bg = bg or "NONE", -- fallback to transparent if no bg
	})

	api.nvim_win_set_option(win, "winhighlight", "Normal:MojSnake")
	api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	snake = { { 5, 5 }, { 4, 5 }, { 3, 5 } }
	dir = "right"
	food = random_food()
	score = 0
	running = true

	vim.on_key(on_key, ns)

	game_loop()
end

return M
