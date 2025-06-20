local M = {}

function M.run(subcommand)
  if subcommand == "snake" then
    require("moj.snake").start()
  elseif subcommand == "flappy" then
    require("moj.flappy").start()
  else
    print("Unknown subcommand: " .. subcommand)
    print("Available subcommands: snake, flappy")
  end
end

vim.api.nvim_create_user_command("Moj", function(opts)
  M.run(opts.args)
end, {
  nargs = 1,
  complete = function()
    return { "snake", "flappy" }
  end,
})

return M
