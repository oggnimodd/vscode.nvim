local M = {}

M.defaults = {
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
    '**/_core/**',
    '**/themes/**',
    '~/coding/razor/dataset/**',
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
}

M.options = vim.deepcopy(M.defaults)

local function list_to_set(values)
  local set = {}
  for _, value in ipairs(values or {}) do
    set[string.lower(value)] = true
  end
  return set
end

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts)

  if not M.options.include or vim.tbl_isempty(M.options.include) then
    M.options.include = vim.deepcopy(M.defaults.include)
  end

  M.options.filetype_set = list_to_set(M.options.filetypes)
  M.options.extension_set = list_to_set(M.options.extensions)
end

function M.get()
  return M.options
end

function M.is_allowed_buffer(bufnr)
  bufnr = bufnr or 0
  local options = M.get()
  local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

  if options.filetype_set[string.lower(filetype or '')] then
    return true
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  local extension = vim.fn.fnamemodify(name, ':e')
  return options.extension_set[string.lower(extension or '')] == true
end

M.setup()

return M
