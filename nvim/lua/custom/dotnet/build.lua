-- Add to your init.lua or create a file like dotnet.lua and require it

local M = {}

function M.setup()
  local overseer = require 'overseer'

  vim.api.nvim_create_user_command('DotnetBuild', function(opts)
    local cmd = 'dotnet build'

    -- Add additional arguments if provided
    if opts.args and opts.args ~= '' then
      cmd = cmd .. ' ' .. opts.args
    end

    local task = overseer.new_task {
      name = 'dotnet build',
      cmd = cmd,
      cwd = vim.fn.getcwd(),
      components = {
        { 'on_output_quickfix', open = false, relative_file_root = vim.fn.getcwd() },
        'default',
      },
    }

    task:subscribe('on_complete', function(task)
      if task.exit_code == 0 then
        vim.notify('Dotnet build succeeded!', vim.log.levels.INFO)
      else
        vim.notify('Dotnet build failed!', vim.log.levels.ERROR)
        -- Open the quickfix list with the errors
        vim.cmd 'copen'
      end
    end)

    task:start()
  end, { nargs = '?', desc = 'Build dotnet solution' })
end

return M
