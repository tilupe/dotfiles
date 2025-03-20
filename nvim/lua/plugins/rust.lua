return {
  {
    'simrat39/rust-tools.nvim',
    config = function()
      require('rust-tools').setup {
        tools = {
          autoSetHints = true,
          hoverWithoutFloating = true,
        },
      }
    end,
  },
}
