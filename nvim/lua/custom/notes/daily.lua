local M = {}

-- ============================================================================
-- Constants
-- ============================================================================

local SECONDS_PER_DAY = 86400
local FILE_WRITE_DELAY_MS = 100 -- Wait for zk to finish writing
local UNCOMPLETED_BULLET_PATTERN = '^%s*[%-%*]%s*%[[%s%!%?]%]'
local DAILY_NOTE_PATTERN = '^%d%d%d%d%-%d%d%-%d%d%.md$'

-- ============================================================================
-- Configuration
-- ============================================================================

local default_config = {
  notebook_root = vim.env.ZK_NOTEBOOK_DIR or '/home/tilupe/notes',
  daily_dir = 'daily',
  bullet_journal_heading = '## Bullet Journal',
  bullet_journal_end = '<!-- END BULLET JOURNAL -->',
  due_date_tag = '#due:',
  overdue_warning = true,
  enable_highlighting = true,
}

M.config = vim.deepcopy(default_config)

-- Bullet types for rapid logging
M.bullet_types = {
  task = { marker = '[ ]', name = 'Task', desc = 'Something to do' },
  done = { marker = '[x]', name = 'Done', desc = 'Completed task' },
  migrated = { marker = '[>]', name = 'Migrated', desc = 'Moved to future' },
  scheduled = { marker = '[<]', name = 'Scheduled', desc = 'Moved to future log' },
  event = { marker = '[o]', name = 'Event', desc = 'Something that happened' },
  note = { marker = '[-]', name = 'Note', desc = 'Information to remember' },
  priority = { marker = '[!]', name = 'Priority', desc = 'Important/urgent' },
  explore = { marker = '[?]', name = 'Explore', desc = 'Research/think about' },
}

-- Migration actions for selective migration
M.migration_actions = {
  migrate = { marker = '[>]', symbol = 'M', desc = 'Migrate to today' },
  done = { marker = '[x]', symbol = 'D', desc = 'Mark as done' },
  skip = { marker = nil, symbol = 'S', desc = 'Skip (leave as-is)' },
}

-- Toggle cycle: character -> next character (data-driven approach)
local toggle_cycle = {
  [' '] = 'x', -- task -> done
  ['x'] = '>', -- done -> migrated
  ['>'] = ' ', -- migrated -> task
  ['<'] = ' ', -- scheduled -> task
  ['o'] = 'x', -- event -> done
  ['-'] = 'x', -- note -> done
  ['!'] = 'x', -- priority -> done
  ['?'] = 'x', -- explore -> done
}

-- ============================================================================
-- File I/O Helpers
-- ============================================================================

--- Check if a file exists
---@param path string
---@return boolean
local function file_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

--- Read all lines from a file
---@param file_path string
---@return string[]|nil
local function read_file_lines(file_path)
  local file = io.open(file_path, 'r')
  if not file then
    return nil
  end
  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()
  return lines
end

--- Write lines to a file
---@param file_path string
---@param lines string[]
---@param trailing_newline boolean|nil Add trailing newline (default: false)
---@return boolean success
local function write_file_lines(file_path, lines, trailing_newline)
  local file = io.open(file_path, 'w')
  if not file then
    return false
  end
  local content = table.concat(lines, '\n')
  if trailing_newline then
    content = content .. '\n'
  end
  file:write(content)
  file:close()
  return true
end

--- Find the line index of the Bullet Journal heading
---@param lines string[]
---@return number|nil 1-indexed line number, or nil if not found
local function find_bullet_journal_heading(lines)
  local pattern = '^' .. vim.pesc(M.config.bullet_journal_heading)
  for i, line in ipairs(lines) do
    if line:match(pattern) then
      return i
    end
  end
  return nil
end

--- Reload buffer if it's open
---@param file_path string
local function reload_buffer_if_open(file_path)
  local bufnr = vim.fn.bufnr(file_path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('edit!')
    end)
  end
end

-- ============================================================================
-- Daily Note Scanner
-- ============================================================================

--- Scan daily notes and process each one
---@param days number|nil Days to look back (nil = all)
---@param processor fun(file_path: string, date_str: string)
local function scan_daily_notes(days, processor)
  local daily_path = M.config.notebook_root .. '/' .. M.config.daily_dir
  local handle = vim.uv.fs_scandir(daily_path)
  if not handle then
    return
  end

  local cutoff_date = days and os.date('%Y-%m-%d', os.time() - (days * SECONDS_PER_DAY))

  while true do
    local name, entry_type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end

    if entry_type == 'file' and name:match(DAILY_NOTE_PATTERN) then
      local date_str = name:gsub('%.md$', '')
      if not cutoff_date or date_str >= cutoff_date then
        processor(daily_path .. '/' .. name, date_str)
      end
    end
  end
end

-- ============================================================================
-- Core Functions
-- ============================================================================

--- Get the path for today's daily note
---@return string
function M.get_today_note_path()
  local date_str = os.date('%Y-%m-%d')
  return string.format('%s/%s/%s.md', M.config.notebook_root, M.config.daily_dir, date_str)
end

--- Find the most recent daily note (excluding today)
---@return string|nil path Path to the most recent daily note
function M.find_last_daily_note()
  local daily_path = M.config.notebook_root .. '/' .. M.config.daily_dir
  local today = os.date('%Y-%m-%d')

  -- Try zk first
  local cmd = string.format(
    'zk list --quiet --format "{{path}}" --sort created- --limit 10 --notebook-dir %s %s 2>/dev/null',
    vim.fn.shellescape(M.config.notebook_root),
    vim.fn.shellescape(daily_path)
  )

  local output = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    for line in output:gmatch('[^\r\n]+') do
      local full_path = M.config.notebook_root .. '/' .. line
      local filename = vim.fn.fnamemodify(full_path, ':t:r')
      if filename ~= today and file_exists(full_path) then
        return full_path
      end
    end
  end

  -- Fallback: filesystem scan
  return M.find_last_daily_note_via_filesystem()
end

--- Fallback: Find the most recent daily note using filesystem
---@return string|nil
function M.find_last_daily_note_via_filesystem()
  local daily_path = M.config.notebook_root .. '/' .. M.config.daily_dir
  local today = os.date('%Y-%m-%d')

  local handle = vim.uv.fs_scandir(daily_path)
  if not handle then
    return nil
  end

  local notes = {}
  while true do
    local name, entry_type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if entry_type == 'file' and name:match(DAILY_NOTE_PATTERN) then
      local date_str = name:gsub('%.md$', '')
      if date_str ~= today then
        table.insert(notes, { date = date_str, path = daily_path .. '/' .. name })
      end
    end
  end

  table.sort(notes, function(a, b)
    return a.date > b.date
  end)

  return notes[1] and notes[1].path or nil
end

--- Extract uncompleted todos from a file's Bullet Journal section
---@param file_path string
---@return table[] todos List of {line_num, text}
function M.extract_uncompleted_todos(file_path)
  local file = io.open(file_path, 'r')
  if not file then
    return {}
  end

  local todos = {}
  local in_bullet_journal = false
  local line_num = 0
  local heading_pattern = '^' .. vim.pesc(M.config.bullet_journal_heading)
  local end_pattern = vim.pesc(M.config.bullet_journal_end)

  for line in file:lines() do
    line_num = line_num + 1

    if line:match(heading_pattern) then
      in_bullet_journal = true
    elseif line:match(end_pattern) then
      break
    elseif in_bullet_journal and line:match('^## ') and not line:match(heading_pattern) then
      break
    elseif in_bullet_journal and line:match(UNCOMPLETED_BULLET_PATTERN) then
      table.insert(todos, { line_num = line_num, text = line })
    end
  end

  file:close()
  return todos
end

--- Mark todos as migrated in the source file
---@param file_path string
---@param lines_to_mark number[]
---@return boolean success
function M.mark_todos_as_migrated(file_path, lines_to_mark)
  if #lines_to_mark == 0 then
    return true
  end

  local lines = read_file_lines(file_path)
  if not lines then
    return false
  end

  local mark_set = {}
  for _, num in ipairs(lines_to_mark) do
    mark_set[num] = true
  end

  for i, line in ipairs(lines) do
    if mark_set[i] then
      lines[i] = line:gsub('%[([%s%!%?])%]', '[>]', 1)
    end
  end

  return write_file_lines(file_path, lines)
end

--- Insert todos into a file's Bullet Journal section
---@param file_path string
---@param todos table[]|string[]
---@return boolean success
function M.insert_todos_into_file(file_path, todos)
  if #todos == 0 then
    return true
  end

  local todos_to_insert = {}
  for _, todo in ipairs(todos) do
    table.insert(todos_to_insert, type(todo) == 'table' and todo.text or todo)
  end

  local bufnr = vim.fn.bufnr(file_path)

  -- If file is open in a buffer, modify the buffer directly
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local insert_index = find_bullet_journal_heading(lines)

    if not insert_index then
      vim.notify('Could not find Bullet Journal section', vim.log.levels.WARN)
      return false
    end

    vim.api.nvim_buf_set_lines(bufnr, insert_index, insert_index, false, todos_to_insert)
    return true
  end

  -- File not open, modify directly
  local lines = read_file_lines(file_path)
  if not lines then
    return false
  end

  local insert_index = find_bullet_journal_heading(lines)
  if not insert_index then
    vim.notify('Could not find Bullet Journal section', vim.log.levels.WARN)
    return false
  end

  for i = #todos_to_insert, 1, -1 do
    table.insert(lines, insert_index + 1, todos_to_insert[i])
  end

  return write_file_lines(file_path, lines, true)
end

--- Create a new daily note using zk and migrate todos
---@param todos table[]
---@param source_file string|nil
---@param callback fun(path: string)|nil
function M.create_daily_note_with_todos(todos, source_file, callback)
  local cmd = string.format(
    'zk new --print-path --group daily --notebook-dir %s %s/%s 2>&1',
    vim.fn.shellescape(M.config.notebook_root),
    vim.fn.shellescape(M.config.notebook_root),
    M.config.daily_dir
  )

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not (data and data[1] and data[1] ~= '') then
        return
      end

      local new_path = data[1]:gsub('%s+$', '')

      vim.defer_fn(function()
        if not file_exists(new_path) then
          vim.notify('Failed to create daily note', vim.log.levels.ERROR)
          return
        end

        if #todos > 0 then
          M.insert_todos_into_file(new_path, todos)

          if source_file then
            local line_nums = {}
            for _, todo in ipairs(todos) do
              if todo.line_num then
                table.insert(line_nums, todo.line_num)
              end
            end
            M.mark_todos_as_migrated(source_file, line_nums)
          end

          vim.notify(string.format('Migrated %d todos', #todos), vim.log.levels.INFO)
        end

        if callback then
          callback(new_path)
        end
      end, FILE_WRITE_DELAY_MS)
    end,
    on_stderr = function(_, data)
      if data and data[1] and data[1] ~= '' then
        vim.notify('zk error: ' .. table.concat(data, '\n'), vim.log.levels.ERROR)
      end
    end,
  })
end

--- Ensure today's daily note exists
---@param callback fun(path: string)
---@param skip_migration boolean|nil
function M.ensure_today_note(callback, skip_migration)
  local today_path = M.get_today_note_path()

  if file_exists(today_path) then
    callback(today_path)
    return
  end

  local last_note = M.find_last_daily_note()
  local todos = last_note and M.extract_uncompleted_todos(last_note) or {}

  if #todos > 0 and not skip_migration and last_note then
    M.show_migration_picker(todos, last_note, function(migrations, source_file)
      local todos_to_migrate = M.process_migrations(migrations, source_file)

      local counts = { migrate = 0, done = 0, skip = 0 }
      for _, migration in ipairs(migrations) do
        counts[migration.action] = counts[migration.action] + 1
      end

      M.create_daily_note_with_todos(todos_to_migrate, nil, function(new_path)
        vim.schedule(function()
          if counts.migrate > 0 or counts.done > 0 then
            vim.notify(
              string.format('Migrated: %d | Done: %d | Skipped: %d', counts.migrate, counts.done, counts.skip),
              vim.log.levels.INFO
            )
          end
          callback(new_path)
        end)
      end)
    end)
  else
    M.create_daily_note_with_todos({}, nil, function(new_path)
      vim.schedule(function()
        callback(new_path)
      end)
    end)
  end
end

--- Main DailyNote command function
---@param skip_migration boolean|nil
function M.daily_note(skip_migration)
  M.ensure_today_note(function(path)
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
    vim.notify("Opened today's daily note", vim.log.levels.INFO)
  end, skip_migration)
end

-- ============================================================================
-- Bullet Operations
-- ============================================================================

--- Add a bullet entry to today's daily note
---@param bullet_type string
---@param text string|nil
function M.add_bullet(bullet_type, text)
  local bullet = M.bullet_types[bullet_type]
  if not bullet then
    vim.notify('Unknown bullet type: ' .. bullet_type, vim.log.levels.ERROR)
    return
  end

  local function commit_bullet(entry_text)
    if not entry_text or entry_text == '' then
      vim.notify('Cancelled', vim.log.levels.INFO)
      return
    end

    M.ensure_today_note(function(today_path)
      M.add_bullet_to_file(today_path, bullet.marker, entry_text)
    end)
  end

  if text then
    commit_bullet(text)
  else
    vim.ui.input({ prompt = bullet.name .. ': ' }, commit_bullet)
  end
end

--- Add a bullet entry to a specific file
---@param file_path string
---@param marker string
---@param text string
function M.add_bullet_to_file(file_path, marker, text)
  local bullet_line = string.format('- %s %s', marker, text)
  local normalized_path = vim.fn.fnamemodify(file_path, ':p')
  local bufnr = vim.fn.bufnr(normalized_path)

  -- If file is open in a buffer, modify the buffer directly
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local insert_index = find_bullet_journal_heading(lines)

    if not insert_index then
      vim.notify('Could not find Bullet Journal section', vim.log.levels.WARN)
      return
    end

    vim.api.nvim_buf_set_lines(bufnr, insert_index, insert_index, false, { bullet_line })
    vim.notify(string.format('Added %s: %s', marker, text), vim.log.levels.INFO)
    return
  end

  -- File not open, modify directly
  local lines = read_file_lines(file_path)
  if not lines then
    vim.notify('Could not open file: ' .. file_path, vim.log.levels.ERROR)
    return
  end

  local insert_index = find_bullet_journal_heading(lines)
  if not insert_index then
    vim.notify('Could not find Bullet Journal section', vim.log.levels.WARN)
    return
  end

  table.insert(lines, insert_index + 1, bullet_line)

  if not write_file_lines(file_path, lines, true) then
    vim.notify('Could not write file: ' .. file_path, vim.log.levels.ERROR)
    return
  end

  -- Trigger buffer reload if exists
  local existing_bufnr = vim.fn.bufnr(normalized_path)
  if existing_bufnr ~= -1 then
    vim.bo[existing_bufnr].modified = false
    vim.cmd('checktime ' .. existing_bufnr)
  end

  vim.notify(string.format('Added %s: %s', marker, text), vim.log.levels.INFO)
end

--- Show picker to select bullet type, then add entry
function M.add_bullet_picker()
  local items = {}
  local lookup = {}

  for key, bullet in pairs(M.bullet_types) do
    local display = string.format('%s %s - %s', bullet.marker, bullet.name, bullet.desc)
    table.insert(items, display)
    lookup[display] = key
  end

  table.sort(items)

  vim.ui.select(items, { prompt = 'Select bullet type:' }, function(choice)
    if choice then
      M.add_bullet(lookup[choice])
    end
  end)
end

--- Toggle a todo checkbox on current line (cycle through states)
function M.toggle_bullet()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  local new_line = line:gsub('%[([%s%!%?xo%-><%?])%]', function(char)
    local next_char = toggle_cycle[char]
    return next_char and ('[' .. next_char .. ']') or ('[' .. char .. ']')
  end, 1)

  if new_line ~= line then
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
  else
    vim.notify('No bullet found on current line', vim.log.levels.INFO)
  end
end

-- ============================================================================
-- Migration Picker
-- ============================================================================

--- Create the migration picker window
---@param todo_count number
---@return number buf, number win
local function create_migration_window(todo_count)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'

  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(todo_count + 6, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Migration Review ',
    title_pos = 'center',
  })

  return buf, win
end

--- Render migration picker content
---@param buf number
---@param todos table[]
---@param states table
---@param source_file string
local function render_migration_items(buf, todos, states, source_file)
  local lines = {
    'Review todos from previous note. Press:',
    '  m = migrate  |  d = done  |  s = skip  |  <CR> = confirm  |  q = cancel',
    '',
  }

  for i, todo in ipairs(todos) do
    local action = M.migration_actions[states[i]]
    local todo_text = todo.text:gsub('^%s*[%-%*]%s*', '')
    table.insert(lines, string.format(' [%s] %s', action.symbol, todo_text))
  end

  table.insert(lines, '')
  table.insert(lines, string.format(' %d todos | Source: %s', #todos, vim.fn.fnamemodify(source_file, ':t')))

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Highlight markers
  local ns = vim.api.nvim_create_namespace('migration_picker')
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for i = 1, #todos do
    local line_idx = i + 2
    local hl = states[i] == 'migrate' and 'DiagnosticInfo'
      or states[i] == 'done' and 'DiagnosticOk'
      or 'DiagnosticWarn'
    vim.api.nvim_buf_add_highlight(buf, ns, hl, line_idx, 1, 4)
  end
end

--- Show selective migration picker
---@param todos table[]
---@param source_file string
---@param on_complete fun(migrations: table[], source_file: string)
function M.show_migration_picker(todos, source_file, on_complete)
  if #todos == 0 then
    on_complete({}, source_file)
    return
  end

  local states = {}
  for i = 1, #todos do
    states[i] = 'migrate'
  end

  local buf, win = create_migration_window(#todos)

  local function get_current_index()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local idx = cursor[1] - 3
    return (idx >= 1 and idx <= #todos) and idx or nil
  end

  local function set_state(new_state)
    local idx = get_current_index()
    if idx then
      states[idx] = new_state
      render_migration_items(buf, todos, states, source_file)
    end
  end

  local function set_all(new_state)
    for i = 1, #todos do
      states[i] = new_state
    end
    render_migration_items(buf, todos, states, source_file)
  end

  local function confirm()
    vim.api.nvim_win_close(win, true)
    local migrations = {}
    for i, todo in ipairs(todos) do
      table.insert(migrations, { line_num = todo.line_num, text = todo.text, action = states[i] })
    end
    on_complete(migrations, source_file)
  end

  local function cancel()
    vim.api.nvim_win_close(win, true)
    vim.notify('Migration cancelled', vim.log.levels.INFO)
  end

  -- Keymaps
  local opts = { buffer = buf, nowait = true }
  vim.keymap.set('n', 'm', function() set_state('migrate') end, opts)
  vim.keymap.set('n', 'd', function() set_state('done') end, opts)
  vim.keymap.set('n', 's', function() set_state('skip') end, opts)
  vim.keymap.set('n', 'M', function() set_all('migrate') end, opts)
  vim.keymap.set('n', 'D', function() set_all('done') end, opts)
  vim.keymap.set('n', 'S', function() set_all('skip') end, opts)
  vim.keymap.set('n', '<CR>', confirm, opts)
  vim.keymap.set('n', 'q', cancel, opts)
  vim.keymap.set('n', '<Esc>', cancel, opts)

  render_migration_items(buf, todos, states, source_file)
  vim.api.nvim_win_set_cursor(win, { 4, 0 })
end

--- Process migration results and update source file
---@param migrations table[]
---@param source_file string
---@return table[]
function M.process_migrations(migrations, source_file)
  if #migrations == 0 then
    return {}
  end

  local lines = read_file_lines(source_file)
  if not lines then
    vim.notify('Could not read source file', vim.log.levels.WARN)
    return {}
  end

  local line_actions = {}
  for _, migration in ipairs(migrations) do
    line_actions[migration.line_num] = migration.action
  end

  local todos_to_migrate = {}

  for i, line in ipairs(lines) do
    local action = line_actions[i]
    if action == 'migrate' then
      lines[i] = line:gsub('%[([%s%!%?])%]', '[>]', 1)
      table.insert(todos_to_migrate, { line_num = i, text = line })
    elseif action == 'done' then
      lines[i] = line:gsub('%[([%s%!%?])%]', '[x]', 1)
    end
  end

  write_file_lines(source_file, lines)
  reload_buffer_if_open(source_file)

  return todos_to_migrate
end

-- ============================================================================
-- Due Date Support
-- ============================================================================

--- Parse due date from a bullet line
---@param line string
---@return string|nil
function M.parse_due_date(line)
  return line:match(M.config.due_date_tag .. '(%d%d%d%d%-%d%d%-%d%d)')
end

--- Check if a date is overdue
---@param date_str string
---@return boolean
function M.is_overdue(date_str)
  return date_str < os.date('%Y-%m-%d')
end

--- Get due date presets
---@return table[]
local function get_due_date_presets()
  local now = os.time()
  return {
    { label = 'No due date', date = nil },
    { label = 'Today', date = os.date('%Y-%m-%d', now) },
    { label = 'Tomorrow', date = os.date('%Y-%m-%d', now + SECONDS_PER_DAY) },
    { label = 'In 3 days', date = os.date('%Y-%m-%d', now + 3 * SECONDS_PER_DAY) },
    { label = 'Next week', date = os.date('%Y-%m-%d', now + 7 * SECONDS_PER_DAY) },
    { label = 'Next month', date = os.date('%Y-%m-%d', now + 30 * SECONDS_PER_DAY) },
  }
end

--- Show due date picker and call callback with result
---@param callback fun(due_date: string|nil)
local function show_due_date_picker(callback)
  local presets = get_due_date_presets()
  local items = {}
  for _, preset in ipairs(presets) do
    table.insert(items, preset.label)
  end

  vim.ui.select(items, { prompt = 'Due date:' }, function(choice)
    if not choice then
      callback(nil)
      return
    end
    for _, preset in ipairs(presets) do
      if preset.label == choice then
        callback(preset.date)
        return
      end
    end
    callback(nil)
  end)
end

--- Add a bullet with optional due date
---@param bullet_type string
---@param text string|nil
---@param due_date string|nil
function M.add_bullet_with_due(bullet_type, text, due_date)
  local bullet = M.bullet_types[bullet_type]
  if not bullet then
    vim.notify('Unknown bullet type: ' .. bullet_type, vim.log.levels.ERROR)
    return
  end

  -- If text provided, add directly
  if text then
    local entry = due_date and (text .. ' ' .. M.config.due_date_tag .. due_date) or text
    M.ensure_today_note(function(path)
      M.add_bullet_to_file(path, bullet.marker, entry)
    end, true)
    return
  end

  -- Interactive flow
  vim.ui.input({ prompt = bullet.name .. ': ' }, function(input_text)
    if not input_text or input_text == '' then
      vim.notify('Cancelled', vim.log.levels.INFO)
      return
    end

    show_due_date_picker(function(selected_date)
      local entry = selected_date and (input_text .. ' ' .. M.config.due_date_tag .. selected_date) or input_text
      M.ensure_today_note(function(path)
        M.add_bullet_to_file(path, bullet.marker, entry)
      end, true)
    end)
  end)
end

-- ============================================================================
-- Cross-Note Task Search
-- ============================================================================

--- Search all notes for uncompleted bullets
---@param opts table|nil
---@return table[]
function M.search_bullets(opts)
  opts = opts or {}
  local bullet_type = opts.type or 'all'
  local results = {}

  scan_daily_notes(opts.days, function(file_path, date_str)
    local file = io.open(file_path, 'r')
    if not file then
      return
    end

    local line_num = 0
    local in_bullet_journal = false
    local heading_pattern = '^' .. vim.pesc(M.config.bullet_journal_heading)
    local end_pattern = vim.pesc(M.config.bullet_journal_end)

    for line in file:lines() do
      line_num = line_num + 1

      if line:match(heading_pattern) then
        in_bullet_journal = true
      elseif line:match(end_pattern) then
        break
      elseif in_bullet_journal then
        local is_match = false
        if bullet_type == 'all' then
          is_match = line:match(UNCOMPLETED_BULLET_PATTERN)
        elseif bullet_type == 'task' then
          is_match = line:match('^%s*[%-%*]%s*%[ %]')
        elseif bullet_type == 'priority' then
          is_match = line:match('^%s*[%-%*]%s*%[!%]')
        elseif bullet_type == 'explore' then
          is_match = line:match('^%s*[%-%*]%s*%[%?%]')
        end

        if is_match then
          local due = M.parse_due_date(line)
          table.insert(results, {
            file = file_path,
            date = date_str,
            line_num = line_num,
            text = line,
            due_date = due,
            is_overdue = due and M.is_overdue(due) or false,
          })
        end
      end
    end
    file:close()
  end)

  table.sort(results, function(a, b)
    if a.is_overdue ~= b.is_overdue then
      return a.is_overdue
    end
    return a.date > b.date
  end)

  return results
end

--- Open bullet search in Snacks picker or quickfix
---@param opts table|nil
function M.bullet_search(opts)
  local results = M.search_bullets(opts or {})

  if #results == 0 then
    vim.notify('No uncompleted bullets found', vim.log.levels.INFO)
    return
  end

  local ok, snacks = pcall(require, 'snacks')
  if ok and snacks.picker then
    local items = {}
    for _, result in ipairs(results) do
      local text = result.text:gsub('^%s*[%-%*]%s*', '')
      local prefix = result.is_overdue and '! OVERDUE: ' or ''
      table.insert(items, {
        text = prefix .. text,
        file = result.file,
        pos = { result.line_num, 0 },
        preview = { file = result.file, line = result.line_num },
      })
    end

    snacks.picker({
      title = 'Bullet Search',
      items = items,
      format = function(item) return { { item.text } } end,
      confirm = function(picker, item)
        picker:close()
        vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
        vim.api.nvim_win_set_cursor(0, { item.pos[1], 0 })
      end,
    })
  else
    local qf_items = {}
    for _, result in ipairs(results) do
      table.insert(qf_items, {
        filename = result.file,
        lnum = result.line_num,
        text = (result.is_overdue and '[OVERDUE] ' or '') .. result.text:gsub('^%s*', ''),
      })
    end
    vim.fn.setqflist(qf_items)
    vim.cmd('copen')
    vim.notify(string.format('Found %d uncompleted bullets', #results), vim.log.levels.INFO)
  end
end

-- ============================================================================
-- Floating Quick Capture
-- ============================================================================

--- Show floating window for quick bullet capture
---@param bullet_type string|nil
function M.quick_capture(bullet_type)
  bullet_type = bullet_type or 'task'

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'

  local width = math.min(60, vim.o.columns - 4)
  local height = 3
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local bullet = M.bullet_types[bullet_type] or M.bullet_types.task
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = string.format(' Quick Capture [%s %s] ', bullet.marker, bullet.name),
    title_pos = 'center',
  })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '' })
  vim.cmd('startinsert')

  local keymap_opts = { buffer = buf, nowait = true }

  vim.keymap.set('i', '<CR>', function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text = table.concat(lines, ' '):gsub('^%s+', ''):gsub('%s+$', '')
    vim.api.nvim_win_close(win, true)
    if text ~= '' then
      M.ensure_today_note(function(today_path)
        M.add_bullet_to_file(today_path, bullet.marker, text)
      end, true)
    end
  end, keymap_opts)

  vim.keymap.set({ 'i', 'n' }, '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, keymap_opts)

  local types = { 'task', 'priority', 'explore', 'event', 'note' }
  local current_idx = 1
  for i, t in ipairs(types) do
    if t == bullet_type then
      current_idx = i
      break
    end
  end

  vim.keymap.set('i', '<Tab>', function()
    current_idx = (current_idx % #types) + 1
    bullet_type = types[current_idx]
    bullet = M.bullet_types[bullet_type]
    vim.api.nvim_win_set_config(win, {
      title = string.format(' Quick Capture [%s %s] ', bullet.marker, bullet.name),
      title_pos = 'center',
    })
  end, keymap_opts)
end

-- ============================================================================
-- Weekly Review
-- ============================================================================

--- Show weekly review of all uncompleted tasks
function M.weekly_review()
  local results = M.search_bullets({ days = 7 })

  if #results == 0 then
    vim.notify('No uncompleted bullets in the past week', vim.log.levels.INFO)
    return
  end

  -- Group by date
  local by_date = {}
  for _, result in ipairs(results) do
    by_date[result.date] = by_date[result.date] or {}
    table.insert(by_date[result.date], result)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'

  local lines = { '# Weekly Review', '', string.format('*%d uncompleted items from the past 7 days*', #results), '' }

  local dates = vim.tbl_keys(by_date)
  table.sort(dates, function(a, b) return a > b end)

  for _, date in ipairs(dates) do
    table.insert(lines, '## ' .. date)
    table.insert(lines, '')
    for _, result in ipairs(by_date[date]) do
      local text = result.text:gsub('^%s*', '')
      if result.is_overdue then
        text = text .. ' **[OVERDUE]**'
      end
      table.insert(lines, text)
    end
    table.insert(lines, '')
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.cmd('vsplit')
  vim.api.nvim_win_set_buf(0, buf)

  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = buf })
  vim.keymap.set('n', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    for _, result in ipairs(results) do
      if result.text:gsub('^%s*', '') == line:gsub('^%s*', ''):gsub(' %*%*%[OVERDUE%]%*%*$', '') then
        vim.cmd('close')
        vim.cmd('edit ' .. vim.fn.fnameescape(result.file))
        vim.api.nvim_win_set_cursor(0, { result.line_num, 0 })
        return
      end
    end
  end, { buffer = buf })
end

-- ============================================================================
-- Tag Aggregation
-- ============================================================================

--- Extract all tags from daily notes
---@param days number|nil
---@return table<string, table[]>
function M.extract_tags(days)
  local tags = {}

  scan_daily_notes(days, function(file_path, date_str)
    local file = io.open(file_path, 'r')
    if not file then
      return
    end

    local line_num = 0
    for line in file:lines() do
      line_num = line_num + 1
      for tag in line:gmatch('#([%w_-]+)') do
        if not tag:match('^due:') then
          tags[tag] = tags[tag] or {}
          table.insert(tags[tag], {
            file = file_path,
            date = date_str,
            line_num = line_num,
            text = line,
          })
        end
      end
    end
    file:close()
  end)

  return tags
end

--- Show tag picker
function M.tag_search()
  local tags = M.extract_tags(30)

  if vim.tbl_isempty(tags) then
    vim.notify('No tags found in recent notes', vim.log.levels.INFO)
    return
  end

  local tag_list = {}
  for tag, items in pairs(tags) do
    table.insert(tag_list, { tag = tag, count = #items, items = items })
  end
  table.sort(tag_list, function(a, b) return a.count > b.count end)

  local items = {}
  for _, tag_info in ipairs(tag_list) do
    table.insert(items, string.format('#%s (%d)', tag_info.tag, tag_info.count))
  end

  vim.ui.select(items, { prompt = 'Select tag:' }, function(choice)
    if not choice then
      return
    end

    local tag = choice:match('#([%w_-]+)')
    local tag_items = tags[tag]
    if not tag_items then
      return
    end

    local ok, snacks = pcall(require, 'snacks')
    if ok and snacks.picker then
      local picker_items = {}
      for _, item in ipairs(tag_items) do
        table.insert(picker_items, {
          text = item.date .. ': ' .. item.text:gsub('^%s*', ''),
          file = item.file,
          pos = { item.line_num, 0 },
        })
      end

      snacks.picker({
        title = '#' .. tag,
        items = picker_items,
        confirm = function(picker, item)
          picker:close()
          vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
          vim.api.nvim_win_set_cursor(0, { item.pos[1], 0 })
        end,
      })
    else
      local qf_items = {}
      for _, item in ipairs(tag_items) do
        table.insert(qf_items, {
          filename = item.file,
          lnum = item.line_num,
          text = item.text:gsub('^%s*', ''),
        })
      end
      vim.fn.setqflist(qf_items)
      vim.cmd('copen')
    end
  end)
end

-- ============================================================================
-- Visual Highlighting
-- ============================================================================

--- Setup syntax highlighting for bullet types
function M.setup_highlighting()
  if not M.config.enable_highlighting then
    return
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function()
      local highlights = {
        BulletTask = { link = 'Todo' },
        BulletDone = { fg = '#6c7086', strikethrough = true },
        BulletMigrated = { fg = '#89b4fa', italic = true },
        BulletScheduled = { fg = '#89b4fa', italic = true },
        BulletEvent = { fg = '#a6e3a1' },
        BulletNote = { fg = '#9399b2' },
        BulletPriority = { fg = '#f38ba8', bold = true },
        BulletExplore = { fg = '#f9e2af' },
        BulletOverdue = { fg = '#f38ba8', bold = true, undercurl = true },
        BulletDueDate = { fg = '#89b4fa', italic = true },
      }

      for group, hl_opts in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, hl_opts)
      end

      vim.cmd([[
        syntax match BulletTask /- \[ \].*/
        syntax match BulletDone /- \[x\].*/
        syntax match BulletMigrated /- \[>\].*/
        syntax match BulletScheduled /- \[<\].*/
        syntax match BulletEvent /- \[o\].*/
        syntax match BulletNote /- \[-\].*/
        syntax match BulletPriority /- \[!\].*/
        syntax match BulletExplore /- \[?\].*/
        syntax match BulletDueDate /#due:\d\d\d\d-\d\d-\d\d/
      ]])
    end,
  })
end

-- ============================================================================
-- Setup
-- ============================================================================

--- Setup function to create commands
---@param opts table|nil Configuration overrides
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend('force', M.config, opts)
  end

  M.setup_highlighting()

  -- Commands
  vim.api.nvim_create_user_command('DailyNote', function(cmd_opts)
    M.daily_note(cmd_opts.bang)
  end, { desc = 'Open or create daily note with todo migration', bang = true })

  vim.api.nvim_create_user_command('BulletTask', function(cmd_opts)
    M.add_bullet('task', cmd_opts.args ~= '' and cmd_opts.args or nil)
  end, { desc = 'Add task bullet', nargs = '?' })

  vim.api.nvim_create_user_command('BulletEvent', function(cmd_opts)
    M.add_bullet('event', cmd_opts.args ~= '' and cmd_opts.args or nil)
  end, { desc = 'Add event bullet', nargs = '?' })

  vim.api.nvim_create_user_command('BulletNote', function(cmd_opts)
    M.add_bullet('note', cmd_opts.args ~= '' and cmd_opts.args or nil)
  end, { desc = 'Add note bullet', nargs = '?' })

  vim.api.nvim_create_user_command('BulletPriority', function(cmd_opts)
    M.add_bullet('priority', cmd_opts.args ~= '' and cmd_opts.args or nil)
  end, { desc = 'Add priority bullet', nargs = '?' })

  vim.api.nvim_create_user_command('BulletExplore', function(cmd_opts)
    M.add_bullet('explore', cmd_opts.args ~= '' and cmd_opts.args or nil)
  end, { desc = 'Add explore bullet', nargs = '?' })

  vim.api.nvim_create_user_command('Bullet', function()
    M.add_bullet_picker()
  end, { desc = 'Add bullet (shows picker)' })

  vim.api.nvim_create_user_command('BulletToggle', function()
    M.toggle_bullet()
  end, { desc = 'Toggle bullet state on current line' })

  vim.api.nvim_create_user_command('BulletCapture', function(cmd_opts)
    M.quick_capture(cmd_opts.args ~= '' and cmd_opts.args or nil)
  end, { desc = 'Quick capture bullet in floating window', nargs = '?' })

  vim.api.nvim_create_user_command('BulletDue', function()
    M.add_bullet_with_due('task')
  end, { desc = 'Add task with due date picker' })

  vim.api.nvim_create_user_command('BulletSearch', function(cmd_opts)
    M.bullet_search({ type = cmd_opts.args ~= '' and cmd_opts.args or 'all' })
  end, {
    desc = 'Search uncompleted bullets',
    nargs = '?',
    complete = function() return { 'all', 'task', 'priority', 'explore' } end,
  })

  vim.api.nvim_create_user_command('WeeklyReview', function()
    M.weekly_review()
  end, { desc = 'Show weekly review of uncompleted bullets' })

  vim.api.nvim_create_user_command('BulletTags', function()
    M.tag_search()
  end, { desc = 'Search by tag' })

  vim.api.nvim_create_user_command('BulletOverdue', function()
    local results = M.search_bullets({ type = 'all' })
    local overdue = vim.tbl_filter(function(result) return result.is_overdue end, results)
    if #overdue == 0 then
      vim.notify('No overdue items', vim.log.levels.INFO)
      return
    end
    local qf_items = {}
    for _, result in ipairs(overdue) do
      table.insert(qf_items, {
        filename = result.file,
        lnum = result.line_num,
        text = '[OVERDUE ' .. result.due_date .. '] ' .. result.text:gsub('^%s*', ''),
      })
    end
    vim.fn.setqflist(qf_items)
    vim.cmd('copen')
    vim.notify(string.format('%d overdue items', #overdue), vim.log.levels.WARN)
  end, { desc = 'Show overdue bullets' })
end

return M
