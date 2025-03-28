-- ~/.config/nvim/lua/custom/commands.lua

-- Command to copy the relative path of the current file
vim.api.nvim_create_user_command('CopyRelativePath', function()
  local current_file_path = vim.fn.expand '%'
  if current_file_path == '' then
    vim.notify('Buffer has no associated file path', vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('+', current_file_path) -- '+' is the system clipboard register
  vim.notify('Copied relative path: ' .. current_file_path)
end, {
  desc = 'Copy relative path of current file to clipboard',
  nargs = 0, -- This command takes no arguments
})

-- Add other custom commands below
