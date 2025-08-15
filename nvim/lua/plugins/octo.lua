return {
  'pwntester/octo.nvim',
  dependencies  = {
    'nvim-lua/plenary.nvim',
    'folke/snacks.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  config = function ()
    require"octo".setup(
      {
        picker = "snacks",
      }
    )

      vim.treesitter.language.register('markdown', 'octo')
  end
}
