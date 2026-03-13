return {
  {
    'saghen/blink.compat',
    version = '*',
    lazy = true,
    config = true,
    opts = {},
  },
  {
    'saghen/blink.cmp',
    dependencies = {
      -- 'mikavilpas/blink-ripgrep.nvim',
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
      -- { 'Kaiser-Yang/blink-cmp-dictionary', dependencies = { 'nvim-lua/plenary.nvim' } },
      -- { 'Kaiser-Yang/blink-cmp-avante' },
      { 'folke/lazydev.nvim', opts = {} },
      -- {
      --   'fang2hou/blink-copilot',
      -- },
    },
    version = '1.*',
    build = 'nix run .#build-plugin',
    config = function()
      vim.cmd 'highlight Pmenu guibg=none'
      vim.cmd 'highlight PmenuExtra guibg=none'
      vim.cmd 'highlight FloatBorder guibg=none'
      vim.cmd 'highlight NormalFloat guibg=none'
      require('blink.cmp').setup {
        keymap = {
          preset = 'default',
          ['<Up>'] = { 'select_prev', 'fallback' },
          ['<Down>'] = { 'select_next', 'fallback' },
          ['<C-f>'] = {},
        },
        cmdline = {
          enabled = true,
          completion = { menu = { auto_show = true } },
        },
        completion = {
          menu = {
            border = nil,
            scrolloff = 1,
            scrollbar = false,
            draw = {
              columns = {
                { 'kind_icon' },
                { 'label', 'label_description', gap = 1 },
                { 'kind' },
                { 'source_name' },
              },
            },
          },
          trigger = {
            show_on_keyword = true,
            show_on_trigger_character = true,
            show_on_insert_on_trigger_character = true,
            show_on_accept_on_trigger_character = true,
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
            window = {
              border = nil,
              scrollbar = false,
              winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
            },
          },
          accept = { auto_brackets = { enabled = true } },
          list = { selection = {
            preselect = function(ctx)
              return ctx.mode ~= 'cmdline'
            end,
          } },
        },
        -- fuzzy = { implementation = 'prefer_rust_with_warning' },
        appearance = {
          use_nvim_cmp_as_default = true,
          nerd_font_variant = 'mono',
        },
        signature = {
          enabled = true,
          window = {
            show_documentation = true,
          },
        },
        snippets = { preset = 'luasnip' },
        sources = {
          default = { 'snippets', 'lazydev', 'lsp', 'path', 'buffer' }, -- , 'avante_commands', 'avante_mentions', 'avante_files' 'easy-dotnet'
          per_filetype = {
            gitcommit = { 'git' },
            markdown = { 'snippets', 'lsp', 'path', 'buffer' },
          },
          providers = {
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              -- make lazydev completions top priority (see `:h blink.cmp`)
              score_offset = 100,
            },
          },
        },
      }
      require('luasnip.loaders.from_vscode').lazy_load()
    end,
  },
  {
    'xzbdmw/colorful-menu.nvim',
    config = function()
      -- You don't need to set these options.
      require('colorful-menu').setup {
        ls = {
          lua_ls = {
            -- Maybe you want to dim arguments a bit.
            arguments_hl = '@comment',
          },
          gopls = {
            -- By default, we render variable/function's type in the right most side,
            -- to make them not to crowd together with the original label.

            -- when true:
            -- foo             *Foo
            -- ast         "go/ast"

            -- when false:
            -- foo *Foo
            -- ast "go/ast"
            align_type_to_right = true,
            -- When true, label for field and variable will format like "foo: Foo"
            -- instead of go's original syntax "foo Foo". If align_type_to_right is
            -- true, this option has no effect.
            add_colon_before_type = false,
            -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
            preserve_type_when_truncate = true,
          },
          -- for lsp_config or typescript-tools
          ts_ls = {
            -- false means do not include any extra info,
            -- see https://github.com/xzbdmw/colorful-menu.nvim/issues/42
            extra_info_hl = '@comment',
          },
          vtsls = {
            -- false means do not include any extra info,
            -- see https://github.com/xzbdmw/colorful-menu.nvim/issues/42
            extra_info_hl = '@comment',
          },
          ['rust-analyzer'] = {
            -- Such as (as Iterator), (use std::io).
            extra_info_hl = '@comment',
            -- Similar to the same setting of gopls.
            align_type_to_right = true,
            -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
            preserve_type_when_truncate = true,
          },
          clangd = {
            -- Such as "From <stdio.h>".
            extra_info_hl = '@comment',
            -- Similar to the same setting of gopls.
            align_type_to_right = true,
            -- the hl group of leading dot of "•std::filesystem::permissions(..)"
            import_dot_hl = '@comment',
            -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
            preserve_type_when_truncate = true,
          },
          zls = {
            -- Similar to the same setting of gopls.
            align_type_to_right = true,
          },
          roslyn = {
            extra_info_hl = '@comment',
          },
          dartls = {
            extra_info_hl = '@comment',
          },
          -- The same applies to pyright/pylance
          basedpyright = {
            -- It is usually import path such as "os"
            extra_info_hl = '@comment',
          },
          pylsp = {
            extra_info_hl = '@comment',
            -- Dim the function argument area, which is the main
            -- difference with pyright.
            arguments_hl = '@comment',
          },
          -- If true, try to highlight "not supported" languages.
          fallback = true,
          -- this will be applied to label description for unsupport languages
          fallback_extra_info_hl = '@comment',
        },
        -- If the built-in logic fails to find a suitable highlight group for a label,
        -- this highlight is applied to the label.
        fallback_highlight = '@variable',
        -- If provided, the plugin truncates the final displayed text to
        -- this width (measured in display cells). Any highlights that extend
        -- beyond the truncation point are ignored. When set to a float
        -- between 0 and 1, it'll be treated as percentage of the width of
        -- the window: math.floor(max_width * vim.api.nvim_win_get_width(0))
        -- Default 60.
        max_width = 60,
      }
    end,
  },
}
