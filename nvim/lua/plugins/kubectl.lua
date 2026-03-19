return {
  {
    'ramilito/kubectl.nvim',
    build = 'nix run .#build-plugin',
    dependencies = 'saghen/blink.download',
    config = function()
      require('kubectl').setup {}
      vim.keymap.set('n', '<leader>kk', '<cmd>lua require("kubectl").toggle({ tab = true })<cr>', { noremap = true, silent = true, desc = 'Toggle Kubectl' })
    end,
  },
}
