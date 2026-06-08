local M = {}

function M.list_to_dict(list)
  local dict = {}
  for _, item in ipairs(list) do
    dict[item] = true
  end
  return dict
end

function M.buf_valid(buf_id) return buf_id and vim.api.nvim_buf_is_valid(buf_id) or false end

function M.win_valid(win_id) return win_id and vim.api.nvim_win_is_valid(win_id) or false end

function M.set_buf_option(buf_id, name, value)
  if M.buf_valid(buf_id) then vim.api.nvim_set_option_value(name, value, { buf = buf_id, scope = 'local' }) end
end

function M.set_win_option(win_id, name, value)
  if M.win_valid(win_id) then vim.api.nvim_set_option_value(name, value, { win = win_id, scope = 'local' }) end
end

function M.get_hl_color(group, key)
  local hl = vim.api.nvim_get_hl(0, { name = group })
  return hl[key] and string.format('#%06x', hl[key]) or nil
end

return M
