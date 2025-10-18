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
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
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
          lualine_b = { 'branch', 'diff', 'diagnostics' },
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
                unix = '',
                dos = '',
                mac = '',
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

              shorting_target = 40, -- Shortens path to leave 40 spaces in the window
              symbols = {
                modified = '[+]', -- Text to show when the file is modified.
                readonly = '[-]', -- Text to show when the file is non-modifiable or readonly.
                unnamed = '[No Name]', -- Text to show for unnamed buffers.
                newfile = '[New]', -- Text to show for newly created file before first write
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

              shorting_target = 40, -- Shortens path to leave 40 spaces in the window
              symbols = {
                modified = '[+]', -- Text to show when the file is modified.
                readonly = '[-]', -- Text to show when the file is non-modifiable or readonly.
                unnamed = '[No Name]', -- Text to show for unnamed buffers.
                newfile = '[New]', -- Text to show for newly created file before first write
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
