local cmp = require 'cmp'
local config = require 'file_complete.config'
local scanner = require 'file_complete.scanner'

local source = {}

local function current_query(params)
  return params.context.cursor_before_line:match('@([^%s]*)$')
end

local function trigger_characters()
  local chars = { '@', '/', '.', '-', '_', '~' }

  for code = string.byte('a'), string.byte('z') do
    chars[#chars + 1] = string.char(code)
  end

  for code = string.byte('A'), string.byte('Z') do
    chars[#chars + 1] = string.char(code)
  end

  for code = string.byte('0'), string.byte('9') do
    chars[#chars + 1] = string.char(code)
  end

  return chars
end

local function filter_text(item, query)
  local display = item.display
  local aliases = {
    '@' .. display,
  }

  if vim.startswith(display, '~/') then
    table.insert(aliases, 1, '@' .. display:sub(3))
  end

  local basename = display:match '[^/]+$'
  if basename and basename ~= display then
    table.insert(aliases, 1, '@' .. basename)
  end

  for _, include in ipairs(config.get().include or {}) do
    local include_path = vim.fn.fnamemodify(vim.fn.expand(include), ':p'):gsub('/+$', '')
    if vim.startswith(item.absolute, include_path .. '/') then
      local relative = item.absolute:sub(#include_path + 2)
      table.insert(aliases, 1, '@' .. relative)
      table.insert(aliases, 1, '@~/' .. relative)
    end
  end

  local typed = '@' .. string.lower(query or '')
  for _, alias in ipairs(aliases) do
    if vim.startswith(string.lower(alias), typed) then
      return alias
    end
  end

  for _, alias in ipairs(aliases) do
    if string.lower(alias):find(typed, 1, true) then
      return alias
    end
  end

  return aliases[1]
end

local function completion_items(items, query)
  local completion_items = {}
  for index, item in ipairs(items) do
    local word = filter_text(item, query)
    completion_items[#completion_items + 1] = {
      label = item.display,
      filterText = word,
      word = word,
      insertText = item.insert_text,
      kind = cmp.lsp.CompletionItemKind.File,
      detail = item.source == 'cwd' and 'cwd' or 'home',
      sortText = string.format('%06d:%s', index, item.sort_key),
      data = {
        path = item.absolute,
      },
    }
  end

  return completion_items
end

function source.new()
  return setmetatable({}, { __index = source })
end

function source:is_available()
  return config.is_allowed_buffer(0)
end

function source:get_debug_name()
  return 'file_complete'
end

function source:get_position_encoding_kind()
  return 'utf-8'
end

function source:get_trigger_characters()
  return trigger_characters()
end

function source:get_keyword_pattern()
  return [[\%(@\S*\)]]
end

function source:complete(params, callback)
  local query = current_query(params)
  if not query then
    callback()
    return
  end

  scanner.search(query, function(items)
    if #items == 0 and vim.startswith(query, '~/') then
      scanner.search(query:sub(3), function(fallback_items)
        callback {
          isIncomplete = true,
          items = completion_items(fallback_items, query),
        }
      end)
      return
    end

    callback {
      isIncomplete = true,
      items = completion_items(items, query),
    }
  end)
end

function source:resolve(completion_item, callback)
  if completion_item.data and completion_item.data.path then
    completion_item.documentation = {
      kind = cmp.lsp.MarkupKind.PlainText,
      value = completion_item.data.path,
    }
  end

  callback(completion_item)
end

return source
