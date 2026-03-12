local M = {}

-- Registry of language handlers
M.languages = {}

-- Register a language handler
function M.register(name, handler)
  M.languages[name] = handler
end

-- Start debugging for a language
function M.debug(lang)
  local handler = M.languages[lang]
  if not handler then
    local available = vim.tbl_keys(M.languages)
    vim.notify(
      string.format('Unknown language: %s. Available: %s', lang, table.concat(available, ', ')),
      vim.log.levels.ERROR
    )
    return
  end

  handler.debug()
end

-- List available languages
function M.list()
  return vim.tbl_keys(M.languages)
end

-- Load built-in language handlers
local function load_languages()
  local languages_path = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h') .. '/languages'
  local files = vim.fn.glob(languages_path .. '/*.lua', false, true)

  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ':t:r')
    local ok, handler = pcall(require, 'debug-runner.languages.' .. name)
    if ok and handler then
      M.register(name, handler)
    end
  end
end

-- Setup function
function M.setup()
  load_languages()

  -- Create :Debug command with completion
  vim.api.nvim_create_user_command('Debug', function(opts)
    if opts.args == '' then
      vim.ui.select(M.list(), { prompt = 'Select language:' }, function(lang)
        if lang then
          M.debug(lang)
        end
      end)
    else
      M.debug(opts.args)
    end
  end, {
    nargs = '?',
    complete = function()
      return M.list()
    end,
  })
end

return M
