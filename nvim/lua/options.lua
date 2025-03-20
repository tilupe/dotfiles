-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3 -- from avante.nvim
vim.opt.formatoptions = 'jcroqlnt' -- tcqj
vim.opt.shortmess:append { W = true, I = true, c = true }
vim.opt.breakindent = true
vim.opt.clipboard = 'unnamedplus' -- Access system clipboard
vim.opt.cmdheight = 1
vim.opt.completeopt = 'menuone,noselect,longest'
vim.opt.confirm = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.hidden = true
vim.opt.hlsearch = true
vim.opt.joinspaces = false
vim.opt.mouse = 'a'
vim.opt.pumblend = 10
vim.opt.pumheight = 10
vim.opt.scrollback = 100000
vim.opt.scrolloff = 20
vim.opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize' }
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.showmode = false
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.ignorecase = true
vim.opt.inccommand = 'split'
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.timeoutlen = 300
vim.opt.title = true
vim.opt.fixeol = false

vim.opt.undofile = true -- save undo history
local keyset = vim.keymap.set
keyset('i', ',', ',<C-g>U')
keyset('i', '.', '.<C-g>U')
keyset('i', '!', '!<C-g>U')
keyset('i', '?', '?<C-g>U')

vim.opt.wildmode = 'list:longest,list:full' -- for : stuff
vim.opt.wildignore:append { '.javac', 'node_modules', '*.pyc' }
vim.opt.wildignore:append { '.aux', '.out', '.toc' } -- LaTeX
vim.opt.wildignore:append {
  '.o',
  '.obj',
  '.dll',
  '.exe',
  '.so',
  '.a',
  '.lib',
  '.pyc',
  '.pyo',
  '.pyd',
  '.swp',
  '.swo',
  '.class',
  '.DS_Store',
  '.git',
  '.hg',
  '.orig',
}
vim.opt.splitkeep = 'screen'
vim.opt.shortmess:append { C = true }

vim.opt.updatetime = 1000

vim.opt.swapfile = false

-- grep
--
if vim.fn.executable 'rg' == 1 then
  vim.opt.grepprg = 'rg --vimgrep --hidden --smart-case'
  vim.opt.grepformat = '%f:%l:%c:%m'
end

-- fold
vim.opt.foldcolumn = '1' -- '0' is not bad
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- view
vim.opt.wrap = true
vim.opt.number = true
vim.opt.relativenumber = true

-- langauge
vim.opt.spelllang = { 'en_us', 'de_ch' }
vim.opt.spell = true
vim.opt.spelloptions = 'camel'

-- Diff
vim.opt.fillchars = 'diff:╱'
vim.opt.diffopt = 'filler,internal,closeoff,algorithm:histogram,context:5,linematch:60,indent-heuristic' --'

vim.g.mapleader = ' '
vim.g.maplocalleader = '§'
vim.g.have_nerd_font = true

vim.opt.list = true
vim.opt.listchars = { tab = '│ ' }
