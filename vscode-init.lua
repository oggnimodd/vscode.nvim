-- ~/.config/nvim/vscode-init.lua
-- This is a dedicated config for the vscode-neovim extension.

-- The most important line: allows Neovim to talk to VS Code.
local vscode = require 'vscode'

-- Set a leader key. Space is a common and good choice.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- -----------------------------------------------------------------
-- Essential Options
-- -----------------------------------------------------------------
vim.opt.clipboard = 'unnamedplus' -- CRITICAL: Use system clipboard for copy/paste
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.number = true -- Show the absolute number on the current line

vim.opt.ignorecase = true -- Case-insensitive searching...
vim.opt.smartcase = true -- ...unless you type a capital letter

vim.opt.hlsearch = true -- Highlight all search results
vim.opt.incsearch = true -- Show search results as you type

-- Make j and k move by visual lines when word wrap is on
vim.keymap.set('n', 'j', 'gj', { noremap = true, silent = true })
vim.keymap.set('n', 'k', 'gk', { noremap = true, silent = true })
vim.keymap.set('v', 'j', 'gj', { noremap = true, silent = true })
vim.keymap.set('v', 'k', 'gk', { noremap = true, silent = true })

-- -----------------------------------------------------------------
-- What NOT to put here:
-- -----------------------------------------------------------------
-- 1. Plugin managers (lazy.nvim, packer)
-- 2. UI plugins (NvimTree, Telescope, Lualine)
-- 3. Colorschemes (tokyonight, etc.)
-- 4. LSP clients (lspconfig, mason)
-- 5. Autocompletion engines (nvim-cmp)
--
-- Let VS Code handle all of that! We just want Neovim for its text editing power.

-- -----------------------------------------------------------------
-- Keymaps: The heart of the integration!
-- We map Vim keys to execute VS Code commands.
-- -----------------------------------------------------------------
local map = vim.keymap.set

-- Save File: Ctrl+S
-- This tells Neovim to ask VS Code to save the file.
map({ 'n', 'v', 'i' }, '<C-s>', function()
  -- Use vscode.call to make the save action SYNCHRONOUS.
  -- The script will pause here until the save is complete.
  -- The third argument is a timeout; -1 means wait indefinitely.
  vscode.call('workbench.action.files.save', {}, -1)

  -- Now that the save is 100% done, check if we were in insert mode.
  if vim.api.nvim_get_mode().mode:find 'i' then
    -- If so, send the <Esc> key. The editor is now in a stable
    -- state and will correctly process the mode change.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
  end
end, { desc = 'VSCode Save File & Exit Insert' })

-- Quit Editor/Tab: Ctrl+Q
-- This tells Neovim to ask VS Code to close the current editor tab.
map({ 'n', 'i', 'v', 'c' }, '<C-q>', function()
  vscode.action 'workbench.action.closeActiveEditor'
end, { desc = 'VSCode Close Editor' })

-- Clipboard: Copy, Cut, Paste (Ctrl+C, Ctrl+X, Ctrl+V)
-- Since we set `clipboard = 'unnamedplus'`, Neovim's standard yank (y),
-- delete (d), and put (p) commands will automatically use the system
-- clipboard. We don't need to map them to `"+y` etc.
-- This makes `yy`, `dd`, `p`, `P`, `ciw` etc. all work with the system clipboard out of the box.

-- Let's add your VS Code-style mappings for convenience.
-- Note: We don't need to handle insert mode separately for these,
-- because VS Code's native Ctrl+C/X/V will work there by default.
map('n', '<C-c>', 'yy', { desc = 'Copy Line (System Clipboard)' })
map('v', '<C-c>', 'y', { desc = 'Copy Selection (System Clipboard)' })

map('n', '<C-x>', 'dd', { desc = 'Cut Line (System Clipboard)' })
map('v', '<C-x>', 'd', { desc = 'Cut Selection (System Clipboard)' })

map('n', '<C-v>', 'p', { desc = 'Paste After (System Clipboard)' })
map('n', 'gP', 'P', { desc = 'Paste Before (System Clipboard)' })
map('v', '<C-v>', 'p', { desc = 'Paste Over Selection (System Clipboard)' })

-- Indentation: Tab and Shift+Tab
-- In Normal and Visual mode, we want Tab/S-Tab to trigger VS Code's indent commands.
map('n', '<Tab>', function()
  vscode.action 'editor.action.indentLines'
end, { desc = 'VSCode Indent Line' })
map('n', '<S-Tab>', function()
  vscode.action 'editor.action.outdentLines'
end, { desc = 'VSCode Outdent Line' })
map('v', '<Tab>', function()
  vscode.action 'editor.action.indentLines'
end, { desc = 'VSCode Indent Selection' })
map('v', '<S-Tab>', function()
  vscode.action 'editor.action.outdentLines'
end, { desc = 'VSCode Outdent Selection' })
