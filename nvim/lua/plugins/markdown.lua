return {
  {
    'yousefhadder/markdown-plus.nvim',
    ft = 'markdown',
    config = function()
      require('markdown-plus').setup {
        -- Your custom configuration here
      }
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function(args)
          -- Schedule this to run after all other FileType autocmds
          vim.schedule(function()
          end)
        end,
      })
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
    config = function()
      require('render-markdown').setup {
        enabled = true,
        completions = { blink = { enabled = true } },
      }

      vim.treesitter.language.register('markdown', 'vimwiki')
      -- vim.treesitter.language.register('markdown', 'octo')
    end,
  },
}
