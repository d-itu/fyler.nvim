vim.cmd([[
  if exists("b:current_syntax")
    finish
  endif

  syn match FYLER_STORE_ID /\/\d* / conceal

  let b:current_syntax = "Fyler_Finder"
]])
