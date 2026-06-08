-- NOTE: using |require| because Fyler.import will not be available without setup.
if vim.fn.has('nvim-0.11') == 0 then
  vim.notify('Fyler.nvim requires at least NVIM 0.11', vim.log.levels.ERROR, { title = 'Fyler.nvim' })
  return
end

if vim.g.loaded_fyler == 1 then return end
vim.g.loaded_fyler = 1

local command = require('fyler.command')
vim.api.nvim_create_user_command('Fyler', command.cmd, command.opts)
