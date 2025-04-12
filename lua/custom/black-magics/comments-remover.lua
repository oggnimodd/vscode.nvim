local M = {}

--- Removes all comments from the current buffer using Tree-sitter.
--- Handles main language comments and injected languages (e.g., Svelte <script>, <style>).
function M.remove_all_comments()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_get_option_value('modifiable', { buf = bufnr }) then
    vim.notify('Buffer is not modifiable.', vim.log.levels.WARN)
    return
  end

  local filetype = vim.bo[bufnr].filetype -- Still useful for messages

  -- Let Tree-sitter find the correct parser for the buffer
  local parser = vim.treesitter.get_parser(bufnr) -- Don't pass filetype here
  if not parser then
    -- Use the filetype in the error message for clarity
    vim.notify('No Tree-sitter parser available for filetype: ' .. filetype, vim.log.levels.WARN)
    return
  end

  local ranges = {}

  local function collect_comment_ranges(tree, lang, source_buf)
    local query_str = '(comment) @comment'

    -- *** Removed the vim.treesitter.language.is_registered check ***

    local ok, query = pcall(vim.treesitter.query.parse, lang, query_str)
    -- If pcall failed OR query.parse returned nil/false, treat as failure
    if not ok or not query then
      -- Include the error message from pcall if available (stored in 'query' variable on failure)
      local err_msg = ok and 'query parsing returned nil/false' or tostring(query)
      vim.notify('Failed to parse comment query for language: ' .. lang .. '. Error: ' .. err_msg, vim.log.levels.WARN)
      return
    end

    -- Check if buffer still valid before getting lines
    if not vim.api.nvim_buf_is_valid(source_buf) then
      return
    end
    local first_line = vim.api.nvim_buf_get_lines(source_buf, 0, 1, false)[1] or ''
    local is_shebang = first_line:match '^#!'

    for id, node in query:iter_captures(tree:root(), source_buf, 0, -1) do
      local start_row, start_col, end_row, end_col = node:range()
      -- Skip shebang on the very first line
      if start_row == 0 and is_shebang then
        goto continue -- Using goto requires label definition *within* the function scope
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

  -- Get the actual language name from the parser object for the main tree query
  local main_lang = parser:lang()
  if not main_lang then
    vim.notify('Could not determine language name from main parser.', vim.log.levels.WARN)
    return -- Can't proceed without the language name
  end

  -- Parse the entire buffer and process the main tree
  local trees = parser:parse()
  if trees and trees[1] then
    local main_tree = trees[1]
    collect_comment_ranges(main_tree, main_lang, bufnr)
  else
    vim.notify('Failed to parse main tree for language: ' .. main_lang, vim.log.levels.WARN)
    -- Don't necessarily return here, injected languages might still work
  end

  -- Process all injected language trees (e.g., JavaScript, CSS in Svelte)
  -- parser:children() returns a map { lang_name = child_parser }
  for lang, child_parser in pairs(parser:children()) do
    local child_trees = child_parser:parse()
    if child_trees and child_trees[1] then
      local child_tree = child_trees[1]
      collect_comment_ranges(child_tree, lang, bufnr) -- 'lang' here is the correct key from the map
    else
      vim.notify('Failed to parse injected tree for language: ' .. lang, vim.log.levels.WARN)
    end
  end

  if #ranges == 0 then
    vim.notify('No comments found in the buffer.', vim.log.levels.INFO)
    return
  end

  -- Sort ranges in reverse order to avoid shifting issues when deleting
  table.sort(ranges, function(a, b)
    if a.start_row == b.start_row then
      return a.start_col > b.start_col
    end
    return a.start_row > b.start_row
  end)

  local deleted_count = 0
  -- Use the simpler, individual deletion loop which is safer
  for _, range in ipairs(ranges) do -- Iterate reverse-sorted ranges
    local start_row = range.start_row
    local start_col = range.start_col
    local end_row = range.end_row
    local end_col = range.end_col

    -- Re-check buffer validity and line count within the loop
    if not vim.api.nvim_buf_is_valid(bufnr) then
      vim.notify('Buffer became invalid during deletion.', vim.log.levels.WARN)
      return
    end
    local current_line_count = vim.api.nvim_buf_line_count(bufnr)

    if start_row >= current_line_count then
      vim.notify('Skipping out-of-bounds range: ' .. start_row .. ':' .. start_col, vim.log.levels.DEBUG)
      goto skip_individual -- Use different label
    end
    -- Ensure end_row isn't out of bounds *now*
    end_row = math.min(end_row, current_line_count - 1)
    -- Ensure start_row is not greater than potentially adjusted end_row
    if start_row > end_row then
      vim.notify('Skipping range where start > end after adjustment: ' .. start_row .. ' > ' .. end_row, vim.log.levels.DEBUG)
      goto skip_individual
    end

    local delete_whole_line = false
    if start_row == end_row then
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)
      if lines and #lines > 0 then
        local line = lines[1] or ''
        -- Adjust end_col if it exceeds line length (can happen after prior edits)
        local current_end_col = math.min(end_col, #line)
        local current_start_col = math.min(start_col, #line) -- Adjust start_col too

        -- Check if comment is the only non-whitespace content
        -- Ensure start <= end before sub()
        if current_start_col <= current_end_col then
          local before = line:sub(1, current_start_col):match '^%s*$' ~= nil
          local after = line:sub(current_end_col + 1):match '^%s*$' ~= nil
          if before and after then
            delete_whole_line = true
          end
        elseif line:match '^%s*$' then -- If start>end and line is all whitespace, delete
          delete_whole_line = true
        end
      else
        goto skip_individual -- Line likely deleted already or buffer issue
      end
    end

    local ok, err
    if delete_whole_line then
      -- Ensure we don't delete past the end of the buffer
      local del_end_row = math.min(start_row + 1, vim.api.nvim_buf_line_count(bufnr)) -- Recheck count just before delete
      ok, err = pcall(vim.api.nvim_buf_set_lines, bufnr, start_row, del_end_row, false, {})
    else
      -- Use the potentially adjusted end_row and ensure start/end cols are valid
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false) -- Fetch lines again right before edit
      if lines and #lines > 0 then
        local first_line_len = #lines[1]
        local last_line_len = #lines[#lines]

        -- Clamp columns to valid ranges for the *current* state of the lines
        local effective_start_col = math.min(start_col, first_line_len)
        local effective_end_col = math.min(end_col, last_line_len)

        -- Final sanity check for coordinates
        if start_row == end_row and effective_start_col > effective_end_col then
          vim.notify(
            'Skipping invalid range after final adjustments: ' .. start_row .. ':' .. effective_start_col .. '-' .. end_row .. ':' .. effective_end_col,
            vim.log.levels.DEBUG
          )
          goto skip_individual
        end

        ok, err = pcall(vim.api.nvim_buf_set_text, bufnr, start_row, effective_start_col, end_row, effective_end_col, { '' })
      else
        ok = false -- Treat as error if lines cannot be fetched
        err = 'Could not fetch lines for text setting just before edit'
      end
    end

    if ok then
      deleted_count = deleted_count + 1
    else
      vim.notify('Error removing comment at ' .. start_row .. ':' .. start_col .. ' - ' .. tostring(err), vim.log.levels.ERROR)
      -- Optionally 'return' here if one error should stop the whole process
    end

    ::skip_individual:: -- Label for this loop's goto
  end

  vim.notify('Removed ' .. deleted_count .. ' comment(s).', vim.log.levels.INFO)
end

-- Register the user command
vim.api.nvim_create_user_command('RemoveAllComments', function()
  M.remove_all_comments()
end, {
  desc = 'Remove all comments from the current buffer using Tree-sitter',
})

return M
