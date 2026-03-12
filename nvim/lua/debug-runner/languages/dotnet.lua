local M = {}

local dap = require('dap')

-- Run a shell command and return trimmed output
local function shell(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end
  local result = handle:read('*a')
  handle:close()
  return result and result:gsub('^%s*(.-)%s*$', '%1') or nil
end

-- Split string by newlines
local function lines(str)
  if not str or str == '' then
    return {}
  end
  local result = {}
  for line in str:gmatch('[^\r\n]+') do
    table.insert(result, line)
  end
  return result
end

-- Check if file exists
local function file_exists(path)
  local f = io.open(path, 'r')
  if f then
    f:close()
    return true
  end
  return false
end

-- Find launchSettings.json files
local function find_launchsettings()
  return lines(shell('fd --type f launchSettings.json'))
end

-- Get profiles from launchSettings.json
local function get_profiles(file)
  return lines(shell(string.format("jq -r '.profiles | keys[]' %q", file)))
end

-- Get environment variables from a profile
local function get_env_vars(file, profile)
  local json = shell(string.format(
    "jq -r '.profiles[\"%s\"].environmentVariables // {} | to_entries | .[] | \"\\(.key)=\\(.value)\"' %q",
    profile, file
  ))
  local env = {}
  for _, line in ipairs(lines(json)) do
    local key, value = line:match('([^=]+)=(.*)')
    if key then
      env[key] = value
    end
  end

  -- Get applicationUrl and set as ASPNETCORE_URLS
  local app_url = shell(string.format(
    "jq -r '.profiles[\"%s\"].applicationUrl // empty' %q",
    profile, file
  ))
  if app_url and app_url ~= '' then
    env['ASPNETCORE_URLS'] = app_url
  end

  return env
end

-- Get project path from launchSettings path
local function get_project_path(launchsettings_file)
  local dir = vim.fn.fnamemodify(launchsettings_file, ':h')
  return shell(string.format('realpath %q', dir .. '/../'))
end

-- Find .csproj file in directory
local function find_csproj(project_path)
  local result = shell(string.format('fd -d 1 "\\.csproj$" %q', project_path))
  local files = lines(result)
  return files[1] and vim.fn.fnamemodify(files[1], ':t') or nil
end

-- Find the most recent net* folder in bin/Debug
local function find_framework_folder(project_path)
  local debug_path = project_path .. '/bin/Debug'
  local result = shell(string.format('ls -td %q/net* 2>/dev/null | head -1', debug_path))
  if result and result ~= '' then
    return vim.fn.fnamemodify(result, ':t')
  end
  return nil
end

-- Select from list using vim.ui.select
local function select(items, prompt, callback)
  if #items == 0 then
    vim.notify('No items to select', vim.log.levels.WARN)
    return
  end
  if #items == 1 then
    callback(items[1])
    return
  end
  vim.ui.select(items, { prompt = prompt }, callback)
end

-- Build the project before debugging
local function build_project(project_path, csproj, callback)
  local project_file = project_path .. '/' .. csproj
  vim.notify('Building ' .. csproj .. '...', vim.log.levels.INFO)

  vim.fn.jobstart({ 'dotnet', 'build', project_file }, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          vim.notify('Build successful', vim.log.levels.INFO)
          callback(true)
        else
          vim.notify('Build failed', vim.log.levels.ERROR)
          callback(false)
        end
      end)
    end,
  })
end

-- Main debug function
function M.debug()
  local launchsettings = find_launchsettings()

  if #launchsettings == 0 then
    vim.notify('No launchSettings.json found', vim.log.levels.ERROR)
    return
  end

  select(launchsettings, 'Select launchSettings.json:', function(selected_file)
    if not selected_file then
      return
    end

    local profiles = get_profiles(selected_file)
    if #profiles == 0 then
      vim.notify('No profiles found', vim.log.levels.ERROR)
      return
    end

    select(profiles, 'Select profile:', function(profile)
      if not profile then
        return
      end

      local project_path = get_project_path(selected_file)
      local csproj = find_csproj(project_path)

      if not csproj then
        vim.notify('No .csproj found', vim.log.levels.ERROR)
        return
      end

      local project_name = csproj:gsub('%.csproj$', '')

      -- Build first, then debug
      build_project(project_path, csproj, function(success)
        if not success then
          return
        end

        -- Find the actual framework folder after build
        local framework = find_framework_folder(project_path)
        if not framework then
          vim.notify('No net* folder found in bin/Debug/', vim.log.levels.ERROR)
          return
        end

        local dll_path = string.format('%s/bin/Debug/%s/%s.dll', project_path, framework, project_name)

        if not file_exists(dll_path) then
          vim.notify('DLL not found: ' .. dll_path, vim.log.levels.ERROR)
          return
        end

        local env = get_env_vars(selected_file, profile)

        vim.notify(string.format('Debugging %s (%s)', project_name, profile), vim.log.levels.INFO)

        local config = {
          type = 'coreclr',
          name = project_name,
          request = 'launch',
          program = dll_path,
          cwd = project_path,
          stopAtEntry = false,
          console = 'integratedTerminal',
          justMyCode = false,
          env = env,
        }

        dap.run(config)
      end)
    end)
  end)
end

return M
