return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      {
        lazy = false,
        'nsidorenco/neotest-vstest',
      },
    },
    version = '*',
    event = 'VeryLazy',
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-vstest' {
            dap_settings = {
              type = 'coreclr',
            },
          },
        },
      }
      vim.keymap.set('n', '<leader>tF', function()
        require('neotest').run.run { vim.fn.expand('%'), strategy = 'dap' }
      end, { desc = 'File Debug' })
      vim.keymap.set('n', '<leader>tL', function()
        require('neotest').run.run_last { strategy = 'dap' }
      end, { desc = 'Last Debug' })
      vim.keymap.set('n', '<leader>ta', "<cmd>lua require('neotest').run.attach()<cr>", { desc = 'Attach' })
      vim.keymap.set('n', '<leader>tf', "<cmd>lua require('neotest').run.run({vim.fn.expand('%')})<cr>", { desc = 'File' })
      vim.keymap.set('n', '<leader>tl', "<cmd>lua require('neotest').run.run_last()<cr>", { desc = 'Last' })

      vim.keymap.set('n', '<leader>tn', function()
        require('neotest').run.run()
      end, { desc = 'Nearest' })

      vim.keymap.set('n', '<leader>tN', function()
        local path = vim.fn.expand '%'
        if path and path ~= '' then
          require('neotest').run.run { path, strategy = 'dap' }
        else
          require('neotest').run.run { strategy = 'dap' }
        end
      end, { desc = 'Debug Nearest' })
      vim.keymap.set('n', '<leader>to', "<cmd>lua require('neotest').output.open({ enter = true })<cr>", { desc = 'Output' })
      vim.keymap.set('n', '<leader>tS', "<cmd>lua require('neotest').run.stop()<cr>", { desc = 'Stop' })
      vim.keymap.set('n', '<leader>ts', "<cmd>lua require('neotest').summary.toggle()<cr>", { desc = 'Summary' })
    end,
  },
}
