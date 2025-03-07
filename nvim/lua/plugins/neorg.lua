return {
  {
    'nvim-neorg/neorg',
    dependencies = {
      { 'nvim-neorg/neorg-telescope' },
      { 'benlubas/neorg-interim-ls' },
      { 'nvim-lua/plenary.nvim' },
    },
    lazy = false,
    version = '*',
    config = function()
      require('neorg').setup {
        load = {
          ['core.defaults'] = {},
          ['core.concealer'] = {},
          ['core.esupports.metagen'] = {
            type = 'auto',
          },
          ['core.completion'] = {
            config = { engine = { module_name = 'external.lsp-completion' } },
          },
          ['core.integrations.telescope'] = {},
          ['core.export'] = {},
          ['core.text-objects'] = {},
          ['core.export.markdown'] = {},
          ['core.dirman'] = {
            config = {
              workspaces = {
                notes = '~/private/notes',
              },
              default_workspace = 'notes',
            },
          },
          ['external.interim-ls'] = {
            config = {
              -- default config shown
              completion_provider = {
                -- Enable or disable the completion provider
                enable = true,

                -- Show file contents as documentation when you complete a file name
                documentation = true,

                -- Try to complete categories provided by Neorg Query. Requires `benlubas/neorg-query`
                categories = false,

                -- suggest heading completions from the given file for `{@x|}` where `|` is your cursor
                -- and `x` is an alphanumeric character. `{@name}` expands to `[name]{:$/people:# name}`
                people = {
                  enable = false,

                  -- path to the file you're like to use with the `{@x` syntax, relative to the
                  -- workspace root, without the `.norg` at the end.
                  -- ie. `folder/people` results in searching `$/folder/people.norg` for headings.
                  -- Note that this will change with your workspace, so it fails silently if the file
                  -- doesn't exist
                  path = 'people',
                },
              },
            },
          },
        },
      }

      vim.wo.foldlevel = 99
      vim.wo.conceallevel = 2

      vim.keymap.set('i', '<C-l>', function()
        require('telescope').extensions.neorg.insert_link()
      end, { desc = 'Insert Neorg link' })
      vim.keymap.set('i', '<C-S-L>', function()
        require('telescope').extensions.neorg.insert_file_link()
      end, { desc = 'Insert Neorg link' })

      vim.keymap.set('n', '<leader>nr', ':Neorg return<CR>', { desc = 'Return to Neorg' })
      vim.keymap.set('n', '<leader>no', ':Neorg index<CR>', { desc = 'Open Neorg index' })
      vim.keymap.set('n', '<leader>nn', function()
        -- Prompt the user for note title
        vim.ui.input({
          prompt = 'Enter note title: ',
        }, function(title)
          -- Check if the user cancelled or provided empty input
          if not title or title == '' then
            print 'Note creation cancelled'
            return
          end

          -- Format the filename:
          -- 1. Replace spaces with underscores
          local formatted_title = title:gsub('%s+', '_')

          -- 2. Create timestamp prefix in YYYYMMddhhss format
          local timestamp = os.date '%Y%m%d%H%M%S'

          -- 3. Combine timestamp and title with proper extension
          local filename = timestamp .. '-' .. formatted_title .. '.norg'

          -- Determine the target directory
          local current_buffer_path = vim.fn.expand '%:p:h'
          local notes_root = vim.fn.expand '~/private/notes'
          local target_dir

          -- Check if current buffer is within the notes directory
          if string.find(current_buffer_path, notes_root, 1, true) then
            target_dir = current_buffer_path
          else
            target_dir = notes_root .. '/inbox'
          end

          -- Create the inbox directory if it doesn't exist
          if target_dir == notes_root .. '/inbox' then
            vim.fn.mkdir(target_dir, 'p')
          end

          -- Full path for the new note
          local file_path = target_dir .. '/' .. filename

          -- Create and open the file
          vim.cmd('edit ' .. vim.fn.fnameescape(file_path))

          -- Add title as a heading in the new note
          vim.api.nvim_buf_set_lines(0, 0, 0, false, {
            '* ' .. title,
            '',
            '', -- Extra line for content
          })

          -- Position cursor on the empty line after the heading
          vim.api.nvim_win_set_cursor(0, { 3, 0 })

          -- Enable insert mode
          vim.cmd 'startinsert'

          print('Created new note: ' .. filename)
        end)
      end, { desc = 'New note' })

      vim.keymap.set('n', '<leader>nt', function()
        -- Prompt the user for task text
        vim.ui.input({
          prompt = 'Enter task: ',
        }, function(task_text)
          -- Check if the user cancelled or provided empty input
          if not task_text or task_text == '' then
            print 'Task capture cancelled'
            return
          end

          -- Format the task in Neorg format
          local task_line = '- ( ) ' .. task_text

          -- Path to the todo file
          local file_path = vim.fn.expand '~/private/notes/todo.norg'

          -- Append the task to the file
          local file = io.open(file_path, 'a')
          if not file then
            print('Error: Could not open file ' .. file_path)
            return
          end

          -- Add a newline if needed and append the task
          file:write('\n' .. task_line)
          file:close()

          print('Task added: ' .. task_text)
        end)
      end, { desc = 'Add a task to the todo list' })
    end,
  },
  {
    'lukas-reineke/headlines.nvim',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = true, 
  },
}
