return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = function()
      require('nvim-treesitter.install').update { with_sync = true }()
    end,
    config = function()
      local configs = require 'nvim-treesitter.configs'
      configs.setup {
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
        ensure_installed = {
          'bash',
          'c',
          'c_sharp',
          'cpp',
          'kdl',
          'css',
          'dockerfile',
          'go',
          'html',
          'javascript',
          'json',
          'lua',
          'markdown',
          'markdown_inline',
          'python',
          'rust',
          'toml',
          'hyprlang',
          'vimdoc',
          'razor',
          'typescript',
          'vim',
          'yaml',
        },
      }
    end,
  },
  { 'yorickpeterse/nvim-tree-pairs', config = true },
}
