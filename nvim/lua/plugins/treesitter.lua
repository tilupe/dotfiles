return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    -- function()
    -- require('nvim-treesitter.install').update { with_sync = true }()
    -- end,
    config = function()
      require('nvim-treesitter').setup {
        -- Directory to install parsers and queries to (prepended to `runtimepath` to have priority)
        install_dir = vim.fn.stdpath 'data' .. '/site',
      }

      require('nvim-treesitter').install {
        'bash',
        'c',
        'c_sharp',
        'cpp',
        'css',
        'dockerfile',
        'go',
        'html',
        'hyprlang',
        'http',
        'java',
        'javascript',
        'json',
        'kdl',
        'lua',
        'markdown',
        'markdown_inline',
        'nix',
        'php',
        'python',
        'query',
        'razor',
        'rust',
        'scss',
        'sql',
        'templ',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
        'zig',
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'norg',
          'neorg',
          'lua',
          'python',
          'rust',
          'typescript',
          'javascript',
          'c',
          'cpp',
          'java',
          'go',
          'html',
          'css',
          'markdown',
          'yaml',
          'json',
          'toml',
          'bash',
          'zsh',
          'sh',
        },
        callback = function()
          if pcall(vim.treesitter.start) then
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    config = function()
      require('nvim-treesitter-textobjects').setup {
        select = {
          enable = true,
          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,
          -- You can choose the select mode (default is charwise 'v')
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * method: eg 'v' or 'o'
          -- and should return the mode ('v', 'V', or '<c-v>') or a table
          -- mapping query_strings to modes.
          selection_modes = {
            ['@parameter.outer'] = 'v', -- charwise
            ['@function.outer'] = 'V', -- linewise
            -- ['@class.outer'] = '<c-v>', -- blockwise
          },
          -- If you set this to `true` (default is `false`) then any textobject is
          -- extended to include preceding or succeeding whitespace. Succeeding
          -- whitespace has priority in order to act similarly to eg the built-in
          -- `ap`.
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * selection_mode: eg 'v'
          -- and should return true of false
          include_surrounding_whitespace = false,
        },
        move = {
          -- whether to set jumps in the jumplist
          set_jumps = true,
        },
      }

      local select = require('nvim-treesitter-textobjects.select').select_textobject

      vim.keymap.set({ 'o', 'x' }, 'af', function()
        select('@function.outer', 'textobjects')
      end, { desc = 'Select around function' })
      vim.keymap.set({ 'o', 'x' }, 'if', function()
        select('@function.inner', 'textobjects')
      end, { desc = 'Select inner function' })
      vim.keymap.set({ 'o', 'x' }, 'ac', function()
        select('@class.outer', 'textobjects')
      end, { desc = 'Select outer class' })
      vim.keymap.set({ 'o', 'x' }, 'ic', function()
        select('@class.inner', 'textobjects')
      end, { desc = 'Select inner class' })
      vim.keymap.set({ 'o', 'x' }, 'as', function()
        select('@local.scope', 'locals')
      end, { desc = 'Select outer class' })

      local swap = require 'nvim-treesitter-textobjects.swap'
      vim.keymap.set('n', '<leader>ps', function()
        swap.swap_next '@parameter.inner'
      end)
      vim.keymap.set('n', '<leader>pS', function()
        swap.swap_previous '@parameter.outer'
      end)

      local move = require 'nvim-treesitter-textobjects.move'

      -- You can use the capture groups defined in `textobjects.scm`
      vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
        move.goto_next_start('@function.outer', 'textobjects')
      end)
      vim.keymap.set({ 'n', 'x', 'o' }, ']]', function()
        move.goto_next_start('@class.outer', 'textobjects')
      end)
      -- You can also pass a list to group multiple queries.
      vim.keymap.set({ 'n', 'x', 'o' }, ']o', function()
        move.goto_next_start({ '@loop.inner', '@loop.outer' }, 'textobjects')
      end)
      -- You can also use captures from other query groups like `locals.scm` or `folds.scm`
      vim.keymap.set({ 'n', 'x', 'o' }, ']s', function()
        move.goto_next_start('@local.scope', 'locals')
      end)
      vim.keymap.set({ 'n', 'x', 'o' }, ']z', function()
        move.goto_next_start('@fold', 'folds')
      end)

      vim.keymap.set({ 'n', 'x', 'o' }, ']M', function()
        move.goto_next_end('@function.outer', 'textobjects')
      end)
      vim.keymap.set({ 'n', 'x', 'o' }, '][', function()
        move.goto_next_end('@class.outer', 'textobjects')
      end)

      vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
        move.goto_previous_start('@function.outer', 'textobjects')
      end)
      vim.keymap.set({ 'n', 'x', 'o' }, '[[', function()
        move.goto_previous_start('@class.outer', 'textobjects')
      end)

      vim.keymap.set({ 'n', 'x', 'o' }, '[M', function()
        move.goto_previous_end('@function.outer', 'textobjects')
      end)
      vim.keymap.set({ 'n', 'x', 'o' }, '[]', function()
        move.goto_previous_end('@class.outer', 'textobjects')
      end)
    end,
  },
  -- { 'yorickpeterse/nvim-tree-pairs', config = true },
}
