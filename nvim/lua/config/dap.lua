-- ============================================================================
-- nvim-dap Configuration for C# with launchSettings.json support
-- ============================================================================
-- 
-- Installation (using lazy.nvim):
-- Add this to your plugins:
--
-- {
--   'mfussenegger/nvim-dap',
--   dependencies = {
--     'rcarriga/nvim-dap-ui',      -- Optional but highly recommended
--     'nvim-neotest/nvim-nio',     -- Required for nvim-dap-ui
--     'theHamsta/nvim-dap-virtual-text', -- Optional: shows variable values as virtual text
--   },
-- }
--
-- Then add this file to your config or copy the contents to your init.lua
-- ============================================================================

local dap = require('dap')

-- ============================================================================
-- Adapter Configuration
-- ============================================================================

dap.adapters.coreclr = {
  type = 'executable',
  command = 'netcoredbg',
  args = {'--interpreter=vscode'}
}

-- ============================================================================
-- Find DLL Helper Function
-- ============================================================================

local function find_dll()
  -- Try to find the most recent DLL in bin/Debug or bin/Release
  local debug_pattern = vim.fn.getcwd() .. '/bin/Debug/**/*.dll'
  local release_pattern = vim.fn.getcwd() .. '/bin/Release/**/*.dll'
  
  local debug_dlls = vim.fn.glob(debug_pattern, false, true)
  local release_dlls = vim.fn.glob(release_pattern, false, true)
  
  -- Filter out system DLLs (keep only project DLLs)
  local function is_project_dll(dll)
    local name = vim.fn.fnamemodify(dll, ':t')
    -- Exclude common system DLLs
    local exclude_patterns = {
      '^Microsoft%.', '^System%.', '^netstandard%.', 
      '^Newtonsoft%.', '^runtime%.', '^mscorlib%.'
    }
    for _, pattern in ipairs(exclude_patterns) do
      if name:match(pattern) then
        return false
      end
    end
    return true
  end
  
  local project_dlls = {}
  for _, dll in ipairs(debug_dlls) do
    if is_project_dll(dll) then
      table.insert(project_dlls, dll)
    end
  end
  for _, dll in ipairs(release_dlls) do
    if is_project_dll(dll) then
      table.insert(project_dlls, dll)
    end
  end
  
  if #project_dlls == 0 then
    return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
  elseif #project_dlls == 1 then
    return project_dlls[1]
  else
    -- Multiple DLLs found, let user choose
    local display_names = {}
    for i, dll in ipairs(project_dlls) do
      -- Show relative path for clarity
      display_names[i] = vim.fn.fnamemodify(dll, ':.')
    end
    
    local choice_idx = nil
    vim.ui.select(display_names, {
      prompt = "Select DLL to debug:",
    }, function(choice, idx)
      choice_idx = idx
    end)
    
    -- Wait for selection (vim.ui.select is async)
    if choice_idx then
      return project_dlls[choice_idx]
    else
      return project_dlls[1] -- Default to first if cancelled
    end
  end
end

-- ============================================================================
-- Parse and Run with launchSettings.json
-- ============================================================================

local function debug_with_launch_settings()
  -- First, ensure the project is built
  vim.notify("Building project...", vim.log.levels.INFO)
  
  -- Find solution file
  local sln_file = vim.fn.glob(vim.fn.getcwd() .. '/*.sln')
  local slnx_file = vim.fn.glob(vim.fn.getcwd() .. '/*.slnx')
  local solution_file = sln_file ~= "" and sln_file or slnx_file
  
  if solution_file == "" then
    vim.notify("No solution file found. Build manually first.", vim.log.levels.WARN)
  else
    -- Build synchronously
    local build_result = vim.fn.system({'dotnet', 'build', solution_file})
    if vim.v.shell_error ~= 0 then
      vim.notify("Build failed! Fix errors before debugging.", vim.log.levels.ERROR)
      return
    end
    vim.notify("Build successful!", vim.log.levels.INFO)
  end
  
  -- Look for launchSettings.json
  local launch_settings_path = vim.fn.getcwd() .. '/Properties/launchSettings.json'
  
  if vim.fn.filereadable(launch_settings_path) == 0 then
    vim.notify("launchSettings.json not found in Properties/", vim.log.levels.ERROR)
    return
  end
  
  -- Read and parse launchSettings.json
  local content = vim.fn.readfile(launch_settings_path)
  local json_str = table.concat(content, '\n')
  local ok, launch_settings = pcall(vim.fn.json_decode, json_str)
  
  if not ok then
    vim.notify("Failed to parse launchSettings.json", vim.log.levels.ERROR)
    return
  end
  
  if not launch_settings.profiles then
    vim.notify("No profiles found in launchSettings.json", vim.log.levels.ERROR)
    return
  end
  
  -- Get profiles
  local profiles = {}
  for name, _ in pairs(launch_settings.profiles) do
    table.insert(profiles, name)
  end
  
  -- Sort profiles for consistency
  table.sort(profiles)
  
  -- Let user select a profile
  vim.ui.select(profiles, {
    prompt = "Select launch profile:",
  }, function(choice)
    if not choice then 
      vim.notify("Debug cancelled", vim.log.levels.INFO)
      return 
    end
    
    local profile = launch_settings.profiles[choice]
    
    -- Find the DLL
    local dll_path = find_dll()
    
    if not dll_path or dll_path == "" then
      vim.notify("No DLL selected", vim.log.levels.ERROR)
      return
    end
    
    -- Parse command line args
    local args = {}
    if profile.commandLineArgs then
      -- Handle both string and already-split args
      if type(profile.commandLineArgs) == "string" then
        args = vim.split(profile.commandLineArgs, ' ', { trimempty = true })
      else
        args = profile.commandLineArgs
      end
    end
    
    -- Parse environment variables
    local env = profile.environmentVariables or {}
    
    -- Determine working directory
    local cwd = profile.workingDirectory or vim.fn.getcwd()
    -- Handle ${workspaceFolder} placeholder
    cwd = cwd:gsub("${workspaceFolder}", vim.fn.getcwd())
    
    -- Determine console type
    local console = "integratedTerminal" -- default
    if profile.console then
      console = profile.console
    end
    
    vim.notify("Starting debugger with profile: " .. choice, vim.log.levels.INFO)
    
    -- Start debugging with the profile settings
    dap.run({
      type = 'coreclr',
      name = 'Launch: ' .. choice,
      request = 'launch',
      program = dll_path,
      args = args,
      cwd = cwd,
      env = env,
      console = console,
      stopAtEntry = false,
    })
  end)
end

-- ============================================================================
-- Basic C# Configuration (fallback)
-- ============================================================================

dap.configurations.cs = {
  {
    type = "coreclr",
    name = "launch - netcoredbg",
    request = "launch",
    program = find_dll,
  },
}

-- ============================================================================
-- Commands
-- ============================================================================

vim.api.nvim_create_user_command('DotnetDebug', debug_with_launch_settings, {
  desc = "Debug C# project with launchSettings.json"
})

vim.api.nvim_create_user_command('DapToggleBreakpoint', function()
  require('dap').toggle_breakpoint()
end, { desc = "Toggle breakpoint" })

vim.api.nvim_create_user_command('DapContinue', function()
  require('dap').continue()
end, { desc = "Start/Continue debugging" })

-- ============================================================================
-- Keymaps
-- ============================================================================

local keymap = vim.keymap.set

-- Debug controls
keymap('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue' })
keymap('n', '<F10>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
keymap('n', '<F11>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
keymap('n', '<F12>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
keymap('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
keymap('n', '<leader>B', function() 
  require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
end, { desc = 'Debug: Set Conditional Breakpoint' })
keymap('n', '<leader>dr', function() require('dap').repl.open() end, { desc = 'Debug: Open REPL' })
keymap('n', '<leader>dl', function() require('dap').run_last() end, { desc = 'Debug: Run Last' })
keymap('n', '<leader>dt', function() require('dap').terminate() end, { desc = 'Debug: Terminate' })

-- Launch with profile
keymap('n', '<leader>dd', debug_with_launch_settings, { desc = 'Debug: Launch with profile' })

-- ============================================================================
-- DAP UI Setup (Optional but Recommended)
-- ============================================================================

local dapui_ok, dapui = pcall(require, 'dapui')
if dapui_ok then
  dapui.setup({
    icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
    mappings = {
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      edit = "e",
      repl = "r",
      toggle = "t",
    },
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.25 },
          { id = "breakpoints", size = 0.25 },
          { id = "stacks", size = 0.25 },
          { id = "watches", size = 0.25 },
        },
        size = 40,
        position = "left",
      },
      {
        elements = {
          { id = "repl", size = 0.5 },
          { id = "console", size = 0.5 },
        },
        size = 10,
        position = "bottom",
      },
    },
    controls = {
      enabled = true,
      element = "repl",
    },
    floating = {
      max_height = nil,
      max_width = nil,
      border = "single",
      mappings = {
        close = { "q", "<Esc>" },
      },
    },
    windows = { indent = 1 },
    render = {
      max_type_length = nil,
      max_value_lines = 100,
    }
  })

  -- Auto open/close UI
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end

  -- UI toggle keymap
  keymap('n', '<leader>du', function() dapui.toggle() end, { desc = 'Debug: Toggle UI' })
end

-- ============================================================================
-- Virtual Text Setup (Optional)
-- ============================================================================

local virtual_text_ok, virtual_text = pcall(require, 'nvim-dap-virtual-text')
if virtual_text_ok then
  virtual_text.setup({
    enabled = true,
    enabled_commands = true,
    highlight_changed_variables = true,
    highlight_new_as_changed = false,
    show_stop_reason = true,
    commented = false,
    only_first_definition = true,
    all_references = false,
    filter_references_pattern = '<module',
    virt_text_pos = 'eol',
    all_frames = false,
    virt_lines = false,
    virt_text_win_col = nil
  })
end

-- ============================================================================
-- Signs (Breakpoint icons)
-- ============================================================================

vim.fn.sign_define('DapBreakpoint', { text='🔴', texthl='', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointCondition', { text='🟡', texthl='', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointRejected', { text='🚫', texthl='', linehl='', numhl='' })
vim.fn.sign_define('DapLogPoint', { text='📝', texthl='', linehl='', numhl='' })
vim.fn.sign_define('DapStopped', { text='▶️', texthl='', linehl='debugPC', numhl='' })

-- ============================================================================
-- Success message
-- ============================================================================

vim.notify("nvim-dap C# configuration loaded! Use :DotnetDebug to start", vim.log.levels.INFO)
