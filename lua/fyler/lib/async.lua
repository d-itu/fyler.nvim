local M = {}

---@param co thread
---@private
local safe_resume = function(co, ...)
  local args = { ... }
  if coroutine.status(co) == 'suspended' then
    coroutine.resume(co, unpack(args))
  else
    vim.schedule(function() coroutine.resume(co, unpack(args)) end)
  end
end

-- Wraps a libuv async function so it can be used inside a coroutine.
-- The returned function takes the same args as the original.
-- and returns the callback's arguments via `coroutine.yield`.
--
---@param fn function
---@return function
M.await = function(fn)
  return function(...)
    local args = { ... }
    local co = coroutine.running()
    table.insert(args, function(...) safe_resume(co, ...) end)
    fn(unpack(args))
    return coroutine.yield()
  end
end

--- Creates a barrier that calls `callback` after `n` invocations of the returned function.
--- If `n` is 0, the callback is scheduled immediately.
---
---@param n integer
---@param callback function
---@return function
M.barrier = function(n, callback)
  if n == 0 then
    vim.schedule(callback)
    return function() end
  end
  local count = 0
  return function()
    count = count + 1
    if count == n then vim.schedule(callback) end
  end
end

return M
