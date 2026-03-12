return {
  'mfussenegger/nvim-dap',
  dependencies = {
    {
      'igorlfs/nvim-dap-view',
      opts = {
        winbar = {
          show = true,
          default_section = 'scopes',
          show_keymap_hints = true,
          sections = { 'scopes', 'watches', 'breakpoints', 'threads', 'repl', 'console' },
        },
        windows = {
          size = 0.35,
          position = 'below',
          terminal = {
            size = 0.5,
            position = 'right',
          },
        },
        auto_toggle = true,
      },
    },
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
  },
  keys = {
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Continue',
    },
    {
      '<leader>ds',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<leader>do',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Conditional Breakpoint',
    },
    {
      '<leader>dr',
      function()
        require('dap').repl.open()
      end,
      desc = 'Debug: Open REPL',
    },
    {
      '<leader>dl',
      function()
        require('dap').run_last()
      end,
      desc = 'Debug: Run Last',
    },
    {
      '<leader>dt',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: Terminate',
    },
    {
      '<leader>du',
      function()
        require('dap-view').toggle()
      end,
      desc = 'Debug: Toggle View',
    },
    {
      '<leader>dw',
      function()
        require('dap-view').add_expr()
      end,
      desc = 'Debug: Add Watch',
    },
  },
  config = function()
    local dap = require 'dap'

    -- Adapter configuration
    dap.adapters.coreclr = {
      type = 'executable',
      command = 'netcoredbg',
      args = { '--interpreter=vscode' },
    }

    -- Basic C# configuration
    dap.configurations.cs = {
      {
        type = 'coreclr',
        name = 'launch - netcoredbg',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
        end,
      },
    }

    -- Virtual text setup
    require('nvim-dap-virtual-text').setup {
      enabled = true,
      highlight_changed_variables = true,
      show_stop_reason = true,
      virt_text_pos = 'eol',
    }

    -- Sign definitions
    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◐', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '◆', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DapStopped', linehl = 'DapStoppedLine', numhl = '' })

    -- Highlight groups
    vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#e06c75' })
    vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { fg = '#e5c07b' })
    vim.api.nvim_set_hl(0, 'DapBreakpointRejected', { fg = '#5c6370' })
    vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#61afef' })
    vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#98c379' })
    vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#2e3b2e' })
  end,
}
