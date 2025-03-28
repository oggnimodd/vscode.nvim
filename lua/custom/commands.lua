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

--- Copies all diagnostics (errors, warnings, info, hints) for the current buffer
--- to the system clipboard (+ register).
local function CopyAllDiagnosticsToClipboard()
  -- Get diagnostics for the current buffer (buffer 0)
  -- No severity filter, so we get everything.
  local diagnostics = vim.diagnostic.get(0)

  if not diagnostics or #diagnostics == 0 then
    print 'No diagnostics found in the current buffer.'
    return
  end

  -- Map severity enum to readable names
  local severity_map = {
    [vim.diagnostic.severity.ERROR] = 'ERROR',
    [vim.diagnostic.severity.WARN] = 'WARN',
    [vim.diagnostic.severity.INFO] = 'INFO',
    [vim.diagnostic.severity.HINT] = 'HINT',
  }

  local lines_to_copy = {}
  for _, diag in ipairs(diagnostics) do
    local severity_str = severity_map[diag.severity] or 'UNKNOWN'
    local source_str = diag.source or '?'
    -- Format: "Line:Col [SEVERITY] (Source) Message"
    -- vim.diagnostic uses 0-based indexing for line/col, so add 1 for display
    local formatted_line = string.format('%d:%d [%s] (%s) %s', diag.lnum + 1, diag.col + 1, severity_str, source_str, diag.message)
    table.insert(lines_to_copy, formatted_line)
  end

  -- Concatenate all formatted lines with newline separators
  local content = table.concat(lines_to_copy, '\n')

  -- Set the '+' register (system clipboard)
  -- Assumes your clipboard setup ('unnamedplus') is working,
  -- but setreg('+', ...) forces it to the system clipboard regardless.
  vim.fn.setreg('+', content)

  -- Give feedback
  print(string.format('Copied %d diagnostics to clipboard.', #diagnostics))
end

-- Create the user command :CopyDiagnostics
vim.api.nvim_create_user_command(
  'CopyDiagnostics', -- The command name
  CopyAllDiagnosticsToClipboard, -- The function to call
  {
    desc = 'Copy all diagnostics for the current buffer to the clipboard', -- Description for :help etc.
    nargs = 0, -- This command takes no arguments
  }
)

-- [[ END Diagnostic Copy Command ]]

-- Add other custom commands below
