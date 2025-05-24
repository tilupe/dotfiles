-- Roslyn and Razor LanguageServer
local rzls_lib_path = vim.fs.joinpath(vim.fn.resolve(vim.fn.exepath 'rzls'), '..', '..', 'lib', 'rzls')
local design_time_target_path = vim.fs.joinpath(rzls_lib_path, 'Targets', 'Microsoft.NET.Sdk.Razor.DesignTime.targets')
local razor_compiler_path = vim.fs.joinpath(rzls_lib_path, 'Microsoft.CodeAnalysis.Razor.Compiler.dll')
local cmd = {
  'Microsoft.CodeAnalysis.LanguageServer',
  '--stdio',
  '--logLevel=Information',
  '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
  '--razorSourceGenerator=' .. razor_compiler_path,
  '--razorDesignTimePath=' .. design_time_target_path,
}
return
  {
  cmd = cmd,
  filetypes = { 'cs', 'razor', 'cshtml' },
  on_attach = function()
    print 'This will run when the server attaches!'
  end,
  settings = {
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
    ['csharp|code_lens'] = {
      dotnet_enable_references_code_lens = true,
      dotnet_enable_tests_code_lens = true,
    },
    ['csharp|symbol_search'] = {
      dotnet_search_reference_assemblies = true,
    },
    ['csharp|completion'] = {
      dotnet_show_completion_items_from_unimported_namespaces = true,
      dotnet_show_name_completion_suggestions = true,
      dotnet_provide_regex_completions = true,
    },
    ['csharp|background_analysis'] = {
      dotnet_analyzer_diagnostics_scope = 'fullSolution',
      dotnet_compiler_diagnostics_scope = 'fullSolution',
    },
  },
  
}
