local M = {}

M.default_todo_file = vim.fn.expand '~' .. '/zettelkasten/todo.md'

-- Function to quickly add a todo item to a todo.md file
function M.AddTodo()
  -- Ask for todo text
  local todo_text = vim.fn.input {
    prompt = 'Todo: ',
    cancelreturn = '__CANCELLED__',
  }

  -- Check if input was cancelled or empty
  if todo_text == '__CANCELLED__' or todo_text == '' then
    print 'Todo creation cancelled.'
    return
  end

  -- Ask for due date
  local due_date = vim.fn.input {
    prompt = 'Due date (optional): ',
    cancelreturn = '__CANCELLED__',
  }

  -- Check if input was cancelled
  if due_date == '__CANCELLED__' then
    print 'Todo creation cancelled.'
    return
  end

  -- Format the todo string
  local todo_string = '- [ ] ' .. todo_text .. ' #Todo'
  if due_date ~= '' then
    todo_string = todo_string .. ' #duedate:' .. due_date
  end

  -- Find todo.md file
  local todo_file_path = M.FindTodoFile()
  if not todo_file_path then
    todo_file_path = M.default_todo_file
  end

  -- Try to add the todo item
  local success, error_msg = pcall(function()
    M.AddTodoToFile(todo_file_path, todo_string)
  end)

  if not success then
    vim.notify('Failed to add todo: ' .. error_msg, vim.log.levels.ERROR)
  else
    vim.notify('Todo added successfully to ' .. todo_file_path, vim.log.levels.INFO)

    -- If the todo.md file is currently open in a buffer, reload it
    local bufnr = vim.fn.bufnr(todo_file_path)
    if bufnr ~= -1 then
      vim.cmd('checktime ' .. bufnr)
    end
  end
end

-- Function to add a todo entry to the specified file
function M.AddTodoToFile(file_path, todo_string)
  -- Read the file content
  local file_content = {}
  local file = io.open(file_path, 'r')
  if not file then
    error 'Could not open todo.md file for reading'
  end

  for line in file:lines() do
    table.insert(file_content, line)
  end
  file:close()

  -- Find the "## Capture" section or use end of file
  local capture_index = nil
  for i, line in ipairs(file_content) do
    if line:match '^## Capture' then
      capture_index = i
      break
    end
  end

  -- Insert the todo item
  if capture_index then
    table.insert(file_content, capture_index + 1, todo_string)
  else
    -- If no "## Capture" section exists, add it and then the todo
    table.insert(file_content, '')
    table.insert(file_content, '## Capture')
    table.insert(file_content, todo_string)
  end

  -- Write the updated content back to the file
  file = io.open(file_path, 'w')
  if not file then
    error 'Could not open todo.md file for writing'
  end

  file:write(table.concat(file_content, '\n'))
  file:close()

  return true
end

-- Function to find todo.md file in project directory
function M.FindTodoFile()
  -- Get the directory of the current buffer
  local current_buffer_path = vim.fn.expand '%:p:h'
  if current_buffer_path == '' then
    current_buffer_path = vim.fn.getcwd()
  end

  local path = current_buffer_path

  -- Walk up directory tree looking for todo.md
  while true do
    -- Check if we've reached the root directory
    if path == '/' or path:match '^%a:[/\\]$' then
      break
    end

    -- Check if this directory contains a project marker (.git/.jj/.obsidian)
    local is_project_dir = false
    for _, marker in ipairs { '.git', '.jj', '.obsidian' } do
      local marker_path = path .. '/' .. marker
      if vim.fn.isdirectory(marker_path) == 1 then
        is_project_dir = true
        break
      end
    end

    -- Check for todo.md in this directory
    local todo_path = path .. '/todo.md'
    if vim.fn.filereadable(todo_path) == 1 then
      return todo_path
    end

    -- Stop if we're at a project root but didn't find todo.md
    if is_project_dir then
      break
    end

    -- Move up one directory
    path = vim.fn.fnamemodify(path, ':h')
  end

  return nil
end

return M
