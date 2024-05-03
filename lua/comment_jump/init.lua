local M = {}

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

local update = function(ns_id, comments, comments_reset)
    return function()
        -- get buffer
        local bufnr = vim.api.nvim_get_current_buf()

        -- parse the file has a lua file
        local ts_parser = require("nvim-treesitter.parsers").get_parser()
        if ts_parser==nil then
            return
        end

        local ts_tree_root = ts_parser:parse()[1]:root()

        local file_type = vim.api.nvim_buf_get_option(0, "filetype")

        local success, ts_query = pcall(vim.treesitter.query.parse, file_type, "[[(comment) @all]]")
        if not success then
            return
        end

        -- get all lines of file
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        -- reset old_comments
        for _, comment in pairs(comments_reset) do
            vim.api.nvim_buf_set_extmark(0, ns_id, comment.line_start, comment.col_start, {end_col = comment.col_end, hl_group = 0, id=comment.extid})
        end
        comments_reset = {}

        -- read the parsed comment
        for id, node, metadata, match in ts_query:iter_captures(ts_tree_root, bufnr, 0, -1) do
            -- skip non comment
            -- if (node:type()=="comment") then
            local line_start, col_start, line_end, col_end = node:range()
            for _, line in pairs(table.slice(lines, line_start+1, line_end+1)) do
                -- keep only the comment part
                local line_content = line:sub(col_start+1, col_end+1)

                for idx, comment in pairs(comments) do
                    local regex = vim.regex(comment.regex)
                    -- hilight it if string found
                    if regex:match_str(line_content) then
                        extid = vim.api.nvim_buf_set_extmark(0, ns_id, line_start, col_start, {end_col = col_end, hl_group = "comment_jump_"..idx})
                        table.insert(comments_reset, {extid=extid, line_start=line_start, col_start=col_start, col_end=cold_end})
                    end
                end
            end
        end
    end
end

M.Setup = function(comments)
    -- create hl groups 
    for idx, comment in pairs(comments) do
        vim.api.nvim_set_hl(0, "comment_jump_"..idx, {fg=comment.color})
    end

    -- a record of comments line to check if we need to remove them
    local comments_reset = {};

    -- create namespace
    local ns_id = vim.api.nvim_create_namespace("comment_jump")

    -- create autogroup
    local augroup = vim.api.nvim_create_augroup("comment_jump", {clear = true})
    vim.api.nvim_create_autocmd({'BufWinEnter', 'BufFilePost', 'BufWritePost', 'TextChanged', 'TextChangedI'}, {
        group = augroup,
        callback = update(ns_id, comments, comments_reset)})
    end


return M
