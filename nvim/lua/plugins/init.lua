return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    -- or                              , branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },
  { 'nvim-lua/plenary.nvim' },
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
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },
        signs_staged = {
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          interval = 1000,
          follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
          delay = 1000,
          ignore_whitespace = false,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
        sign_priority = 6,
        status_formatter = nil,
        update_debounce = 200,
        max_file_length = 40000,
        preview_config = {
          border = 'rounded',
          style = 'minimal',
          relative = 'cursor',
          row = 0,
          col = 1,
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
    'rose-pine/neovim',
    name = 'rose-pine',
  },
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = 'latte',
          dark = 'macchiato',
        },
        transparent_background = true,
        show_end_of_buffer = false, -- show the '~' characters after the end of buffers
        term_colors = false,
        dim_inactive = {
          enabled = false,
          shade = 'dark',
          percentage = 0.15,
        },
        no_italic = false, -- Force no italic
        no_bold = false, -- Force no bold
        styles = {
          comments = { 'italic' },
          conditionals = { 'italic' },
          loops = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        color_overrides = {},
        custom_highlights = {},
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          telescope = true,
          notify = false,
          mini = false,
          -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
        },
      }

      -- setup must be called before loading
      -- vim.cmd.colorscheme 'catppuccin'
    end,
  },
  { 'rebelot/kanagawa.nvim', priority = 1000 },
  {
    'neanias/everforest-nvim',
    priority = 1000,
    config = function()
      local everforest = require 'everforest'
      require('everforest').setup {
        ---Controls the "hardness" of the background. Options are "soft", "medium" or "hard".
        ---Default is "medium".
        background = 'hard',
        ---How much of the background should be transparent. 2 will have more UI
        ---components be transparent (e.g. status line background)
        transparent_background_level = 2,
        ---Whether italics should be used for keywords and more.
        italics = true,
        disable_italic_comments = false,
        ---By default, the colour of the sign column background is the same as the as normal text
        ---background, but you can use a grey background by setting this to `"grey"`.
        sign_column_background = 'grey',
        ---The contrast of line numbers, indent lines, etc. Options are `"high"` or
        ---`"low"` (default).
        ui_contrast = 'high',
        ---Dim inactive windows. Only works in Neovim. Can look a bit weird with Telescope.
        ---
        ---When this option is used in conjunction with show_eob set to `false`, the
        ---end of the buffer will only be hidden inside the active window. Inside
        ---inactive windows, the end of buffer filler characters will be visible in
        ---dimmed symbols. This is due to the way Vim and Neovim handle `EndOfBuffer`.
        dim_inactive_windows = true,
        ---Some plugins support highlighting error/warning/info/hint texts, by
        ---default these texts are only underlined, but you can use this option to
        ---also highlight the background of them.
        diagnostic_text_highlight = true,
        ---Which colour the diagnostic text should be. Options are `"grey"` or `"coloured"` (default)
        diagnostic_virtual_text = 'coloured',
        ---Some plugins support highlighting error/warning/info/hint lines, but this
        ---feature is disabled by default in this colour scheme.
        diagnostic_line_highlight = true,
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
        float_style = 'birght',
        ---Inlay hints are special markers that are displayed inline with the code to
        ---provide you with additional information. You can use this option to customize
        ---the background color of inlay hints.
        ---
        ---Options are `"none"` or `"dimmed"`.
        inlay_hints_background = 'dimmed',
        ---You can override specific highlights to use other groups or a hex colour.
        ---This function will be called with the highlights and colour palette tables.
        ---@param highlight_groups Highlights
        ---@param palette Palette
        -- on_highlights = function(hl, palette)
        --   -- hl.DiagnosticError = { fg = palette.none, bg = palette.none, sp = palette.red }
        -- end,
        -- ---@param palette Palette
        -- colours_override = function(palette) end,
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
          csharpier = { command = 'dotnet', args = { 'csharpier', 'format', '--write-stdout' } },
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
          kdl = { 'kdlfmt' },
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
    config = true,
  },
  {
    -- Debug Framework
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
    },
    config = function()
      require 'config.nvim-dap'
    end,
    event = 'VeryLazy',
  },
  {
    -- UI for debugging
    'rcarriga/nvim-dap-ui',
    dependencies = {
      'mfussenegger/nvim-dap',
      'nvim-neotest/nvim-nio',
    },
    config = function()
      require 'config.nvim-dap-ui'
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

  -- {
  --   'nicolasgb/jj.nvim',
  --   config = function()
  --     require('jj').setup {}
  --     local cmd = require 'jj.cmd'
  --     vim.keymap.set('n', '<leader>jd', cmd.describe, { desc = 'JJ describe' })
  --     vim.keymap.set('n', '<leader>jl', cmd.log, { desc = 'JJ log' })
  --     vim.keymap.set('n', '<leader>je', cmd.edit, { desc = 'JJ edit' })
  --     vim.keymap.set('n', '<leader>jn', cmd.new, { desc = 'JJ new' })
  --     vim.keymap.set('n', '<leader>js', cmd.status, { desc = 'JJ status' })
  --     vim.keymap.set('n', '<leader>dj', cmd.diff, { desc = 'JJ diff' })
  --     vim.keymap.set('n', '<leader>sj', cmd.squash, { desc = 'JJ squash' })
  --
  --     -- Pickers
  --     vim.keymap.set('n', '<leader>jg', function()
  --       require('jj.picker').status()
  --     end, { desc = 'JJ Picker status' })
  --     vim.keymap.set('n', '<leader>jh', function()
  --       require('jj.picker').file_history()
  --     end, { desc = 'JJ Picker file history' })
  --
  --     -- Some functions like `describe` or `log` can take parameters
  --     vim.keymap.set('n', '<leader>ji', function()
  --       cmd.log {
  --         revisions = '@',
  --       }
  --     end, { desc = 'JJ log' })
  --
  --     -- This is an alias i use for moving bookmarks its so good
  --     vim.keymap.set('n', '<leader>jt', function()
  --       cmd.j 'tug'
  --       cmd.log {}
  --     end, { desc = 'JJ tug' })
  --   end,
  -- },
  { 'Tastyep/structlog.nvim', version = '*' },
  {
    'nvim-mini/mini.files',
    version = '*',
    config = function()
      require('mini.files').setup()
      vim.keymap.set('n', '-', function()
        MiniFiles.open(vim.api.nvim_buf_get_name(0))
      end, { desc = 'Explore' })

      vim.keymap.set('n', '<leader>e', function()
        MiniFiles.open()
      end, { desc = 'Explore' })
    end,
  },
  {
    'stevearc/overseer.nvim',
    config = true,
  },
  {
    'max397574/better-escape.nvim',
    config = function()
      require('better_escape').setup {
        timeout = 300, -- after `timeout` passes, you can press the escape key and the plugin will ignore it
        default_mappings = false, -- setting this to false removes all the default mappings
        mappings = {
          -- i for insert
          i = {
            j = {
              -- These can all also be functions
              k = '<Esc>',
            },
          },
          c = {
            j = {
              k = '<C-c>',
            },
          },
          t = {
            j = {
              k = '<C-\\><C-n>',
            },
          },
          v = {
            j = {
              k = '<Esc>',
            },
          },
          s = {
            j = {
              k = '<Esc>',
            },
          },
        },
      }
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
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },
  {
    'MagicDuck/grug-far.nvim',
    config = function()
      require('grug-far').setup {}
    end,
  },
  -- {
  --   "ramilito/kubectl.nvim",
  --   -- use a release tag to download pre-built binaries
  --   version = '2.*',
  --   -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  --   build = 'cargo build --release',
  --   dependencies = "saghen/blink.download",
  --   config = function()
  --     require("kubectl").setup({})
  --     vim.keymap.set('n', '<leader>kk', function()
  --       require('kubectl').toggle { true }
  --     end, { noremap = true, silent = true })
  --   end,
  -- },
  {
    'letieu/wezterm-move.nvim',
    keys = { -- Lazy loading, don't need call setup() function
      {
        '<C-h>',
        function()
          require('wezterm-move').move 'h'
        end,
      },
      {
        '<C-j>',
        function()
          require('wezterm-move').move 'j'
        end,
      },
      {
        '<C-k>',
        function()
          require('wezterm-move').move 'k'
        end,
      },
      {
        '<C-l>',
        function()
          require('wezterm-move').move 'l'
        end,
      },
    },
  },
}
