-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]

vim.opt.backup = false -- Do not keep a backup file
vim.opt.writebackup = false -- Do not make a backup before overwriting file
vim.opt.swapfile = false -- Disable swap files (optional, but reduces file I/O noise)

-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- vim.opt.numberwidth = 1

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = false
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.opt.confirm = true

vim.opt.cmdheight = 1 -- Set command line height to 1
vim.opt.laststatus = 3 -- Always show the status line (global)

-- ADD/MODIFY THESE LINES FOR 2-SPACE INDENTATION: --------
vim.opt.tabstop = 2 -- Number of visual spaces per TAB.
vim.opt.softtabstop = 2 -- Number of spaces inserted for a TAB in Insert mode.
vim.opt.shiftwidth = 2 -- Number of spaces used for autoindenting (>> << commands).
vim.opt.expandtab = true -- Use spaces instead of actual Tab characters.
vim.opt.autoindent = true -- Copy indent from current line when starting a new line.
vim.opt.smartindent = true -- Perform smart autoindenting when starting a new line.
-- -- END OF 2-SPACE INDENTATION SETTINGS -------------------

-- Disable default tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have coliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Remove 'r' and 'o' from formatoptions when a file is loaded
-- This prevents auto-continuation of comments on new lines
vim.api.nvim_create_autocmd('FileType', {
  pattern = '*', -- Apply to all file types
  callback = function()
    -- Use vim.opt_local to set options for the current buffer only
    vim.opt_local.formatoptions:remove { 'c', 'r', 'o' }
  end,
  desc = 'Disable automatic comment continuation on new line',
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to automatically pass options to a plugin's `setup()` function, forcing the plugin to be loaded.
  --

  -- Alternatively, use `config = function() ... end` for full control over the configuration.
  -- If you prefer to call `setup` explicitly, use:
  --    {
  --        'lewis6991/gitsigns.nvim',
  --        config = function()
  --            require('gitsigns').setup({
  --                -- Your gitsigns configuration here
  --            })
  --        end,
  --    }
  --
  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`.
  --
  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `opts` key (recommended), the configuration runs
  -- after the plugin has been loaded as `require(MODULE).setup(opts)`.

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.opt.timeoutlen
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback', lsp_fallback = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      log_level = vim.log.levels.DEBUG,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 1500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        json = { 'biome', 'prettierd', stop_after_first = true },
        jsonc = { 'biome', 'prettierd', stop_after_first = true },
        svelte = { 'prettierd' },
        javascript = { 'biome', 'prettierd', stop_after_first = true },
        typescript = { 'biome', 'prettierd', stop_after_first = true },
        tsx = { 'biome', 'prettierd', stop_after_first = true },
        jsx = { 'biome', 'prettierd', stop_after_first = true },
        html = { 'prettierd' },
        css = { 'biome', 'prettierd', stop_after_first = true },
        python = {
          -- To fix auto-fixable lint errors.
          'ruff_fix',
          -- To run the Ruff formatter.
          'ruff_format',
          -- To organize the imports.
          'ruff_organize_imports',
        }, -- Conform can also run multiple formatters sequentially

        -- Yaml shenanigans
        yaml = { 'prettierd' },
        yml = { 'prettierd' },

        -- Toml shenanigans
        toml = { 'prettierd' },

        vue = { 'prettierd' },

        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },

  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
      },
      'saadparwaiz1/cmp_luasnip',

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-nvim-lsp-signature-help',
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {} -- Basic setup for luasnip
      require('luasnip.loaders.from_vscode').lazy_load { paths = { vim.fn.stdpath 'config' .. '/lua/snippets' } }

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = {
          completeopt = 'menu,menuone,noinsert',
        },
        mapping = cmp.mapping.preset.insert {
          -- Use <Up> and <Down> to navigate completion menu
          ['<Up>'] = cmp.mapping.select_prev_item(),
          ['<Down>'] = cmp.mapping.select_next_item(),

          -- Scroll documentation
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          -- Abort completion (close menu without selecting) using Ctrl+E
          ['<C-e>'] = cmp.mapping.abort(),

          -- Accept selected completion using Enter
          ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          },

          -- Manually trigger completion
          ['<C-Space>'] = cmp.mapping.complete {},

          -- Snippet jumping (if luasnip is active)
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),

          -- NOTE: <Tab> and <S-Tab> are intentionally NOT mapped here
          -- This allows Tab to fall through for Supermaven or default behavior
        },
        sources = {
          { name = 'lazydev', group_index = 0 },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          -- Uncomment this if you awnt to use the path source
          -- { name = 'path' },
          { name = 'nvim_lsp_signature_help' },
          -- Consider adding { name = 'supermaven' } if it offers a cmp source
        },
      }
    end,
  },
  --  LSP Plugins
  require 'kickstart.plugins.lsp',

  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        transparent = true,
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
      }

      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      -- require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      -- Default Treesitter configurations options
      -- Keep the parts you want from the original Kickstart opts:
      local ensure_installed = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'typescript',
        'javascript',
        'css',
        'json',
        'tsx',
        'svelte',
        'rust',
        'go',
        'gomod',
        'gowork',
        'gosum',
        -- Add any other languages you frequently use
      }
      local auto_install = true
      local highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' }, -- Keep if needed
      }
      local indent = { enable = true, disable = { 'ruby' } } -- Keep if needed

      -- Now, add your specific textobjects configuration:
      local textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj
          keymaps = {
            -- Your custom keymaps here:
            ['a='] = { query = '@assignment.outer', desc = 'Select outer part of an assignment' },
            ['i='] = { query = '@assignment.inner', desc = 'Select inner part of an assignment' },
            ['l='] = { query = '@assignment.lhs', desc = 'Select left hand side of an assignment' },
            ['r='] = { query = '@assignment.rhs', desc = 'Select right hand side of an assignment' },
            ['aa'] = { query = '@parameter.outer', desc = 'Select outer part of a parameter/argument' },
            ['ia'] = { query = '@parameter.inner', desc = 'Select inner part of a parameter/argument' },
            ['ai'] = { query = '@conditional.outer', desc = 'Select outer part of a conditional' },
            ['ii'] = { query = '@conditional.inner', desc = 'Select inner part of a conditional' },
            ['al'] = { query = '@loop.outer', desc = 'Select outer part of a loop' },
            ['il'] = { query = '@loop.inner', desc = 'Select inner part of a loop' },
            ['af'] = { query = '@call.outer', desc = 'Select outer part of a function call' },
            ['if'] = { query = '@call.inner', desc = 'Select inner part of a function call' },
            ['am'] = { query = '@function.outer', desc = 'Select outer part of a method/function definition' },
            ['im'] = { query = '@function.inner', desc = 'Select inner part of a method/function definition' },
            ['ac'] = { query = '@class.outer', desc = 'Select outer part of a class' },
            ['ic'] = { query = '@class.inner', desc = 'Select inner part of a class' },
            -- Include other keymaps from original Kickstart if desired, e.g.:
            -- ['ak'] = '@block.outer', ['ik'] = '@block.inner', -- Kickstart used 'k' for block
            -- ['as'] = '@statement.outer', ['is'] = '@statement.inner', -- Kickstart used 's' for statement
            -- ['ad'] = '@comment.outer', -- Kickstart used 'd' for comment
          },
          -- You can retain these from Kickstart or remove if not needed:
          -- selection_modes = {
          --   ['@parameter.outer'] = 'v', -- charwise
          --   ['@function.outer'] = 'V', -- linewise
          --   ['@class.outer'] = '<c-v>', -- blockwise
          -- },
          -- include_surrounding_whitespace = true,
        },
        swap = {
          enable = true,
          swap_next = {
            ['<leader>na'] = '@parameter.inner',
            ['<leader>n:'] = '@property.outer',
            ['<leader>nm'] = '@function.outer',
          },
          swap_previous = {
            ['<leader>pa'] = '@parameter.inner',
            ['<leader>p:'] = '@property.outer',
            ['<leader>pm'] = '@function.outer',
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            [']f'] = { query = '@call.outer', desc = 'Next function call start' },
            [']m'] = { query = '@function.outer', desc = 'Next method/function def start' },
            [']c'] = { query = '@class.outer', desc = 'Next class start' },
            [']i'] = { query = '@conditional.outer', desc = 'Next conditional start' },
            [']l'] = { query = '@loop.outer', desc = 'Next loop start' },
            [']s'] = { query = '@scope', query_group = 'locals', desc = 'Next scope' },
            [']z'] = { query = '@fold', query_group = 'folds', desc = 'Next fold' },
            -- Add back Kickstart default if desired:
            -- [']]'] = '@class.outer', -- Kickstart default
          },
          goto_next_end = {
            [']F'] = { query = '@call.outer', desc = 'Next function call end' },
            [']M'] = { query = '@function.outer', desc = 'Next method/function def end' },
            [']C'] = { query = '@class.outer', desc = 'Next class end' },
            [']I'] = { query = '@conditional.outer', desc = 'Next conditional end' },
            [']L'] = { query = '@loop.outer', desc = 'Next loop end' },
            -- Add back Kickstart default if desired:
            -- [']['] = '@class.outer', -- Kickstart default
          },
          goto_previous_start = {
            ['[f'] = { query = '@call.outer', desc = 'Prev function call start' },
            ['[m'] = { query = '@function.outer', desc = 'Prev method/function def start' },
            ['[c'] = { query = '@class.outer', desc = 'Prev class start' },
            ['[i'] = { query = '@conditional.outer', desc = 'Prev conditional start' },
            ['[l'] = { query = '@loop.outer', desc = 'Prev loop start' },
            -- Add back Kickstart default if desired:
            -- ['[['] = '@class.outer', -- Kickstart default
          },
          goto_previous_end = {
            ['[F'] = { query = '@call.outer', desc = 'Prev function call end' },
            ['[M'] = { query = '@function.outer', desc = 'Prev method/function def end' },
            ['[C'] = { query = '@class.outer', desc = 'Prev class end' },
            ['[I'] = { query = '@conditional.outer', desc = 'Prev conditional end' },
            ['[L'] = { query = '@loop.outer', desc = 'Prev loop end' },
            -- Add back Kickstart default if desired:
            -- ['[]'] = '@class.outer', -- Kickstart default
          },
        },
        -- Include other textobject modules if needed, e.g., lsp_interop
        -- lsp_interop = { enable = true, ... }
      }

      -- Call the main Treesitter setup function
      require('nvim-treesitter.configs').setup {
        ensure_installed = ensure_installed,
        auto_install = auto_install,
        highlight = highlight,
        indent = indent,
        textobjects = textobjects, -- Pass your detailed textobjects config here
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = 'gnn', -- Start selection
            node_incremental = 'gnp', -- Expand selection (gn + plus/positive)
            scope_incremental = 'gns', -- Expand to next scope
            node_decremental = 'gnm', -- Shrink selection (gn + minus)
          },
        },
      }

      -- Setup repeatable moves AFTER the main setup
      local ts_repeat_move = require 'nvim-treesitter.textobjects.repeatable_move'
      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move)
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite)
      -- vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr)
      -- vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr)
      -- vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr)
      -- vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr)

      -- Optional: You might have custom query files (like for a:/i:). Ensure they are in your runtime path.
      -- Example: ~/.config/nvim/after/queries/javascript/textobjects.scm
      -- Example: ~/.config/nvim/after/queries/typescript/textobjects.scm
      -- No extra Lua code needed here if the files are placed correctly. Treesitter finds them automatically.
    end,
  },

  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.neo-tree',
  -- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search

  -- Transparent
  {
    'xiyaowong/transparent.nvim',
    -- Optional: You might want this to load slightly later,
    -- after the colorscheme and statusline are fully set up.
    -- event = "VeryLazy",
    config = function()
      require('transparent').setup {
        -- Keep extra_groups empty unless you find specific exceptions
        extra_groups = {
          'MiniStatuslineFilename',
        },
        -- Keep exclude_groups empty
        exclude_groups = {},
        on_clear = function() end,
      }
    end,
  },
  {
    'supermaven-inc/supermaven-nvim',
    config = function()
      require('supermaven-nvim').setup {}
    end,
  },
  { -- Autoclose and autorename HTML/XML/JSX tags
    'windwp/nvim-ts-autotag',
    config = function()
      require('nvim-ts-autotag').setup {
        -- defaults:
        -- filetypes = { "html", "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte", "vue", "tsx", "jsx", "rescript", "xml", "php", "markdown", "astro", "glimmer", "handlebars", "hbs" }
      }
    end,
  },
  {
    'romgrk/barbar.nvim',
    dependencies = {
      'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
      'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    config = function()
      require('barbar').setup()
      local map = vim.keymap.set
      local opts_noremap = { noremap = true, silent = true }
      -- Browser like
      -- Some terminals like kitty will intercept ctrl-tab and ctrl-shift-tab
      map({ 'n', 'v' }, '<C-Tab>', ':BufferNext<CR>', opts_noremap)
      map({ 'n', 'v' }, '<C-S-Tab>', ':BufferPrevious<CR>', opts_noremap)
      map('n', '<Leader>q', ':BufferClose<CR>', opts_noremap)
    end,

    version = '^1.0.0', -- optional: only update when a new 1.x version is released
  },
  {
    'rmagatti/auto-session',
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
      -- log_level = 'debug',
    },
  },
  {
    'numToStr/Comment.nvim',
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    config = function()
      local U = require 'Comment.utils'
      local A = vim.api
      local cfg -- Will be set after require('Comment').setup

      -- Helper to check if a line is empty (needed by custom_comment_toggle)
      local function is_line_empty(lnum)
        -- ... (no changes) ...
        if lnum <= 0 or lnum > A.nvim_buf_line_count(0) then
          return false
        end
        local line_content = A.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
        return line_content ~= nil and line_content:match '^%s*$' ~= nil
      end

      -- Linewise toggle for Normal mode (handles empty lines, count)
      local function custom_comment_toggle(ctype_arg)
        -- ... (no changes) ...
        local ctype = ctype_arg == 'block' and U.ctype.blockwise or U.ctype.linewise
        local current_lnum = A.nvim_win_get_cursor(0)[1]
        cfg = cfg or require('Comment.config'):get()

        if is_line_empty(current_lnum) then
          local ctx = {
            cmode = U.cmode.comment,
            cmotion = U.cmotion.line,
            ctype = ctype,
            range = { srow = current_lnum, scol = 0, erow = current_lnum, ecol = 0 },
          }
          local lcs_raw, rcs_raw = U.parse_cstr(cfg, ctx)
          if not lcs_raw then
            vim.notify('Custom Toggle: Could not determine comment string.', vim.log.levels.WARN)
            return
          end
          local lcs = vim.trim(lcs_raw)
          local rcs = vim.trim(rcs_raw or '')
          local padding_char = U.get_pad(U.is_fn(cfg.padding))
          local if_rcs = U.is_empty(rcs) and rcs or padding_char .. rcs
          local new_line_content = lcs .. padding_char .. if_rcs
          local target_col_0based_before_append = vim.fn.strchars(lcs)

          A.nvim_buf_set_lines(0, current_lnum - 1, current_lnum, false, { new_line_content })
          local final_line_len = vim.fn.strchars(new_line_content)
          target_col_0based_before_append = math.min(target_col_0based_before_append, final_line_len)
          target_col_0based_before_append = math.max(target_col_0based_before_append, 0)
          A.nvim_win_set_cursor(0, { current_lnum, target_col_0based_before_append })
          A.nvim_feedkeys(A.nvim_replace_termcodes('a', true, false, true), 'ni', false)
        else
          local plug_mapping = (ctype == U.ctype.linewise) and '<Plug>(comment_toggle_linewise_current)' or '<Plug>(comment_toggle_blockwise_current)'
          A.nvim_feedkeys(A.nvim_replace_termcodes(plug_mapping, true, false, true), 'n', false)
        end
      end

      -- **UPDATED: Function for Insert Mode Ctrl+/ (toggles CURRENT line with sticky cursor)**
      local function custom_toggle_comment_current_insert()
        cfg = cfg or require('Comment.config'):get()
        local current_lnum, current_col_0based = unpack(A.nvim_win_get_cursor(0))
        local action_cmode

        -- --- Get necessary comment info ---
        local ctx_for_strings = {
          cmode = U.cmode.toggle,
          cmotion = U.cmotion.line,
          ctype = U.ctype.linewise,
          range = { srow = current_lnum, scol = 0, erow = current_lnum, ecol = 0 },
        }
        local lcs_raw, rcs_raw = U.parse_cstr(cfg, ctx_for_strings)
        if not lcs_raw then
          vim.notify('Custom Insert Toggle: Could not determine comment string.', vim.log.levels.WARN)
          return
        end
        local lcs = vim.trim(lcs_raw)
        local rcs = vim.trim(rcs_raw or '')
        local padding_bool = U.is_fn(cfg.padding)
        local padding_char = U.get_pad(padding_bool)
        local if_rcs = U.is_empty(rcs) and rcs or padding_char .. rcs
        -- Calculate lengths needed for cursor adjustment (use strchars for multibyte safety)
        local lcs_len = vim.fn.strchars(lcs)
        local padding_len = vim.fn.strchars(padding_char)
        local comment_prefix_len = lcs_len + padding_len

        -- --- Get current line content and calculate relative cursor position ---
        local current_line_content = A.nvim_buf_get_lines(0, current_lnum - 1, current_lnum, false)[1]
        if current_line_content == nil then
          vim.notify('Custom Insert Toggle: Could not get current line content.', vim.log.levels.ERROR)
          return
        end
        local indent_str = current_line_content:match '^%s*' or ''
        local indent_len = vim.fn.strchars(indent_str)
        -- Calculate cursor position relative to the start of non-whitespace content
        -- max(0, ...) ensures it's not negative if cursor is in indentation
        local relative_col = math.max(0, current_col_0based - indent_len)

        -- --- Check if the current line is commented ---
        local is_commented_func = U.is_commented(lcs, rcs, padding_bool, nil, nil) -- Full line check
        local current_is_commented = is_commented_func(current_line_content)

        -- --- Prepare context for post_hook ---
        local final_ctx = {
          cmotion = U.cmotion.line,
          ctype = U.ctype.linewise,
          range = { srow = current_lnum, scol = 0, erow = current_lnum, ecol = vim.fn.strchars(current_line_content) },
        }

        if current_is_commented then
          -- *** UNCOMMENT ACTION (IN PLACE on current line) ***
          action_cmode = U.cmode.uncomment
          final_ctx.cmode = action_cmode
          local uncommenter_func = U.uncommenter(lcs, rcs, padding_bool, nil, nil)
          local uncommented_line
          local success, result = pcall(uncommenter_func, current_line_content)
          if not success then
            vim.notify('Custom Insert Toggle: Error during uncomment: ' .. tostring(result), vim.log.levels.WARN)
            return
          end
          uncommented_line = result --[[@as string]]

          -- Replace the current line
          A.nvim_buf_set_lines(0, current_lnum - 1, current_lnum, false, { uncommented_line })

          -- Calculate new cursor column: indent + (relative_col adjusted for removed prefix)
          -- The relative position was calculated *after* the comment prefix, so subtract prefix length
          local adjusted_relative_col = math.max(0, relative_col - comment_prefix_len)
          local target_col = indent_len + adjusted_relative_col

          -- Clamp target_col to the new line length
          local new_line_len = vim.fn.strchars(uncommented_line)
          target_col = math.min(target_col, new_line_len)
          target_col = math.max(0, target_col) -- Ensure not negative

          -- Set cursor position
          A.nvim_win_set_cursor(0, { current_lnum, target_col })
        else
          -- *** COMMENT ACTION (IN PLACE on current line) ***
          action_cmode = U.cmode.comment
          final_ctx.cmode = action_cmode
          local content_after_indent = current_line_content:match '^%s*(.*)' or current_line_content
          local commented_line = indent_str .. lcs .. padding_char .. content_after_indent .. if_rcs

          -- Replace the current line
          A.nvim_buf_set_lines(0, current_lnum - 1, current_lnum, false, { commented_line })

          -- Calculate new cursor column: indent + prefix + relative_col
          local target_col = indent_len + comment_prefix_len + relative_col

          -- Clamp target_col to the new line length
          local new_line_len = vim.fn.strchars(commented_line)
          target_col = math.min(target_col, new_line_len)
          target_col = math.max(0, target_col) -- Ensure not negative

          -- Set cursor position
          A.nvim_win_set_cursor(0, { current_lnum, target_col })
        end

        -- Call post_hook if defined
        U.is_fn(cfg.post_hook, final_ctx)

        -- Stay in Insert mode
      end

      -- >>>>> SETUP <<<<<
      cfg = require('Comment').setup {
        padding = true,
        sticky = false, -- Note: This setup option primarily affects NORMAL mode ops. We handle Insert mode sticky manually.
        ignore = nil,
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        mappings = {
          basic = false,
          extra = true,
        },
        post_hook = nil,
        toggler = { line = 'gcc', block = 'gbc' },
        opleader = { line = 'gc', block = 'gb' },
        extra = { above = 'gcO', below = 'gco', eol = 'gcA' },
      }

      -- >>>>> MAPPINGS <<<<<
      local vvar = A.nvim_get_vvar

      -- Custom Normal mode toggles (gcc, gbc)
      vim.keymap.set('n', 'gcc', function()
        if vvar 'count' == 0 then
          custom_comment_toggle 'line'
        else
          A.nvim_feedkeys(A.nvim_replace_termcodes('<Plug>(comment_toggle_linewise_count)', true, false, true), 'n', false)
        end
      end, { expr = false, desc = '[Custom] Comment toggle line / count' })
      vim.keymap.set('n', 'gbc', function()
        if vvar 'count' == 0 then
          custom_comment_toggle 'block'
        else
          A.nvim_feedkeys(A.nvim_replace_termcodes('<Plug>(comment_toggle_blockwise_count)', true, false, true), 'n', false)
        end
      end, { expr = false, desc = '[Custom] Comment toggle block / count' })

      -- Ctrl+/ Normal Mode Toggle
      vim.keymap.set('n', '<C-/>', function()
        if vvar 'count' == 0 then
          custom_comment_toggle 'line'
        else
          A.nvim_feedkeys(A.nvim_replace_termcodes('<Plug>(comment_toggle_linewise_count)', true, false, true), 'n', false)
        end
      end, { expr = false, desc = '[Custom] Comment toggle line / count (Ctrl+/)' })

      -- Operator pending mappings (gc, gb)
      vim.keymap.set('n', 'gc', '<Plug>(comment_toggle_linewise)', { desc = 'Comment toggle linewise operator' })
      vim.keymap.set('n', 'gb', '<Plug>(comment_toggle_blockwise)', { desc = 'Comment toggle blockwise operator' })

      -- Visual mode mappings (gc, gb, C-/)
      vim.keymap.set('x', 'gc', '<Plug>(comment_toggle_linewise_visual)', { desc = 'Comment toggle linewise visual' })
      vim.keymap.set('x', 'gb', '<Plug>(comment_toggle_blockwise_visual)', { desc = 'Comment toggle blockwise visual' })
      vim.keymap.set('x', '<C-/>', '<Plug>(comment_toggle_linewise_visual)', { desc = 'Comment toggle linewise visual (Ctrl+/)' })

      -- ** Ctrl+/ Insert Mode Toggle (Uses the sticky cursor logic) **
      vim.keymap.set(
        'i',
        '<C-/>',
        custom_toggle_comment_current_insert,
        { noremap = true, silent = true, desc = '[Custom] Toggle comment current line (Insert Ctrl+/)' }
      )

      -- Explicit extra mappings (optional)
      -- ...
      -- >>>>> END OF MAPPINGS <<<<<
    end, -- end config function
  },
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      direction = 'float',
      -- open_mapping = [[<c-\>]], -- REMOVED or commented out
      -- Explicitly set inside the mappings
      size = function(term)
        if term.direction == 'horizontal' then
          return math.floor(vim.o.lines * 0.25)
        elseif term.direction == 'vertical' then
          return math.floor(vim.o.columns * 0.4)
        end
        return 15
      end,
      auto_scroll = true,
      shell = vim.o.shell,
      float_opts = {
        border = 'none',
        width = vim.o.columns,
        height = function()
          return math.max(1, vim.o.lines - 2)
        end,
        row = 0,
        col = 0,
      },
    },
  },
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    require('neo-tree.command').execute { action = 'show' }
  end,
})

-- Noob mappings
pcall(require, 'custom.mappings')
pcall(require, 'custom.commands')
require 'custom.black-magics.comments-remover'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
