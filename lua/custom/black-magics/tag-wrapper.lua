-- ~/.config/nvim/lua/custom/black-magics/tag-wrapper.lua

local M = {}

local ts_utils = require 'nvim-treesitter.ts_utils'
local api = vim.api
local fn = vim.fn

-- Helper: print_node_info (Keep for debugging if needed)
local function print_node_info(node, label)
  if not node then
    print(label .. ': nil node')
    return
  end
  local node_type_ok, node_type = pcall(node.type, node)
  local range_ok, sr, sc, er, ec = pcall(node.range, node)
  local text_ok, text = pcall(vim.treesitter.get_node_text, node, 0)
  local named_ok, is_named = pcall(node.is_named, node)
  local type_str = node_type_ok and node_type or 'ERR_TYPE'
  local range_str = range_ok and string.format('[%d:%d -> %d:%d]', sr, sc, er, ec) or 'ERR_RANGE'
  local text_str = text_ok and (string.len(text) > 60 and (string.sub(text, 1, 57) .. '...') or text) or 'ERR_TEXT'
  text_str = text_str:gsub('\n', '\\n'):gsub('\r', '\\r')
  local named_str = named_ok and tostring(is_named) or 'ERR_NAMED'
  print(string.format('%s: Type=%s, Range=%s, Named=%s, Text="%s"', label, type_str, range_str, named_str, text_str))
end

-- Helper: get_indent_str (Consistent)
local function get_indent_str(bufnr, level)
  if level <= 0 then
    return ''
  end
  local use_tabs = not vim.bo[bufnr].expandtab
  local shiftwidth = vim.bo[bufnr].shiftwidth
  if use_tabs then
    local tabstop = vim.bo[bufnr].tabstop
    local num_tabs = math.floor(level / tabstop)
    local num_spaces = level % tabstop
    return string.rep('\t', num_tabs) .. string.rep(' ', num_spaces)
  else
    return string.rep(' ', level * shiftwidth)
  end
end

-- Helper: get_indent_level (Consistent)
local function get_indent_level(line_str, bufnr)
  local indent_str = line_str:match '^%s*'
  if not indent_str then
    return 0
  end
  local tabstop = vim.bo[bufnr].tabstop
  local level = 0
  for i = 1, #indent_str do
    if indent_str:sub(i, i) == '\t' then
      level = level + tabstop - (level % tabstop)
    else
      level = level + 1
    end
  end
  return level
end

-- *** FINAL REVISION: Find IMMEDIATE Element Containing or EQUAL TO Start Node ***
local function get_immediate_containing_element(start_node)
  -- print("--- get_immediate_containing_element ---") -- Keep commented unless debugging
  if not start_node then
    return nil
  end
  -- print_node_info(start_node, "  Starting search from") -- Keep commented unless debugging

  local current = start_node
  local max_climbs = 15
  local climbs = 0

  while current and climbs < max_climbs do
    climbs = climbs + 1
    -- print_node_info(current, "  Checking current node") -- Keep commented unless debugging

    local node_type_ok, node_type = pcall(current.type, current)
    if node_type_ok then
      if node_type == 'element' or node_type == 'jsx_element' or node_type == 'fragment' then
        -- print("  Current node is an element type, returning current.") -- Keep commented unless debugging
        return current
      end
      if node_type == 'program' or node_type == 'ERROR' or node_type == 'chunk' then
        return nil
      end
      -- print("  Current node type '" .. node_type .. "' is not element, getting parent.") -- Keep commented unless debugging
    else
      return nil
    end

    local parent_ok, parent = pcall(current.parent, current)
    if not parent_ok or not parent then
      return nil
    end
    current = parent
  end
  return nil
end

-- Normal Mode Handler (Uses final helper)
local function handle_normal_wrap_only(bufnr)
  -- print("--- handle_normal_wrap_only ---") -- Keep commented unless debugging
  local node_at_cursor
  if ts_utils.get_deepest_node_at_pos then
    local cursor_pos = api.nvim_win_get_cursor(0)
    node_at_cursor = ts_utils.get_deepest_node_at_pos(bufnr, cursor_pos[1], cursor_pos[2])
  else
    vim.notify_once('ts_utils.get_deepest_node_at_pos not found, using fallback.', vim.log.levels.WARN)
    node_at_cursor = ts_utils.get_node_at_cursor()
  end
  if not node_at_cursor then
    node_at_cursor = ts_utils.get_named_node_at_cursor()
  end
  if not node_at_cursor then
    vim.notify('No Treesitter node found at cursor.', vim.log.levels.WARN)
    return
  end
  -- print_node_info(node_at_cursor, "  Node found at cursor") -- Keep commented unless debugging

  local element_node = get_immediate_containing_element(node_at_cursor)
  if not element_node then
    vim.notify('Could not find immediate surrounding tag element to wrap.', vim.log.levels.WARN)
    return
  end
  -- print_node_info(element_node, "  Element node found to wrap") -- Keep commented unless debugging

  local range_ok, sr, _, er, _ = pcall(element_node.range, element_node)
  if not range_ok then
    vim.notify('Could not get element range.', vim.log.levels.ERROR)
    return
  end

  local lines_ok, original_lines = pcall(api.nvim_buf_get_lines, bufnr, sr, er + 1, false)
  if not lines_ok or #original_lines == 0 then
    vim.notify('Could not get element content.', vim.log.levels.ERROR)
    return
  end

  local base_indent_level = get_indent_level(original_lines[1], bufnr)
  local base_indent_str = get_indent_str(bufnr, base_indent_level)
  local sw = vim.bo[bufnr].shiftwidth
  local shift_indent_str = get_indent_str(bufnr, sw)

  vim.ui.input({ prompt = 'Wrap element with tag: ' }, function(input_tag)
    if not input_tag or input_tag == '' then
      vim.notify('Wrap cancelled.', vim.log.levels.INFO)
      return
    end
    if not input_tag:match '^[a-zA-Z_:][a-zA-Z0-9%-_:.]*$' then
      vim.notify('Invalid tag name format...', vim.log.levels.ERROR)
      return
    end

    local wrapped_lines = {}
    table.insert(wrapped_lines, base_indent_str .. '<' .. input_tag .. '>')
    for _, line in ipairs(original_lines) do
      table.insert(wrapped_lines, shift_indent_str .. line)
    end
    table.insert(wrapped_lines, base_indent_str .. '</' .. input_tag .. '>')

    local replace_ok, err = pcall(api.nvim_buf_set_lines, bufnr, sr, er + 1, false, wrapped_lines)
    if replace_ok then
      vim.notify('Wrapped element in <' .. input_tag .. '>.', vim.log.levels.INFO)
      local format_start_line = sr + 1
      local format_end_line = sr + #wrapped_lines
      pcall(api.nvim_buf_call, bufnr, function()
        vim.cmd(format_start_line .. ',' .. format_end_line .. 'normal! ==')
      end)
    else
      vim.notify('Error applying wrap: ' .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

-- Main entry function - NORMAL MODE ONLY
function M.wrap_in_tag_prompt()
  local current_mode = fn.mode(1)
  local bufnr = api.nvim_get_current_buf()
  if current_mode == 'n' then
    handle_normal_wrap_only(bufnr)
  end
end

return M
