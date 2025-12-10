vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.md',
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Check if file starts with YAML frontmatter
    if lines[1] ~= '---' then
      return
    end

    -- Find the end of YAML frontmatter
    local yaml_end = nil
    for i = 2, #lines do
      if lines[i] == '---' then
        yaml_end = i
        break
      end
    end

    if not yaml_end then
      return
    end

    -- Update last-update field
    local timestamp = os.date '%Y-%m-%d %H:%M:%S'
    local updated = false

    for i = 2, yaml_end - 1 do
      if lines[i]:match '^last%-update:' then
        lines[i] = 'last-update: ' .. timestamp
        updated = true
        break
      end
    end

    if updated then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end
  end,
})
