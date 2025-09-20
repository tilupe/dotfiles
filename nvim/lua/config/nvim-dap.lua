local M = {}
local dap = require 'dap'
local nui_popup = require('nui.popup')
local nui_menu = require('nui.menu')

local netcoredbg_adapter = {
  type = 'executable',
  command = 'netcoredbg',
  args = {
    '--interpreter=vscode',
    require"config.dotnet_runner"
  },
}

dap.adapters.netcoredbg = netcoredbg_adapter -- needed for normal debugging
dap.adapters.coreclr = netcoredbg_adapter -- needed for unit test debugging

dap.configurations.cs = {
  {
    type = 'coreclr',
    name = 'launch - netcoredbg',
    request = 'launch',
    program = function()
      -- return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/src/", "file")
      return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/net9.0/', 'file')
    end,
  },
}

function M.find_launch_settings(test)
  -- Search for launch settings in common locations
  if (test) then
    return vim.fn.getcwd() .. '/src/Dg.Sales.Host/Properties/launchSettings.json'
  end
  local potential_paths = {
    vim.fn.getcwd() .. '/Properties/launchSettings.json',
    vim.fn.getcwd() .. '/src/Properties/launchSettings.json',
    vim.fn.getcwd() .. '/**/Properties/launchSettings.json',
  }
  for _, path in ipairs(potential_paths) do
    local expanded_paths = vim.fn.glob(path, false, true)
    for _, expanded_path in ipairs(expanded_paths) do
      if vim.fn.filereadable(expanded_path) == 1 then
        return expanded_path
      end
    end
  end
  return nil
end
-- Function to find .csproj file
function M.find_csproj(launch_settings_path)
  local csproj_files = vim.fn.resolve(launch_settings_path .. '/../*.csproj', false, true)
  if #csproj_files > 0 then
    return csproj_files[1]
  end
  return nil
end

-- Parse launch settings JSON
function M.parse_launch_settings(file_path)
  if not file_path then
    return nil
  end

  local file = io.open(file_path, 'r')
  if not file then
    return nil
  end

  local content = file:read '*all'
  file:close()

  -- Parse JSON
  local status, json_data = pcall(vim.fn.json_decode, content)
  if not status then
    vim.notify('Failed to parse launchSettings.json: ' .. json_data, vim.log.levels.ERROR)
    return nil
  end

  return json_data
end
-- Extract profiles from parsed JSON
function M.extract_profiles(json_data)
  vim.inspect(json_data)
  if not json_data or not json_data.profiles then
    print('no json data')
    return {}
  end

  local profiles = {}
  for name, profile in pairs(json_data.profiles) do
    table.insert(profiles, {
      name = name,
      commandName = profile.commandName,
      commandLineArgs = profile.commandLineArgs,
      environmentVariables = profile.environmentVariables,
      applicationUrl = profile.applicationUrl,
    })
  end

  return profiles
end
-- Launch debugger with selected profile
function M.launch_with_profile(profile, csproj_path)
  if not csproj_path then
    vim.notify('No .csproj file found', vim.log.levels.ERROR)
    return
  end

  local project_dir = vim.fn.fnamemodify(csproj_path, ':h')
  local program_name = vim.fn.fnamemodify(csproj_path, ':t:r')

  local env_vars = {}
  if profile.environmentVariables then
    for k, v in pairs(profile.environmentVariables) do
      env_vars[k] = v
    end
  end

  print(program_name)

  -- Configure launch settings
  local config = {
    type = 'netcoredbg',
    name = profile.name,
    request = 'launch',
    program = vim.fn.getcwd() .. '/bin/Debug/net9.0/' .. program_name .. '.dll', -- Adjust the path as needed
    args = {},
    cwd = project_dir,
    stopAtEntry = true,
    env = env_vars,
  }

  -- Add command line args if they exist
  if profile.commandLineArgs then
    -- Split commandLineArgs by space while respecting quotes
    local args = {}
    local pattern = '[^%s"]+|"[^"]+"'
    for arg in string.gmatch(profile.commandLineArgs, pattern) do
      -- Remove surrounding quotes if present
      arg = arg:gsub('^"(.*)"$', '%1')
      table.insert(args, arg)
    end
    config.args = args
  end

  -- Start debugging
  dap.run(config)
end

-- Show menu to select profile
function M.select_launch_profile()
  local launch_settings_path = M.find_launch_settings(true)
  if not launch_settings_path then
    vim.notify('Could not find launchSettings.json', vim.log.levels.ERROR)
    return
  end

  local csproj_path = M.find_csproj()
  if not csproj_path then
    vim.notify('Could not find .csproj file', vim.log.levels.ERROR)
    return
  end

  local json_data = M.parse_launch_settings(launch_settings_path)
  local profiles = M.extract_profiles(json_data)

  if #profiles == 0 then
    vim.notify('No profiles found in launchSettings.json', vim.log.levels.ERROR)
    return
  end

  -- Create menu items
  local menu_items = {}
  for i, profile in ipairs(profiles) do
    table.insert(menu_items, nui_menu.item(profile.name, { profile = profile }))
  end

  -- Create a popup menu
  local menu = nui_menu({
    position = '50%',
    size = {
      width = 60,
      height = #profiles + 2,
    },
    border = {
      style = 'single',
      text = {
        top = ' Select Launch Profile ',
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = 'Normal:Normal',
    },
  }, {
    lines = menu_items,
    max_width = 50,
    keymap = {
      focus_next = { 'j', '<Down>', '<Tab>' },
      focus_prev = { 'k', '<Up>', '<S-Tab>' },
      close = { '<Esc>', '<C-c>' },
      submit = { '<CR>', '<Space>' },
    },
    on_submit = function(item)
      M.launch_with_profile(item.profile, csproj_path)
    end,
  })

  menu:mount()
end
vim.keymap.set('n', '<leader>dc', "<Cmd>lua require'dap'.continue()<CR>", { desc = 'Continue' })
vim.keymap.set('n', '<leader>dt', "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>", { desc = 'Run Test (DAP)' })
vim.keymap.set('n', '<leader>db', "<Cmd>lua require'dap'.toggle_breakpoint()<CR>", { desc = 'Toggle Breakpoint' })
vim.keymap.set('n', '<leader>dn', "<Cmd>lua require'dap'.step_over()<CR>", { desc = 'Step Over' })
vim.keymap.set('n', '<leader>di', "<Cmd>lua require'dap'.step_into()<CR>", { desc = 'Step In' })
vim.keymap.set('n', '<leader>do', "<Cmd>lua require'dap'.step_out()<CR>", { desc = 'Step Out' })
vim.keymap.set('n', '<leader>dr', "<Cmd>lua require'dap'.repl.open()<CR>", { desc = 'REPL' })
vim.keymap.set('n', '<leader>dl', "<Cmd>lua require'dap'.run_last()<CR>", { desc = 'Run Last' })
vim.api.nvim_set_keymap("n", "<F5>", "<cmd>lua require('config.nvim-dap').select_launch_profile()<CR>", { noremap = true, silent = true })

return M
