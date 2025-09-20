return {
  {
    'seblyng/roslyn.nvim',
    ft = { 'cs', 'razor' },
    dependencies = {
      {
        -- By loading as a dependencies, we ensure that we are available to set
        -- the handlers for Roslyn.
        'tris203/rzls.nvim',
        config = function()
          require('rzls').setup {
            path = vim.fn.exepath 'rzls',
          }
        end,
      },
    },
    opts = {
      -- "auto" | "roslyn" | "off"
      --
      -- - "auto": Does nothing for filewatching, leaving everything as default
      -- - "roslyn": Turns off neovim filewatching which will make roslyn do the filewatching
      -- - "off": Hack to turn off all filewatching. (Can be used if you notice performance issues)
      filewatching = 'auto',

      -- Optional function that takes an array of targets as the only argument. Return the target you
      -- want to use. If it returns `nil`, then it falls back to guessing the target like normal
      -- Example:
      --
      -- choose_target = function(target)
      --     return vim.iter(target):find(function(item)
      --         if string.match(item, "Foo.sln") then
      --             return item
      --         end
      --     end)
      -- end
      choose_target = nil,

      -- Optional function that takes the selected target as the only argument.
      -- Returns a boolean of whether it should be ignored to attach to or not
      --
      -- I am for example using this to disable a solution with a lot of .NET Framework code on mac
      -- Example:
      --
      -- ignore_target = function(target)
      --     return string.match(target, "Foo.sln") ~= nil
      -- end
      ignore_target = nil,

      -- Whether or not to look for solution files in the child of the (root).
      -- Set this to true if you have some projects that are not a child of the
      -- directory with the solution file
      broad_search = false,

      -- Whether or not to lock the solution target after the first attach.
      -- This will always attach to the target in `vim.g.roslyn_nvim_selected_solution`.
      -- NOTE: You can use `:Roslyn target` to change the target
      lock_target = false,
    },
    conig = true,
    init = function()
      -- We add the Razor file types before the plugin loads.
      vim.filetype.add {
        extension = {
          razor = 'razor',
          cshtml = 'razor',
        },
      }
    end,
  },

  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'VeryLazy', -- Or `LspAttach`
    priority = 1000, -- needs to be loaded in first
    config = function()
      require('tiny-inline-diagnostic').setup {
        -- ...
        signs = {
          left = '',
          right = '',
          diag = '●',
          arrow = '    ',
          up_arrow = '    ',
          vertical = ' │',
          vertical_end = ' └',
        },
        blend = {
          factor = 0.22,
        },
        -- ...
      }

      vim.diagnostic.config { virtual_text = false }
    end,
  },
}
