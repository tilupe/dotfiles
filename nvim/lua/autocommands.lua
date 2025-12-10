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

-- Markdown update last-update field on save
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.md',
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Check if file starts with YAML frontmatter
    if lines[1] ~= '---' then
      return
    end

    -- Find the end of YAML frontmatter
    local yaml_end = nil
    for i = 2, #lines do
      if lines[i] == '---' then
        yaml_end = i
        break
      end
    end

    if not yaml_end then
      return
    end

    -- Update last-update field
    local timestamp = os.date '%Y-%m-%d %H:%M:%S'
    local updated = false

    for i = 2, yaml_end - 1 do
      if lines[i]:match '^last%-update:' then
        lines[i] = 'last-update: ' .. timestamp
        updated = true
        break
      end
    end

    if updated then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end
  end,
})
-- Markdown YAML frontmatter folding
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = 'v:lua.fold_yaml_frontmatter()'

    -- Auto-fold YAML frontmatter
    if vim.fn.getline(1) == '---' then
      vim.cmd 'normal! zM'
    end
  end,
})

function _G.fold_yaml_frontmatter()
  local line = vim.fn.getline(vim.v.lnum)

  -- First line with ---
  if vim.v.lnum == 1 and line == '---' then
    return '>1'
  end

  -- Lines between the two ---
  if vim.fn.getline(1) == '---' then
    for i = 2, vim.fn.line '$' do
      if vim.fn.getline(i) == '---' then
        if vim.v.lnum < i then
          return '1'
        elseif vim.v.lnum == i then
          return '<1'
        end
        break
      end
    end
  end

  return '0'
end
