local M = {}
local templ = require 'custom.notes.templates'
local utils = require 'custom.notes.utils'

---@param options table<string, NoteTemplate> Dictionary of note templates to choose from
---@param callback fun(template: NoteTemplate|nil) Function to call with the selected template
function M.select_template(options, callback)
  -- Convert dictionary to array for selection UI
  local templates_array = {}
  local names = {}
  local keys = {}

  -- Build arrays for selection
  local i = 1
  for key, template in pairs(options) do
    templates_array[i] = template
    names[i] = template.name or key
    keys[i] = key
    i = i + 1
  end

  -- Check if we have any templates
  if #templates_array == 0 then
    print 'No templates available'
    callback(nil)
    return
  end

  -- Show selection UI with callback
  vim.ui.select(names, {
    prompt = 'Select a template:',
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if idx and templates_array[idx] then
      -- Store the original key with the template
      local selected = templates_array[idx]
      selected._key = keys[idx] -- Save the key for reference
      callback(selected)
    else
      callback(nil)
    end
  end)
end

function M.new_note()
  M.select_template(templ.templates, function(template)
    if template then
      print('Selected template: ' .. template.name)
      -- Continue with template processing
      M.create_note(template)
    else
      print 'No template selected'
    end
  end)
end

---@param template NoteTemplate The note template to process
function M.create_note(template)
  -- Apply the template
  local template_value = templ.map_template(template)

  -- check if file already exists and open it
  local f = io.open(template_value.note_path)
  if f then
    f:close()
    vim.notify 'opening existing file..'
    vim.cmd('edit ' .. vim.fn.fnameescape(template_value.note_path))
    return false
  end

  local content = templ.apply_template(template_value)
  if not content then
    print 'Failed to process template'
    return false
  end

  -- Check for cursor placeholder
  local cursor_line, cursor_column = 1, 0
  local lines = {}
  for line in content:gmatch '([^\n]*)\n?' do
    table.insert(lines, line)
  end

  -- Find cursor placeholder position
  for i, line in ipairs(lines) do
    local col_start, col_end = line:find '%%cursor%%'
    if col_start then
      cursor_line = i
      cursor_column = col_start - 1 -- 0-indexed column
      -- Remove the placeholder
      lines[i] = line:sub(1, col_start - 1) .. line:sub(col_end + 1)
      break
    end
  end

  -- Reconstruct the content without the cursor placeholder
  content = table.concat(lines, '\n')

  -- Create the new file
  local file = io.open(template_value.note_path, 'w')
  if not file then
    print('Could not create file: ' .. template_value.note_path)
    return false
  end

  -- Write content to file
  file:write(content)
  file:close()

  -- Open the file in Neovim
  vim.cmd('edit ' .. vim.fn.fnameescape(template_value.note_path))

  -- Position cursor
  vim.api.nvim_win_set_cursor(0, { cursor_line, cursor_column })

  return true
end

return M
