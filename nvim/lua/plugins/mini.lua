return {

  { 'nvim-mini/mini.icons', version = false, config = true },
  { 'nvim-mini/mini.extra', version = false, config = true },
  {
    'nvim-mini/mini.ai',
    event = 'VeryLazy',
    config = true,
  },
  {
    'nvim-mini/mini.bracketed',
    version = '*',
    config = true,
  },
  { 'nvim-mini/mini.pairs', version = '*', config = true },
  {
    'nvim-mini/mini.surround',
    version = '*',
    config = true,
  },
  {
    'nvim-mini/mini.clue',
    version = '*',
    config = function()
      local miniclue = require 'mini.clue'
      miniclue.setup { -- cute prompts about bindings

        triggers = {
          { mode = 'n', keys = '<Leader>' },
          { mode = 'x', keys = '<Leader>' },
          { mode = 'n', keys = '<space>' },
          { mode = 'x', keys = '<space>' },

          -- Built-in completion
          { mode = 'i', keys = '<C-x>' },

          -- `g` key
          { mode = 'n', keys = 'g' },
          { mode = 'x', keys = 'g' },

          -- Marks
          { mode = 'n', keys = "'" },
          { mode = 'n', keys = '`' },
          { mode = 'x', keys = "'" },
          { mode = 'x', keys = '`' },

          -- Registers
          { mode = 'n', keys = '"' },
          { mode = 'x', keys = '"' },
          { mode = 'i', keys = '<C-r>' },
          { mode = 'c', keys = '<C-r>' },

          -- Window commands
          { mode = 'n', keys = '<C-w>' },

          -- `z` key
          { mode = 'n', keys = 'z' },
          { mode = 'x', keys = 'z' },

          -- Bracketed
          { mode = 'n', keys = '[' },
          { mode = 'n', keys = ']' },
        },
        clues = {
          { mode = 'n', keys = '<Leader>t', desc = '+Test' },
          { mode = 'n', keys = '<Leader>g', desc = '+Git' },
          { mode = 'n', keys = '<Leader>f', desc = '+Find' },
          { mode = 'n', keys = '<Leader>x', desc = '+eXecute' },
          { mode = 'n', keys = '<Leader>r', desc = '+Refactor' },
          { mode = 'n', keys = '<Leader>l', desc = '+Lsp' },
          { mode = 'n', keys = '<Leader>c', desc = '+Code' },
          { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
          { mode = 'n', keys = '<Leader>u', desc = '+Toggle' },
          { mode = 'n', keys = '<Leader>k', desc = '+Harpoon' },
          { mode = 'n', keys = '<Leader>d', desc = '+Debug' },
          miniclue.gen_clues.builtin_completion(),
          miniclue.gen_clues.g(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers(),
          miniclue.gen_clues.windows(),
          miniclue.gen_clues.z(),
        },
      }
    end,
  },
}
