-- ~/.config/nvim/lua/custom/mappings.lua
-- Goal: Make Neovim feel more like VS Code for common actions.
local map = vim.keymap.set
local opts = { noremap = true, silent = true } -- Default options for mappings

-- [[ Basic File Operations ]]
-- Save file (Force)
map({ 'n', 'v', 'i' }, '<C-s>', '<Cmd>write!<CR><Esc>', { desc = 'Save File (Forced)' })
-- Quit All (Force)
map({ 'n', 'i', 'v', 'c' }, '<C-q>', '<Cmd>qa!<CR>', { desc = 'Quit All without saving' })

-- Ensure 'vim.opt.clipboard = "unnamedplus"' is set in init.lua or similar config
-- [[ Clipboard Operations (Copy/Paste/Cut) ]]

map('n', '<C-c>', '"+yy', { desc = 'Copy Current Line to system clipboard' })
map('v', '<C-c>', '"+y', { desc = 'Copy Selection to system clipboard' }) -- ADDED THIS LINE
map('i', '<C-c>', '<C-o>"+yy', { desc = 'Copy Current Line to system clipboard' })

-- Paste
map('n', '<C-v>', '"+p', { desc = 'Paste from system clipboard after cursor' })
map('n', 'gP', '"+P', { desc = 'Paste from system clipboard before cursor' }) -- Using "+P for before cursor
map('i', '<C-v>', function()
  local content = vim.fn.getreg '+' -- Get content from system clipboard (+) register
  -- Pastes the content:
  -- true: convert CRLF to LF (generally good for consistency)
  -- -1: paste all data at once, handling it like a bracketed paste
  vim.api.nvim_paste(content, true, -1)
end, { desc = 'Paste from system clipboard (smart)' })
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
map('i', '<C-j>', '<C-o>o', { desc = '[VSCode] Insert line below' })
-- CORRECTED THIS LINE: Remove the <Esc> to stay in Insert mode
map('n', '<C-j>', 'o', { desc = '[VSCode] Insert line below' })
map('v', '<C-j>', '<Esc>o', { desc = '[VSCode] Insert line below (exit visual)' })

-- Also make ctrl+enter similar to vscode basically ctrl+J
map('i', '<C-Enter>', '<C-o>o', { desc = '[VSCode] Insert line below' })
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

-- Select entire line with 'vv' (like Shift+V)
map({ 'n', 'v' }, 'vv', 'V', { desc = 'Select entire line (like V)' })

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

-- [[ LSP Rename (F2) ]]
map({ 'n', 'v', 'i' }, '<F2>', '<Cmd>lua vim.lsp.buf.rename()<CR>', { desc = 'Rename Symbol' })

-- Delete word backwards in command line mode (like Ctrl+W)
map('c', '<C-BS>', '<C-w>', { desc = 'Delete word backwards' })

-- Maps <leader>xi to wait for a text object character (e.g., w, ", (, {, etc.)
-- Example Usage: <leader>xiw -> changes inside word
-- Example Usage: <leader>xi" -> changes inside double quotes
map('n', '<leader>xi', 'ci', { desc = '[X]change [I]nside object' })

-- Maps <leader>xa to wait for a text object character
-- Example Usage: <leader>xaw -> changes around word (word + space)
-- Example Usage: <leader>xa" -> changes around double quotes (quotes + content)
map('n', '<leader>xa', 'ca', { desc = '[X]change [A]round object' })

-- Map <leader>wc to force-close the current window
map('n', '<leader>wc', '<Cmd>close!<CR>', { desc = '[W]indow [C]lose (Force)' })
-- Or maybe <leader>wq
-- map('n', '<leader>wq', '<Cmd>close!<CR>', { desc = '[W]indow [Q]uit (Force)' })

-- Rename surrounding HTML/JSX tag (Requires ./black-magics/tag-renamer.lua)
-- Using <leader>tr for [T]ag [R]ename
map('n', '<leader>tr', function()
  require('custom.black-magics.tag-renamer').rename_tag_prompt()
end, { desc = '[T]ag [R]ename Tag (Prompt)' })

local tag_wrapper = require 'custom.black-magics.tag-wrapper'
map('n', '<leader>tw', function()
  tag_wrapper.wrap_tag_prompt()
end, { desc = '[T]ag [W]rap Element (Normal)' })
map('v', '<leader>tw', function()
  tag_wrapper.wrap_tag_prompt()
end, { desc = '[T]ag [W]rap Selection (Visual)' })

-- Hover
vim.keymap.set('n', '<leader>k', vim.lsp.buf.hover, { desc = 'Show Type Definition' })

-- VS Code style Command Palette (Ctrl+Shift+P)
map({ 'n', 'i' }, '<C-S-p>', function()
  require('telescope.builtin').commands()
end, { desc = '[Cmd Palette] Commands' })

-- Go to first non-blank character (^) using Alt+h
map({ 'n', 'v' }, '<A-h>', '^', { desc = 'Go/Select to First Non-Blank' })
map('i', '<A-h>', '<C-o>^', { desc = 'Go to First Non-Blank' })

-- Go to end of line ($) using Alt+l
map({ 'n', 'v' }, '<A-l>', '$', { desc = 'Go/Select to End of Line' })
map('i', '<A-l>', '<C-o>$', { desc = 'Go to End of Line' })

-- Optional: Absolute start (column 0)
-- map({ 'n', 'v' }, '<A-h>', '0', { desc = 'Go/Select to Start of Line (Col 0)' })
-- map('i', '<A-h>', '<C-o>0', { desc = 'Go to Start of Line (Col 0)' })

-- Move by visual lines when wrap is enabled
vim.keymap.set('n', 'j', 'gj', { noremap = true, silent = true, desc = 'Move down visual line' })
vim.keymap.set('n', 'k', 'gk', { noremap = true, silent = true, desc = 'Move up visual line' })

-- Optional: Make it work similarly in Visual mode for selection
vim.keymap.set('v', 'j', 'gj', { noremap = true, silent = true, desc = 'Move selection down visual line' })
vim.keymap.set('v', 'k', 'gk', { noremap = true, silent = true, desc = 'Move selection up visual line' })

map('n', '<leader>dc', '<Cmd>RemoveTrailingComments<CR>', { desc = 'Remove Trailing Comments' })
map('n', '<leader>dx', '<Cmd>RemoveAllComments<CR>', { desc = 'Remove All Comments' })

-- Terminal stuff using Alt+`
local Terminal = require('toggleterm.terminal').Terminal

map({ 'n', 'i', 't' }, '<c-\\>', function()
  local bottom_term_config = {
    direction = 'float',
    id = 1,
    hidden = true,
    float_opts = {
      border = 'none',
      width = vim.o.columns,
      height = function()
        return math.max(1, math.floor(vim.o.lines * 0.30))
      end,
      row = function()
        local term_height = math.max(1, math.floor(vim.o.lines * 0.30))
        local border_height = 0
        return math.max(0, vim.o.lines - term_height - border_height)
      end,
      col = 0,
    },
    on_open = function(t)
      vim.schedule(function()
        vim.cmd 'startinsert!'
        vim.cmd 'nohlsearch'
      end)
    end,
  }
  local term = Terminal:new(bottom_term_config)
  term:toggle()
end, {
  desc = 'Toggle terminal (float bottom ID 1)',
  noremap = true,
  silent = true,
})

map({ 'n', 'i', 't' }, '<A-`>', function()
  local default_float_config = {
    direction = 'float',
    id = 2,
    hidden = true,
    float_opts = {
      border = 'none',
      width = vim.o.columns,
      height = function()
        return math.max(1, vim.o.lines - 2)
      end,
      row = 0,
      col = 0,
    },
    on_open = function(t)
      vim.schedule(function()
        vim.cmd 'startinsert!'
        vim.cmd 'nohlsearch'
      end)
    end,
  }
  local term = Terminal:new(default_float_config)
  term:toggle()
end, {
  desc = 'Toggle terminal (near full screen float ID 2)',
  noremap = true,
  silent = true,
})

-- Make ctrl + backspace work in terminal
map('t', '<C-BS>', '<C-W>', { noremap = true, silent = true, desc = 'Delete word backward in terminal' })

-- Telescope search diagnostics
map('n', '<leader>se', function()
  require('telescope.builtin').diagnostics()
end, { noremap = true, silent = true, desc = '[S]earch [E]rrors (Diagnostics)' })

-- Show line diagnostics (Float)
map('n', '<leader>e', vim.diagnostic.open_float, { noremap = true, silent = true, desc = 'Show Line Diagnostics (Float)' })

-- Diagnostic Navigation
map('n', ']d', vim.diagnostic.goto_next, { noremap = true, silent = true, desc = 'Go to Next Diagnostic' })
map('n', '[d', vim.diagnostic.goto_prev, { noremap = true, silent = true, desc = 'Go to Previous Diagnostic' })

-- Search Buffer
map('n', '<leader>sb', function()
  require('telescope.builtin').current_buffer_fuzzy_find()
end, { noremap = true, silent = true, desc = 'Live Grep Current File' })

-- Rust analyzer manual check
map('n', '<leader>rc', function()
  -- Step 1: Save all modified buffers. This is crucial for rust-analyzer.
  vim.cmd 'wa'

  -- Step 2: Get the active rust-analyzer client for the current buffer.
  local clients = vim.lsp.get_clients { bufnr = 0, name = 'rust_analyzer' }
  if #clients == 0 then
    vim.notify('rust-analyzer is not active for this buffer.', vim.log.levels.WARN, { title = 'LSP' })
    return
  end

  -- Step 3: Send the NOTIFICATION to the server. This is the key change.
  for _, client in ipairs(clients) do
    local params = vim.lsp.util.make_text_document_params()
    client.notify('rust-analyzer/runFlycheck', params)
  end

  -- Step 4: Provide user feedback that the command was sent.
  vim.notify('rust-analyzer: check triggered.', vim.log.levels.INFO, { title = 'LSP' })
end, {
  noremap = true,
  silent = true,
  desc = '[R]ust [C]heck Project (rust-analyzer)',
})

-- Flutter
map('n', '<leader>fr', '<Cmd>FlutterReload<CR>', { desc = '[F]lutter [R]eload' })
map('n', '<leader>fq', '<Cmd>FlutterQuit<CR>', { desc = '[F]lutter [Q]uit' })
map('n', '<leader>fl', '<Cmd>FlutterLogToggle<CR>', { desc = '[F]lutter [L]og Toggle' })
map('n', '<leader>fx', '<Cmd>FlutterRun -d web-server --web-port 4002<CR>', { desc = '[F]lutter Run Web Server' })

-- Add any other future custom mappings below this line
