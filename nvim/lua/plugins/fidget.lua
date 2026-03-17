return {
  'j-hui/fidget.nvim',
  event = 'LspAttach',
  config = function()
    require('fidget').setup {
      progress = {
        poll_rate = 0.5,
        suppress_on_insert = true,
        ignore_done_already = true,
        ignore_empty_message = true,
        display = {
          render_limit = 16,
          done_ttl = 3,
          done_icon = '✓',
          done_style = 'Constant',
          progress_ttl = math.huge,
          progress_icon = { pattern = 'dots', period = 1 },
          progress_style = 'WarningMsg',
          group_style = 'Title',
          icon_style = 'Question',
          priority = 30,
          skip_history = true,
          format_message = function(msg)
            if msg.message then
              return msg.message
            else
              return msg.done and 'Completed' or 'In progress...'
            end
          end,
          format_annote = function(msg)
            return msg.title
          end,
          format_group_name = function(group)
            return tostring(group)
          end,
          overrides = {
            rust_analyzer = { name = 'rust-analyzer' },
            roslyn = { name = 'Roslyn' },
          },
        },
        lsp = {
          progress_ringbuf_size = 0,
        },
      },
      notification = {
        poll_rate = 10,
        filter = vim.log.levels.INFO,
        history_size = 128,
        override_vim_notify = false,
        configs = { default = vim.tbl_extend('force', {}, {}) },
        redirect = function(msg, level, opts)
          if opts and opts.on_open then
            local ok, integration = pcall(require, 'fidget.integration.nvim-notify')
            if ok then
              return integration.delegate(msg, level, opts)
            end
          end
        end,
        view = {
          stack_upwards = true,
          icon_separator = ' ',
          group_separator = '---',
          group_separator_hl = 'Comment',
        },
        window = {
          normal_hl = 'Comment',
          winblend = 0,
          border = 'none',
          zindex = 45,
          max_width = 0,
          max_height = 0,
          x_padding = 1,
          y_padding = 0,
          align = 'bottom',
          relative = 'editor',
        },
      },
    }
  end,
}
