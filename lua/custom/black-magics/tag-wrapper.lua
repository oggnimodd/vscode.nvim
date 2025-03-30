-- ~/.config/nvim/lua/custom/black-magics/tag-wrapper.lua

local M = {}

-- Attempt to load the required modules
local ts_utils_ok, ts_utils = pcall(require, 'nvim-treesitter.ts_utils')
local parsers_ok, parsers = pcall(require, 'nvim-treesitter.parsers')
local api = vim.api

-- Check if modules loaded and the ESSENTIAL function exists
-- We ONLY check for get_node_at_cursor now, as get_named_node_at_cursor is missing for you
if not ts_utils_ok or not parsers_ok or not ts_utils or not ts_utils.get_node_at_cursor then
  local msg = 'ERROR: Tag Wrapper failed to load dependencies.\n'
  if not ts_utils_ok then
    msg = msg .. "- Could not load 'nvim-treesitter.ts_utils'. Is nvim-treesitter installed and updated?\n"
  elseif not ts_utils then
    msg = msg .. "- 'nvim-treesitter.ts_utils' loaded as nil.\n"
  else
    -- Only check for the one we will definitely use
    if not ts_utils.get_node_at_cursor then
      msg = msg .. "- Function 'get_node_at_cursor' is missing from ts_utils.\n"
    end
  end
  if not parsers_ok then
    msg = msg .. "- Could not load 'nvim-treesitter.parsers'. Is nvim-treesitter installed?\n"
  end
  vim.notify(msg, vim.log.levels.ERROR, { title = 'Tag Wrapper Init Error' })
  -- Optionally print available functions for deep debugging:
  -- if ts_utils then print("Available in ts_utils:", vim.inspect(ts_utils)) end
  return M -- Return the empty module table so Neovim doesn't crash further
end

-- Debug helper function (optional, but useful)
local function print_node_info(node, label)
  if not node then
    print(label .. ': nil node')
    return
  end
  -- Use pcall for safety when accessing node properties
  local node_type_ok, node_type = pcall(node.type, node)
  local range_ok, sr, sc, er, ec = pcall(node.range, node)
  local text_ok, text = pcall(vim.treesitter.get_node_text, node, 0) -- Assuming vim.treesitter is available
  local named_ok, is_named = pcall(node.is_named, node)

  local type_str = node_type_ok and node_type or 'ERR_TYPE'
  local range_str = range_ok and string.format('[%d:%d -> %d:%d]', sr, sc, er, ec) or 'ERR_RANGE'
  local text_str = text_ok and text or 'ERR_TEXT'
  local named_str = named_ok and tostring(is_named) or 'ERR_NAMED'

  print(string.format('%s: Type=%s, Range=%s, Named=%s, Text="%s"', label, type_str, range_str, named_str, text_str))
end

-- Find the innermost element/jsx_element/fragment node containing the given node
local function get_closest_containing_element_node(node)
  local current = node
  while current do
    -- Use pcall for safety
    local type_ok, node_type = pcall(current.type, current)
    if type_ok then
      -- Add any other element-like container types your parsers might use
      if
        node_type == 'element'
        or node_type == 'jsx_element'
        or node_type == 'jsx_self_closing_element' -- Treat self-closing as an element to wrap
        or node_type == 'fragment' -- Handle <>...</> fragments
      then
        return current
      end
    else
      -- Handle error if needed, or just continue upwards
      print 'Warning: Error getting node type during traversal'
    end

    -- Use pcall for safety
    local parent_ok, parent = pcall(current.parent, current)
    if parent_ok and parent then
      current = parent
    else
      break -- Reached root or error getting parent
    end
  end
  return nil -- No suitable containing element found
end

function M.wrap_tag_prompt()
  local bufnr = api.nvim_get_current_buf()
  local parser = parsers.get_parser(bufnr) -- Assumes parsers loaded correctly due to check above
  if not parser then
    vim.notify('No active Treesitter parser for this buffer.', vim.log.levels.WARN)
    return
  end

  -- *** CHANGE HERE: Only use get_node_at_cursor ***
  -- Use pcall here for extra safety during the actual call
  local node_ok, current_node = pcall(ts_utils.get_node_at_cursor)

  if not node_ok or not current_node then
    vim.notify('No Treesitter node found at cursor.', vim.log.levels.WARN)
    -- Add more debug info if needed
    if not node_ok then
      print 'Error calling get_node_at_cursor'
    end
    return
  end

  -- Find the element we want to wrap (this function walks up the tree, so starting node is okay)
  local element_to_wrap = get_closest_containing_element_node(current_node)

  if not element_to_wrap then
    vim.notify('Could not find a containing HTML/JSX element to wrap.', vim.log.levels.WARN)
    -- print_node_info(current_node, "Cursor Node") -- For debugging
    return
  end

  -- print_node_info(element_to_wrap, "Element to Wrap") -- For debugging

  -- Use pcall for safety
  local range_ok, sr, sc, er, ec = pcall(element_to_wrap.range, element_to_wrap)
  if not range_ok then
    vim.notify('Failed to get range of the element to wrap.', vim.log.levels.ERROR)
    return
  end

  -- Determine element type for potentially different handling (e.g., fragments)
  -- Use pcall for safety
  local el_type_ok, element_type = pcall(element_to_wrap.type, element_to_wrap)
  if not el_type_ok then
    element_type = 'unknown' -- Assign a default if type cannot be read
    print 'Warning: Could not determine element type.'
  end

  vim.ui.input({ prompt = 'Wrap with tag: ', default = '' }, function(new_tag_name)
    if not new_tag_name or new_tag_name == '' then
      vim.notify('Tag wrapping cancelled.', vim.log.levels.INFO)
      return
    end
    -- Basic validation for tag name
    if not new_tag_name:match '^[a-zA-Z_:][a-zA-Z0-9%-_:.]*$' then
      vim.notify('Invalid tag name format.', vim.log.levels.ERROR)
      return
    end

    -- Use nvim_buf_call for atomicity (all changes succeed or none do)
    local apply_success, result = pcall(api.nvim_buf_call, bufnr, function()
      -- Get the original text content of the element
      local original_lines = api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})
      if not original_lines then
        error 'Failed to get original text of the element.' -- Throw error inside pcall
      end
      local original_text = table.concat(original_lines, '\n')

      local wrapped_text_lines

      -- Handle Fragments specifically (<>...</>)
      if element_type == 'fragment' then
        -- Find the opening <> and closing </> ranges within the fragment
        local open_tag_node, close_tag_node
        -- Use pcall for safety
        local iter_ok, iter = pcall(element_to_wrap.iter_children, element_to_wrap)
        if iter_ok and iter then -- Check iter is not nil
          for child in iter do
            -- Use pcall for safety
            local child_type_ok, child_type = pcall(child.type, child)
            if child_type_ok then
              -- Node types might vary slightly between parsers (e.g., '<>' vs 'open_tag')
              if child_type == '<>' or child_type == 'open_tag' then
                open_tag_node = child
              elseif child_type == '</>' or child_type == 'close_tag' then
                close_tag_node = child
              end
            else
              print 'Warning: Error getting child type in fragment.'
            end
            if open_tag_node and close_tag_node then
              break
            end
          end
        else
          print 'Warning: Could not iterate children of fragment.'
        end

        if open_tag_node and close_tag_node then
          -- Use pcall for safety
          local open_range_ok, osr, osc, oer, oec = pcall(open_tag_node.range, open_tag_node)
          local close_range_ok, csr, csc, cer, cec = pcall(close_tag_node.range, close_tag_node)

          if open_range_ok and close_range_ok then
            -- Perform replacements in reverse order (bottom-up) to preserve line numbers
            api.nvim_buf_set_text(bufnr, csr, csc, cer, cec, { '</' .. new_tag_name .. '>' })
            api.nvim_buf_set_text(bufnr, osr, osc, oer, oec, { '<' .. new_tag_name .. '>' })
            return -- IMPORTANT: Return early as we handled fragment replacement differently
          else
            error 'Could not get ranges for fragment tags <> and </>.'
          end
        else
          vim.notify('Fragment tags (<> </>) not found, wrapping entire fragment content.', vim.log.levels.WARN)
          -- Fallback for fragments if tags aren't found: wrap the whole text content
          local wrapped_text = '<' .. new_tag_name .. '>' .. original_text .. '</' .. new_tag_name .. '>'
          wrapped_text_lines = vim.split(wrapped_text, '\n', { plain = true }) -- Use plain=true for safety
          -- Replace the original element's range with the new wrapped text
          api.nvim_buf_set_text(bufnr, sr, sc, er, ec, wrapped_text_lines)
          return -- Return early
        end
      end

      -- Standard wrapping for element, jsx_element, jsx_self_closing_element
      local wrapped_text = '<' .. new_tag_name .. '>' .. original_text .. '</' .. new_tag_name .. '>'
      wrapped_text_lines = vim.split(wrapped_text, '\n', { plain = true }) -- Use plain=true for safety

      -- Replace the original element's range with the new wrapped text
      api.nvim_buf_set_text(bufnr, sr, sc, er, ec, wrapped_text_lines)
    end) -- end of nvim_buf_call

    if not apply_success then
      vim.notify('Error applying wrapping changes: ' .. tostring(result), vim.log.levels.ERROR)
    else
      vim.notify('Wrapped element with <' .. new_tag_name .. '>.', vim.log.levels.INFO)
      -- Optional: Trigger auto-formatting if you have a formatter setup
      -- pcall(vim.lsp.buf.format, { async = true }) -- Use pcall for safety
    end
  end)
end

return M
