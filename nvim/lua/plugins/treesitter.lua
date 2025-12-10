return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = 
      ':TSUpdate',
    -- function()
    -- require('nvim-treesitter.install').update { with_sync = true }()
    -- end,
    config = function()
      require('nvim-treesitter').setup {
        -- Directory to install parsers and queries to (prepended to `runtimepath` to have priority)
        install_dir = vim.fn.stdpath 'data' .. '/site',
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
          'templ',
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
