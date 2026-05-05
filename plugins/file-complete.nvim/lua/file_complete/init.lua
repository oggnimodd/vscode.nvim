local config = require 'file_complete.config'

local M = {}

local source_id = nil

local function with_file_complete_source(cmp)
  local existing = cmp.get_config().sources or {}
  local rest = {}

  for _, source in ipairs(existing) do
    if source.name ~= 'file_complete' then
      rest[#rest + 1] = source
    end
  end

  return cmp.config.sources({
    {
      name = 'file_complete',
      keyword_length = 0,
      priority = 1000,
    },
  }, rest)
end

function M.setup(opts)
  config.setup(opts)

  local ok, cmp = pcall(require, 'cmp')
  if not ok then
    return
  end

  if not source_id then
    source_id = cmp.register_source('file_complete', require('file_complete.source').new())
  end

  require('file_complete.scanner').prime()

  cmp.setup {
    sources = with_file_complete_source(cmp),
  }
end

function M.clear_cache()
  require('file_complete.scanner').clear_cache()
end

return M
