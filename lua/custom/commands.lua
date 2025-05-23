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

-- ============================================================
-- == Command to Copy Project File Tree (JS/TS Projects) ==
-- ============================================================

--- Finds the nearest ancestor directory containing a specific marker file.
---@param start_dir string The directory to start searching from.
---@param marker string The filename to look for (e.g., 'package.json', '.git').
---@return string|nil The path to the directory containing the marker, or nil if not found.
local function find_project_root(start_dir, marker)
  local current_dir = start_dir
  local uv = vim.uv or vim.loop -- Use vim.uv if available (Neovim 0.10+), fallback to vim.loop
  if not current_dir or current_dir == '' then
    return nil -- Cannot search from an empty path
  end

  while current_dir do
    local marker_path = current_dir .. '/' .. marker
    local stat = uv.fs_stat(marker_path)

    if stat and stat.type == 'file' then
      return current_dir -- Found the marker file in this directory
    end

    -- Stop if we've reached the filesystem root
    local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
    if parent_dir == current_dir or parent_dir == '' then
      break -- Reached root or invalid path
    end
    current_dir = parent_dir
  end

  return nil -- Marker not found in ancestor directories
end

--- Copies a filtered file tree of the current JS/TS project to the clipboard (Quiet Version).
local function CopyProjectTreeToClipboard_Quiet()
  -- 1. Check if 'tree' command exists
  if vim.fn.executable 'tree' == 0 then
    vim.notify("Error: 'tree' command not found. Please install it.", vim.log.levels.ERROR)
    return
  end

  -- 2. Determine starting directory (current file's dir or cwd)
  local current_buf_path = vim.fn.expand '%:p'
  local start_dir
  if current_buf_path ~= '' then
    start_dir = vim.fn.expand '%:p:h'
  else
    start_dir = vim.fn.getcwd()
  end

  if not start_dir or start_dir == '' then
    vim.notify('Error: Could not determine a starting directory.', vim.log.levels.ERROR)
    return
  end

  -- 3. Find the project root marked by 'package.json'
  local project_root = find_project_root(start_dir, 'package.json')

  if not project_root then
    vim.notify('Error: Could not find project root (package.json).', vim.log.levels.ERROR)
    return
  end

  -- 4. Define ignore patterns for 'tree -I'
  local ignore_pattern = table.concat({
    'node_modules',
    '.git',
    'dist',
    'build',
    'out',
    '.cache',
    'coverage',
    '.DS_Store',
    '*.log',
    '.env*',
    '.vscode',
    '.idea',
    -- Add any other patterns you want to ignore
  }, '|')

  -- 5. Construct and execute the 'tree' command
  local command_list = { 'tree', '-I', ignore_pattern, project_root }
  -- REMOVED: vim.notify('Running: ' .. table.concat(command_list, ' '), vim.log.levels.INFO)

  local tree_output = vim.trim(vim.fn.system(command_list))

  -- 6. Check for errors during execution
  if vim.v.shell_error ~= 0 then
    -- Display the actual error output from the command if available and not empty
    local error_message = "Error running 'tree' command. Exit code: " .. vim.v.shell_error
    if tree_output and tree_output ~= '' then
      error_message = error_message .. '\nOutput:\n' .. tree_output
    end
    vim.notify(error_message, vim.log.levels.ERROR)
    return
  end

  -- REMOVED: Warning for empty output - just copy the (potentially empty) string

  -- 7. Copy the output to the clipboard
  vim.fn.setreg('+', tree_output)
  vim.notify 'Project file tree copied to clipboard.' -- Simplified success message
end

-- Create the user command :CopyProjectTree
vim.api.nvim_create_user_command(
  'CopyProjectTree',
  CopyProjectTreeToClipboard_Quiet, -- Use the quiet version of the function
  {
    desc = 'Find JS/TS project root and copy filtered file tree to clipboard (Quiet)',
    nargs = 0, -- This command takes no arguments
  }
)

-- [[ END Project Tree Command ]]

-- ============================================================
-- == Command to Remove Trailing Comments ==
-- ============================================================

-- Function to remove trailing comments based on filetype, handling multiple styles efficiently
local function remove_trailing_comments()
  local ft = vim.bo.filetype
  local pattern -- Will hold the final Vim regex pattern string

  -- Define basic patterns (need double backslash for Lua string and Vim regex)
  local python_pattern = '\\S\\zs\\s*#.*$'
  local lua_pattern = '\\S\\zs\\s*--.*$'
  local js_pattern = '\\S\\zs\\s*//.*$'
  local block_pattern = '\\S\\zs\\s*/\\*.*\\*/$' -- C-style block comment /* ... */ on one line
  local html_pattern = '\\S\\zs\\s*<!--.*-->$' -- HTML/XML comment <!-- ... --> on one line

  -- Determine the pattern(s) based on filetype
  if ft == 'python' then
    pattern = python_pattern
  elseif ft == 'lua' then
    pattern = lua_pattern
  elseif vim.tbl_contains({ 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'jsonc' }, ft) then
    -- Combine JS line comments and block comments on the same line
    pattern = '\\S\\zs\\s*\\(//.*\\|/\\*.*\\*/\\)$' -- Need to group alternatives with \(...\) and escape |
  elseif ft == 'svelte' then
    -- Combine JS line, C block, and HTML comments
    pattern = '\\S\\zs\\s*\\(//.*\\|/\\*.*\\*/\\|<!--.*-->\\)$'
  elseif ft == 'css' or ft == 'scss' or ft == 'less' then
    pattern = block_pattern -- CSS primarily uses block comments
  elseif ft == 'html' or ft == 'xml' or ft == 'vue' then -- Vue template uses HTML comments
    pattern = html_pattern
  elseif ft == 'sh' or ft == 'bash' or ft == 'zsh' then
    pattern = python_pattern -- Shell uses '#' like Python
  elseif ft == 'vim' then
    pattern = '\\S\\zs\\s*\\".*$' -- Vimscript uses "
  elseif ft == 'sql' then
    pattern = lua_pattern -- SQL often uses '--'
  else
    -- Add more filetypes and their comment styles here if needed
    -- Example: elseif ft == 'ruby' then pattern = python_pattern end
    -- vim.notify('No specific trailing comment pattern for filetype: ' .. ft, vim.log.levels.WARN)
    return -- Exit if no pattern is defined for the current filetype
  end

  if not pattern then
    return -- Exit if pattern logic somehow failed (shouldn't happen with current structure)
  end

  -- Save view/cursor before making changes
  local original_cursor = vim.api.nvim_win_get_cursor(0)
  local original_view = vim.fn.winsaveview()
  local separator = '#' -- Using '#' as the separator for :s to avoid escaping '/' in patterns

  -- Escape the *final* pattern for the chosen separator ONLY if the pattern contains the separator
  -- In this case, our patterns don't use '#', so escaping is technically not needed, but it's safer.
  local escaped_pattern_for_cmd = vim.fn.escape(pattern, separator)

  -- Construct the single substitution command
  -- %s#<pattern>##e
  -- % - whole buffer
  -- s - substitute
  -- # - separator
  -- <pattern> - the regex to match (escaped for the separator)
  -- # - separator
  -- (empty) - replace with nothing
  -- # - separator
  -- e - suppress errors if pattern not found (prevents "E486: Pattern not found" messages/prompts)
  local cmd = string.format('%%s%s%s%s%se', separator, escaped_pattern_for_cmd, separator, separator)
  -- print("Executing command: " .. cmd) -- Uncomment for debugging

  -- Execute the command
  vim.cmd(cmd)

  -- Restore view/cursor after making changes
  -- Use pcall for safety, although errors here are less likely
  pcall(vim.fn.winrestview, original_view)
  pcall(vim.api.nvim_win_set_cursor, 0, original_cursor)
end

-- Create or update the user command :RemoveTrailingComments
vim.api.nvim_create_user_command('RemoveTrailingComments', remove_trailing_comments, {
  desc = 'Remove trailing comments for current filetype (Optimized)',
  force = true, -- Allow redefining the command
})

-- [[ END Remove Trailing Comments Command ]]

-- Add other custom commands below
