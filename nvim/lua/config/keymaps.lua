vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Better viewing
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', 'g,', 'g,zvzz')
vim.keymap.set('n', 'g;', 'g;zvzz')

-- Better escape using jk in insert and terminal mode
vim.keymap.set('t', '<M-h>', '<C-\\><C-n><C-w>h')
vim.keymap.set('t', '<M-j>', '<C-\\><C-n><C-w>j')
vim.keymap.set('t', '<M-k>', '<C-\\><C-n><C-w>k')
vim.keymap.set('t', '<M-l>', '<C-\\><C-n><C-w>l')

-- Better indent and moving
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')
vim.keymap.set('v', 'J', ":m '>+1<cr>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<cr>gv=gv")
-- Paste over currently selected text without yanking it
--vim.keymap.set('v', 'p', '"_dP')

-- Resize window using <shift> arrow keys
vim.keymap.set('n', '<down>', ':resize +2<cr>')
vim.keymap.set('n', '<up>', ':resize -2<cr>')
vim.keymap.set('n', '<right>', ':vertical resize +2<cr>')
vim.keymap.set('n', '<left>', ':vertical resize -2<cr>')

vim.keymap.set('n', '<leader>qq', '<CMD>qa<CR>', { desc = 'Quit all' })
vim.keymap.set('n', '<leader>bx', '<C-W>c', { desc = 'Close' })
vim.keymap.set('n', '<leader>br', '<CMD>e<CR>', { desc = 'Reload' })

-- remove highlight
vim.keymap.set('n', '<Esc>', vim.cmd.nohlsearch)

-- Quickfix navigation
-- vim.keymap.set('n', '<C-J>', vim.cmd.cnext, { desc = 'Quickfix next' })
-- vim.keymap.set('n', '<C-K>', vim.cmd.cprev, { desc = 'Quickfix prev' })
vim.keymap.set('n', '<leader>co', vim.cmd.copen, { desc = 'Quickfix open' })

-- Tabs
vim.keymap.set('n', '<leader><tab>d', '<CMD>tabclose<CR>', { desc = 'Close' })

-- inlay hints
vim.keymap.set('n', '<leader>li', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = 'Inlay Hints Toggle' })

vim.keymap.set('n', '<leader>lr', function()
  vim.lsp.codelens.refresh()
end, { desc = 'Code[L]ens [r]efresh' })

-- Diagnostics
vim.keymap.set('n', '<leader>cj', '<CMD>lua vim.diagnostic.goto_next()<CR>', { desc = 'Next Diagnostic' })
vim.keymap.set('n', '[d', '<CMD>lua vim.diagnostic.goto_next()<CR>', { desc = 'Next Diagnostic' })
vim.keymap.set('n', '<leader>ck', '<CMD>lua vim.diagnostic.goto_prev()<CR>', { desc = 'Previous Diagnostic' })
vim.keymap.set('n', ']d', '<CMD>lua vim.diagnostic.goto_prev()<CR>', { desc = 'Previous Diagnostic' })

-- Customs
-- Notes
vim.keymap.set('n', '<leader>nt', function()
  require('custom.notes.todos').AddTodo()
end, { desc = 'Todo (Add)' })

vim.keymap.set('n', '<leader>nn', function()
  require('custom.notes').new_note()
end, { desc = 'New' })
