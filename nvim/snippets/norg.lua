local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local snippets, autosnippets = {}, {}

local definition_multi_line = s('definition', {
  t '$$ ',
  i(1, 'TERM'), -- Insert node for you to type the language
  t { '', '' },
  i(2, 'TBD'),
  t { '', '$$' },
})
table.insert(snippets, definition_multi_line)

return snippets, autosnippets
