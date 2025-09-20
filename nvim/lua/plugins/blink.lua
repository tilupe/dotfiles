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
      { 'Kaiser-Yang/blink-cmp-dictionary', dependencies = { 'nvim-lua/plenary.nvim' } },
      { 'Kaiser-Yang/blink-cmp-avante' },
      {
        'fang2hou/blink-copilot',
      },
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
        fuzzy = { implementation = 'prefer_rust_with_warning' },
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
          default = { 'snippets', 'lsp', 'easy-dotnet', 'path', 'buffer' }, -- , 'avante_commands', 'avante_mentions', 'avante_files'
          providers = {
            avante = {
              module = 'blink-cmp-avante',
              name = 'Avante',
              opts = {
                -- options for blink-cmp-avante
              },
            },
            ['easy-dotnet'] = {
              name = 'easy-dotnet',
              enabled = true,
              module = 'easy-dotnet.completion.blink',
              score_offset = 10000,
              async = true,
            },
          },
        },
      }
      require('luasnip.loaders.from_vscode').lazy_load()
    end,
  },
}
