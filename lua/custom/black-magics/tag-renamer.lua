-- ~/.config/nvim/lua/custom/black-magics/tag-renamer.lua

local M = {}

local ts_utils = require 'nvim-treesitter.ts_utils'
local parsers = require 'nvim-treesitter.parsers'

-- Debug helper function (using pcall for safety)
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
  local text_str = text_ok and text or 'ERR_TEXT'
  local named_str = named_ok and tostring(is_named) or 'ERR_NAMED'

  print(string.format('%s: Type=%s, Range=%s, Named=%s, Text="%s"', label, type_str, range_str, named_str, text_str))
end

-- get_closest_opening_tag_node function (Keep previous working version)
local function get_closest_opening_tag_node(node)
  if not node then
    return nil
  end
  local node_type_ok, node_type = pcall(node.type, node)
  if not node_type_ok then
    return nil
  end

  if node_type == 'start_tag' or node_type == 'jsx_opening_element' or node_type == 'jsx_self_closing_element' then
    return node
  end

  if node_type == 'element' or node_type == 'jsx_element' or node_type == 'fragment' then
    local iter_ok, iter = pcall(node.iter_children, node)
    if iter_ok then
      for child in iter do
        local child_type_ok, child_type = pcall(child.type, child)
        if child_type_ok and (child_type == 'start_tag' or child_type == 'jsx_opening_element' or child_type == 'jsx_self_closing_element') then
          return child
        end
      end
    end
  end

  if node_type == 'end_tag' or node_type == 'jsx_closing_element' then
    local parent_ok, parent = pcall(node.parent, node)
    if parent_ok and parent then
      local p_type_ok, parent_type = pcall(parent.type, parent)
      if p_type_ok and (parent_type == 'element' or parent_type == 'jsx_element') then
        local iter_ok, iter = pcall(parent.iter_children, parent)
        if iter_ok then
          for child in iter do
            local c_type_ok, child_type = pcall(child.type, child)
            if c_type_ok and (child_type == 'start_tag' or child_type == 'jsx_opening_element') then
              return child
            end
          end
        end
      end
    end
    local parent_fallback_ok, parent_fallback = pcall(node.parent, node)
    if parent_fallback_ok and parent_fallback then
      return get_closest_opening_tag_node(parent_fallback)
    end
  end

  local parent_ok, parent = pcall(node.parent, node)
  if parent_ok and parent then
    return get_closest_opening_tag_node(parent)
  end

  return nil
end

-- *** FINAL get_tag_name_node ***
local function get_tag_name_node(tag_node)
  if not tag_node then
    return nil
  end
  local type_ok, tag_node_type = pcall(tag_node.type, tag_node)
  if not type_ok then
    return nil
  end

  -- Strategy 1: Try field name 'name' first
  local cbfn_success, name_node_by_field = pcall(tag_node.child_by_field_name, tag_node, 'name')
  if cbfn_success and name_node_by_field then
    local name_type_ok, name_type = pcall(name_node_by_field.type, name_node_by_field)
    if name_type_ok then
      if (tag_node_type == 'start_tag' or tag_node_type == 'end_tag') and name_type == 'tag_name' then
        return name_node_by_field
      elseif tag_node_type == 'jsx_opening_element' or tag_node_type == 'jsx_closing_element' or tag_node_type == 'jsx_self_closing_element' then
        -- Accept specific JSX types OR the generic identifier seen in debug
        if name_type == 'jsx_identifier' or name_type == 'jsx_namespace_name' or name_type == 'jsx_member_expression' or name_type == 'identifier' then
          return name_node_by_field
        end
      end
    end
  end

  -- Strategy 2: Fallback to iterating ALL children
  local iter_ok, iter = pcall(tag_node.iter_children, tag_node)
  if not iter_ok then
    return nil
  end -- Bail if basic iteration fails

  local is_jsx = (tag_node_type == 'jsx_opening_element' or tag_node_type == 'jsx_closing_element' or tag_node_type == 'jsx_self_closing_element')

  for child in iter do
    local child_type_ok, child_type = pcall(child.type, child)
    if child_type_ok then
      if tag_node_type == 'start_tag' or tag_node_type == 'end_tag' then
        if child_type == 'tag_name' then
          return child
        end
      elseif is_jsx then
        -- *** FIX: Accept 'identifier' for JSX based on debug output ***
        if child_type == 'jsx_identifier' or child_type == 'jsx_namespace_name' or child_type == 'jsx_member_expression' or child_type == 'identifier' then
          return child
        end
      end
    end
  end

  return nil
end

-- get_closing_tag_node function (Keep previous working version)
local function get_closing_tag_node(element_node)
  if not element_node then
    return nil
  end
  local type_ok, element_type = pcall(element_node.type, element_node)
  if not type_ok or (element_type ~= 'element' and element_type ~= 'jsx_element') then
    return nil
  end
  local count_ok, count = pcall(element_node.child_count, element_node)
  if not count_ok then
    return nil
  end
  for i = count - 1, 0, -1 do
    local child_ok, child = pcall(element_node.child, element_node, i)
    if child_ok and child then
      local child_type_ok, child_type = pcall(child.type, child)
      if child_type_ok and (child_type == 'end_tag' or child_type == 'jsx_closing_element') then
        return child
      end
    end
  end
  return nil
end

-- rename_tag_prompt function (Main logic - keep previous working version)
function M.rename_tag_prompt()
  local bufnr = vim.api.nvim_get_current_buf()
  local parser = parsers.get_parser(bufnr)
  if not parser then
    vim.notify('No active Treesitter parser...', vim.log.levels.WARN)
    return
  end
  local current_node = ts_utils.get_node_at_cursor() or ts_utils.get_named_node_at_cursor()
  if not current_node then
    vim.notify('No Treesitter node found at cursor.', vim.log.levels.WARN)
    return
  end

  local opening_tag_node = get_closest_opening_tag_node(current_node)
  if not opening_tag_node then
    vim.notify('Could not find corresponding opening/self-closing tag.', vim.log.levels.WARN)
    return
  end

  local opening_tag_name_node = get_tag_name_node(opening_tag_node)
  if not opening_tag_name_node then
    vim.notify('Could not find tag name node within the opening/self-closing tag.', vim.log.levels.WARN)
    -- You could uncomment this to see which tag failed, if needed:
    -- print_node_info(opening_tag_node, "Tag where name search failed")
    return
  end

  local range_ok, sr1, sc1, er1, ec1 = pcall(opening_tag_name_node.range, opening_tag_name_node)
  if not range_ok then
    vim.notify('Failed to get range of tag name node.', vim.log.levels.ERROR)
    return
  end
  local old_name = vim.api.nvim_buf_get_text(bufnr, sr1, sc1, er1, ec1, {})[1] or ''
  if old_name == '' then
    vim.notify('Could not extract old tag name.', vim.log.levels.WARN)
    return
  end

  local closing_tag_name_range = nil
  local parent_ok, parent_element = pcall(opening_tag_node.parent, opening_tag_node)
  if parent_ok and parent_element then
    local closing_tag_node = get_closing_tag_node(parent_element)
    if closing_tag_node then
      local closing_tag_name_node = get_tag_name_node(closing_tag_node) -- Use final func here too
      if closing_tag_name_node then
        local c_range_ok, sr2, sc2, er2, ec2 = pcall(closing_tag_name_node.range, closing_tag_name_node)
        if c_range_ok then
          closing_tag_name_range = { sr = sr2, sc = sc2, er = er2, ec = ec2 }
        end
      end
    end
  end

  vim.ui.input({ prompt = 'New tag name: ', default = old_name }, function(input)
    if not input or input == '' or input == old_name then
      vim.notify('Tag rename cancelled...', vim.log.levels.INFO)
      return
    end
    if not input:match '^[a-zA-Z_:][a-zA-Z0-9%-_:.]*$' then
      vim.notify('Invalid tag name format...', vim.log.levels.ERROR)
      return
    end
    local text_changes = {}
    table.insert(text_changes, { sr1, sc1, er1, ec1, { input } })
    if closing_tag_name_range then
      local old_closing_name = vim.api.nvim_buf_get_text(
        bufnr,
        closing_tag_name_range.sr,
        closing_tag_name_range.sc,
        closing_tag_name_range.er,
        closing_tag_name_range.ec,
        {}
      )[1] or ''
      if old_closing_name == old_name then
        table.insert(text_changes, { closing_tag_name_range.sr, closing_tag_name_range.sc, closing_tag_name_range.er, closing_tag_name_range.ec, { input } })
      else
        vim.notify(string.format("Warning: Closing tag name '%s' mismatch...", old_closing_name, old_name), vim.log.levels.WARN)
      end
    end
    local apply_success, result = pcall(vim.api.nvim_buf_call, bufnr, function()
      table.sort(text_changes, function(a, b)
        if a[1] ~= b[1] then
          return a[1] > b[1]
        else
          return a[2] > b[2]
        end
      end)
      for _, change in ipairs(text_changes) do
        vim.api.nvim_buf_set_text(bufnr, change[1], change[2], change[3], change[4], change[5])
      end
    end)
    if not apply_success then
      vim.notify('Error applying changes: ' .. tostring(result), vim.log.levels.ERROR)
    else
      local msg = string.format('Renamed <%s> to <%s>', old_name, input)
      local type_ok, opening_tag_type = pcall(opening_tag_node.type, opening_tag_node)
      local text_ok, node_text = pcall(vim.treesitter.get_node_text, opening_tag_node, bufnr)
      local is_self_closing = type_ok and opening_tag_type == 'jsx_self_closing_element'
        or (type_ok and opening_tag_type == 'start_tag' and text_ok and node_text:match '%/>$')
      if #text_changes == 2 then
        msg = msg .. ' (including closing tag).'
      elseif is_self_closing then
        msg = msg .. ' (self-closing tag).'
      elseif closing_tag_name_range and #text_changes == 1 then
        msg = msg .. ' (opening tag only - closing tag name mismatch).'
      else
        msg = msg .. ' (opening tag only).'
      end
      vim.notify(msg, vim.log.levels.INFO)
    end
  end)
end

return M
