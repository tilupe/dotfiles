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
----------------------------
-------- Norg Setup --------
----------------------------


-- continue list and heading with Enter
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'norg',
  callback = function()
    vim.keymap.set('i', '<CR>', function()
      local line = vim.api.nvim_get_current_line()
      local trimmed = vim.trim(line)

      -- Check if line starts with list markers
      local list_marker = string.match(trimmed, '^[-~]+%s*')
      -- Check if line starts with heading markers
      local heading_marker = string.match(trimmed, '^%*+%s*')

      -- If we're not in a list or heading, just return regular Enter
      if not list_marker and not heading_marker then
        return '<CR>'
      end

      -- If the line only contains the marker (with or without whitespace), end the list/heading
      if (list_marker and #trimmed == #list_marker) or (heading_marker and #trimmed == #heading_marker) then
        return '<Esc>cc<CR>'
      end

      -- Continue the list/heading
      if list_marker then
        return '<CR>' .. list_marker
      elseif heading_marker then
        return '<CR>'
      end
    end, { buffer = true, expr = true })
  end,
})



----------------------------
-------- Norg Setup End ----
----------------------------
