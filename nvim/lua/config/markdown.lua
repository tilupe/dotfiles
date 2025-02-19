require('render-markdown').setup {
  enabled = true,
  max_file_size = 1.5,
  debounce = 100,
  -- Capture groups that get pulled from markdown
  markdown_query = [[
        (atx_heading [
            (atx_h1_marker)
            (atx_h2_marker)
            (atx_h3_marker)
            (atx_h4_marker)
            (atx_h5_marker)
            (atx_h6_marker)
        ] @heading)

        (thematic_break) @dash

        (fenced_code_block) @code

        [
            (list_marker_plus)
            (list_marker_minus)
            (list_marker_star)
        ] @list_marker

        (task_list_marker_unchecked) @checkbox_unchecked
        (task_list_marker_checked) @checkbox_checked

        (block_quote) @quote

        (pipe_table) @table
    ]],
  -- Capture groups that get pulled from quote nodes
  markdown_quote_query = [[
        [
            (block_quote_marker)
            (block_continuation)
        ] @quote_marker
    ]],
  -- Capture groups that get pulled from inline markdown
  inline_query = [[
        (code_span) @code

        (shortcut_link) @shortcut

        [(inline_link) (full_reference_link) (image)] @link
    ]],
  log_level = 'error',
  file_types = { 'markdown' },
  -- Vim modes that will show a rendered view of the markdown file
  -- All other modes will be uneffected by this plugin
  render_modes = { 'n', 'c', 'i' },
  -- Set to avoid seeing warnings for conflicts in health check
  acknowledge_conflicts = false,
  anti_conceal = {
    -- This enables hiding any added text on the line the cursor is on
    -- This does have a performance penalty as we must listen to the 'CursorMoved' event
    enabled = true,
  },
  latex = {
    -- Whether LaTeX should be rendered, mainly used for health check
    enabled = true,
    -- Executable used to convert latex formula to rendered unicode
    converter = 'latex2text',
    -- Highlight for LaTeX blocks
    highlight = 'RenderMarkdownMath',
    -- Amount of empty lines above LaTeX blocks
    top_pad = 0,
    -- Amount of empty lines below LaTeX blocks
    bottom_pad = 0,
  },
  heading = {
    -- Turn on / off heading icon & background rendering
    enabled = true,
    -- Turn on / off any sign column related rendering
    sign = true,
    -- Determines how the icon fills the available space:
    --  inline: underlying '#'s are concealed resulting in a left aligned icon
    --  overlay: result is left padded with spaces to hide any additional '#'
    position = 'overlay',
    -- Replaces '#+' of 'atx_h._marker'
    -- The number of '#' in the heading determines the 'level'
    -- The 'level' is used to index into the array using a cycle
    icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
    -- Added to the sign column if enabled
    -- The 'level' is used to index into the array using a cycle
    signs = { '󰫎 ' },
    -- Width of the heading background:
    --  block: width of the heading text
    --  full: full width of the window
    width = 'full',
    -- The 'level' is used to index into the array using a clamp
    -- Highlight for the heading icon and extends through the entire line
    backgrounds = {
      'RenderMarkdownH1Bg',
      'RenderMarkdownH2Bg',
      'RenderMarkdownH3Bg',
      'RenderMarkdownH4Bg',
      'RenderMarkdownH5Bg',
      'RenderMarkdownH6Bg',
    },
    -- The 'level' is used to index into the array using a clamp
    -- Highlight for the heading and sign icons
    foregrounds = {
      'RenderMarkdownH1',
      'RenderMarkdownH2',
      'RenderMarkdownH3',
      'RenderMarkdownH4',
      'RenderMarkdownH5',
      'RenderMarkdownH6',
    },
  },
  code = {
    -- Turn on / off code block & inline code rendering
    enabled = true,
    -- Turn on / off any sign column related rendering
    sign = true,
    -- Determines how code blocks & inline code are rendered:
    --  none: disables all rendering
    --  normal: adds highlight group to code blocks & inline code, adds padding to code blocks
    --  language: adds language icon to sign column if enabled and icon + name above code blocks
    --  full: normal + language
    style = 'full',
    -- Determines where language icon is rendered:
    --  right: Right side of code block
    --  left: Left side of code block
    position = 'left',
    -- An array of language names for which background highlighting will be disabled
    -- Likely because that language has background highlights itself
    disable_background = { 'diff' },
    -- Amount of padding to add to the left of code blocks
    left_pad = 0,
    -- Amount of padding to add to the right of code blocks when width is 'block'
    right_pad = 0,
    -- Width of the code block background:
    --  block: width of the code block
    --  full: full width of the window
    width = 'full',
    -- Determins how the top / bottom of code block are rendered:
    --  thick: use the same highlight as the code body
    --  thin: when lines are empty overlay the above & below icons
    border = 'thin',
    -- Used above code blocks for thin border
    above = '▄',
    -- Used below code blocks for thin border
    below = '▀',
    -- Highlight for code blocks
    highlight = 'RenderMarkdownCode',
    -- Highlight for inline code
    highlight_inline = 'RenderMarkdownCodeInline',
  },
  dash = {
    -- Turn on / off thematic break rendering
    enabled = true,
    icon = '─',
    width = 'full',
    highlight = 'RenderMarkdownDash',
  },
  bullet = {
    enabled = true,
    icons = {  '◉', '●', '•', '⁍', '⦿', '⁌' },
    right_pad = 0,
    highlight = 'RenderMarkdownBullet',
  },
  checkbox = {
    enabled = true,
    unchecked = {
      icon = '☐',
      highlight = 'RenderMarkdownUnchecked',
    },
    checked = {
      icon = '✔',
      highlight = 'RenderMarkdownChecked',
    },
    -- Define custom checkbox states, more involved as they are not part of the markdown grammar
    -- As a result this requires neovim >= 0.10.0 since it relies on 'inline' extmarks
    -- Can specify as many additional states as you like following the 'todo' pattern below
    --   The key in this case 'todo' is for healthcheck and to allow users to change its values
    --   'raw': Matched against the raw text of a 'shortcut_link'
    --   'rendered': Replaces the 'raw' value when rendering
    --   'highlight': Highlight for the 'rendered' icon
    custom = {
      waiting_todo = { raw = '[-]', rendered = '󰥔', highlight = 'RenderMarkdownTodo' },
      unclear_todo = { raw = '[?]', rendered = '❓', highlight = 'RenderMarkdownTodo' },
    },
  },
  quote = {
    enabled = true,
    icon = '▋',
    highlight = 'RenderMarkdownQuote',
  },
  pipe_table = {
    -- Turn on / off pipe table rendering
    enabled = true,
    -- Determines how the table as a whole is rendered:
    --  none: disables all rendering
    --  normal: applies the 'cell' style rendering to each row of the table
    --  full: normal + a top & bottom line that fill out the table when lengths match
    style = 'full',
    -- Determines how individual cells of a table are rendered:
    --  overlay: writes completely over the table, removing conceal behavior and highlights
    --  raw: replaces only the '|' characters in each row, leaving the cells unmodified
    --  padded: raw + cells are padded with inline extmarks to make up for any concealed text
    cell = 'padded',
    -- Gets placed in delimiter row for each column, position is based on alignmnet
    alignment_indicator = '━',
        -- Characters used to replace table border
        -- Correspond to top(3), delimiter(3), bottom(3), vertical, & horizontal
        -- stylua: ignore
        border = {
            '┌', '┬', '┐',
            '├', '┼', '┤',
            '└', '┴', '┘',
            '│', '─',
        },
    -- Highlight for table heading, delimiter, and the line above
    head = 'RenderMarkdownTableHead',
    -- Highlight for everything else, main table rows and the line below
    row = 'RenderMarkdownTableRow',
    -- Highlight for inline padding used to add back concealed space
    filler = 'RenderMarkdownTableFill',
  },
  -- Callouts are a special instance of a 'block_quote' that start with a 'shortcut_link'
  -- Can specify as many additional values as you like following the pattern from any below, such as 'note'
  --   The key in this case 'note' is for healthcheck and to allow users to change its values
  --   'raw': Matched against the raw text of a 'shortcut_link', case insensitive
  --   'rendered': Replaces the 'raw' value when rendering
  --   'highlight': Highlight for the 'rendered' text and quote markers
  callout = {
    note = { raw = '[!NOTE]', rendered = '󰋽 Note', highlight = 'RenderMarkdownInfo' },
    tip = { raw = '[!TIP]', rendered = '󰌶 Tip', highlight = 'RenderMarkdownSuccess' },
    important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'RenderMarkdownHint' },
    warning = { raw = '[!WARNING]', rendered = '󰀪 Warning', highlight = 'RenderMarkdownWarn' },
    caution = { raw = '[!CAUTION]', rendered = '󰳦 Caution', highlight = 'RenderMarkdownError' },
    -- Obsidian: https://help.a.md/Editing+and+formatting/Callouts
    abstract = { raw = '[!ABSTRACT]', rendered = '󰨸 Abstract', highlight = 'RenderMarkdownInfo' },
    todo = { raw = '[!TODO]', rendered = '󰗡 Todo', highlight = 'RenderMarkdownInfo' },
    success = { raw = '[!SUCCESS]', rendered = '󰄬 Success', highlight = 'RenderMarkdownSuccess' },
    question = { raw = '[!QUESTION]', rendered = '󰘥 Question', highlight = 'RenderMarkdownWarn' },
    failure = { raw = '[!FAILURE]', rendered = '󰅖 Failure', highlight = 'RenderMarkdownError' },
    danger = { raw = '[!DANGER]', rendered = '󱐌 Danger', highlight = 'RenderMarkdownError' },
    bug = { raw = '[!BUG]', rendered = '󰨰 Bug', highlight = 'RenderMarkdownError' },
    example = { raw = '[!EXAMPLE]', rendered = '󰉹 Example', highlight = 'RenderMarkdownHint' },
    quote = { raw = '[!QUOTE]', rendered = '󱆨 Quote', highlight = 'RenderMarkdownQuote' },
  },
  link = {
    -- Turn on / off inline link icon rendering
    enabled = true,
    -- Inlined with 'image' elements
    image = '󰥶 ',
    -- Inlined with 'inline_link' elements
    hyperlink = '󰌹 ',
    -- Applies to the inlined icon
    highlight = 'RenderMarkdownLink',
  },
  sign = {
    -- Turn on / off sign rendering
    enabled = true,
    -- Applies to background of sign text
    highlight = 'RenderMarkdownSign',
  },
  -- Window options to use that change between rendered and raw view
  win_options = {
    -- See :h 'conceallevel'
    conceallevel = {
      -- Used when not being rendered, get user setting
      default = vim.api.nvim_get_option_value('conceallevel', {}),
      -- Used when being rendered, concealed text is completely hidden
      rendered = 3,
    },
    -- See :h 'concealcursor'
    concealcursor = {
      -- Used when not being rendered, get user setting
      default = vim.api.nvim_get_option_value('concealcursor', {}),
      -- Used when being rendered, disable concealing text in all modes
      rendered = '',
    },
  },
  -- More granular configuration mechanism, allows different aspects of buffers
  -- to have their own behavior. Values default to the top level configuration
  -- if no override is provided. Supports the following fields:
  --   enabled, max_file_size, debounce, render_modes, anti_conceal, heading, code,
  --   dash, bullet, checkbox, quote, pipe_table, callout, link, sign, win_options
  overrides = {
    -- Overrides for different buftypes, see :h 'buftype'
    buftype = {
      nofile = {
        sign = { enabled = false },
      },
    },
  },
  -- Mapping from treesitter language to user defined handlers
  -- See 'Custom Handlers' document for more info
  custom_handlers = {},
}

vim.treesitter.language.register('markdown', 'vimwiki')
