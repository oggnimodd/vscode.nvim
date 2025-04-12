-- ~/.config/nvim/lua/utils/remove_comments.lua (or your preferred location)

local M = {}

--- Removes all comments from the current buffer using Tree-sitter.
--- Handles main language comments and injected languages.
function M.remove_all_comments()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Pre-checks
  if not vim.api.nvim_buf_is_valid(bufnr) then
    -- No notification needed for invalid buffer, just exit.
    return
  end
  if not vim.api.nvim_get_option_value('modifiable', { buf = bufnr }) then
    vim.notify('Buffer is not modifiable.', vim.log.levels.WARN)
    return
  end

  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    local ft = vim.bo[bufnr].filetype
    vim.notify('No Tree-sitter parser available for filetype: ' .. (ft or 'unknown'), vim.log.levels.WARN)
    return
  end

  local ranges = {} -- Table to store {start_row, start_col, end_row, end_col}

  -- Function to collect comment ranges for a given tree and language
  local function collect_comment_ranges(tree, lang_name, source_buf)
    -- Use the simple query confirmed to work by :InspectTree
    local query_str = '(comment) @comment'
    local ok, query = pcall(vim.treesitter.query.parse, lang_name, query_str)

    if not ok or not query then
      local err_msg = ok and 'query parsing returned nil/false' or tostring(query)
      vim.notify('Failed to parse comment query for language: ' .. lang_name .. '. Error: ' .. err_msg, vim.log.levels.ERROR)
      return -- Skip collecting for this language/tree if query fails
    end

    -- Check buffer validity once before iterating captures
    if not vim.api.nvim_buf_is_valid(source_buf) then
      return
    end

    local first_line = vim.api.nvim_buf_get_lines(source_buf, 0, 1, false)[1] or ''
    local is_shebang = first_line:match '^#!'

    for id, node in query:iter_captures(tree:root(), source_buf, 0, -1) do
      local start_row, start_col, end_row, end_col = node:range()

      -- Skip shebang comments on the very first line
      if start_row == 0 and is_shebang then
        local node_text = vim.treesitter.get_node_text(node, source_buf)
        if node_text and node_text:match '^#!' then
          goto continue -- Skip this capture
        end
      end

      table.insert(ranges, {
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
      })
      ::continue:: -- Label for goto
    end
  end

  -- Process the main language tree
  local main_lang = parser:lang()
  if main_lang then
    local trees = parser:parse()
    if trees and trees[1] then
      collect_comment_ranges(trees[1], main_lang, bufnr)
    else
      -- Don't notify unless parsing explicitly failed? Or maybe warn?
      -- vim.notify('Failed to parse main tree for language: ' .. main_lang, vim.log.levels.WARN)
    end
  end

  -- Process injected language trees
  for lang, child_parser in pairs(parser:children()) do
    local child_trees = child_parser:parse()
    if child_trees then
      for _, child_tree in ipairs(child_trees) do
        collect_comment_ranges(child_tree, lang, bufnr)
      end
    else
      -- vim.notify('Failed to parse injected tree(s) for language: ' .. lang, vim.log.levels.WARN)
    end
  end

  -- Exit if no comments were found
  if #ranges == 0 then
    vim.notify('No comments found.', vim.log.levels.INFO)
    return
  end

  -- Sort ranges in reverse order for safe deletion from bottom to top
  table.sort(ranges, function(a, b)
    if a.start_row == b.start_row then
      return a.start_col > b.start_col
    end
    return a.start_row > b.start_row
  end)

  local deleted_count = 0
  local errors_count = 0

  -- Perform deletions individually, iterating through reverse-sorted ranges
  for _, range in ipairs(ranges) do
    -- Re-check buffer validity in each iteration (important!)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      errors_count = errors_count + 1 -- Count as error if buffer becomes invalid
      break
    end

    local start_row, start_col, end_row, end_col = range.start_row, range.start_col, range.end_row, range.end_col
    local current_line_count = vim.api.nvim_buf_line_count(bufnr)

    -- Bounds checks relative to the *current* buffer state
    if start_row >= current_line_count then
      goto skip_individual -- Range is now beyond buffer end
    end
    local effective_end_row = math.min(end_row, current_line_count - 1)
    if start_row > effective_end_row then
      goto skip_individual -- Range became invalid after adjustments
    end

    -- Check if the comment spans the entire line content (except whitespace)
    -- This check is slightly costly as it gets lines, but necessary for clean deletes
    local delete_whole_line = false
    if start_row == effective_end_row then
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)
      if lines and #lines > 0 then
        local line = lines[1]
        local line_len = #line
        local effective_start_col = math.min(start_col, line_len)
        local effective_end_col = math.min(end_col, line_len)

        if effective_start_col <= effective_end_col then
          local before = line:sub(1, effective_start_col)
          local after = line:sub(effective_end_col + 1)
          if before:match '^%s*$' and after:match '^%s*$' then
            delete_whole_line = true
          end
        elseif line:match '^%s*$' then -- Handle cases where line becomes empty/whitespace
          delete_whole_line = true
        end
      end
    end
    -- Note: Multi-line whole-line check removed for simplicity/performance,
    -- usually deleting the content via set_text is sufficient.

    local ok, err
    if delete_whole_line then
      -- Delete the entire line(s) spanned by the original range start_row
      local del_end_row = math.min(start_row + 1, vim.api.nvim_buf_line_count(bufnr))
      local del_start_row = math.max(0, start_row)
      if del_start_row < del_end_row then
        ok, err = pcall(vim.api.nvim_buf_set_lines, bufnr, del_start_row, del_end_row, false, {})
      else
        ok = true -- No lines to delete, consider it success
      end
    else
      -- Delete text within the range using set_text
      -- Need to refetch lines/clamp columns *right before* the edit for accuracy
      local current_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, effective_end_row + 1, false)
      if current_lines and #current_lines > 0 then
        local first_line_len = #current_lines[1]
        local last_line_len = #(current_lines[#current_lines] or '')
        local final_start_col = math.min(start_col, first_line_len)
        local final_end_col = math.min(end_col, last_line_len)

        -- Final sanity check before API call
        if start_row > effective_end_row or (start_row == effective_end_row and final_start_col >= final_end_col) then
          -- If the range is now invalid or zero-width, skip the API call
          ok = true -- Treat as success (nothing to delete)
        else
          ok, err = pcall(vim.api.nvim_buf_set_text, bufnr, start_row, final_start_col, effective_end_row, final_end_col, { '' })
        end
      else
        ok = false -- Could not fetch lines just before edit
        err = 'Failed to get lines for final edit range check'
      end
    end

    if ok then
      deleted_count = deleted_count + 1
    else
      errors_count = errors_count + 1
      -- Log specific errors only if deletion fails
      vim.notify(string.format('Error removing comment at %d:%d : %s', range.start_row + 1, range.start_col + 1, tostring(err)), vim.log.levels.ERROR)
      -- Consider adding 'break' here if one error should stop everything
    end

    ::skip_individual:: -- Label for goto skips
  end

  -- Final notification
  local final_message = 'Removed ' .. deleted_count .. ' comment(s).'
  if errors_count > 0 then
    final_message = final_message .. ' Encountered ' .. errors_count .. ' error(s).'
    vim.notify(final_message, vim.log.levels.WARN) -- Use WARN if errors occurred
  elseif deleted_count > 0 then
    vim.notify(final_message, vim.log.levels.INFO) -- Use INFO only if successful deletes happened
  else
    -- If ranges were found but 0 were deleted (e.g., due to errors or skips)
    -- No notification might be preferable unless errors occurred.
  end
end

-- Register the user command (ensure this is run only once, e.g., in init.lua)
vim.api.nvim_create_user_command('RemoveAllComments', function()
  M.remove_all_comments()
end, {
  desc = 'Remove all comments from the current buffer using Tree-sitter',
})

return M
