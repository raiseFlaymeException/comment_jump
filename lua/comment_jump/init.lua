local M = {}

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

local update = function(ns_id, comments)
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
        local ts_query = vim.treesitter.query.parse(file_type, "[[(comment) @all]]")

        -- get all lines of file
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        -- read the parsed comment
        for id, node, metadata, match in ts_query:iter_captures(ts_tree_root, bufnr, 0, -1) do
            -- skip non comment
            if (node:type()=="comment") then
                local line_start, col_start, line_stop, col_stop = node:range()
                for _, line in pairs(table.slice(lines, line_start+1, line_stop+1)) do
                    -- keep only the comment part
                    local line_content = line:sub(col_start+1, col_stop+1)

                    for idx, comment in pairs(comments) do
                        local regex = vim.regex(comment.regex)
                        -- hilight it if string found
                        if regex:match_str(line_content) then
                            vim.api.nvim_buf_add_highlight(0, ns_id, "comment_jump_"..idx, line_start, col_start, col_stop)
                        end
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

    -- create namespace
    local ns_id = vim.api.nvim_create_namespace("comment_jump")

    -- create autogroup
    local augroup = vim.api.nvim_create_augroup("comment_jump", {clear = true})
    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufFilePost', 'BufWritePost', 'TextChanged', 'TextChangedI'  }, {
        group = augroup,
        callback = update(ns_id, comments)})
    end


return M
