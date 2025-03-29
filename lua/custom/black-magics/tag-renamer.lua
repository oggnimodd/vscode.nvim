local M = {}

local ts_utils = require 'nvim-treesitter.ts_utils'

-- Recursively climb up the AST from the node under cursor
-- until we find a start_tag / jsx_opening_element.
-- Now it also handles being inside the element or on a closing tag.
local function get_closest_start_tag_node(node)
  if not node then
    return nil
  end

  local t = node:type()

  if t == 'start_tag' or t == 'jsx_opening_element' then
    return node
  elseif t == 'element' or t == 'fragment' then -- Added fragment for JSX <>...</>
    -- Prefer the first child if it's a tag, handles cursor inside element
    local first_child = node:child(0)
    if first_child then
      local fct = first_child:type()
      if fct == 'start_tag' or fct == 'jsx_opening_element' then
        return first_child
      end
    end
    -- Fallback if first child isn't the tag (e.g. comment before tag)
    for child in node:iter_children() do
      local ct = child:type()
      if ct == 'start_tag' or ct == 'jsx_opening_element' then
        return child
      end
    end
  elseif t == 'end_tag' or t == 'jsx_closing_element' then
    local parent = node:parent()
    if parent and (parent:type() == 'element' or parent:type() == 'fragment') then
      -- Find the start tag within the parent element
      for child in parent:iter_children() do
        local ct = child:type()
        if ct == 'start_tag' or ct == 'jsx_opening_element' then
          return child
        end
      end
    end
  end

  -- Climb up otherwise
  return get_closest_start_tag_node(node:parent())
end

-- Extract the tag_name child node from a start_tag, end_tag, jsx_opening_element, or jsx_closing_element.
local function get_tag_name_node(tag_node)
  if not tag_node then
    return nil
  end
  local expected_type = tag_node:type()
  for child in tag_node:iter_children() do
    local t = child:type()
    -- Match tag_name for HTML, jsx_identifier for JSX opening/closing elements
    if t == 'tag_name' then
      return child
    elseif
      (expected_type == 'jsx_opening_element' or expected_type == 'jsx_closing_element')
      and (t == 'jsx_identifier' or t == 'jsx_namespace_name' or t == 'jsx_member_expression')
    then
      -- Handle basic <Component>, <Namespace.Component>, <obj.Component>
      return child
    end
  end
  return nil
end

-- Find the closing tag node from an element node
local function get_closing_tag_node(element_node)
  if not element_node then
    return nil
  end
  -- Closing tag is often the last child, search backwards might be slightly faster
  for i = element_node:child_count() - 1, 0, -1 do
    local child = element_node:child(i)
    if child then -- Check if child exists
      local t = child:type()
      if t == 'end_tag' or t == 'jsx_closing_element' then
        return child
      end
    end
  end
  return nil
end

function M.rename_html_tag_prompt()
  local bufnr = vim.api.nvim_get_current_buf()

  -- 1) Get node at cursor
  local current_node = ts_utils.get_node_at_cursor()
  if not current_node then
    vim.notify('No Treesitter node at cursor.', vim.log.levels.WARN)
    return
  end

  -- 2) Find the corresponding start_tag / jsx_opening_element
  local start_tag_node = get_closest_start_tag_node(current_node)
  if not start_tag_node then
    vim.notify('Could not find corresponding start tag.', vim.log.levels.WARN)
    return
  end

  -- 3) Find the tag_name node within the start tag
  local start_tag_name_node = get_tag_name_node(start_tag_node)
  if not start_tag_name_node then
    vim.notify('Could not find tag name in start tag.', vim.log.levels.WARN)
    return
  end

  -- 4) Get range and text of the START tag name
  local sr1, sc1, er1, ec1 = start_tag_name_node:range() -- 0-based row/col
  local old_name = vim.api.nvim_buf_get_text(bufnr, sr1, sc1, er1, ec1, {})[1] or ''
  if old_name == '' then
    vim.notify('Could not extract old tag name.', vim.log.levels.WARN)
    return
  end

  -- 4.5) Try to find the CLOSING tag and its name node BEFORE prompting/editing
  local closing_tag_name_range = nil -- Will store {sr, sc, er, ec}
  local parent_element = start_tag_node:parent()

  -- Check if the parent is an 'element' or 'fragment' which can contain start/end tags
  if parent_element and (parent_element:type() == 'element' or parent_element:type() == 'fragment') then
    local closing_tag_node = get_closing_tag_node(parent_element)
    if closing_tag_node then
      local closing_tag_name_node = get_tag_name_node(closing_tag_node)
      if closing_tag_name_node then
        -- Store the range now, before any buffer edits
        local sr2, sc2, er2, ec2 = closing_tag_name_node:range()
        closing_tag_name_range = { sr = sr2, sc = sc2, er = er2, ec = ec2 }
      end
    end
  end

  -- 5) Prompt user for the new tag name.
  vim.ui.input({
    prompt = 'New tag name: ',
    default = old_name,
  }, function(input)
    if not input or input == '' or input == old_name then
      vim.notify('Tag rename cancelled or name unchanged.', vim.log.levels.INFO)
      return
    end

    -- Basic check for invalid characters (adjust regex as needed for stricter rules)
    -- Allows alphanumeric, -, _, : (for namespaces like <svg:rect>)
    if not input:match '^[a-zA-Z0-9%-_:]+$' and not input:match '^[a-zA-Z][a-zA-Z0-9%-_:%.]*$' then -- Allow . for JSX members
      vim.notify('Invalid tag name characters: ' .. input, vim.log.levels.ERROR)
      return
    end
    if input:match '^%d' then -- Cannot start with a number
      vim.notify('Invalid tag name: Cannot start with a number.', vim.log.levels.ERROR)
      return
    end

    -- 6) Prepare changes. Store them to apply carefully.
    -- Using nvim_buf_call ensures ranges are relative to the state *before* changes.
    local text_changes = {}

    -- Add start tag change
    table.insert(text_changes, { sr1, sc1, er1, ec1, { input } })

    -- Add closing tag change if its range was found
    if closing_tag_name_range then
      table.insert(text_changes, {
        closing_tag_name_range.sr,
        closing_tag_name_range.sc,
        closing_tag_name_range.er,
        closing_tag_name_range.ec,
        { input },
      })
    end

    -- 7) Apply changes using nvim_buf_call for atomicity regarding ranges
    local success, result = pcall(vim.api.nvim_buf_call, bufnr, function()
      -- Apply changes in reverse order of lines/columns to avoid shifting subsequent ranges incorrectly
      -- within this atomic operation.
      table.sort(text_changes, function(a, b)
        if a[1] ~= b[1] then
          return a[1] > b[1] -- Sort by start row DESC
        else
          return a[2] > b[2] -- Then by start col DESC
        end
      end)

      for _, change in ipairs(text_changes) do
        local sr, sc, er, ec, text_lines = unpack(change)
        vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, text_lines)
      end
    end)

    if not success then
      vim.notify('Error applying changes: ' .. tostring(result), vim.log.levels.ERROR)
    else
      vim.notify(string.format('Renamed <%s> to <%s>.', old_name, input), vim.log.levels.INFO)
    end
  end)
end

return M
