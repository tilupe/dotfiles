local M = {}
local utils = require 'custom.notes.utils'
local nio = require 'nio'

---@class NoteTemplateValues
---@field name string Display name for the template selection menu
---@field file string Path to the template file (relative or absolute)
---@field title string Title for the note (or function that returns title)
---@field note_path string Directory or full path for saving (or function that generates path)
---@field tags string List of default tags (or function that generates tags)
---@field id string Unique identifier for the note (or function that generates ID)
---@field date string Date string (or function that returns formatted date)

---@param template NoteTemplate The note template to process
---@return NoteTemplateValues values Mapped values of template
function M.map_template(template)
  if not template then
    error 'Template is required'
  end

  local date = utils.get_date_object()
  local values = {}
  values.file = template.file()
  values.title = template.title(date)
  values.note_path = template.note_path(values.title, date)
  values.tags = M.create_tags(template.tags())
  values.id = template.id(date)
  values.date = date:as_datetime()

  return values
end
---@class NoteTemplate
---@field name string Display name for the template selection menu
---@field id fun(date:DateObject):string Title for the note (or function that returns title)
---@field file function|nil Path to the template file (relative or absolute)
---@field title fun(date:DateObject, callback):string|nil Title for the note (or function that returns title)
---@field note_path fun(title: string, date:DateObject):string|nil Directory path or function that takes title and returns path
---@field tags fun(): string[]|nil List of default tags (or function that generates tags)

---@type table<string, NoteTemplate>
M.templates = {
  quick = {
    name = 'Quick Note',
    id = function(date)
      return date:as_id()
    end,
    title = function(date)
      return date:as_title()
    end,
    tags = function()
      return {
        'notiz',
      }
    end,
    file = function()
      local file = vim.fn.stdpath 'config' .. '/lua/custom/notes/template_files/default_note.md'
      if not vim.fn.filereadable(file) then
        error('Template file does not exist: ' .. file)
      end
      return file
    end,
    note_path = function(title, date)
      return '/home/tilupe/zettelkasten/fleeting/' .. date:as_file_name() .. '.md'
    end,
  },
  default = {
    name = 'Default Note',
    id = function(date)
      return date:as_id()
    end,
    title = function(date)
      local title
      nio.run(function()
        title = nio.ui.input { prompt = 'Title:' }
      end)
      if not title or title == '' then
        return date:as_title()
      end
      return title
    end,
    tags = function()
      return {
        'notiz',
      }
    end,
    file = function()
      local file = vim.fn.stdpath 'config' .. '/lua/custom/notes/template_files/default_note.md'
      if not vim.fn.filereadable(file) then
        error('Template file does not exist: ' .. file)
      end
      return file
    end,
    note_path = function(title, date)
      return '/home/tilupe/zettelkasten/fleeting/' .. date:as_title() .. '_' .. title:gsub('%s', '_') .. '.md'
    end,
  },
  story = {
    name = 'Story Jira',
    id = function(date)
      return date:as_id()
    end,
    title = function(date)
      local story_number
      nio.run(function()
        story_number = nio.ui.input { prompt = 'Story Number: OCA-' }
      end)
      if not story_number or story_number == '' then
        error 'Story number is required'
      end
      return 'OCA-' .. story_number
    end,
    tags = function()
      return {
        'work',
        'story',
        'galaxus',
      }
    end,
    file = function()
      local file = vim.fn.stdpath 'config' .. '/lua/custom/notes/template_files/default_note.md'
      if not vim.fn.filereadable(file) then
        error('Template file does not exist: ' .. file)
      end
      return file
    end,
    note_path = function(title, date)
      return '/home/tilupe/zettelkasten/project/work/tickets/' .. date:as_title() .. '_' .. title:gsub('%s', '_') .. '.md'
    end,
  },
}

---@param template NoteTemplateValues The note template to process
---@return string|nil content content of file or nil
function M.apply_template(template)
  local file = io.open(template.file, 'r')
  if not file then
    print('Could not open template file: ' .. template.file)
    return nil
  end

  local content = file:read '*all'
  file:close()

  -- Find all variables in the template
  local replaceables = {}
  for var in string.gmatch(content, '%%%%([%w_]+)%%%%') do
    replaceables[var] = true
  end

  -- Prompt for each unique variable
  -- Prompt for each unique variable
  local values = {}
  for var, _ in pairs(replaceables) do
    values[var] = template[var] or ''
  end

  -- Replace variables with values
  for var, val in pairs(values) do
    content = string.gsub(content, '%%%%' .. var .. '%%%%', val)
  end

  return content
end

function M.create_tags(tags)
  if not tags or #tags == 0 then
    return 'tags: []'
  end
  return 'tags: [' .. table.concat(tags, ', ') .. ']'
end

return M
