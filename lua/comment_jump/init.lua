local M = {}

local table_slice = function(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

-- NOTE: don't forget to escape the characters with % (see https://help.interfaceware.com/v6/lua-magic-characters)
local language_comment = {
    c                = {"^//", "^/%*", "%*/$"},
    cpp              = {"^//", "^/%*", "%*/$"},

    lua              = {"^%-%-"},
    python           = {"^#"},

    html             = {"^<!%-%-", "%-%->$"},
    css              = {"^/%*", "%*/$"},
    javascript       = {"^//", "^/%*", "%*/$"},

    haskell          = {"^%-%-", "^{%-", "%-}$"}
}


local remove_spaces = true

local comments = {}

-- a record of comments line to check if we need to remove them
local comments_reset = {};

-- create namespace
local ns_id = vim.api.nvim_create_namespace("comment_jump")

-- create autogroup
local augroup = vim.api.nvim_create_augroup("comment_jump", {clear = true})

local update = function()
    -- get buffer
    local bufnr = vim.api.nvim_get_current_buf()

    -- parse the file has a lua file
    local ts_parser = require("nvim-treesitter.parsers").get_parser()
    if ts_parser==nil then
        return
    end

    local ts_tree_root = ts_parser:parse()[1]:root()

    local file_type = vim.api.nvim_buf_get_option(bufnr, "filetype")

    local success, ts_query = pcall(vim.treesitter.query.parse, file_type, "[[(comment) @all]]")
    if not success then
        return
    end

    -- get all lines of file
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    if comments_reset[bufnr] == nil then
        comments_reset[bufnr] = {}
    end
    -- reset old_comments
    for _, comment in pairs(comments_reset[bufnr]) do
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, 
            comment.line_start, comment.col_start, 
            {end_col = comment.col_end, hl_group = 0, id=comment.extid})
    end
    comments_reset[bufnr] = {}

    -- read the parsed comment
    for id, node, metadata, match in ts_query:iter_captures(ts_tree_root, bufnr, 0, -1) do
        local line_start, col_start, line_end, col_end = node:range()
        for _, line in pairs(table_slice(lines, line_start+1, line_end+1)) do
            -- keep only the comment part
            local line_content = line:sub(col_start+1, col_end+1)
            to_remove_com = language_comment[file_type]
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
                -- print(line_content, regex:match_str(line_content) == nil)
                -- hilight it if string found
                if regex:match_str(line_content) then
                    extid = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_start, col_start, {end_col = col_end, hl_group = "comment_jump_"..idx})
                    table.insert(comments_reset, {extid=extid, line_start=line_start, col_start=col_start, col_end=cold_end})
                end
            end
        end
    end
end

M.JumpTo = function(name)
    -- TODO: put every file in the current folder and up that contain the comment <name> inside the quickfix list
    inside = false
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

M.Setup = function(setup)
    if setup.remove_spaces == false then
        remove_spaces = false
    end
    comments = setup.comments

    -- create hl groups 
    for idx, comment in pairs(comments) do
        vim.api.nvim_set_hl(0, "comment_jump_"..idx, {fg=comment.fg, bg=comment.bg, underline=comment.underline})
    end

    vim.api.nvim_create_autocmd({'BufWinEnter', 'BufFilePost', 'BufWritePost', 'TextChanged', 'TextChangedI'}, {
        group = augroup,
        callback = update})
    end

-- TODO: support for multiline comment
-- TODO: bug on comment
-- to test if Setup works, uncomment the next lines, then do :so and do a small change to the file
-- M.Setup({
--     comments={
--         {regex="^TODO.*$", fg="red"}
--     }
-- }) -- TODO: test
-- vim.keymap.set("n", "<leader>cj", function()
--     M.JumpTo(vim.fn.input("comment to search: "))
-- end)
return M
