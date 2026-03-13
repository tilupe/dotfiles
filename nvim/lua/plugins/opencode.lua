return {
  'nickjvandyke/opencode.nvim',
  version = '*',
  dependencies = {
    {
      'folke/snacks.nvim',
      optional = true,
      opts = {
        input = {},
        picker = {
          actions = {
            opencode_send = function(...)
              return require('opencode').snacks_picker_send(...)
            end,
          },
          win = {
            input = {
              keys = {
                ['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
              },
            },
          },
        },
      },
    },
  },
  config = function()
    vim.g.opencode_opts = {}
    vim.o.autoread = true

    -- OpenCode keymaps using <leader>o prefix to avoid conflicts
    vim.keymap.set({ 'n', 'x' }, '<leader>oa', function()
      require('opencode').ask('@this: ', { submit = true })
    end, { desc = 'OpenCode: Ask' })

    vim.keymap.set({ 'n', 'x' }, '<leader>ox', function()
      require('opencode').select()
    end, { desc = 'OpenCode: Execute action' })

    vim.keymap.set({ 'n', 't' }, '<leader>oo', function()
      require('opencode').toggle()
    end, { desc = 'OpenCode: Toggle' })

    -- Using gz prefix (z-commands are mostly free, gz is unmapped)
    vim.keymap.set({ 'n', 'x' }, 'gz', function()
      return require('opencode').operator('@this ')
    end, { desc = 'OpenCode: Add range', expr = true })

    vim.keymap.set('n', 'gzz', function()
      return require('opencode').operator('@this ') .. '_'
    end, { desc = 'OpenCode: Add line', expr = true })
  end,
}
