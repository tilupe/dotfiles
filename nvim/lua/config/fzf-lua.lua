local fzf = require 'fzf-lua'
local actions = require 'fzf-lua.actions'
fzf.setup {
  file_icons = 'mini',
  formatter = 'path.filename_first',
  previewers = {
    builtin = {
      extensions = {
        ['png'] = { 'viu', '-b' },
        ['jpg'] = { 'ueberzug' },
        ['jpeg'] = { 'ueberzug' },
      },
    },
  },
  files = {
    cmd = 'fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache --exclude .obsidian',
    fzf_opts = {
      ['--history'] = vim.fn.stdpath 'data' .. '/fzf-lua-files-history',
    },
  },
  grep = {
    actions = {
      ['ctrl-q'] = {
        fn = actions.file_edit_or_qf,
        prefix = 'select-all+',
      },
    },
    fzf_opts = {
      ['--history'] = vim.fn.stdpath 'data' .. '/fzf-lua-grep-history',
    },
  },
}

vim.keymap.set('v', '<C-s>', function()
  vim.cmd 'FzfLua grep_visual'
end, { desc = 'grep string' })
