local M = {}

local table_slice = function(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced + 1] = tbl[i]
    end

    return sliced
end

-- NOTE: don't forget to escape the characters with % (see https://help.interfaceware.com/v6/lua-magic-characters)
local language_comment = {
    c          = { "^//", "^/%*", "%*/$" },
    cpp        = { "^//", "^/%*", "%*/$" },

    lua        = { "^%-%-" },
    python     = { "^#" },

    html       = { "^<!%-%-", "%-%->$" },
    css        = { "^/%*", "%*/$" },
    javascript = { "^//", "^/%*", "%*/$" },

    haskell    = { "^%-%-", "^{%-", "%-}$" }
}


local remove_spaces = true

local comments = {}

-- create namespace
local ns_id = vim.api.nvim_create_namespace("comment_jump")

-- create autogroup
local augroup = vim.api.nvim_create_augroup("comment_jump", { clear = true })

local update = function()
    -- get buffer
    local bufnr = vim.api.nvim_get_current_buf()

    -- parse the file has a lua file
    local ts_parser = require("nvim-treesitter.parsers").get_parser()
    if ts_parser == nil then
        return
    end

    local ts_tree_root = ts_parser:parse()[1]:root()

    local file_type = vim.api.nvim_buf_get_option(bufnr, "filetype") -- deprecated

    local success, ts_query = pcall(vim.treesitter.query.parse, file_type, "[[(comment) @all]]")
    if not success then
        return
    end

    -- get all lines of file
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- reset old_comments
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1);

    -- read the parsed comment
    for _, node, _ in ts_query:iter_captures(ts_tree_root, bufnr, 0, -1) do
        local line_start, col_start, line_end, col_end = node:range()
        for _, line in pairs(table_slice(lines, line_start + 1, line_end + 1)) do
            -- keep only the comment part
            local line_content = line:sub(col_start + 1, col_end + 1)
            local to_remove_com = language_comment[file_type]
            if to_remove_com ~= nil then
                for _, reg in pairs(language_comment[file_type]) do
                    line_content = line_content:gsub(reg, "")
                end
            end
            if remove_spaces then
                if line_content:sub(1, 1) == " " then
                    line_content = line_content:sub(2)
                end
            end
            for idx, comment in pairs(comments) do
                local regex = vim.regex(comment.regex)
                -- hilight it if string found
                if regex:match_str(line_content) then
                    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_start, col_start,
                        { end_col = col_end, end_row = line_end, hl_group = "comment_jump_" .. idx })
                end
            end
        end
    end
end

M.JumpTo = function(name)
    -- TODO: put every file in the current folder and up that contain the comment <name> inside the quickfix list
    local inside = false
    for _, comment in pairs(comments) do
        for k, v in pairs(comment) do
            if k == "regex" and v == name then
                inside = true
                break
            end
        end
    end

    if not inside then
        vim.api.nvim_err_writeln("CommentJumpTo: \"" .. name .. "\" not in comments")
    end
end

M.setup = function(setup)
    if setup.remove_spaces == false then
        remove_spaces = false
    end
    comments = setup.comments

    -- create hl groups
    for idx, comment in pairs(comments) do
        vim.api.nvim_set_hl(0, "comment_jump_" .. idx,
            { fg = comment.fg, bg = comment.bg, underline = comment.underline })
    end

    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufFilePost', 'BufWritePost', 'TextChanged', 'TextChangedI' }, {
        group = augroup,
        callback = update
    })
end

-- to test if Setup works, uncomment the next lines, then do :so and do a small change to the file
-- M.setup({
--     comments={
--         {regex="^TODO.*$", fg="red"}
--     }
-- }) -- TODO: test
-- vim.keymap.set("n", "<leader>cj", function()
--     M.JumpTo(vim.fn.input("comment to search: "))
-- end)
return M
