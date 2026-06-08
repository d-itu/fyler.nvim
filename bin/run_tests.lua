vim.iter({ 'nvim-mini/mini.test' }):each(function(repo)
  local module_name = repo:match('/(.*)$')
  local install_path = vim.fs.joinpath(vim.fn.getcwd(), 'tmp', 'deps', module_name)

  if not vim.uv.fs_stat(install_path) then
    print('* Downloading ' .. module_name .. " to '" .. install_path .. "/'")

    vim.system({ 'git', 'clone', '--depth=1', 'https://github.com/' .. repo, install_path }):wait()

    if vim.v.shell_error > 0 then error('Error while cloning dependency: ' .. module_name) end
  end

  vim.opt.runtimepath:append(install_path)
end)

local collect_cases = function()
  return require('mini.test').collect({
    find_files = function() return vim.fn.globpath('tests', '**/*.test.lua', true, true) end,
    filter_cases = function() return true end,
  })
end

local format_desc = function(case)
  local desc = table.concat(case.desc, ' | ')
  if #case.args > 0 then
    local args = vim.inspect(case.args, { newline = '', indent = '' })
    desc = ('%s + args %s'):format(desc, args)
  end
  return desc
end

local has_list = false
for i = 1, #arg do
  if arg[i] == '--list' then
    has_list = true
    break
  end
end

if has_list then
  for _, case in ipairs(collect_cases()) do
    print(format_desc(case))
  end
  return
end

local selected_tests = vim.env.FYLER_NVIM_TEST_SELECTED and vim.split(vim.env.FYLER_NVIM_TEST_SELECTED, '\n') or nil
require('mini.test').run({
  execute = { stop_on_error = true },
  collect = {
    find_files = function() return vim.fn.globpath('tests', '**/*.test.lua', true, true) end,
    filter_cases = function(case)
      if not selected_tests then return true end
      local desc = format_desc(case)
      for _, name in ipairs(selected_tests) do
        if name == desc then return true end
      end
      return false
    end,
  },
})
