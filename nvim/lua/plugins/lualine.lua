return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-mini/mini.icons',
      -- 'GustavEikaas/easy-dotnet.nvim',
      {
        'letieu/harpoon-lualine',
        dependencies = {
          {
            'ThePrimeagen/harpoon',
            branch = 'harpoon2',
          },
        },
      },
    },
    config = function()
      local jj = require 'config.jj'
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = { 'dap-view', 'dap-repl', 'k8s_*' },
          },
          ignore_focus = {},
          always_divide_middle = true,
          always_show_tabline = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
            refresh_time = 16, -- ~60fps
            events = {
              'WinEnter',
              'BufEnter',
              'BufWritePost',
              'SessionLoadPost',
              'FileChangedShellPost',
              'VimResized',
              'Filetype',
              'CursorMoved',
              'CursorMovedI',
              'ModeChanged',
            },
          },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {
            { jj.bookmark, cond = jj.is_jj_repo, icon = '' },
            { 'branch', cond = jj.is_not_jj_repo },
            'diff',
            'diagnostics',
          },
          lualine_c = {
            {
              'macro',
              fmt = function()
                local reg = vim.fn.reg_recording()
                if reg ~= '' then
                  return 'Recording @' .. reg
                end
                return nil
              end,
              color = { fg = '#ff9e64' },
              draw_empty = false,
            },
            {
              'harpoon2',
              icon = '♥',
              indicators = { 'a', 's', 'q', 'w' },
              active_indicators = { 'A', 'S', 'Q', 'W' },
              color_active = { fg = '#00ff00' },
              _separator = ' ',
              no_harpoon = 'Harpoon not loaded',
            },
            'filename',
          },
          lualine_x = {
            'encoding',
            {
              'fileformat',
              symbols = {
                unix = '',
                dos = '',
                mac = '',
              },
            },
            'filetype',
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            {
              'filename',
              file_status = true,
              newfile_status = false,
              path = 3,
              shorting_target = 40,
              symbols = {
                modified = '[+]',
                readonly = '[-]',
                unnamed = '[No Name]',
                newfile = '[New]',
              },
            },
          },
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
        inactive_winbar = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            {
              'filename',
              file_status = true,
              newfile_status = false,
              path = 3,
              shorting_target = 40,
              symbols = {
                modified = '[+]',
                readonly = '[-]',
                unnamed = '[No Name]',
                newfile = '[New]',
              },
            },
          },
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
        extensions = {},
      }
    end,
  },
}
