local finder = Fyler.import('fyler.finder')
local ns = vim.api.nvim_create_namespace('FylerIndentGuide')

---@param indents table<integer, integer> --table of all indent levels for each line
---@param blanks table<integer, boolean> --table storing whether line is blank
---@param from integer --line to start scan from
---@param bottom integer --bottom of scan range
---@param max_indent integer --if next line has indent level greater than max_indent, then return nil as this is the final line in this level
---@return integer|nil
local function next_sibling_indent(indents, blanks, from, bottom, max_indent)
  for j = from + 1, bottom do
    local next_indent = indents[j]
    if next_indent ~= nil and not blanks[j] and next_indent <= max_indent then return next_indent end
  end
  return nil
end

---check if the line has siblings at the same indent level below it
---@param indents table<integer, integer> --table of all indent levels for each line
---@param blanks table<integer, boolean> --table storing whether line is blank
---@param from integer --line to start scan from
---@param bottom integer --bottom of scan range
---@param level integer --indent level to check for siblings
---@return boolean --true if more siblings (same indent level) below
local function has_sibling_below(indents, blanks, from, bottom, level)
  for j = from + 1, bottom do
    local next_indent = indents[j]
    if next_indent == nil then return false end
    if not blanks[j] then
      if next_indent < level then return false end
      if next_indent == level then return true end
    end
  end
  return false
end

vim.api.nvim_set_decoration_provider(ns, {
  on_win = function(_, _, bufnr, toprow, botrow)
    if vim.bo[bufnr].filetype ~= 'fyler_finder' then return end

    local inst = finder.instance_get_or_nil(vim.api.nvim_get_current_tabpage())
    if not (inst and inst.cache.ui.indent_guides and vim.bo[bufnr].filetype == 'fyler_finder') then return end

    -- Normalize to 1-indexed
    if toprow == 0 then
      toprow = toprow + 1
      botrow = botrow + 1
    end

    local sw = vim.bo[bufnr].shiftwidth
    if sw == 0 then sw = vim.bo[bufnr].tabstop end

    vim.api.nvim_buf_call(bufnr, function()
      -- calculate indents and blank lines
      local indents, blanks = {}, {}
      for l = toprow, botrow do
        indents[l] = vim.fn.indent(l)
        if vim.fn.getline(l):find('^%s*$') then blanks[l] = true end
      end

      -- resolve blank lines first so lines above can detect them as siblings
      for l = toprow, botrow do
        if blanks[l] then
          local prev = vim.fn.prevnonblank(l)
          if prev > 0 then
            indents[l] = indents[prev] or vim.fn.indent(prev)
            blanks[l] = nil
          end
        end
      end

      -- render indent guides
      for l = toprow, botrow do
        local indent = indents[l]
        if indent > 0 then
          local depth = indent / sw
          local parts = {}

          for lvl = 1, depth do
            local ilevel = lvl * sw

            if lvl < depth then
              -- show bar if a sibling exists at this depth
              parts[#parts + 1] = has_sibling_below(indents, blanks, l, botrow, ilevel) and '│ ' or '  '
            else
              -- last child or middle child
              local next_indent = next_sibling_indent(indents, blanks, l, botrow, indent)
              parts[#parts + 1] = (not next_indent or next_indent ~= indent) and '└╴' or '├╴'
            end
          end

          vim.api.nvim_buf_set_extmark(bufnr, ns, l - 1, 0, {
            virt_text = { { table.concat(parts), 'FylerIndentGuide' } },
            virt_text_pos = 'overlay',
            hl_mode = 'combine',
            ephemeral = true,
          })
        end
      end
    end)
  end,
})
