local helper = require('tests.helper')
local n = helper.new_child_neovim()
local T = helper.new_set({ hooks = { pre_case = n.setup, post_once = n.stop } })

T['Finder with kind'] = helper.new_set({
  hooks = { pre_case = function() n.set_size(12, 50) end },
  parametrize = {
    { 'floating' },
    { 'replace' },
    { 'split_left' },
    { 'split_left_most' },
    { 'split_above' },
    { 'split_above_all' },
    { 'split_right' },
    { 'split_right_most' },
    { 'split_below' },
    { 'split_below_all' },
  },
})

T['Finder with kind']['can render entries'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-dir/', 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.expect_screenshot()
end

T['Finder with kind']['respects mappings'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-dir/', 'a-dir/aa-file', '.hidden-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys('<CR>')
  vim.uv.sleep(10)
  n.expect_screenshot()
  n.type_keys({ 'j', '<BS>' })
  vim.uv.sleep(10)
  n.expect_screenshot()
  n.type_keys('g.')
  vim.uv.sleep(10)
  n.expect_screenshot()
  n.type_keys('.')
  vim.uv.sleep(10)
  n.expect_screenshot()
  n.type_keys('-')
  vim.uv.sleep(10)
  n.expect_screenshot()
  n.type_keys('.')
  vim.uv.sleep(10)
  n.type_keys('=')
  vim.uv.sleep(10)
  n.expect_screenshot()
  n.type_keys('q')
  vim.uv.sleep(10)
  n.expect_screenshot()
end

T['Finder with kind']['can open file'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys('<CR>')
  n.expect_screenshot()
end

T['Finder with kind']['can open file in split'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys('<C-s>')
  n.expect_screenshot()
end

T['Finder with kind']['can open file in vsplit'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys('<C-v>')
  n.expect_screenshot()
end

T['Finder with kind']['can open file in tabedit'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys('<C-t>')
  n.expect_screenshot()
end

T['Finder with kind']['can dispatch refresh'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  helper.get_tmpdir('data', { 'c-file', 'd-file' })
  n.type_keys('<C-r>')
  vim.uv.sleep(10)
  n.expect_screenshot()
end

T['Finder with kind']['can create split window if not available'] = function(kind)
  if kind == 'floating' or kind == 'replace' then return end
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys({ '<C-w><C-o>', '<CR>' })
  n.expect_screenshot()
end

T['Finder with kind']['can prevent user from hijacking window'] = function(kind)
  if kind == 'float' or kind == 'replace' then return end
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.fwd_lua('vim.cmd.edit')(helper.joinpath(tmpdir, 'a-file'))
  n.expect_screenshot()
end

T['Finder with kind']['can do basic file system manipulation'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys({
    'dd',
    '0',
    'C',
    'renamed-file',
    '<ESC>',
    'yyp',
    '0',
    'C',
    'copied-file',
    '<ESC>',
    'o',
    'new-file',
    '<ESC>',
    ':w<CR>',
  })
  n.expect_screenshot()
  n.type_keys('y')
  vim.uv.sleep(10)
  n.expect_screenshot()
end

T['Finder with kind']['can handle swap in file system manipulation'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys({
    '0',
    'rb',
    'j',
    'ra',
    ':w<CR>',
  })
  vim.uv.sleep(10)
  helper.expect.equality(
    vim.tbl_contains({
      'Move│a-file->a-file.fyler_tmp\\nMove│b-file->a-file\\nMove│a-file.fyler_tmp->b-file',
      'Move│b-file->b-file.fyler_tmp\\nMove│a-file->b-file\\nMove│b-file.fyler_tmp->a-file',
    }, (table.concat(n.api.nvim_buf_get_lines(0, 0, -1, false), '\\n'):gsub('%s*', ''))),
    true
  )
  n.type_keys('y')
  vim.uv.sleep(10)
  n.expect_screenshot()
end

T['Finder with kind']['can handle chain-dependencies in file system manipulation'] = function(kind)
  local tmpdir = helper.get_tmpdir('data', { 'a-file', 'b-file', 'c-file' })
  n.fwd_lua('require("fyler").setup')({})
  n.fwd_lua('require("fyler").open')({ kind = kind, root_path = tmpdir })
  vim.uv.sleep(10)
  n.type_keys({
    '0',
    'rb',
    'j',
    'rc',
    'j',
    'rd',
    ':w<CR>',
  })
  vim.uv.sleep(10)
  n.type_keys('y')
  vim.uv.sleep(10)
  helper.expect.equality(vim.fn.readfile(helper.joinpath(tmpdir, 'b-file')), { 'ROOT/a-file' })
  helper.expect.equality(vim.fn.readfile(helper.joinpath(tmpdir, 'c-file')), { 'ROOT/b-file' })
  helper.expect.equality(vim.fn.readfile(helper.joinpath(tmpdir, 'd-file')), { 'ROOT/c-file' })
end

return T
