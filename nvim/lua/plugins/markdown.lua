return {
  {
    'yousefhadder/markdown-plus.nvim',
    ft = 'markdown',
    config = function()
      require('markdown-plus').setup {}
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
