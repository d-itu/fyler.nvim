local M = {}
local registry = {}

---@class fyler.Extension
---@field name string
---@field setup function|nil
---@field hooks table<string, function>|nil

---@param ext fyler.Extension
function M.register(ext) registry[ext.name] = ext end

---@param config table<string, table>
function M.setup(config)
  for name, opts in pairs(config or {}) do
    if not registry[name] then pcall(require, 'fyler.extensions.' .. name) end
    local ext = registry[name]
    if ext and ext.setup then
      ext.setup(opts, require('fyler.config').DATA)
    elseif not ext then
      vim.notify(('Fyler: extension "%s" not found'):format(name), vim.log.levels.WARN)
    end
  end
end

function M.hook_count(name)
  local count = 0
  for _, ext in pairs(registry) do
    if ext.hooks and ext.hooks[name] then count = count + 1 end
  end
  return count
end

function M.run_hook(name, ...)
  for _, ext in pairs(registry) do
    if ext.hooks and ext.hooks[name] then ext.hooks[name](...) end
  end
end

return M
