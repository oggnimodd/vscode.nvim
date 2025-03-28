-- ~/.config/nvim/lua/custom/mappings.lua
-- Goal: Make Neovim feel more like VS Code for common actions.
local map = vim.keymap.set
local opts = { noremap = true, silent = true } -- Default options for mappings

-- [[ Basic File Operations ]]
-- Save file (Force)
map({ 'n', 'v', 'i' }, '<C-s>', '<Cmd>write!<CR><Esc>', { desc = 'Save File (Forced)' })
-- Quit All (Force)
map({ 'n', 'i', 'v', 'c' }, '<C-q>', '<Cmd>qa!<CR>', { desc = 'Quit All without saving' })

-- [[ Clipboard Operations (Copy/Paste/Cut) ]]
-- Ensure 'vim.opt.clipboard = "unnamedplus"' is set in init.lua or similar config

-- Copy
map('v', '<C-c>', '"+y', { desc = 'Copy Selection to system clipboard' })
map('n', '<C-c>', '"+yy', { desc = 'Copy Current Line to system clipboard' })
map('i', '<C-c>', '<C-o>"+yy', { desc = 'Copy Current Line to system clipboard' })

-- Paste
map('n', '<C-v>', '"+p', { desc = 'Paste from system clipboard after cursor' })
map('n', 'gP', '"+P', { desc = 'Paste from system clipboard before cursor' }) -- Using "+P for before cursor
map('i', '<C-v>', '<C-R>+', { desc = 'Paste from system clipboard' })
-- Paste over selection without yanking the replaced text
map('v', '<C-v>', '"_dP', { desc = 'Paste over selection from system clipboard' })

-- Cut
map('v', '<C-x>', '"+d', { desc = 'Cut Selection to system clipboard' })
map('n', '<C-x>', '"+dd', { desc = 'Cut Current Line to system clipboard' })
map('i', '<C-x>', '<C-o>"+dd', { desc = 'Cut Current Line to system clipboard' })

-- [[ Editing ]]
-- Indentation
map('v', '<Tab>', '>gv', { desc = 'Indent selection' })
map('v', '<S-Tab>', '<gv', { desc = 'Unindent selection' })
map('n', '<Tab>', '>>', { desc = 'Indent line' })
map('n', '<S-Tab>', '<<', { desc = 'Unindent line' })
map('i', '<S-Tab>', '<C-d>', { desc = 'Unindent line (smart)' })

-- Move Lines (Alt + Up/Down)
map('n', '<A-j>', '<Cmd>move .+1<CR>==', { desc = 'Move line down' })
map('n', '<A-down>', '<Cmd>move .+1<CR>==', { desc = 'Move line down' })
map('n', '<A-k>', '<Cmd>move .-2<CR>==', { desc = 'Move line up' })
map('n', '<A-up>', '<Cmd>move .-2<CR>==', { desc = 'Move line up' })
map('i', '<A-j>', '<Esc><Cmd>move .+1<CR>==gi', { desc = 'Move line down' })
map('i', '<A-down>', '<Esc><Cmd>move .+1<CR>==gi', { desc = 'Move line down' })
map('i', '<A-k>', '<Esc><Cmd>move .-2<CR>==gi', { desc = 'Move line up' })
map('i', '<A-up>', '<Esc><Cmd>move .-2<CR>==gi', { desc = 'Move line up' })
map('v', '<A-j>', ":move '>+1<CR>gv=gv", { desc = 'Move selection down' })
map('v', '<A-down>', ":move '>+1<CR>gv=gv", { desc = 'Move selection down' })
map('v', '<A-k>', ":move '<-2<CR>gv=gv", { desc = 'Move selection up' }) -- Corrected range
map('v', '<A-up>', ":move '<-2<CR>gv=gv", { desc = 'Move selection up' }) -- Corrected range

-- Insert Line Below (Ctrl+Enter)
-- Normal Mode: Use 'o' command
map('i', '<C-Enter>', '<C-o>o', { desc = '[VSCode] Insert line below' })
-- CORRECTED THIS LINE: Remove the <Esc> to stay in Insert mode
map('n', '<C-Enter>', 'o', { desc = '[VSCode] Insert line below' })
map('v', '<C-Enter>', '<Esc>o', { desc = '[VSCode] Insert line below (exit visual)' })

-- Normal Mode: Use 'O' command
-- Insert Line Above using Ctrl+K (Alternative to Ctrl+Shift+Enter)
map('n', '<C-k>', 'O', { desc = '[VSCode Alt] Insert line above (Ctrl+k)' })
map('i', '<C-k>', '<C-o>O', { desc = '[VSCode Alt] Insert line above (Ctrl+k)' })
map('v', '<C-k>', '<Esc>O', { desc = '[VSCode Alt] Insert line above (Ctrl+k)' })

-- Delete Line (Ctrl+Shift+K) - without yanking
map({ 'n', 'v' }, '<C-S-k>', '"_dd', { desc = 'Delete line (no yank)' })
map('i', '<C-S-k>', '<C-o>"_dd', { desc = 'Delete line (no yank)' })

-- Delete Word Backwards (Ctrl+Backspace)
map('i', '<C-BS>', '<C-w>', { desc = 'Delete word backwards' })

-- Undo/Redo
map('i', '<C-z>', '<C-o>u', { desc = 'Undo' })
map('n', '<C-z>', 'u', { desc = 'Undo' })
map('v', '<C-z>', '<Esc>u', { desc = 'Undo (exit visual)' }) -- Removed <CR>, it's unneeded
map({ 'n', 'i', 'v' }, '<C-y>', '<C-r>', { desc = 'Redo' }) -- Ctrl+Y often used for Redo
map({ 'n', 'i', 'v' }, '<C-S-z>', '<C-r>', { desc = 'Redo' })

-- [[ Navigation & Selection ]]
-- Select All (Ctrl+A)
map('n', '<C-a>', 'ggVG', { desc = 'Select All' })
map('i', '<C-a>', '<C-O>ggVG', { desc = 'Select All' })
map('v', '<C-a>', '<Esc>ggVG', { desc = 'Select All' })

-- Word Jumps (Ctrl + Left/Right) - Using standard vim motions via <C-o> in insert
map('i', '<C-Right>', '<C-o>w', { desc = 'Jump word right' })
map('i', '<C-Left>', '<C-o>b', { desc = 'Jump word left' })
map('n', '<C-Right>', 'w', { desc = 'Jump word right' })
map('n', '<C-Left>', 'b', { desc = 'Jump word left' })

-- Character Selection (Shift + Arrow Keys)
map('n', '<S-Right>', 'vl', { desc = 'Start visual selection right' })
map('n', '<S-Left>', 'vh', { desc = 'Start visual selection left' })
map('n', '<S-Down>', 'vj', { desc = 'Start visual selection down' })
map('n', '<S-Up>', 'vk', { desc = 'Start visual selection up' })
map('i', '<S-Right>', '<C-o>vl', { desc = 'Start visual selection right' })
map('i', '<S-Left>', '<C-o>vh', { desc = 'Start visual selection left' })
map('i', '<S-Down>', '<C-o>vj', { desc = 'Start visual selection down' })
map('i', '<S-Up>', '<C-o>vk', { desc = 'Start visual selection up' })
map('v', '<S-Right>', 'l', { desc = 'Extend selection right' })
map('v', '<S-Left>', 'h', { desc = 'Extend selection left' })
map('v', '<S-Down>', 'j', { desc = 'Extend selection down' })
map('v', '<S-Up>', 'k', { desc = 'Extend selection up' })

-- Word Selection (Ctrl + Shift + Left/Right)
-- Note: Terminal support for Ctrl+Shift+Arrow can be inconsistent.
map('i', '<C-S-Right>', '<C-o>ve', { desc = 'Select word right' })
map('i', '<C-S-Left>', '<C-o>vb', { desc = 'Select word left' })
map('n', '<C-S-Right>', 've', { desc = 'Select word right' })
map('n', '<C-S-Left>', 'vb', { desc = 'Select word left' })
map('v', '<C-S-Right>', 'e', { desc = 'Expand selection word right' })
map('v', '<C-S-Left>', 'b', { desc = 'Expand selection word left' })

-- Block Selection Start (Ctrl + Shift + Up/Down)
map('n', '<C-S-Up>', '<C-v>k', { desc = 'Start visual block selection up' })
map('n', '<C-S-Down>', '<C-v>j', { desc = 'Start visual block selection down' })
map('i', '<C-S-Up>', '<C-o><C-v>k', { desc = 'Start visual block selection up' })
map('i', '<C-S-Down>', '<C-o><C-v>j', { desc = 'Start visual block selection down' })
-- In visual mode, these keys will extend selection line-wise (same as Shift+Up/Down)
map('v', '<C-S-Up>', 'k', { desc = 'Extend selection up' })
map('v', '<C-S-Down>', 'j', { desc = 'Extend selection down' })

-- Scroll Lines (Ctrl + Up/Down)
map('i', '<C-Up>', '<C-o><C-y>', { desc = 'Scroll up' })
map('i', '<C-Down>', '<C-o><C-e>', { desc = 'Scroll down' })
map('n', '<C-Up>', '<C-y>', { desc = 'Scroll up' })
map('n', '<C-Down>', '<C-e>', { desc = 'Scroll down' })

-- Go to Definition (F12 / Ctrl+Click is often handled by terminal)
map({ 'n', 'v', 'i' }, '<F12>', '<Cmd>lua vim.lsp.buf.definition()<CR>', { desc = 'Go to Definition' })

-- Smart Home/End (Using built-in motions)
map({ 'n', 'v', 'i' }, '<Home>', '<Home>', { desc = 'Go to beginning of line (respects wrap)' }) -- Use built-in <Home>
map({ 'n', 'v', 'i' }, '<C-Home>', '^', { desc = 'Go to first non-blank char' }) -- Ctrl+Home for first non-blank
map({ 'n', 'v', 'i' }, '<End>', '<End>', { desc = 'Go to end of line (respects wrap)' }) -- Use built-in <End>

-- Select to Home/End (Simplified)
map({ 'n', 'i' }, '<S-Home>', '<C-o>v<Home>', { desc = 'Select to beginning of line' })
map({ 'n', 'i' }, '<S-End>', '<C-o>v<End>', { desc = 'Select to end of line' })
map('v', '<S-Home>', '<Home>', { desc = 'Select to beginning of line' }) -- Adjust visual selection bound
map('v', '<S-End>', '<End>', { desc = 'Select to end of line' }) -- Adjust visual selection bound

-- Navigate Change List (Alt + Left/Right) - Simplified
map('n', '<A-Left>', 'g;', { desc = 'Go to previous change' })
map('n', '<A-Right>', 'g,', { desc = 'Go to next change' })
map('i', '<A-Left>', '<C-g>g;', { desc = 'Go to previous change' }) -- Built-in insert mode command
map('i', '<A-Right>', '<C-g>g,', { desc = 'Go to next change' }) -- Built-in insert mode command

-- [[ UI / Interaction ]]
-- Toggle File Explorer (Ctrl+B) - Requires Neo-tree or similar
map({ 'n', 'i' }, '<C-b>', '<Cmd>Neotree toggle<CR>', { desc = 'Toggle File Explorer' })

-- Autocompletion Trigger (Ctrl+Space) - Optional, usually automatic with nvim-cmp
-- map('i', '<C-Space>', 'cmp.mapping.complete()', { expr = true, desc = 'Trigger Completion' })

-- Delete selection with Backspace/Delete
map('v', '<BS>', '"_d', { desc = 'Delete selection (no yank)' })
map('v', '<Delete>', '"_d', { desc = 'Delete selection (no yank)' })

-- [[ Mode Management ]]
-- Use Esc or <C-[> to exit modes (standard Vim behavior)

-- [[ Find Files (Ctrl+P) ]]
map({ 'n', 'i' }, '<C-p>', function()
  require('telescope.builtin').find_files()
end, { desc = '[Ctrl+P] Find Files' })

-- [[ Search (Ctrl+F) ]]
map({ 'n', 'v' }, '<C-f>', '/', { desc = '[Ctrl+F] Search Forward' })
map('i', '<C-f>', '<Esc>/', { desc = '[Ctrl+F] Search Forward' })

-- [[ Commenting (Ctrl+/) ]] - Using Comment.nvim plugin API
-- Normal mode: Toggle current line
map('n', '<C-/>', function()
  require('Comment.api').toggle.linewise.current()
end, { desc = 'Toggle comment line' })

-- Visual mode: Toggle selected lines
map('v', '<C-/>', function()
  -- Need <Esc> to exit visual mode before Comment.nvim gets the range correctly
  local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'nx', false)
  -- Use linewise toggle with the 'v' motion context
  require('Comment.api').toggle.linewise(vim.fn.visualmode())
end, { desc = 'Toggle comment for selection' })

-- Insert mode: Toggle current line with VSCode-like behavior on empty lines
map('i', '<C-/>', function()
  -- Check if the current line is empty or only whitespace
  local current_line = vim.api.nvim_get_current_line()
  local is_line_effectively_empty = current_line:match '^%s*$'

  -- Escape insert mode, perform the toggle, then decide how to re-enter insert mode
  local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'n', true) -- Use 'n' mode, 'true' means remap keys in sequence if needed

  -- Perform the comment toggle using the API
  require('Comment.api').toggle.linewise.current()

  -- Decide how to re-enter insert mode
  if is_line_effectively_empty then
    -- If the line was empty, move to the end of the now-commented line and enter insert mode
    -- 'A' command does exactly this.
    vim.api.nvim_feedkeys('A', 'n', true)
  else
    -- If the line wasn't empty, return to the last known insert position
    -- 'gi' command does exactly this.
    vim.api.nvim_feedkeys('gi', 'n', true)
  end
end, { desc = 'Toggle comment line (VSCode like on empty)' })

-- [[ LSP Rename (F2) ]]
map({ 'n', 'v', 'i' }, '<F2>', '<Cmd>lua vim.lsp.buf.rename()<CR>', { desc = 'Rename Symbol' })

-- Delete word backwards in command line mode (like Ctrl+W)
map('c', '<C-BS>', '<C-w>', { desc = 'Delete word backwards' })

-- Add any other future custom mappings below this line
