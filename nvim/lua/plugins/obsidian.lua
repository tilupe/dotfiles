return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
    config = function()
      require('render-markdown').setup {
        enabled = true,
        completions = { blink = { enabled = true } },
      }

      vim.treesitter.language.register('markdown', 'vimwiki')
      vim.treesitter.language.register('markdown', 'octo')
    end,
  },
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = 'markdown',
    dependencies = {
      -- Required.
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('obsidian').setup {
        ui = { enable = false },
        workspaces = {
          {
            name = 'personal',
            path = '~/Documents/notes',
          },
          {
            name = 'zettelkasten',
            path = '~/zettelkasten',
          },
        },
        picker = {
          name = 'snacks.pick',
        },
        completion = {
          nvim_cmp = false,
          blink = true,
        },
      }
    end,
  },
}
