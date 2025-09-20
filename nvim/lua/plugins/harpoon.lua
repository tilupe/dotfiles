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

      vim.keymap.set('n', '<leader>hh', function()
        harpoon:list():add()
      end, { desc = 'Add' })
      vim.keymap.set('n', '<leader>hi', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = 'Show Menu' })

      vim.keymap.set('n', '<leader>ha', function()
        harpoon:list():select(1)
      end, { desc = 'Select 1' })
      vim.keymap.set('n', '<leader>hs', function()
        harpoon:list():select(2)
      end, { desc = 'Select 2' })
      vim.keymap.set('n', '<leader>hd', function()
        harpoon:list():select(3)
      end, { desc = 'Select 3' })
      vim.keymap.set('n', '<leader>hf', function()
        harpoon:list():select(4)
      end, { desc = 'Select 4' })
      vim.keymap.set('n', '<leader>hg', function()
        harpoon:list():select(5)
      end, { desc = 'Select 5' })
      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set('n', '<leader>hk', function()
        harpoon:list():prev()
      end, { desc = 'Prev' })
      vim.keymap.set('n', '<leader>hj', function()
        harpoon:list():next()
      end, { desc = 'Next' })
    end,
  },
}
