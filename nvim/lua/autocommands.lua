local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = { '*.cshtml', '*.razor' },
  callback = function()
    vim.bo.filetype = 'html.cshtml.razor'
  end,
})

local lsp_setup = vim.api.nvim_create_augroup('LspSetup', { clear = true })
autocmd('LspAttach', {
  callback = function()
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename' })
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = '[G]oto [D]efinition' })
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, { desc = 'Type [D]efinition' })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover Documentation' })
    vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, { desc = '[G]oto [Implementation]' })
    vim.keymap.set('n', '<leader>sh', vim.lsp.buf.signature_help, { desc = 'Signature Documentation' })
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = '[g]oto [D]eclaration' })
    vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, { desc = '[G]oto [D]eclaration' })
  end,
  group = lsp_setup,
  pattern = '*',
})


local group = vim.api.nvim_create_augroup('OoO', {})

local function au(typ, pattern, cmdOrFn)
	if type(cmdOrFn) == 'function' then
		vim.api.nvim_create_autocmd(typ, { pattern = pattern, callback = cmdOrFn, group = group })
	else
		vim.api.nvim_create_autocmd(typ, { pattern = pattern, command = cmdOrFn, group = group })
	end
end

au({ 'CursorHold', 'InsertLeave' }, nil, function()
	local opts = {
		focusable = false,
		scope = 'cursor',
		close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter' },
	}
	vim.diagnostic.open_float(nil, opts)
end)

au('InsertEnter', nil, function()
	vim.diagnostic.enable(false)
end)

au('InsertLeave', nil, function()
	vim.diagnostic.enable(true)
end)
