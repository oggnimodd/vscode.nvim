local cmp = require 'cmp'
local config = require 'file_complete.config'
local scanner = require 'file_complete.scanner'

local source = {}

local function current_query(params)
  return params.context.cursor_before_line:match('@([^%s]*)$')
end

local function completion_items(items)
  local completion_items = {}
  for index, item in ipairs(items) do
    completion_items[#completion_items + 1] = {
      label = item.display,
      filterText = '@' .. item.display,
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
  return { '@' }
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
    callback {
      isIncomplete = true,
      items = completion_items(items),
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
