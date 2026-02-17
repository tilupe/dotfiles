-- Lualine component for Jujutsu (jj) version control
-- Shows closest bookmark and change ID instead of git branch/commit

local M = {}

-- Cache to avoid running jj commands too frequently
local cache = {
  last_update = 0,
  data = nil,
  cwd = nil,
}

local cache_timeout = 10000 -- milliseconds

local function is_jj_repo()
  local jj_dir = vim.fn.finddir('.jj', vim.fn.getcwd() .. ';')
  return jj_dir ~= ''
end

local function run_jj_cmd(cmd)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.trim(result)
end

local function get_jj_info()
  local now = vim.loop.now()
  local cwd = vim.fn.getcwd()

  -- Return cached data if still valid
  if cache.data and cache.cwd == cwd and (now - cache.last_update) < cache_timeout then
    return cache.data
  end

  if not is_jj_repo() then
    cache.data = nil
    cache.cwd = cwd
    cache.last_update = now
    return nil
  end

  -- Get current change ID (short form)
  local change_id = run_jj_cmd('jj log -r @ --no-graph -T "change_id.short(8)"')
  if not change_id then
    return nil
  end

  -- Find closest bookmark by looking at ancestors with bookmarks
  -- This finds the first ancestor (including @) that has a bookmark
  local bookmark = run_jj_cmd('jj log -r "ancestors(@, 50) & bookmarks()" --no-graph -T "bookmarks" --limit 1')

  -- Clean up bookmark name (remove trailing markers like @, *)
  if bookmark and bookmark ~= '' then
    bookmark = bookmark:gsub('[@%*]', ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    -- If multiple bookmarks, take the first one
    bookmark = bookmark:match('^[^%s]+') or bookmark
  else
    bookmark = nil
  end

  cache.data = {
    change_id = change_id,
    bookmark = bookmark,
  }
  cache.cwd = cwd
  cache.last_update = now

  return cache.data
end

-- Lualine component for bookmark (replaces branch)
function M.bookmark()
  local info = get_jj_info()
  if not info then
    return ''
  end
  return info.bookmark or 'no bookmark'
end

-- Lualine component for change ID (replaces commit)
function M.change_id()
  local info = get_jj_info()
  if not info then
    return ''
  end
  return info.change_id or ''
end

-- Combined component showing "bookmark @ change_id"
function M.jj_status()
  local info = get_jj_info()
  if not info then
    return ''
  end
  local bookmark = info.bookmark or '∅'
  return bookmark .. ' @ ' .. (info.change_id or '?')
end

-- Condition function to check if we're in a jj repo
function M.is_jj_repo()
  local is_jj = is_jj_repo()
  return is_jj_repo()
end

-- Condition function to check if we're NOT in a jj repo (for git fallback)
function M.is_not_jj_repo()
  return not is_jj_repo()
end

return M
