local M = {}

M.daily = require('custom.notes.daily')
M.todos = require('custom.notes.todos')

--- Setup all notes-related commands and keybindings
---@param opts table|nil Configuration overrides for daily.lua
function M.setup(opts)
  M.daily.setup(opts)

  -- Daily note
  vim.keymap.set('n', '<leader>nj', M.daily.daily_note, { desc = 'Daily note (journal)' })

  -- Quick capture bullets (all add to today's daily note)
  vim.keymap.set('n', '<leader>nb', M.daily.add_bullet_picker, { desc = 'Add bullet (picker)' })
  vim.keymap.set('n', '<leader>n.', function() M.daily.add_bullet('task') end, { desc = 'Add task' })
  vim.keymap.set('n', '<leader>n!', function() M.daily.add_bullet('priority') end, { desc = 'Add priority' })
  vim.keymap.set('n', '<leader>n?', function() M.daily.add_bullet('explore') end, { desc = 'Add explore' })
  vim.keymap.set('n', '<leader>no', function() M.daily.add_bullet('event') end, { desc = 'Add event' })
  vim.keymap.set('n', '<leader>n-', function() M.daily.add_bullet('note') end, { desc = 'Add note' })

  -- Toggle bullet state on current line (buffer-local for markdown)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function()
      vim.keymap.set('n', '<leader>nx', M.daily.toggle_bullet, { buffer = true, desc = 'Toggle bullet' })
    end,
  })

  -- Quick capture floating window
  vim.keymap.set('n', '<leader>nc', M.daily.quick_capture, { desc = 'Quick capture (float)' })

  -- Task with due date
  vim.keymap.set('n', '<leader>nd', function() M.daily.add_bullet_with_due('task') end, { desc = 'Add task with due' })

  -- Search and review
  vim.keymap.set('n', '<leader>ns', M.daily.bullet_search, { desc = 'Search bullets' })
  vim.keymap.set('n', '<leader>nw', M.daily.weekly_review, { desc = 'Weekly review' })
  vim.keymap.set('n', '<leader>n#', M.daily.tag_search, { desc = 'Search tags' })

  -- Legacy todo (from todos.lua)
  vim.keymap.set('n', '<leader>nt', M.todos.AddTodo, { desc = 'Add todo (legacy)' })
end

return M
