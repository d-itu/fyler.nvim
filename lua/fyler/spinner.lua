local M = {}

local default_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

function M.new(opts)
  opts = opts or {}

  local inst = {
    message = opts.message or 'Loading...',
    frames = opts.frames or default_frames,
    interval = opts.interval or 80,
    timer = nil,
    frame_idx = 0,
    running = false,
  }

  function inst:start()
    if self.running then return end
    self.running = true
    self.frame_idx = 0
    self.timer = vim.uv.new_timer()
    self.timer:start(
      self.interval,
      self.interval,
      vim.schedule_wrap(function()
        if not self.running then return end
        self.frame_idx = (self.frame_idx % #self.frames) + 1
        vim.schedule_wrap(vim.api.nvim_echo)(
          { { self.frames[self.frame_idx] .. ' ' .. self.message, 'None' } },
          false,
          {}
        )
      end)
    )
  end

  function inst:stop()
    if not self.running then return end
    self.running = false
    if self.timer then
      self.timer:stop()
      self.timer:close()
      self.timer = nil
    end
    vim.schedule_wrap(vim.api.nvim_echo)({}, false, {})
  end

  return inst
end

return M
