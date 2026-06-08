local M = {}

M.is_case_insensitive = jit.os == 'Windows' or jit.os == 'OSX'
M.is_windows = jit.os == 'Windows'

---@nodiscard
---@return string
M.do_join = function(...) return M.to_normalize(vim.fs.joinpath(...)) end

---@nodiscard
---@return string[]
M.do_split = function(path)
  return vim
    .iter(vim.split(path:gsub('\\', '/'), '/'))
    :filter(function(segment) return #segment > 0 end)
    :map(function(segment)
      local drive = segment:match('^([%a]):$')
      if drive then return drive:lower() end
      return segment
    end)
    :totable()
end

---@nodiscard
---@return boolean
M.is_abs = function(path) return vim.fn.isabsolutepath(path) == 1 end

---@nodiscard
---@param a string
---@param b string
---@return boolean
M.is_equal = function(a, b) return M.to_normalize(a) == M.to_normalize(b) end
if M.is_case_insensitive then
  ---@nodiscard
  ---@param a string
  ---@param b string
  ---@return boolean
  M.is_equal = function(a, b) return M.to_normalize(a:lower()) == M.to_normalize(b:lower()) end
end

---@nodiscard
---@return string
M.to_abs = function(path) return M.to_normalize(vim.fs.abspath(path)) end

---@nodiscard
---@return string
M.to_dirname = function(path) return vim.fs.dirname(path) end

--- Normalizes a path for use as a table key.
--- On case-insensitive systems (macOS, Windows), lowercases the path
--- so lookkeys remain consistent regardless of input casing.
---
---@nodiscard
---@param path string
---@return string
M.to_key = function(path)
  path = M.to_normalize(path)
  if M.is_case_insensitive then path = path:lower() end
  return path
end

---@nodiscard
---@return string
M.to_normalize = function(path) return vim.fs.normalize(path) end

---@nodiscard
---@return string
M.to_os = function(path) return M.to_normalize(path) end
if M.is_windows then
  M.to_os = function(path)
    local normalized = M.to_normalize(path:gsub('\\', '/'))
    if M.is_abs(path) then
      if normalized:sub(1, 2) == '//' then return normalized end
      local drive, rest = normalized:match('^/([%a])/(.*)$')
      if drive then return ('%s:/%s'):format(drive, rest) end
      return normalized
    end
    local drive, rest = normalized:match('^/([%a])/(.+)$')
    if drive then
      local candidate = ('%s:/%s'):format(drive, rest)
      if M.to_posix(candidate) == path then return candidate end
    end
    return normalized
  end
end

---@nodiscard
---@return string
M.to_posix = function(path) return M.to_normalize(path) end
if M.is_windows then
  M.to_posix = function(path)
    path = M.to_normalize(path)
    if M.is_abs(path) then
      if path:sub(1, 2) == '\\\\' then return M.to_normalize('/' .. path:gsub('\\', '/'):sub(2)) end
      local drive, rest = path:match('^([%a]):[/\\](.*)$')
      if drive then return M.to_normalize(('/%s/%s'):format(drive, rest)) end
    end
    return M.to_normalize(path)
  end
end

---@nodiscard
---@return string
M.to_rel = function(base, target) return vim.fs.relpath(M.to_normalize(base), M.to_normalize(target)) or '' end

return M
