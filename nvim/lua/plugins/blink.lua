return {

  {
    'saghen/blink.compat',
    -- use the latest release, via version = '*', if you also use the latest release for blink.cmp
    version = '*',
    -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
    lazy = true,
    -- make sure to set opts so that lazy.nvim calls blink.compat's setup
    opts = {},
  },
  {
    'saghen/blink.cmp',
    dependencies = {
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
      { 'Kaiser-Yang/blink-cmp-dictionary', dependencies = { 'nvim-lua/plenary.nvim' } },
      { 'Kaiser-Yang/blink-cmp-avante' },
    },

    build = 'nix run .#build-plugin',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    ---
    opts = {
      keymap = { preset = 'default' },
      completion = {
        trigger = {
          show_on_keyword = true,
          show_on_trigger_character = true,
          show_on_insert_on_trigger_character = true,
          show_on_accept_on_trigger_character = true,
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
        },
        accept = { auto_brackets = { enabled = true } },
        list = { selection = {
          preselect = function(ctx)
            return ctx.mode ~= 'cmdline'
          end,
        } },
      },

      fuzzy = {
        implementation = 'prefer_rust_with_warning',
      },
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
        default = { 'snippets', 'lsp', 'dictionary', 'path', 'buffer' }, -- , 'avante_commands', 'avante_mentions', 'avante_files'
        providers = {
          dictionary = {
            module = 'blink-cmp-dictionary',
            name = 'Dict',
            -- Make sure this is at least 2.
            -- 3 is recommended
            min_keyword_length = 3,
            opts = {
              -- options for blink-cmp-dictionary
            },
          },
          avante = {
            module = 'blink-cmp-avante',
            name = 'Avante',
            opts = {
              -- options for blink-cmp-avante
            },
          },
          -- avante_commands = {
          --   name = 'avante_commands',
          --   module = 'blink.compat.source',
          --   score_offset = 90, -- show at a higher priority than lsp
          --   opts = {},
          -- },
          -- avante_files = {
          --   name = 'avante_files',
          --   module = 'blink.compat.source',
          --   score_offset = 100, -- show at a higher priority than lsp
          --   opts = {},
          -- },
          -- avante_mentions = {
          --   name = 'avante_mentions',
          --   module = 'blink.compat.source',
          --   score_offset = 1000, -- show at a higher priority than lsp
          --   opts = {},
          -- },
        },
      },
    },
    opts_extend = { 'sources.default' },
  },
}
