local exe = 'Microsoft.CodeAnalysis.LanguageServer'

local cmd = {
  exe,
  '--logLevel=Information',
  '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.log.get_filename()),
  '--stdio',
}

local function find_razor_extension_path()
  return '/nix/store/9ic0hpanp80scgznjc0xrqxibfan8g1b-vscode-extension-ms-dotnettools-csharp-2.93.22/share/vscode/extensions/ms-dotnettools.csharp/.razorExtension/'
end

local razor_extension_path = find_razor_extension_path()
if razor_extension_path ~= nil then
  cmd = vim.list_extend(cmd, {
    '--razorSourceGenerator=' .. vim.fs.joinpath(razor_extension_path, 'Microsoft.CodeAnalysis.Razor.Compiler.dll'),
    '--razorDesignTimePath=' .. vim.fs.joinpath(razor_extension_path, 'Targets', 'Microsoft.NET.Sdk.Razor.DesignTime.targets'),
    '--extension',
    vim.fs.joinpath(razor_extension_path, 'Microsoft.VisualStudioCode.RazorExtension.dll'),
  })
end

return {
  cmd = cmd,
  filetypes = {
    'cs',
    'razor',
    'cshtml',
  },
  on_attach = function() end,
  settings = {
    ['csharp|background_analysis'] = {
      -- dotnet_analyzer_diagnostics_scope = 'fullSolution',
      -- dotnet_compiler_diagnostics_scope = 'fullSolution',
    },
    ['csharp|inlay_hints'] = {
      csharp_enable_inlay_hints_for_implicit_object_creation = true,
      csharp_enable_inlay_hints_for_implicit_variable_types = true,
      csharp_enable_inlay_hints_for_lambda_parameter_types = true,
      csharp_enable_inlay_hints_for_types = true,
      dotnet_enable_inlay_hints_for_indexer_parameters = true,
      dotnet_enable_inlay_hints_for_literal_parameters = true,
      dotnet_enable_inlay_hints_for_object_creation_parameters = true,
      dotnet_enable_inlay_hints_for_other_parameters = true,
      dotnet_enable_inlay_hints_for_parameters = true,
      dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
      dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
      dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
    },
    ['csharp|symbol_search'] = {
      dotnet_search_reference_assemblies = true,
    },
    ['csharp|completion'] = {
      dotnet_show_name_completion_suggestions = true,
      dotnet_show_completion_items_from_unimported_namespaces = true,
    },
    ['csharp|code_lens'] = {
      dotnet_enable_references_code_lens = true,
    },
  },
}
