local M = {}

M.build_dotnet = function()
  -- Clear the quickfix list
  vim.fn.setqflist({}, 'r')

  -- Set the makeprg to use dotnet build
  vim.opt.makeprg = 'dotnet build'

  -- Set errorformat for dotnet build output
  -- This pattern matches the standard MSBuild error format
  vim.opt.errorformat = {
    '%E%f(%l\\,%c): error %m', -- Errors with line and column
    '%W%f(%l\\,%c): warning %m', -- Warnings with line and column
    '%E%f(%l): error %m', -- Errors with line only
    '%W%f(%l): warning %m', -- Warnings with line only
    '%-G%.%#', -- Ignore other lines
  }

  -- Run make asynchronously
  vim.cmd 'make!'

  -- Notify user that build started
  vim.notify('Building .NET project...', vim.log.levels.INFO)
end

-- Create a command to easily call this function
vim.api.nvim_create_user_command('DotnetBuild', build_dotnet, {})

return M
