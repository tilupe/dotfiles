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
