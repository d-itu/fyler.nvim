local finder = Fyler.import('fyler.finder')

local indent_guide_ns = vim.api.nvim_create_namespace('FylerIndentGuide')
local guide_cache = {}

vim.api.nvim_set_decoration_provider(indent_guide_ns, {
  on_win = function(_, _, buf_id)
    local instance = finder.instance_get_or_nil(vim.api.nvim_get_current_tabpage())
    if not (instance and instance.cache.ui.indent_guides and vim.bo[buf_id].filetype == 'fyler_finder') then return end
    local tick = vim.b[buf_id].changedtick
    if guide_cache[buf_id] and guide_cache[buf_id].tick == tick then return end
    local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
    local levels = {}
    for i, line in ipairs(lines) do
      levels[i - 1] = #line:match('^( *)')
    end
    guide_cache[buf_id] = { tick = tick, levels = levels }
  end,

  on_line = function(_, _, buf_id, row)
    local instance = finder.instance_get_or_nil(vim.api.nvim_get_current_tabpage())
    if not (instance and instance.cache.ui.indent_guides and vim.bo[buf_id].filetype == 'fyler_finder') then return end
    local cache = guide_cache[buf_id]
    if not cache then return end
    local s = cache.levels[row]
    if not s or s == 0 then return end
    for col = 0, s - 2, 2 do
      local has_next = false
      for j = row + 1, #cache.levels do
        local next_s = cache.levels[j]
        if next_s <= col then break end
        if next_s >= col + 2 then
          has_next = true
          break
        end
      end
      local marker = has_next and '│ ' or '└ '
      vim.api.nvim_buf_set_extmark(
        buf_id,
        indent_guide_ns,
        row,
        col,
        { virt_text = { { marker, 'FylerIndentGuide' } }, virt_text_pos = 'overlay', ephemeral = true }
      )
    end
  end,
})

vim.api.nvim_create_autocmd('BufDelete', {
  buffer = vim.api.nvim_get_current_buf(),
  callback = function(ev)
    guide_cache[ev.buf] = nil
    return true
  end,
})
