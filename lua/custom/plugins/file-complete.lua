return {
  dir = vim.fn.stdpath 'config' .. '/plugins/file-complete.nvim',
  name = 'file-complete.nvim',
  main = 'file_complete',
  event = 'InsertEnter',
  dependencies = {
    'hrsh7th/nvim-cmp',
  },
  opts = {
    include = {
      '~/prompts',
      '~/coding/razor',
    },
    exclude = {
      '**/.git/**',
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/target/**',
      '**/.cache/**',
      '~/.local/**',
      '~/.npm/**',
      '~/.cargo/**',
    },
    filetypes = { 'markdown', 'text' },
    extensions = { 'md', 'txt' },
    max_items = 7,
    fff_search_limit = 128,
    fallback_scan_limit = 20000,
    fallback_cache_ttl_ms = 30000,
  },
}
