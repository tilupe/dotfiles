-- Function for Normal/Insert mode - prompts for both link text and URL
function Insert_markdown_link()
  -- Get link text
  local link_text = vim.fn.input 'Link text: '
  if link_text == '' then
    return
  end

  -- Get URL
  local url = vim.fn.input 'URL: '
  if url == '' then
    return
  end

  -- Create markdown link
  local markdown_link = string.format('[%s](%s)', link_text, url)

  -- Insert at cursor position
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local before = string.sub(line, 1, pos[2])
  local after = string.sub(line, pos[2] + 1)
  local new_line = before .. markdown_link .. after
  vim.api.nvim_set_current_line(new_line)

  -- Move cursor to end of inserted link
  vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] + #markdown_link })
end

-- Function for Visual mode - uses selection as link text, prompts for URL
-- Function for Visual mode - uses selection as link text, prompts for URL
-- Function for Visual mode
function Insert_markdown_link_visual()
  -- Store the selection before doing anything
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_row, end_col = end_pos[2], end_pos[3]

  -- Get the selected text
  local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})
  local link_text = table.concat(lines, '\n')

  if link_text == '' then
    return
  end

  -- Get URL
  local url = vim.fn.input 'URL: '
  if url == '' then
    return
  end

  -- Create markdown link
  local markdown_link = string.format('[%s](%s)', link_text, url)

  -- Replace the selected text with the markdown link
  vim.api.nvim_buf_set_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, { markdown_link })
end

local function create_note_with_dir()
  -- Get title
  vim.ui.input({ prompt = 'Note title: ' }, function(title)
    if not title or title == '' then
      return
    end

    -- Get notebook root
    local notebook_root = '/home/tilupe/notes' -- hardcoded for now

    if vim.v.shell_error ~= 0 then
      vim.notify('Not in a zk notebook', vim.log.levels.ERROR)
      return
    end

    -- Find all directories, excluding those starting with dot
    local find_cmd = string.format("find %s -type d -not -path '*/\\.*'", vim.fn.shellescape(notebook_root))
    local dirs_output = vim.fn.system(find_cmd)

    local dirs = {}
    for dir in dirs_output:gmatch '[^\r\n]+' do
      local rel_dir = vim.fn.substitute(dir, vim.fn.escape(notebook_root .. '/', '/'), '', '')
      local ret_dir = vim.fn.substitute(dir, vim.fn.escape(notebook_root .. '/', '/'), '', '')

      if rel_dir ~= notebook_root then
        table.insert(dirs, rel_dir)
      end
    end

    -- Use fzf-lua to pick directory
    require('fzf-lua').fzf_exec(dirs, {
      prompt = 'Select directory: ',
      actions = {
        ['default'] = function(selected)
          local dir = notebook_root .. '/' .. selected[1]

          -- Create directory if it doesn't exist
          if not vim.loop.fs_stat(dir) then
            vim.fn.mkdir(dir, 'p')
          end

          -- Create note with zk.nvim
          require('zk').new {
            title = title,
            dir = dir,
          }
        end,
      },
    })
  end)
end

local function create_daily_note()
  -- Get title

  -- date  --date="yesterday" +"%d-%m-%y"

  local date_command = string.format "date  --date='yesterday' +'%d-%m-%y'"
  local yesterday = vim.fn.system(date_command)

  require('zk').new {
    dir = 'daily',
  }
  vim.ui.input({ prompt = 'Note title: ' }, function(title)
    if not title or title == '' then
      return
    end

    -- Get notebook root
    local notebook_root = '/home/tilupe/notes' -- hardcoded for now

    if vim.v.shell_error ~= 0 then
      vim.notify('Not in a zk notebook', vim.log.levels.ERROR)
      return
    end

    -- Find all directories, excluding those starting with dot
    local find_cmd = string.format("find %s -type d -not -path '*/\\.*'", vim.fn.shellescape(notebook_root))
    local dirs_output = vim.fn.system(find_cmd)

    local dirs = {}
    for dir in dirs_output:gmatch '[^\r\n]+' do
      local rel_dir = vim.fn.substitute(dir, vim.fn.escape(notebook_root .. '/', '/'), '', '')
      local ret_dir = vim.fn.substitute(dir, vim.fn.escape(notebook_root .. '/', '/'), '', '')

      if rel_dir ~= notebook_root then
        table.insert(dirs, rel_dir)
      end
    end

    -- Use fzf-lua to pick directory
    require('fzf-lua').fzf_exec(dirs, {
      prompt = 'Select directory: ',
      actions = {
        ['default'] = function(selected)
          local dir = notebook_root .. '/' .. selected[1]

          -- Create directory if it doesn't exist
          if not vim.loop.fs_stat(dir) then
            vim.fn.mkdir(dir, 'p')
          end

          -- Create note with zk.nvim
          require('zk').new {
            title = title,
            dir = dir,
          }
        end,
      },
    })
  end)
end

return {
  {
    'zk-org/zk-nvim',
    config = function()
      require('zk').setup {
        picker = 'snacks_picker',
        lsp = {
          -- `config` is passed to `vim.lsp.start(config)`
          config = {
            name = 'zk',
            cmd = { 'zk', 'lsp' },
            filetypes = { 'markdown' },
          },
          auto_attach = {
            enabled = true,
          },
        },
      }
      vim.keymap.set('n', '<leader>nn', create_note_with_dir, { desc = 'Create new note' })

      vim.keymap.set('n', '<leader>nd', create_daily_note, { desc = 'Write daily' })
      -- For Normal and Insert mode
      vim.keymap.set({ 'n', 'i' }, '<C-l>', Insert_markdown_link, { desc = 'Insert markdown link' })

      -- For Visual mode
      vim.keymap.set('v', '<C-l>', ':<C-u>lua Insert_markdown_link_visual()<CR>', { desc = 'Insert markdown link from selection' })
    end,
  },
}
