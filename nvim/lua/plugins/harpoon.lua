return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'

      -- REQUIRED
      harpoon:setup()
      -- REQUIRED

      vim.keymap.set('n', '<leader>ke', function()
        harpoon:list():add()
      end, { desc = 'Add' })
      vim.keymap.set('n', '<leader>ki', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = 'Show Menu' })

      vim.keymap.set('n', '<leader>ka', function()
        harpoon:list():select(1)
      end, { desc = 'Select 1' })
      vim.keymap.set('n', '<leader>ks', function()
        harpoon:list():select(2)
      end, { desc = 'Select 2' })
      vim.keymap.set('n', '<leader>kd', function()
        harpoon:list():select(3)
      end, { desc = 'Select 3' })
      vim.keymap.set('n', '<leader>kf', function()
        harpoon:list():select(4)
      end, { desc = 'Select 4' })
      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set('n', '<leader>kk', function()
        harpoon:list():prev()
      end, { desc = 'Prev' })
      vim.keymap.set('n', '<leader>kj', function()
        harpoon:list():next()
      end, { desc = 'Next' })
    end,
  },
}
