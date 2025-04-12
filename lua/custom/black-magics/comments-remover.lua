-- ~/.config/nvim/lua/utils/remove_comments.lua

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
    -- Determine the correct query string based on the language
    local query_str
    if lang_name == 'rust' then
      -- Rust uses specific node types: line_comment and block_comment
      query_str = '[(line_comment) (block_comment)] @comment'
    else
      -- Use the generic query for other languages (might need adjustments for others too)
      query_str = '(comment) @comment'
    end

    -- Parse the chosen query string
    local ok, query = pcall(vim.treesitter.query.parse, lang_name, query_str)

    if not ok or not query then
      local err_msg = ok and 'query parsing returned nil/false' or tostring(query)
      vim.notify('Failed to parse comment query for language: ' .. lang_name .. '. Query: "' .. query_str .. '". Error: ' .. err_msg, vim.log.levels.ERROR)
      return -- Skip collecting for this language/tree if query fails
    end

    -- Check buffer validity once before iterating captures
    if not vim.api.nvim_buf_is_valid(source_buf) then
      return
    end

    local first_line = vim.api.nvim_buf_get_lines(source_buf, 0, 1, false)[1] or ''
    local is_shebang = first_line:match '^#!'

    -- Use the capture name '@comment' defined in the query
    for id, node, metadata in query:iter_captures(tree:root(), source_buf, 0, -1) do
      -- Check if the capture name is indeed '@comment' (it should be based on our queries)
      local capture_name = query.captures[id]
      if capture_name == 'comment' then
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
      end
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
      -- Get the line content only if we need to check for whole-line deletion
      -- Avoid unnecessary API calls if possible
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)
      if lines and #lines > 0 then
        local line = lines[1]
        local line_len = #line
        -- Use potentially adjusted end_col if it exceeds line length
        local current_end_col = math.min(end_col, line_len)

        -- Check if range is valid before sub-stringing
        if start_col <= current_end_col then
          local before = line:sub(1, start_col)
          local after = line:sub(current_end_col + 1)
          if before:match '^%s*$' and after:match '^%s*$' then
            delete_whole_line = true
          end
        elseif line:match '^%s*$' then -- Handle cases where start_col > end_col but line is whitespace
          delete_whole_line = true
        end
      elseif vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] == '' then
        -- If the line is now empty (perhaps due to previous deletions), delete it.
        delete_whole_line = true
      end
    else
      -- Multi-line comment: Check if the *first* line is empty before the comment
      -- and the *last* line is empty after the comment. This is an approximation.
      local first_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)
      local last_lines = vim.api.nvim_buf_get_lines(bufnr, effective_end_row, effective_end_row + 1, false)

      if first_lines and #first_lines > 0 and last_lines and #last_lines > 0 then
        local first_line = first_lines[1]
        local last_line = last_lines[1]
        local first_line_len = #first_line
        local last_line_len = #last_line

        local current_start_col = math.min(start_col, first_line_len)
        local current_end_col = math.min(end_col, last_line_len)

        local before = first_line:sub(1, current_start_col)
        local after = last_line:sub(current_end_col + 1)

        -- Check if all lines between start and end are also effectively empty
        -- (this is simplified: assumes if first/last lines are blanked, the whole block should go)
        local all_intermediate_whitespace = true
        if effective_end_row > start_row then
          local intermediate_lines = vim.api.nvim_buf_get_lines(bufnr, start_row + 1, effective_end_row, false)
          for _, line in ipairs(intermediate_lines) do
            if not line:match '^%s*$' then
              all_intermediate_whitespace = false
              break
            end
          end
        end

        if before:match '^%s*$' and after:match '^%s*$' and all_intermediate_whitespace then
          delete_whole_line = true
        end
      end
    end

    local ok, err
    if delete_whole_line then
      -- Delete the entire line(s) spanned by the original range start_row -> end_row
      -- Adjust end row for deletion API (exclusive)
      local del_end_row = math.min(effective_end_row + 1, vim.api.nvim_buf_line_count(bufnr))
      local del_start_row = math.max(0, start_row) -- Ensure start row is not negative
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
        local first_line_len = current_lines[1] and #current_lines[1] or 0
        local last_line_len = current_lines[#current_lines] and #current_lines[#current_lines] or 0

        -- Clamp columns based on the *actual* line lengths just before editing
        local final_start_col = math.min(start_col, first_line_len)
        local final_end_col = math.min(end_col, last_line_len)

        -- Final sanity check before API call
        if start_row > effective_end_row or (start_row == effective_end_row and final_start_col >= final_end_col) then
          -- If the range is now invalid or zero-width (possibly due to previous edits), skip the API call
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
    -- If ranges were found but 0 were deleted (e.g., due to errors or skips),
    -- check if errors occurred. If not, maybe the 'No comments found' was sufficient.
    -- Avoid double notification if ranges were non-zero but all skipped/errored.
    if errors_count == 0 and #ranges > 0 then
      -- This case is unlikely if errors_count is 0, perhaps notify differently?
      -- Or rely on the initial "No comments found" if #ranges was 0.
      -- Let's stick to no notification here if no deletes and no errors.
    end
  end
end

-- Register the user command (ensure this is run only once, e.g., in init.lua or ftplugin)
-- Check if command already exists to avoid errors on reload
if vim.fn.exists ':RemoveAllComments' == 0 then
  vim.api.nvim_create_user_command('RemoveAllComments', function()
    M.remove_all_comments()
  end, {
    desc = 'Remove all comments from the current buffer using Tree-sitter',
  })
end

return M
