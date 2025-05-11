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
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
      { 'Kaiser-Yang/blink-cmp-dictionary', dependencies = { 'nvim-lua/plenary.nvim' } },
      { 'Kaiser-Yang/blink-cmp-avante' },
      {
        'fang2hou/blink-copilot',
      },
    },
    version = '1.*',
    build = 'nix run .#build-plugin',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
        ['<C-f>'] = {},
      },
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
          window = { border = 'single' },
        },
        accept = { auto_brackets = { enabled = true } },
        list = { selection = {
          preselect = function(ctx)
            return ctx.mode ~= 'cmdline'
          end,
        } },
      },
      fuzzy = {
        implementation = 'prefer_rust',
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
        default = { 'lazydev', 'snippets', 'lsp', 'path', 'buffer' }, -- , 'avante_commands', 'avante_mentions', 'avante_files'
        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 100,
          },
          avante = {
            module = 'blink-cmp-avante',
            name = 'Avante',
            opts = {
              -- options for blink-cmp-avante
            },
          },
        },
      },
    },
    opts_extend = { 'sources.default' },
  },
}
