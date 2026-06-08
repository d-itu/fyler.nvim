local M = {}
local H = {}

H.get_range_text = function(command_args)
  if not command_args.range or command_args.range == 0 then return nil end
  local lines = vim.api.nvim_buf_get_lines(0, command_args.line1 - 1, command_args.line2, false)
  return table.concat(lines, '\n')
end

H.parse_api_args = function(command_args)
  local args = {}
  vim.iter(command_args.fargs):each(function(farg)
    local k, v = farg:match('^(.*)=(.*)$')
    if k and v then args[k] = v end
  end)
  return args
end

H.parse_api_name = function(command_args)
  if #command_args.fargs == 0 or command_args.fargs[1]:match('=') then return 'open' end
  return command_args.fargs[1]
end

---@type vim.api.keyset.user_command
M.opts = { range = true, nargs = '*', desc = 'Fyler.nvim user command' }

---@param command_args vim.api.keyset.create_user_command.command_args
M.cmd = function(command_args)
  local name = H.parse_api_name(command_args)
  local args = H.parse_api_args(command_args)
  local text = H.get_range_text(command_args)
  local api = Fyler[name]
  if not args.root_path and (text and vim.fn.isdirectory(text) == 1) then args.root_path = text end
  if not vim.is_callable(api) then
    vim.notify('Unknown API', vim.log.levels.INFO, { title = 'Fyler.nvim' })
    return
  end
  api(args)
end

return M
