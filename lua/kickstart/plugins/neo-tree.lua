-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    auto_clean_after_session_restore = false,
    -- Close existing buffers on startup
    -- close_floats_on_startup = true, -- Uncomment if you want this behavior
    filesystem = {
      follow_current_file = {
        enabled = true, -- THIS ENABLES THE FEATURE
        leave_dirs_open = true, -- Keep dirs open when revealing a file (can be true or false based on preference)
        -- NOTE: There isn't a specific 'ignore' list just for following.
        --       Instead, we hide these folders from the tree view entirely.
      },
      filtered_items = {
        visible = false, -- Set to true to see hidden files by default
        hide_dotfiles = false, -- If true, hides files/dirs starting with '.'
        hide_gitignored = false, -- RECOMMENDED: Hides files listed in .gitignore
        hide_hidden = true, -- Hides files with the 'hidden' attribute (Windows)
        hide_by_name = {
          -- Folders you want hidden FROM THE TREE VIEW (and thus ignored by follow_current_file)
          'node_modules',
          '.git', -- Already commonly ignored by hide_dotfiles or hide_gitignored
          -- Add your venv folder name here if it's consistent
          -- Often just 'venv' or '.venv'
          'venv',
          '.venv',
          '__pycache__',
          -- Add any other folders you want ignored
          'build',
          'dist',
          'target', -- For Rust projects
          '.DS_Store', -- macOS specific
          'thumbs.db', -- Windows specific
        },
        hide_by_pattern = {
          -- Example: Hide lua cache files
          -- '*.lua.vim',
        },
        never_show = { -- Items listed here will *never* show up in the tree
          -- You can be more aggressive here if needed
          '.DS_Store',
          'thumbs.db',
        },
        never_show_by_pattern = { -- Same as hide_by_pattern, but stronger
          -- '.*/node_modules/.*', -- Could potentially use this, but hide_by_name is usually simpler
        },
      },
      hijack_netrw_behavior = 'open_current',
      window = {
        width = 20, -- Slightly wider maybe? Adjust as needed.
        mappings = {
          ['\\'] = 'close_window',
          ['<C-b>'] = 'close_window',
          -- You might want a mapping to toggle hidden files if you use hide_dotfiles=true
          ['H'] = 'toggle_hidden', -- Example mapping
          ['g?'] = 'show_help', -- Show help popup
        },
      },
    },
    -- You might want to configure other sources like buffers or git_status
    -- sources = { "filesystem", "buffers", "git_status" },
    -- source_selector = { ... }
  },
}
