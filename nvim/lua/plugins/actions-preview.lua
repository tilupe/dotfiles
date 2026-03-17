return {
  'aznhe21/actions-preview.nvim',
  event = 'LspAttach',
  keys = {
    {
      '<leader>ca',
      function()
        require('actions-preview').code_actions()
      end,
      mode = { 'n', 'v' },
      desc = 'Code Action (Preview)',
    },
  },
  opts = {
    diff = {
      algorithm = 'patience',
      ignore_whitespace = true,
    },
    backend = { 'snacks' },
    snacks = {
      -- You can customize snacks.picker options here if needed
      layout = {
        preset = 'ivy',
        position = 'bottom',
      },
    },
  },
  config = function(_, opts)
    -- Set highlight_command after the plugin is loaded
    local has_highlight, highlight = pcall(require, 'actions-preview.highlight')
    if has_highlight then
      opts.highlight_command = {
        highlight.delta(),
      }
    end
    
    require('actions-preview').setup(opts)
  end,
}
