local config = require 'file_complete.config'

local M = {}

local uv = vim.uv or vim.loop
local fallback_cache = {}

local function normalize_path(path)
  if not path or path == '' then
    return nil
  end

  local absolute = vim.fn.fnamemodify(vim.fn.expand(path), ':p')
  absolute = absolute:gsub('/+$', '')
  if absolute == '' then
    return nil
  end
  return absolute
end

local function is_directory(path)
  local stat = path and uv.fs_stat(path)
  return stat and stat.type == 'directory'
end

local function is_inside(parent, child)
  if not parent or not child then
    return false
  end
  return child == parent or vim.startswith(child, parent .. '/')
end

local function home_dir()
  return normalize_path '~'
end

local function relative_to(parent, child)
  if child == parent then
    return ''
  end
  return child:sub(#parent + 2)
end

local function home_path(home, absolute)
  if absolute == home then
    return '~'
  end
  return '~/' .. relative_to(home, absolute)
end

local function compile_excludes(options)
  local compiled = {
    prefixes = {},
    segments = {},
  }

  for _, pattern in ipairs(options.exclude or {}) do
    local absolute = vim.startswith(pattern, '~') or vim.startswith(pattern, '/')

    if absolute then
      local prefix = pattern:match '^[^*]+'
      prefix = prefix and prefix:gsub('/+$', '')
      prefix = normalize_path(prefix)
      if prefix then
        compiled.prefixes[#compiled.prefixes + 1] = prefix
      end
    else
      local segment = pattern:match '^%*%*/([^/]+)/%*%*$'
      if segment then
        compiled.segments[#compiled.segments + 1] = segment
      end
    end
  end

  return compiled
end

local function is_excluded(compiled, absolute, relative)
  for _, prefix in ipairs(compiled.prefixes) do
    if is_inside(prefix, absolute) then
      return true
    end
  end

  local relative_with_edges = '/' .. relative .. '/'
  for _, segment in ipairs(compiled.segments) do
    if relative_with_edges:find('/' .. segment .. '/', 1, true) then
      return true
    end
  end

  return false
end

local function roots(options)
  local home = home_dir()
  local result = {}
  local seen = {}

  local function add_root(path, kind)
    local normalized = normalize_path(path)
    if not normalized or seen[normalized] or not is_directory(normalized) then
      return
    end

    if not is_inside(home, normalized) then
      return
    end

    seen[normalized] = true
    result[#result + 1] = {
      path = normalized,
      kind = kind,
      index = #result + 1,
    }
  end

  add_root(uv.cwd(), 'cwd')

  for _, path in ipairs(options.include or {}) do
    add_root(path, 'home')
  end

  return home, result
end

local function build_item(home, root, relative, score)
  local absolute = root.path .. '/' .. relative
  local insert_text
  local label

  if root.kind == 'cwd' then
    insert_text = '@' .. relative
    label = relative
  else
    label = home_path(home, absolute)
    insert_text = '@' .. label
  end

  return {
    absolute = absolute,
    display = label,
    insert_text = insert_text,
    score = score or 0,
    source = root.kind,
    sort_key = string.format('%03d:%s', root.index, label),
  }
end

local function match_score(query, candidate)
  if query == '' then
    return 1
  end

  local needle = string.lower(query)
  local haystack = string.lower(candidate)
  local start = haystack:find(needle, 1, true)

  if start then
    return 100000 - (start * 100) - #candidate
  end

  local needle_index = 1
  for index = 1, #haystack do
    if haystack:sub(index, index) == needle:sub(needle_index, needle_index) then
      needle_index = needle_index + 1
      if needle_index > #needle then
        return 50000 - index - #candidate
      end
    end
  end

  return nil
end

local function cache_key(root, options)
  return root.path .. '\n' .. table.concat(options.exclude or {}, '\n')
end

local function scan_root(home, root, excludes, options)
  local items = {}
  local scanned = 0

  local function walk(directory)
    if scanned >= options.fallback_scan_limit then
      return
    end

    local handle = uv.fs_scandir(directory)
    if not handle then
      return
    end

    while scanned < options.fallback_scan_limit do
      local name, entry_type = uv.fs_scandir_next(handle)
      if not name then
        break
      end

      local absolute = directory .. '/' .. name
      local relative = relative_to(root.path, absolute)

      if entry_type == 'directory' then
        if not is_excluded(excludes, absolute, relative) then
          walk(absolute)
        end
      elseif entry_type == 'file' then
        scanned = scanned + 1
        if not is_excluded(excludes, absolute, relative) then
          items[#items + 1] = build_item(home, root, relative)
        end
      end
    end
  end

  walk(root.path)
  return items
end

local function cached_root_items(home, root, excludes, options)
  local key = cache_key(root, options)
  local cached = fallback_cache[key]
  local now = uv.now()

  if cached and now - cached.time < options.fallback_cache_ttl_ms then
    return cached.items
  end

  local items = scan_root(home, root, excludes, options)
  fallback_cache[key] = {
    items = items,
    time = now,
  }

  return items
end

local function current_fff_base_path()
  local ok, rust = pcall(require, 'fff.rust')
  if not ok or not rust.get_base_path then
    return nil
  end

  local base_ok, base_path = pcall(rust.get_base_path)
  if not base_ok or not base_path then
    return nil
  end

  return normalize_path(base_path)
end

local function ensure_fff(root)
  local ok, fff = pcall(require, 'fff')
  if not ok then
    return nil, false
  end

  local conf_ok, conf = pcall(require, 'fff.conf')
  if conf_ok then
    conf.get().base_path = root.path
  end

  local current_base = current_fff_base_path()
  if current_base and current_base ~= root.path then
    pcall(fff.change_indexing_directory, root.path)
    return fff, false
  end

  return fff, true
end

local function is_fff_scanning()
  local ok, fuzzy = pcall(require, 'fff.fuzzy')
  if not ok or not fuzzy.is_scanning then
    return false
  end

  local scan_ok, scanning = pcall(fuzzy.is_scanning)
  return scan_ok and scanning == true
end

local function fff_search_root(home, root, excludes, query, options)
  local fff, base_ready = ensure_fff(root)
  if not fff or not base_ready then
    return nil
  end

  local ok, results = pcall(fff.search, query, options.fff_search_limit)
  if not ok or not results then
    return nil
  end

  if #results == 0 and is_fff_scanning() then
    return nil
  end

  local items = {}
  for rank, result in ipairs(results) do
    local absolute = root.path .. '/' .. result.relative_path
    if is_inside(root.path, absolute) then
      local relative = relative_to(root.path, absolute)
      if not is_excluded(excludes, absolute, relative) then
        items[#items + 1] = build_item(home, root, relative, 100000 - rank)
      end
    end
  end

  if #items == 0 then
    return nil
  end

  return items
end

local function fallback_search_root(home, root, excludes, query, options)
  local items = {}

  for _, item in ipairs(cached_root_items(home, root, excludes, options)) do
    local score = match_score(query, item.display)
    if score then
      local copy = vim.deepcopy(item)
      copy.score = score
      items[#items + 1] = copy
    end
  end

  return items
end

local function merge_results(root_results, max_items)
  local by_absolute = {}

  for _, items in ipairs(root_results) do
    for _, item in ipairs(items) do
      local existing = by_absolute[item.absolute]
      if not existing or item.sort_key < existing.sort_key then
        by_absolute[item.absolute] = item
      elseif item.score > existing.score then
        existing.score = item.score
      end
    end
  end

  local items = {}
  for _, item in pairs(by_absolute) do
    items[#items + 1] = item
  end

  table.sort(items, function(left, right)
    if left.score == right.score then
      return left.sort_key < right.sort_key
    end
    return left.score > right.score
  end)

  for index = #items, max_items + 1, -1 do
    items[index] = nil
  end

  return items
end

function M.prime()
  local options = config.get()
  local _, scan_roots = roots(options)
  local root = scan_roots[1]
  if not root then
    return
  end

  local fff, ready = ensure_fff(root)
  if fff and ready then
    pcall(fff.search, '', 1)
  end
end

function M.search(query, callback)
  local options = config.get()
  local home, scan_roots = roots(options)

  if #scan_roots == 0 then
    callback({})
    return
  end

  query = query or ''

  local excludes = compile_excludes(options)
  local root_results = {}

  for _, root in ipairs(scan_roots) do
    local items
    if root.kind == 'cwd' then
      items = fff_search_root(home, root, excludes, query, options)
    end

    if not items then
      items = fallback_search_root(home, root, excludes, query, options)
    end

    root_results[#root_results + 1] = items
  end

  callback(merge_results(root_results, options.max_items))
end

function M.clear_cache()
  fallback_cache = {}

  local ok, fff = pcall(require, 'fff')
  if ok then
    pcall(fff.scan_files)
  end
end

return M
