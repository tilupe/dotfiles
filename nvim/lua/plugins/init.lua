return {
  { 'nvim-lua/plenary.nvim' },
  { 'nvim-neotest/nvim-nio' },
  {
    'sindrets/diffview.nvim',
    config = function()
      require('diffview').setup {
        default_args = {
          DiffviewOpen = { '--imply-local' },
        },
        keymaps = {
          file_panel = {
            {
              'n',
              'cc',
              function()
                vim.ui.input({ prompt = 'Commit message: ' }, function(msg)
                  if not msg then
                    return
                  end
                  local results = vim.system({ 'git', 'commit', '-m', msg }, { text = true }):wait()

                  if results.code ~= 0 then
                    vim.notify(
                      'Commit failed with the message: \n' .. vim.trim(results.stdout .. '\n' .. results.stderr),
                      vim.log.levels.ERROR,
                      { title = 'Commit' }
                    )
                  else
                    vim.notify(results.stdout, vim.log.levels.INFO, { title = 'Commit' })
                  end
                end)
              end,
            },
          },
        },
      }

      vim.keymap.set('n', '<leader>gd', '<CMD>DiffviewOpen<CR>', { desc = 'Diffview open' })
      vim.keymap.set(
        'n',
        '<leader>gDh',
        '<CMD>DiffviewFileHistory --range=origin/HEAD...HEAD --right-only --no-merges<CR>',
        { desc = '[D]iffview commit [h]istory' }
      )
      vim.keymap.set('n', '<leader>gm', '<CMD>DiffviewOpen origin/master...HEAD<CR>', { desc = 'Master [D]' })
      vim.keymap.set('n', '<leader>gq', '<CMD>DiffviewClose<CR>', { desc = 'Quit [D]' })
      vim.keymap.set('n', '<leader>gh', '<CMD>DiffviewFileHistory %<CR>', { desc = 'history' })
      vim.keymap.set('n', '<leader>gH', '<CMD>DiffviewFileHistory<CR>', { desc = 'All File [H]istory' })
      vim.keymap.set('n', '<leader>gR', '<CMD>DiffviewRefresh<CR>', { desc = 'All File [H]istory' })
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufRead',
    config = function()
      require('gitsigns').setup {
        signs = {
          add = { text = '▌' },
          change = { text = '▌' },
          delete = { text = '▌' },
          topdelete = { text = '▌' },
          changedelete = { text = '▌' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          vim.keymap.set('n', '<leader>gj', function()
            if vim.wo.diff then
              return ']c'
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Next Hunk' })

          vim.keymap.set('n', '<leader>gk', function()
            if vim.wo.diff then
              return '[c'
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Prev Hunk' })

          vim.keymap.set('n', '<leader>gj', '<CMD>Gitsigns next_hunk<CR>', { desc = 'Next Hunk' })
          vim.keymap.set('n', '<leader>gk', '<CMD>Gitsigns prev_hunk<CR>', { desc = 'Prev Hunk' })
          vim.keymap.set('n', '<leader>gs', '<CMD>Gitsigns stage_hunk<CR>', { desc = 'Stage Hunk' })
          vim.keymap.set('n', '<leader>gS', '<CMD>Gitsigns undo_stage_hunk<CR>', { desc = 'Undo Stage Hunk' })
          vim.keymap.set('n', '<leader>gr', '<CMD>Gitsigns reset_hunk<CR>', { desc = 'Reset Hunk' })
          vim.keymap.set('n', '<leader>gb', '<CMD>Gitsigns blame<CR>', { desc = 'Blame' })
          vim.keymap.set('n', '<leader>gB', '<CMD>Gitsigns blame_line<CR>', { desc = 'Blame Line' })
          vim.keymap.set('n', '<leader>gp', '<CMD>Gitsigns preview_hunk<CR>', { desc = 'Preview Hunk' })
          vim.keymap.set('n', '<leader>gP', '<CMD>Gitsigns preview_hunk_inline<CR>', { desc = 'Preview Hunk Inline' })
        end,
      }
    end,
    keys = {},
  },
  {
    'mbbill/undotree',
    lazy = true,
    cmd = 'UndotreeToggle',
    keys = {
      { '<leader>U', ':UndotreeToggle<cr>' },
    },
  }, -- see undo tree
  {
    'neanias/everforest-nvim',
    priority = 1000,
    config = function()
      local everforest = require 'everforest'
      require('everforest').setup {
        ---Controls the "hardness" of the background. Options are "soft", "medium" or "hard".
        ---Default is "medium".
        background = 'medium',
        ---How much of the background should be transparent. 2 will have more UI
        ---components be transparent (e.g. status line background)
        transparent_background_level = 2,
        ---Whether italics should be used for keywords and more.
        italics = false,
        ---Disable italic fonts for comments. Comments are in italics by default, set
        ---this to `true` to make them _not_ italic!
        disable_italic_comments = false,
        ---By default, the colour of the sign column background is the same as the as normal text
        ---background, but you can use a grey background by setting this to `"grey"`.
        sign_column_background = 'none',
        ---The contrast of line numbers, indent lines, etc. Options are `"high"` or
        ---`"low"` (default).
        ui_contrast = 'low',
        ---Dim inactive windows. Only works in Neovim. Can look a bit weird with Telescope.
        ---
        ---When this option is used in conjunction with show_eob set to `false`, the
        ---end of the buffer will only be hidden inside the active window. Inside
        ---inactive windows, the end of buffer filler characters will be visible in
        ---dimmed symbols. This is due to the way Vim and Neovim handle `EndOfBuffer`.
        dim_inactive_windows = false,
        ---Some plugins support highlighting error/warning/info/hint texts, by
        ---default these texts are only underlined, but you can use this option to
        ---also highlight the background of them.
        diagnostic_text_highlight = false,
        ---Which colour the diagnostic text should be. Options are `"grey"` or `"coloured"` (default)
        diagnostic_virtual_text = 'coloured',
        ---Some plugins support highlighting error/warning/info/hint lines, but this
        ---feature is disabled by default in this colour scheme.
        diagnostic_line_highlight = false,
        ---By default, this color scheme won't colour the foreground of |spell|, instead
        ---colored under curls will be used. If you also want to colour the foreground,
        ---set this option to `true`.
        spell_foreground = false,
        ---Whether to show the EndOfBuffer highlight.
        show_eob = true,
        ---Style used to make floating windows stand out from other windows. `"bright"`
        ---makes the background of these windows lighter than |hl-Normal|, whereas
        ---`"dim"` makes it darker.
        ---
        ---Floating windows include for instance diagnostic pop-ups, scrollable
        ---documentation windows from completion engines, overlay windows from
        ---installers, etc.
        ---
        ---NB: This is only significant for dark backgrounds as the light palettes
        ---have the same colour for both values in the switch.
        float_style = 'bright',
        ---Inlay hints are special markers that are displayed inline with the code to
        ---provide you with additional information. You can use this option to customize
        ---the background color of inlay hints.
        ---
        ---Options are `"none"` or `"dimmed"`.
        inlay_hints_background = 'none',
        ---You can override specific highlights to use other groups or a hex colour.
        ---This function will be called with the highlights and colour palette tables.
        ---@param highlight_groups Highlights
        ---@param palette Palette
        on_highlights = function(highlight_groups, palette) end,
        ---You can override colours in the palette to use different hex colours.
        ---This function will be called once the base and background colours have
        ---been mixed on the palette.
        ---@param palette Palette
        colours_override = function(palette) end,
      }
      -- everforest.setup {
      --
      --   background = 'hard',
      --   italics = true,
      --   inlay_hints_background = 'dimmed',
      --   disable_italic_comments = false,
      --   diagnostic_line_highlight = true,
      --   show_eob = false,
      --   spell_foreground = true,
      -- }
      everforest.load()
    end,
  },
  { 'norcalli/nvim-colorizer.lua' },
  {
    'zbirenbaum/copilot.lua', -- Copilot but lua
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = true,
    opts = {
      panel = {
        enabled = false,
        auto_refresh = false,
        keymap = {
          jump_prev = '[[',
          jump_next = ']]',
          accept = '<C-CR>',
          refresh = 'gr',
          open = '<M-CR>',
        },
        layout = {
          position = 'bottom', -- | top | left | right
          ratio = 0.4,
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = '<C-f>',
          accept_word = false,
          accept_line = false,
          next = '<C-Down>',
          prev = '<C-Up>',
          dismiss = '<C-x>',
        },
      },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ['.'] = false,
      },
      copilot_node_command = 'node', -- Node.js version must be > 18.x
      server_opts_overrides = {},
    },
  },
  {
    'stevearc/conform.nvim',
    config = function()
      require('conform').setup {
        formatters = {
          csharpier = { command = 'dotnet', args = { 'csharpier', '--write-stdout' } },
        },
        formatters_by_ft = {
          lua = { 'stylua' },
          go = { 'goimports', 'gofmt' },
          python = { 'isort', 'black' },
          rust = { 'rustfmt', lsp_format = 'fallback' },
          javascript = { 'prettierd', 'prettier', stop_after_first = true },
          cs = { 'csharpier' },
          nix = { 'nixfmt' },
          json = { 'jq' },
          sql = { 'sql_formatter', lsp_format = 'never' },
          --['*'] = { 'injected' }, -- enables injected-lang formatting for all filetypes
        },
        default_format_opts = {
          lsp_format = 'fallback',
        },
      }
      require('conform').formatters.sql_formatter = {
        prepend_args = { '-c', vim.fn.expand '~/.config/sql_formatter.json' },
      }

      vim.keymap.set('n', '<leader>bw', function()
        require('conform').format()
        vim.cmd 'update!'
      end, { desc = 'Save' })
      vim.keymap.set('n', '<leader>ba', function()
        require('conform').format()
        vim.cmd 'wa'
      end, { desc = 'Save' })

      vim.keymap.set('n', '<leader>cf', function()
        require('conform').format()
      end, { desc = 'Format' })
    end,
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    version = '*',
    config = function()
      require 'config.luasnip'
    end,
  },
  {
    'mfussenegger/nvim-dap',
    config = function()
      require('config.dap').setup()
    end,
  },
  { 'nvim-tree/nvim-web-devicons', version = '*' },
  {
    'NeogitOrg/neogit',
    config = function()
      require('neogit').setup {
        kind = 'auto',
        graph_style = 'unicode',
        disable_commit_confirmation = false,
        integrations = {
          diffview = true,
        },
      }

      vim.keymap.set('n', '<leader>gg', function()
        local neogit = require 'neogit'
        return neogit.open { kind = 'replace' }
      end, { desc = 'Neogit' })
    end,
  },
  { 'Tastyep/structlog.nvim', version = '*' },
  {
    'stevearc/oil.nvim',
    version = '*',
    config = function()
      require('oil').setup {
        default_file_explorer = false,
      }
      vim.api.nvim_create_autocmd('User', {
        pattern = 'OilActionsPost',
        callback = function(event)
          if event.data.actions.type == 'move' then
            Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
          end
        end,
      })

      vim.keymap.set('n', '<leader>-', function()
        local git_root_path = vim.fn.finddir('.git', '.;')
        vim.cmd('Oil ' .. git_root_path)
      end, { desc = 'Explore git root' })
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Explore' })
    end,
  },
  {
    'stevearc/overseer.nvim',
    config = true,
  },
  {
    'max397574/better-escape.nvim',
    config = function()
      require('better_escape').setup()
    end,
  },
  {
    'stevearc/quicker.nvim',
    lazy = false,
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {},
    config = function()
      vim.keymap.set('n', '<leader>qf', function()
        require('quicker').toggle()
      end, {
        desc = 'Toggle quickfix',
      })
      vim.keymap.set('n', '<leader>ql', function()
        require('quicker').toggle { loclist = true }
      end, {
        desc = 'Toggle loclist',
      })
      require('quicker').setup {
        keys = {
          {
            '>',
            function()
              require('quicker').expand { before = 2, after = 2, add_to_existing = true }
            end,
            desc = 'Expand quickfix context',
          },
          {
            '<',
            function()
              require('quicker').collapse()
            end,
            desc = 'Collapse quickfix context',
          },
        },
      }
    end,
  },
  {
    'OXY2DEV/helpview.nvim',
    lazy = false, -- Recommended

    -- In case you still want to lazy load
    -- ft = "help",

    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },
  {
    'GustavEikaas/easy-dotnet.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'folke/snacks.nvim' },
    ft = 'cs',
    config = function()
      local dotnet = require 'easy-dotnet'
      dotnet.setup {
        picker = 'snacks',
      }
    end,
    keys = {
      {
        '<leader>xr',
        function()
          require('easy-dotnet').run_profile()
        end,
        { desc = '[r]un' },
      },
      {
        '<leader>xb',
        function()
          require('easy-dotnet').build_quickfix()
        end,
        { desc = '[b]uild' },
      },
      {
        '<leader>xs',
        function()
          require('easy-dotnet').restore()
        end,
        { desc = 'Re[s]tor' },
      },
      {
        '<leader>xd',
        function()
          vim.cmd 'Dotnet'
        end,
        { desc = 'Dotnet' },
      },
    },
  },
  {
    'MagicDuck/grug-far.nvim',
    config = function()
      require('grug-far').setup {}
    end,
  },
  {
    'ramilito/kubectl.nvim',
    config = function()
      require('kubectl').setup()
      vim.keymap.set('n', '<leader>k', '<cmd>lua require("kubectl").toggle()<cr>', { noremap = true, silent = true })
    end,
  },
  {
    'mrjones2014/smart-splits.nvim',
    config = function()
      vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
      vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
      vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
      vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
      vim.keymap.set('n', '<C-\\>', require('smart-splits').move_cursor_previous)
    end,
  },
  {
    'MonsieurTib/neonuget',
    config = function()
      require('neonuget').setup {
        -- Optional configuration
        dotnet_path = 'dotnet', -- Path to dotnet CLI
        default_project = nil, -- Auto-detected, or specify path like "./MyProject/MyProject.csproj"
      }
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },
  -- {
  --   'mcauley-penney/visual-whitespace.nvim',
  --   config = true,
  --   opts = {
  --     enable = true,
  --   },
  --   keys = {
  --     { '<leader>uW',
  --       function ()
  --       require("visual-whitespace").toggle()
  --     end
  --       , { desc = 'WhiteSpace' } },
  --   },
  -- },
  -- { 'ThePrimeagen/vim-be-good' },
  -- {
  --   'm4xshen/hardtime.nvim',
  --   dependencies = { 'MunifTanjim/nui.nvim' },
  --   config = true,
  --   keys = {
  --     { '<leader>gH', '<CMD>Hardtime toggle<CR>', { desc = 'Hardtime' } },
  --   },
  -- }
}
