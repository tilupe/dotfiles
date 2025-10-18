-- lua/submission/init.lua
local M = {}

-- Function to open a buffer with jj log output
function M.show_jj_log()
  -- Create a new scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.bo[buf].modifiable = true
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.api.nvim_buf_set_name(buf, 'JJ Log')

  -- Open the buffer in a split window
  vim.cmd 'vsplit'
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Use the modern job API to run jj log
  local command = { 'jj', 'log', '--no-pager', '--limit', '15', '--reversed' }

  -- Start the job and capture output with colors
  local job_id = vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
      end
    end,
    on_exit = function()
      vim.bo[buf].modifiable = false
      vim.bo[buf].modified = false
    end,
    stdout_buffered = false,
    stderr_buffered = false,
    pty = true, -- This preserves colors
  })

  -- Set keymaps for the buffer
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':bdelete!<CR>', { noremap = true, silent = true })
end

-- Set up the command
function M.setup()
  vim.api.nvim_create_user_command('JJ', function()
    M.show_jj_log()
  end, {})
end

return M
