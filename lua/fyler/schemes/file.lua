local libpath = Fyler.import('fyler.lib.path')
local libasync = Fyler.import('fyler.lib.async')

local M = {}

local uv = vim.uv

---@param path string
---@return boolean
M.is_dir = function(path) return vim.fn.isdirectory(libpath.to_normalize(path)) == 1 end

---@class fs_entry
---@field name string
---@field type string

---@param path string
---@param cb fun(err: string|nil, entries: fs_entry[]|nil)
M.scan_dir = function(path, cb)
  assert(path, 'Expected string got nil')

  local co = coroutine.create(function()
    local success, result = pcall(function()
      local opendir = libasync.await(uv.fs_opendir)
      local readdir = libasync.await(uv.fs_readdir)
      local stat = libasync.await(uv.fs_stat)
      local realpath = libasync.await(uv.fs_realpath)

      local err, dir = opendir(libpath.to_os(path))
      if err then error(err) end

      local entries = {}

      while true do
        local read_err, chunk = readdir(dir)
        if read_err then
          uv.fs_closedir(dir, function() end)
          error(read_err)
        end
        if not chunk then break end
        vim.list_extend(entries, chunk)
      end

      for _, entry in ipairs(entries) do
        if entry.type == 'link' then
          local full_path = libpath.do_join(path, entry.name)
          local stat_err, stat_result = stat(full_path)
          if not stat_err then
            entry.type = stat_result.type
            local rp_err, rp = realpath(full_path)
            if not rp_err then entry.link_target = rp end
          end
        end
      end

      uv.fs_closedir(dir, function(close_err) cb(close_err, entries) end)
    end)

    if not success then cb(result, nil) end
  end)

  local success, err = coroutine.resume(co)
  if not success then cb(err, nil) end
end

---@param actions fyler.Action[]
---@param cb fun(err: string|nil)
M.execute = function(actions, cb)
  local co = coroutine.create(function()
    local ok, err = pcall(function()
      local mkdir = libasync.await(uv.fs_mkdir)
      local open_file = libasync.await(uv.fs_open)
      local close_file = libasync.await(uv.fs_close)
      local unlink = libasync.await(uv.fs_unlink)
      local rmdir = libasync.await(uv.fs_rmdir)
      local rename = libasync.await(uv.fs_rename)
      local copyfile = libasync.await(uv.fs_copyfile)
      local stat = libasync.await(uv.fs_stat)
      local opendir = libasync.await(uv.fs_opendir)
      local readdir = libasync.await(uv.fs_readdir)
      local closedir = libasync.await(uv.fs_closedir)

      local function delete_recursive(path)
        local opendir_err, dir = opendir(libpath.to_os(path))
        if opendir_err then error(('opendir %s: %s'):format(path, opendir_err)) end

        while true do
          local readdir_err, chunk = readdir(dir)
          if readdir_err then error(('readdir %s: %s'):format(path, readdir_err)) end
          if not chunk then break end
          for _, entry in ipairs(chunk) do
            local entry_path = libpath.do_join(path, entry.name)
            local entry_type = entry.type
            if entry_type == 'link' then
              local stat_err, stat_result = stat(libpath.to_os(entry_path))
              if stat_err then error(('stat %s: %s'):format(entry_path, stat_err)) end
              entry_type = stat_result.type
            end
            if entry_type == 'directory' then
              delete_recursive(entry_path)
            else
              local unlink_err = unlink(libpath.to_os(entry_path))
              if unlink_err then error(('unlink %s: %s'):format(entry_path, unlink_err)) end
            end
          end
        end

        local closedir_err = closedir(dir)
        if closedir_err then error(('closedir %s: %s'):format(path, closedir_err)) end

        local rmdir_err = rmdir(libpath.to_os(path))
        if rmdir_err then error(('rmdir %s: %s'):format(path, rmdir_err)) end
      end

      local function copy_recursive(src, dst)
        local mkdir_err = mkdir(libpath.to_os(dst), 493)
        if mkdir_err then error(('mkdir %s: %s'):format(dst, mkdir_err)) end

        local opendir_err, dir = opendir(libpath.to_os(src))
        if opendir_err then error(('opendir %s: %s'):format(src, opendir_err)) end

        while true do
          local readdir_err, chunk = readdir(dir)
          if readdir_err then error(('readdir %s: %s'):format(src, readdir_err)) end
          if not chunk then break end
          for _, entry in ipairs(chunk) do
            local entry_src = libpath.do_join(src, entry.name)
            local entry_dst = libpath.do_join(dst, entry.name)
            local entry_type = entry.type
            if entry_type == 'link' then
              local stat_err, stat_result = stat(libpath.to_os(entry_src))
              if stat_err then error(('stat %s: %s'):format(entry_src, stat_err)) end
              entry_type = stat_result.type
            end
            if entry_type == 'directory' then
              copy_recursive(entry_src, entry_dst)
            else
              local copyfile_err = copyfile(libpath.to_os(entry_src), libpath.to_os(entry_dst), 0)
              if copyfile_err then error(('copyfile %s -> %s: %s'):format(entry_src, entry_dst, copyfile_err)) end
            end
          end
        end

        local closedir_err = closedir(dir)
        if closedir_err then error(('closedir %s: %s'):format(src, closedir_err)) end
      end

      for _, action in ipairs(actions) do
        if action.name == 'create' then
          if action.dst:sub(-1) == '/' then
            local mkdir_err = mkdir(libpath.to_os(action.dst), 493)
            if mkdir_err then error(('mkdir %s: %s'):format(action.dst, mkdir_err)) end
          else
            local open_err, fd = open_file(libpath.to_os(action.dst), 'w', 420)
            if open_err then error(('create %s: %s'):format(action.dst, open_err)) end
            local close_err = close_file(fd)
            if close_err then error(('close %s: %s'):format(action.dst, close_err)) end
          end
        elseif action.name == 'delete' then
          local stat_err, stat_result = stat(libpath.to_os(action.src))
          if stat_err then
            error(('stat %s: %s'):format(action.src, stat_err))
          elseif stat_result.type == 'directory' then
            delete_recursive(action.src)
          else
            local unlink_err = unlink(libpath.to_os(action.src))
            if unlink_err then error(('unlink %s: %s'):format(action.src, unlink_err)) end
          end
        elseif action.name == 'move' then
          local rename_err = rename(libpath.to_os(action.src), libpath.to_os(action.dst))
          if rename_err then error(('rename %s -> %s: %s'):format(action.src, action.dst, rename_err)) end
        elseif action.name == 'copy' then
          local stat_err, stat_result = stat(libpath.to_os(action.src))
          if stat_err then
            error(('stat %s: %s'):format(action.src, stat_err))
          elseif stat_result.type == 'directory' then
            copy_recursive(action.src, action.dst)
          else
            local copyfile_err = copyfile(libpath.to_os(action.src), libpath.to_os(action.dst), 0)
            if copyfile_err then error(('copyfile %s -> %s: %s'):format(action.src, action.dst, copyfile_err)) end
          end
        end
      end
    end)

    if not ok then
      cb(err)
      return
    end
    cb(nil)
  end)

  local resume_ok, resume_err = coroutine.resume(co)
  if not resume_ok then cb(resume_err) end
end

return M
