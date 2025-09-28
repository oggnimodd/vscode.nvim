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
-- See the vscode keybindings.json

-- Quit Editor/Tab: Ctrl+Q
-- This tells Neovim to ask VS Code to close the current editor tab.
map({ 'n', 'i', 'v', 'c' }, '<C-q>', function()
  vscode.action 'workbench.action.closeActiveEditor'
end, { desc = 'VSCode Close Editor' })

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

-- Go to Start/End of Line (Alt+H, Alt+L)
-- These mappings are triggered by the passthrough rules in keybindings.json
-- We map them to Neovim's native motions to preserve composition (e.g., d$, c^).
map({ 'n', 'v' }, '<A-h>', '^', { desc = 'Go/Select to First Non-Blank' })
map({ 'n', 'v' }, '<A-l>', '$', { desc = 'Go/Select to End of Line' })

-- =================================================================
-- LSP & Diagnostics Mappings
-- =================================================================

-- Show Hover Information (<leader>k)
-- This tells Neovim to ask VS Code to show its hover/LSP information.
map('n', '<leader>k', function()
  vscode.action 'editor.action.showHover'
end, { desc = 'VSCode Show Hover Info' })

-- Navigate Diagnostics (]d and [d)
-- These tell Neovim to ask VS Code to jump to the next/previous problem.
map('n', ']d', function()
  vscode.action 'editor.action.marker.next'
end, { desc = 'Go to Next Diagnostic (Current File)' })

map('n', '[d', function()
  vscode.action 'editor.action.marker.prev'
end, { desc = 'Go to Previous Diagnostic (Current File)' })

-- =================================================================
-- Clipboard Mappings (SIMPLE AND CORRECT)
-- =================================================================

-- In NORMAL mode, map Ctrl+C to yank the current line.
map('n', '<C-c>', 'yy', { desc = 'Copy Line to System Clipboard' })

-- In VISUAL mode, map Ctrl+C to a simple yank and escape macro.
map('v', '<C-c>', 'y<Esc>', { desc = 'Copy Selection and Exit Visual Mode' })

-- Paste mappings.
map('n', '<C-v>', 'p', { desc = 'Paste from System Clipboard' })
map('v', '<C-v>', 'p', { desc = 'Paste over Selection from System Clipboard' })

-- Cut mappings.
map('n', '<C-x>', 'dd', { desc = 'Cut Line to System Clipboard' })
map('v', '<C-x>', 'd', { desc = 'Cut Selection to System Clipboard' })
