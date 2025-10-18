local M = {}

-- Select from list using vim.ui.select
function M.select_from_list(items, prompt, callback)
  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      -- Display just the filename for better readability
      return vim.fn.fnamemodify(item, ":t")
    end,
  }, function(selected_item)
    -- Call the callback with the selected item (or nil if cancelled)
    callback(selected_item)
  end)
end

-- Execute the actual build process asynchronously using nvim-nio
function M.execute_build(solution_file)
  local nio = require("nio")
  
  -- Remember the current directory
  local current_dir = vim.fn.getcwd()
  
  -- Get solution directory and filename
  local solution_dir = vim.fn.fnamemodify(solution_file, ":h")
  local solution_filename = vim.fn.fnamemodify(solution_file, ":t")
  
  -- Show a notification that we're building
  vim.notify("Building " .. solution_filename .. "...", vim.log.levels.INFO)
  
  -- Run the build asynchronously using nio
  nio.run(function()
    -- Change to the solution directory
    vim.cmd("cd " .. vim.fn.fnameescape(solution_dir))
    
    -- Prepare the command and errorformat
    local errorformat = 
      "%f(%l\\,%c): %trror %m," ..
      "%f(%l\\,%c): %tarning %m," ..
      "%f: %trror %m," ..
      "%f: %tarning %m," ..
      "%f(%l\\,%c): %tarning CS%n: %m," ..
      "%f(%l\\,%c): %trror CS%n: %m"
    
    vim.opt_local.errorformat = errorformat
    
    -- Run dotnet build asynchronously
    local cmd = 'dotnet build "' .. solution_filename .. '" /consoleloggerparameters:NoSummary'
    
    -- Use nio.fn.system to run the command asynchronously
    local result = nio.fn.system(cmd)
    
    -- Process the output
    local output = result.stdout .. result.stderr
    local exit_code = result.code
    
    -- Parse the output to populate the quickfix list
    local temp_file = os.tmpname()
    local file = io.open(temp_file, "w")
    if file then
      file:write(output)
      file:close()
      
      -- Create a new quickfix list from the output
      vim.cmd("cgetfile " .. temp_file)
      
      -- Remove the temporary file
      os.remove(temp_file)
    end
    
    -- Change back to the original directory
    vim.cmd("cd " .. vim.fn.fnameescape(current_dir))
    
    -- Check the results
    local qf_list = vim.fn.getqflist()
    
    -- Schedule UI updates to run on the main thread
    nio.scheduler()
    
    if #qf_list == 0 and exit_code == 0 then
      -- No errors or warnings
      vim.notify("Build completed successfully! ✓", vim.log.levels.INFO)
    else
      -- Count errors and warnings
      local error_count = 0
      local warning_count = 0
      
      for _, item in ipairs(qf_list) do
        if item.type == "E" then
          error_count = error_count + 1
        elseif item.type == "W" then
          warning_count = warning_count + 1
        end
      end
      
      if exit_code ~= 0 or error_count > 0 then
        vim.notify("Build failed with " .. error_count .. " error(s) and " .. warning_count .. " warning(s) ✗", vim.log.levels.ERROR)
        -- Open quickfix window if there are errors
        vim.cmd("copen")
      else
        vim.notify("Build completed with " .. warning_count .. " warning(s) ⚠", vim.log.levels.WARN)
        -- Open quickfix window if there are warnings
        if warning_count > 0 then
          vim.cmd("copen")
        end
      end
    end
  end)
end

-- Build a .NET solution
function M.build_dotnet_solution()
  -- Find the solution file
  local solution_files = vim.fn.glob(vim.fn.getcwd() .. "/**/*.slnx", false, true)
  
  -- If no solution file found, try to find a project file instead
  if #solution_files == 0 then
    local project_files = vim.fn.glob(vim.fn.getcwd() .. "/**/*.csproj", false, true)
    
    if #project_files == 0 then
      vim.notify("No .sln or .csproj file found in the current directory or subdirectories", vim.log.levels.ERROR)
      return
    end
    
    solution_files = project_files
  end
  
  -- If multiple solution files found, let user select one
  if #solution_files == 1 then
    local solution_file = solution_files[1]
    M.execute_build(solution_file)
  else
    M.select_from_list(solution_files, "Select a solution file to build", function(selected)
      if not selected then
        vim.notify("No solution file selected", vim.log.levels.WARN)
        return
      end
      M.execute_build(selected)
    end)
  end
end

return M
