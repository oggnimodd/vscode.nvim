-- ~/.config/nvim/lua/custom/copy-file-content.lua
-- NATIVE NEOVIM IMPLEMENTATION

--- Copies the entire content of the current file to the system clipboard
-- without moving the cursor or creating a visual selection.
local function copy_entire_file_content()
  -- Get all lines from the current buffer (0) from start (0) to end (-1)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Determine the correct line ending for the current file
  local eol = vim.bo.fileformat == 'dos' and '\r\n' or '\n'

  -- Join the lines into a single string
  local content = table.concat(lines, eol)

  -- Set the system clipboard register (+)
  vim.fn.setreg('+', content)
  vim.api.nvim_echo({ { 'Native: Copied entire file to clipboard.', 'MoreMsg' } }, false, {})
end

-- Create a user command that we can call from our keymap
vim.api.nvim_create_user_command('CopyFileContent', copy_entire_file_content, { desc = 'Copy the entire file content to the clipboard' })
