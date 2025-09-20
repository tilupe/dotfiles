-- ~/.config/nvim/lua/dotnet_runner.lua

local M = {}

-- Create a function to run shell commands and get output
local function get_command_output(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end

  local result = handle:read '*a'
  handle:close()

  -- Trim whitespace
  result = result:gsub('^%s*(.-)%s*$', '%1')
  return result
end

-- Function to get absolute path
local function get_absolute_path(path)
  local output = get_command_output('realpath "' .. path .. '"')
  return output
end

-- Split string into a table by newlines
local function split_by_newline(str)
  if not str or str == '' then
    return {}
  end

  local result = {}
  for line in str:gmatch '[^\r\n]+' do
    table.insert(result, line)
  end
  return result
end

-- Find all launchsettings.json files
function M.find_launchsettings_files()
  -- Find all launchsettings.json files using fd command
  local launchsettings_cmd = 'fd --type f launchsettings.json'
  local launchsettings_files = get_command_output(launchsettings_cmd)

  if not launchsettings_files or launchsettings_files == '' then
    vim.notify('Error: No launchsettings.json files found', vim.log.levels.ERROR)
    return {}
  end

  -- Convert the output to a table of files
  return split_by_newline(launchsettings_files)
end

-- Extract profiles from the launchsettings.json file
function M.get_profiles(launchsettings_file)
  -- Get profiles from the launchsettings.json file using jq
  local jq_cmd = "jq -r '.profiles | keys[]' \"" .. launchsettings_file .. '"'
  local profiles_output = get_command_output(jq_cmd)

  if not profiles_output or profiles_output == '' then
    vim.notify('Error: No profiles found in ' .. launchsettings_file, vim.log.levels.ERROR)
    return {}
  end

  -- Convert the output to a table of profiles
  return split_by_newline(profiles_output)
end

-- Find .csproj files in the project directory
function M.find_csproj_files(project_path)
  -- Find .csproj files in the project directory
  local fd_cmd = 'fd -d 1 "\\.csproj$" "' .. project_path .. '"'
  local csproj_files_output = get_command_output(fd_cmd)

  if not csproj_files_output or csproj_files_output == '' then
    vim.notify('Error: No .csproj files found in ' .. project_path, vim.log.levels.ERROR)
    return {}
  end

  -- Convert the output to a table of csproj files
  return split_by_newline(csproj_files_output)
end

-- Run the project with the selected profile
function M.run_project(project_path, project_file, profile)
  -- Create the command to run the project
  local cmd = 'dotnet run --project "' .. project_path .. '/' .. project_file .. '" --launch-profile "' .. profile .. '"'

  -- Show a notification with the command being run
  vim.notify('Running: ' .. cmd, vim.log.levels.INFO)

  -- Run the command using jobstart so it runs asynchronously
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line and line ~= '' then
            vim.schedule(function()
              print(line)
            end)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line and line ~= '' then
            vim.schedule(function()
              vim.notify(line, vim.log.levels.ERROR)
            end)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.schedule(function()
          vim.notify('Project completed successfully', vim.log.levels.INFO)
        end)
      else
        vim.schedule(function()
          vim.notify('Project exited with code ' .. exit_code, vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

function M.debug_project(project_path, project_file, profile)
  -- First, determine the output DLL path
  local project_name = vim.fn.fnamemodify(project_file, ':r')

  -- Get the target framework from the project file
  local framework_cmd = 'grep -o "<TargetFramework>.*</TargetFramework>" "'
    .. project_path
    .. '/'
    .. project_file
    .. '" | sed -E "s/<TargetFramework>(.*)<\\/TargetFramework>/\\1/"'
  local framework = get_command_output(framework_cmd) or 'net6.0' -- Default to net6.0 if not found

  -- Construct the likely path to the compiled DLL
  local dll_path = project_path .. '/bin/Debug/' .. framework .. '/' .. project_name .. '.dll'
  print('DLL Path: ' .. dll_path)

  -- Get environment variables and command line args from the launch profile
  local env_vars = {}
  local cmd_args = {}

  -- Show a notification about debugging
  vim.notify('Debugging ' .. project_name .. ' with profile ' .. profile, vim.log.levels.INFO)

  -- Define debug configuration
  local config = {
    type = 'netcoredbg',
    name = 'Debug ' .. project_name .. ' (' .. profile .. ')',
    request = 'launch',
    program = dll_path,
    cwd = project_path,
    stopAtEntry = true,
    args = cmd_args,
    env = {},
    console = 'integratedTerminal',
  }

  -- Set environment variables
  for _, env_var in ipairs(env_vars) do
    local key, value = env_var:match '(.-)=(.*)'
    if key and value then
      config.env[key] = value
    end
  end

  -- Start debugging
  dap.run(config)

  -- Open DAP UI if available
  pcall(function()
    require('dapui').open()
  end)
end

-- Main function to orchestrate the dotnet run workflow
function M.dotnet_run()
  -- Step 1: Find launchsettings.json files
  local launchsettings_files = M.find_launchsettings_files()
  if #launchsettings_files == 0 then
    return
  end

  -- Step 2: Select a launchsettings.json file (this is where you'd use folke/snacks.nvim)
  -- For now, we'll use a placeholder function
  M.select_from_list(launchsettings_files, 'Select a launchSettings.json file', function(selected_file)
    if not selected_file then
      vim.notify('No launchsettings.json file selected', vim.log.levels.WARN)
      return
    end

    -- Step 3: Get and select a profile
    local profiles = M.get_profiles(selected_file)
    if #profiles == 0 then
      return
    end

    M.select_from_list(profiles, 'Select a launch profile', function(selected_profile)
      if not selected_profile then
        vim.notify('No profile selected', vim.log.levels.WARN)
        return
      end

      -- Step 4: Get project directory and find .csproj files
      local project_path = vim.fn.fnamemodify(selected_file, ':h')
      project_path = get_absolute_path(project_path .. '/../')

      local csproj_files = M.find_csproj_files(project_path)
      if #csproj_files == 0 then
        return
      end

      -- Step 5: Select a .csproj file if there are multiple, or use the only one
      if #csproj_files == 1 then
        local project_file = vim.fn.fnamemodify(csproj_files[1], ':t')
        M.run_project(project_path, project_file, selected_profile)
      else
        M.select_from_list(csproj_files, 'Select a .csproj file', function(selected_csproj)
          if not selected_csproj then
            vim.notify('No .csproj file selected', vim.log.levels.WARN)
            return
          end

          local project_file = vim.fn.fnamemodify(selected_csproj, ':t')
          M.run_project(project_path, project_file, selected_profile)
        end)
      end
    end)
  end)
end

function M.dotnet_debug()
  -- Step 1: Find launchsettings.json files
  local launchsettings_files = M.find_launchsettings_files()
  if #launchsettings_files == 0 then
    return
  end

  -- Step 2: Select a launchsettings.json file (this is where you'd use folke/snacks.nvim)
  -- For now, we'll use a placeholder function
  M.select_from_list(launchsettings_files, 'Select a launchSettings.json file', function(selected_file)
    if not selected_file then
      vim.notify('No launchsettings.json file selected', vim.log.levels.WARN)
      return
    end

    -- Step 3: Get and select a profile
    local profiles = M.get_profiles(selected_file)
    if #profiles == 0 then
      return
    end

    M.select_from_list(profiles, 'Select a launch profile', function(selected_profile)
      if not selected_profile then
        vim.notify('No profile selected', vim.log.levels.WARN)
        return
      end

      -- Step 4: Get project directory and find .csproj files
      local project_path = vim.fn.fnamemodify(selected_file, ':h')
      project_path = get_absolute_path(project_path .. '/../')

      local csproj_files = M.find_csproj_files(project_path)
      if #csproj_files == 0 then
        return
      end

      -- Step 5: Select a .csproj file if there are multiple, or use the only one
      if #csproj_files == 1 then
        local project_file = vim.fn.fnamemodify(csproj_files[1], ':t')
        M.debug_project(project_path, project_file, selected_profile)
      else
        M.select_from_list(csproj_files, 'Select a .csproj file', function(selected_csproj)
          if not selected_csproj then
            vim.notify('No .csproj file selected', vim.log.levels.WARN)
            return
          end

          local project_file = vim.fn.fnamemodify(selected_csproj, ':t')
          M.debug_project(project_path, project_file, selected_profile)
        end)
      end
    end)
  end)
end

-- PLACEHOLDER: This function should be replaced with your preferred fuzzy finder
-- This is where you would integrate folke/snacks.nvim
function M.select_from_list(items, prompt, callback)
  -- This is just a basic implementation using vim.ui.select
  -- Replace this with folke/snacks.nvim integration
  vim.ui.select(items, {
    prompt = prompt,
  }, function(selected)
    callback(selected)
  end)
end

-- Create a command to run the dotnet project
vim.api.nvim_create_user_command('DotnetRun', function()
  M.dotnet_run()
end, {})

vim.api.nvim_create_user_command('DotnetDebug', function()
  M.dotnet_debug()
end, {})

-- Key mapping to run the dotnet project
vim.api.nvim_set_keymap('n', '<leader>dr', ':DotnetRun<CR>', { noremap = true, silent = true })

return M
