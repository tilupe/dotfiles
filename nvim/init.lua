require 'options'
require 'config.lazy'
require 'config.keymaps'
require 'autocommands'
require 'core.lsp'
require 'config.dotnet_runner'

-- Add this to your init.lua or a separate lua file

-- Add this to your init.lua or a separate lua file

local function build_dotnet_project()
  -- Find .sln or .slnx file in current directory and parent directories
  local function find_solution_files()
    local current_dir = vim.fn.getcwd()
    local max_depth = 5
    local all_solutions = {}

    for i = 0, max_depth do
      local sln_files = vim.fn.glob(current_dir .. '/*.sln', false, true)
      local slnx_files = vim.fn.glob(current_dir .. '/*.slnx', false, true)

      -- Add all found files
      for _, file in ipairs(sln_files) do
        table.insert(all_solutions, file)
      end
      for _, file in ipairs(slnx_files) do
        table.insert(all_solutions, file)
      end

      -- If we found solutions at this level, return them
      if #all_solutions > 0 then
        return all_solutions
      end

      -- Go up one directory
      current_dir = vim.fn.fnamemodify(current_dir, ':h')

      -- Stop if we've reached the root
      if current_dir == '/' or current_dir == vim.fn.fnamemodify(current_dir, ':h') then
        break
      end
    end

    return all_solutions
  end

  local solution_files = find_solution_files()

  if #solution_files == 0 then
    vim.notify('No .sln or .slnx file found in current or parent directories', vim.log.levels.ERROR)
    return
  end

  local solution_file

  -- If multiple solutions found, let user choose
  if #solution_files > 1 then
    -- Create display names (just filenames, not full paths)
    local display_names = {}
    for i, file in ipairs(solution_files) do
      display_names[i] = vim.fn.fnamemodify(file, ':t')
    end

    vim.ui.select(display_names, {
      prompt = 'Select solution file to build:',
    }, function(choice, idx)
      if not choice then
        vim.notify('Build cancelled', vim.log.levels.INFO)
        return
      end

      solution_file = solution_files[idx]
      start_build(solution_file)
    end)

    return -- Exit here, build will start in callback
  else
    solution_file = solution_files[1]
  end

  start_build(solution_file)
end

-- Separate function to actually run the build
function start_build(solution_file)
  -- Clear quickfix list
  vim.fn.setqflist({}, 'r')

  -- Notify build start
  vim.notify('Building ' .. vim.fn.fnamemodify(solution_file, ':t') .. '...', vim.log.levels.INFO)

  -- Build command
  local cmd = { 'dotnet', 'build', solution_file }

  local output_lines = {}
  local has_errors = false

  -- Start async job
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, data)
      if data then
        vim.list_extend(output_lines, data)
      end
    end,

    on_stderr = function(_, data)
      if data then
        vim.list_extend(output_lines, data)
      end
    end,

    on_exit = function(_, exit_code)
      -- Parse output for errors and warnings
      local qf_list = {}
      local seen = {} -- Track duplicates

      for _, line in ipairs(output_lines) do
        -- Match C# compiler error/warning format
        -- Example: /path/to/file.cs(10,5): error CS1002: ; expected
        local file, lnum, col, severity, code, msg = line:match '(.-)%((%d+),(%d+)%):%s*(%w+)%s+(%S+):%s*(.*)'

        if file and lnum then
          -- Create unique key to detect duplicates
          local key = string.format('%s:%s:%s:%s', file, lnum, col, code)

          if not seen[key] then
            seen[key] = true
            table.insert(qf_list, {
              filename = file,
              lnum = tonumber(lnum),
              col = tonumber(col),
              type = severity:sub(1, 1):upper(), -- 'E' for error, 'W' for warning
              text = string.format('[%s] %s', code, msg),
            })

            if severity:lower() == 'error' then
              has_errors = true
            end
          end
        end
      end

      -- Set quickfix list if there are errors/warnings
      if #qf_list > 0 then
        vim.fn.setqflist(qf_list, 'r')
        vim.cmd 'copen'

        local error_count = vim.tbl_filter(function(item)
          return item.type == 'E'
        end, qf_list)
        local warning_count = vim.tbl_filter(function(item)
          return item.type == 'W'
        end, qf_list)

        vim.notify(string.format('Build completed with %d error(s) and %d warning(s)', #error_count, #warning_count), vim.log.levels.WARN)
      elseif exit_code == 0 then
        vim.notify('✓ Build successful!', vim.log.levels.INFO)
      else
        vim.notify('Build failed with exit code: ' .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end

-- Create a command to call the function
vim.api.nvim_create_user_command('DotnetBuild', build_dotnet_project, {})

-- Optional: Create a keymap
vim.keymap.set('n', '<leader>db', build_dotnet_project, { desc = 'Build dotnet project' })

--------------------------------------------------------------------------
-- Add this to your init.lua or a separate lua file
-- Requires: nvim-dap, nvim-dap-ui, and plenary.nvim

local function debug_dotnet_project()
  local dap = require 'dap'
  local dapui = require 'dapui'

  -- Find launchSettings.json files
  local function find_launchsettings()
    local handle = io.popen 'fd --type f launchsettings.json 2>/dev/null'
    if not handle then
      vim.notify("Error: 'fd' command not found. Please install fd-find.", vim.log.levels.ERROR)
      return {}
    end

    local result = handle:read '*a'
    handle:close()

    local files = {}
    for file in result:gmatch '[^\r\n]+' do
      table.insert(files, file)
    end

    return files
  end

  -- Parse JSON file
  local function parse_json(file_path)
    local file = io.open(file_path, 'r')
    if not file then
      return nil
    end

    local content = file:read '*a'
    file:close()

    return vim.json.decode(content)
  end

  -- Find .csproj files in directory
  local function find_csproj_files(directory)
    local handle = io.popen(string.format('fd -d 1 "\\.csproj$" "%s" 2>/dev/null', directory))
    if not handle then
      return {}
    end

    local result = handle:read '*a'
    handle:close()

    local files = {}
    for file in result:gmatch '[^\r\n]+' do
      table.insert(files, file)
    end

    return files
  end

  -- Step 1: Find and select launchSettings.json
  local launchsettings_files = find_launchsettings()

  if #launchsettings_files == 0 then
    vim.notify('Error: No launchSettings.json found', vim.log.levels.ERROR)
    return
  end

  -- If multiple files, let user choose
  local function select_launchsettings(callback)
    if #launchsettings_files == 1 then
      callback(launchsettings_files[1])
    else
      vim.ui.select(launchsettings_files, {
        prompt = 'Select launchSettings.json:',
        format_item = function(item)
          return vim.fn.fnamemodify(item, ':~:.')
        end,
      }, function(choice)
        if choice then
          callback(choice)
        else
          vim.notify('Selection cancelled', vim.log.levels.INFO)
        end
      end)
    end
  end

  select_launchsettings(function(launchsettings_file)
    -- Step 2: Parse and select profile
    local launch_config = parse_json(launchsettings_file)

    if not launch_config or not launch_config.profiles then
      vim.notify('Error: Invalid launchSettings.json', vim.log.levels.ERROR)
      return
    end

    local profiles = {}
    for profile_name, _ in pairs(launch_config.profiles) do
      table.insert(profiles, profile_name)
    end

    if #profiles == 0 then
      vim.notify('Error: No profiles found in launchSettings.json', vim.log.levels.ERROR)
      return
    end

    vim.ui.select(profiles, {
      prompt = 'Select launch profile:',
    }, function(selected_profile)
      if not selected_profile then
        vim.notify('Profile selection cancelled', vim.log.levels.INFO)
        return
      end

      -- Step 3: Get project directory
      local project_path = vim.fn.fnamemodify(launchsettings_file, ':h:h')
      project_path = vim.fn.fnamemodify(project_path, ':p')

      -- Step 4: Find .csproj files
      local csproj_files = find_csproj_files(project_path)

      if #csproj_files == 0 then
        vim.notify('Error: No .csproj file found in ' .. project_path, vim.log.levels.ERROR)
        return
      end

      local function start_debugging(project_file)
        local profile_config = launch_config.profiles[selected_profile]

        -- Configure netcoredbg adapter if not already configured
        if not dap.adapters.coreclr then
          dap.adapters.coreclr = {
            type = 'executable',
            command = 'netcoredbg',
            args = { '--interpreter=vscode' },
          }
        end

        -- Build the project first
        vim.notify('Building project...', vim.log.levels.INFO)
        local build_cmd = string.format('dotnet build "%s"', project_file)

        vim.fn.jobstart(build_cmd, {
          on_exit = function(_, exit_code)
            if exit_code ~= 0 then
              vim.notify('Build failed!', vim.log.levels.ERROR)
              return
            end

            vim.notify('Build successful! Starting debugger...', vim.log.levels.INFO)

            -- Get the DLL path
            local project_name = vim.fn.fnamemodify(project_file, ':t:r')
            local dll_path = project_path .. '/bin/Debug/net8.0/' .. project_name .. '.dll'

            -- Note: Adjust the framework version (net8.0) based on your project
            -- You might want to parse this from the .csproj file

            -- Create DAP configuration
            local config = {
              type = 'coreclr',
              name = 'Launch: ' .. selected_profile,
              request = 'launch',
              program = dll_path,
              cwd = project_path,
              stopAtEntry = false,
              env = profile_config.environmentVariables or {},
              args = profile_config.commandLineArgs or {},
            }

            -- Add application URL if specified
            if profile_config.applicationUrl then
              config.env.ASPNETCORE_URLS = profile_config.applicationUrl
            end

            -- Open DAP UI
            dapui.open()

            -- Start debugging
            dap.run(config)
          end,
        })
      end

      -- If multiple .csproj files, let user choose
      if #csproj_files == 1 then
        start_debugging(csproj_files[1])
      else
        vim.ui.select(csproj_files, {
          prompt = 'Select .csproj file:',
          format_item = function(item)
            return vim.fn.fnamemodify(item, ':t')
          end,
        }, function(choice)
          if choice then
            start_debugging(choice)
          else
            vim.notify('Project selection cancelled', vim.log.levels.INFO)
          end
        end)
      end
    end)
  end)
end

-- Create a command to call the function
vim.api.nvim_create_user_command('DotnetDebug', debug_dotnet_project, {})

-- Optional: Create a keymap
vim.keymap.set('n', '<leader>dd', debug_dotnet_project, { desc = 'Debug dotnet project' })
