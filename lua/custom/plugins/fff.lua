local uv = vim.uv or vim.loop

local function binary_exists(download)
  local path = download.get_binary_path()
  local stat = uv.fs_stat(path)
  return stat and stat.type == 'file'
end

return {
  dir = '/home/orenji/coding/fff',
  name = 'fff.nvim',
  build = function()
    local download = require 'fff.download'
    if not binary_exists(download) then
      download.download_or_build_binary()
    end
  end,
  lazy = false,
  opts = {
    base_path = vim.fn.getcwd(),
    lazy_sync = true,
    max_results = 128,
    debug = {
      enabled = false,
      show_scores = false,
    },
    logging = {
      enabled = false,
    },
  },
}
