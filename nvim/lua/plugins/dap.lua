return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',              -- Highly recommended UI
    'nvim-neotest/nvim-nio',             -- Required for dap-ui
    'theHamsta/nvim-dap-virtual-text',   -- Optional: shows variables inline
  },
  config = function()
    require('config.dap')
  end
}
