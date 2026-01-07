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
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename' })
    vim.keymap.set('n', 'gd', function()
      vim.lsp.buf.definition()
    end, { noremap = true, silent = true })
    vim.keymap.set('n', '<leader>ld', vim.lsp.buf.definition, { desc = '[G]oto [D]efinition' })
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

    -- Update yaml metadata fields

    -- local current_file = vim.fn.expand '%:p'
    -- local tags = vim.fn.trim(vim.fn.system(string.format("zk list -qP -f '{{join tags \", \"}}' '%s' ", current_file)))
    local timestamp = os.date '%Y-%m-%d %H:%M:%S'
    local updated = false

    for i = 2, yaml_end - 1 do
      if lines[i]:match '^last%-update:' then
        lines[i] = 'last-update: ' .. timestamp
        updated = true
        break
      end
    end

    -- for i = 2, yaml_end - 1 do
    --   if lines[i]:match '^tags:' then
    --     lines[i] = 'tags: [' .. tags .. ']'
    --     updated = true
    --     break
    --   end
    -- end

    if updated then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end
  end,
})

-- Treesitter highlight for specific filetypes
vim.api.nvim_create_autocmd('FileType', {
  pattern = { '<filetype>' },
  callback = function()
    vim.notify('Treesitter activated for ' .. vim.bo.filetype)
    vim.treesitter.start()
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo[0][0].foldmethod = 'expr'
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
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

-- Was ment to auto-update backlinks in markdown files using zk
-- but the problem is that every Down-Link from A to B becomes an Up-Link in B
-- and ZK sees this one again as an Donw-Link to A creating an infinite loop of backlinks.
-- vim.api.nvim_create_autocmd('BufEnter', {
--   pattern = '*.md',
--   callback = function()
--     local current_file = vim.fn.expand '%:p'
--     local current_dir = vim.fn.expand '%:p:h'
--
--     -- Get backlinks using zk
--     local output = vim.fn.system(string.format("zk list --link-to '%s' --format '{{path}}\t{{title}}'", current_file))
--
--     if vim.v.shell_error ~= 0 then
--       return
--     end
--
--     -- Parse backlinks
--     local links = {}
--     for line in output:gmatch '[^\r\n]+' do
--       local path, title = line:match '^(.+)\t(.+)$'
--       if path and title then
--         -- Calculate proper relative path
--         local abs_path = vim.fn.fnamemodify(path, ':p')
--
--         -- Split paths into components
--         local current_parts = vim.split(current_dir, '/', { plain = true })
--         local target_parts = vim.split(vim.fn.fnamemodify(abs_path, ':h'), '/', { plain = true })
--
--         -- Find common prefix
--         local common = 0
--         for i = 1, math.min(#current_parts, #target_parts) do
--           if current_parts[i] == target_parts[i] then
--             common = i
--           else
--             break
--           end
--         end
--
--         -- Build relative path
--         local rel_parts = {}
--         for i = common + 1, #current_parts do
--           table.insert(rel_parts, '..')
--         end
--         for i = common + 1, #target_parts do
--           table.insert(rel_parts, target_parts[i])
--         end
--         table.insert(rel_parts, vim.fn.fnamemodify(abs_path, ':t'))
--
--         local rel_path = table.concat(rel_parts, '/')
--         table.insert(links, string.format('- [%s](%s)', title, rel_path))
--       end
--     end
--
--     -- Find ### Up and ### Down headers
--     local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
--     local up_idx, down_idx = nil, nil
--
--     for i, line in ipairs(lines) do
--       if line:match '^###%s+Up%s*$' then
--         up_idx = i
--       elseif line:match '^###%s+Down%s*$' then
--         down_idx = i
--         break
--       end
--     end
--
--     if not up_idx or not down_idx then
--       return
--     end
--
--     -- Get current content between headers
--     local current_content = vim.api.nvim_buf_get_lines(0, up_idx, down_idx - 1, false)
--     local new_content = #links > 0 and links or { '' }
--
--     -- Check if content changed
--     if #current_content == #new_content then
--       local same = true
--       for i = 1, #current_content do
--         if current_content[i] ~= new_content[i] then
--           same = false
--           break
--         end
--       end
--       if same then
--         return
--       end
--     end
--
--     -- Replace content between headers
--     vim.api.nvim_buf_set_lines(0, up_idx, down_idx - 1, false, new_content)
--   end,
-- })
