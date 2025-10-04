-- ~/.config/nvim/lua/custom/paste-file-content.lua
-- NATIVE NEOVIM IMPLEMENTATION

--- Replaces the entire content of the current file with the system clipboard content
-- without moving the cursor and preserving the file format.
local function paste_entire_file_content()
  -- Get content from system clipboard register (+)
  local content = vim.fn.getreg '+'

  -- Check if clipboard is empty
  if content == '' then
    vim.api.nvim_echo({ { 'Clipboard is empty. Nothing to paste.', 'WarningMsg' } }, false, {})
    return false
  end

  -- Split the clipboard content into lines, handling different line endings
  local lines = vim.split(content, '\r?\n', { trimempty = false })

  -- Remove the last line if it's empty (common when copying from some sources)
  if lines[#lines] == '' then
    table.remove(lines)
  end

  -- Get current buffer to replace content
  local buf = vim.api.nvim_get_current_buf()

  -- Replace entire buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Mark buffer as modified
  vim.api.nvim_set_option_value('modified', true, { buf = buf })

  vim.api.nvim_echo({ { 'Native: Pasted clipboard content to file.', 'MoreMsg' } }, false, {})
  return true
end

-- Create a user command that we can call from our keymap
vim.api.nvim_create_user_command('PasteFileContent', paste_entire_file_content, { desc = 'Replace the entire file content with clipboard data' })

-- Return the function so it can be called from other modules
return {
  paste_entire_file_content = paste_entire_file_content,
}

