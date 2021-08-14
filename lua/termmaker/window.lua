local M = {}

local buffer = require("termmaker.buffer")

function M.current()
    return function()
        return vim.api.nvim_get_current_win(), false
    end
end

function M.horizontal_split()
    return function()
        vim.api.nvim_command("split")
        return vim.api.nvim_get_current_win(), true
    end
end

function M.vertical_split()
    return function()
        vim.api.nvim_command("vsplit")
        return vim.api.nvim_get_current_win(), true
    end
end

function M.auto_split(opts)
    local vsplit = M.vertical_split(opts)
    local hsplit = M.horizontal_split(opts)
    local current = M.current(opts)

    local min_width = 80
    local min_height = 25

    if opts then
        if opts.min_width then
            min_width = opts.min_width
        end
        if opts.min_height then
            min_height = opts.min_height
        end
    end

    return function()
        local cur_height = vim.api.nvim_win_get_height(0)
        local cur_width = vim.api.nvim_win_get_width(0)

        local prefer_vsplit = cur_width > cur_height
        if opts and opts.prefer_vsplit ~= nil then
            prefer_vsplit = opts.prefer_vsplit
        end

        local can_vsplit = cur_width > 2 * min_width
        local can_hsplit = cur_height > 2 * min_height
        if can_vsplit and can_hsplit then
            if prefer_vsplit then
                return vsplit()
            else
                return hsplit()
            end
        elseif can_vsplit then
            return vsplit()
        elseif can_hsplit then
            return hsplit()
        else
            vim.api.nvim_command(string.format("echom 'reusing current window: ch:%d cw%d'", cur_height, cur_width))
            return current()
        end
    end
end

local default_opts = {
    window_factory = M.current(),
    winfixheight = false,
    number = false,
    relativenumber = false,
}

-- set of private options so we don't try to set them as vim window options.
local private_options = {
    window_factory = true,
}

M.Window = {}
M.Window.__index = M.Window

setmetatable(M.Window, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function M.Window.new(opts)
    local self = setmetatable({}, M.Window)

    opts = vim.tbl_extend("keep", opts or {}, default_opts)
    self._winid, self._close_on_restore = opts.window_factory()

    self._prev_window_opts = {}
    for k, v in pairs(opts) do
        if not private_options[k] then
            if not self._prev_window_opts[k] then
                self._prev_window_opts[k] = vim.api.nvim_win_get_option(self._winid, k)
            end
            vim.api.nvim_win_set_option(self._winid, k, v)
        end
    end

    return self
end

function M.Window:show_buffer(buf_or_bufnr)
    local bufnr = 0

    if type(buf_or_bufnr) == "number" then
        bufnr = buf_or_bufnr
    elseif type(buf_or_bufnr) == "table" and getmetatable(buf_or_bufnr) == buffer.Buffer then
        bufnr = buf_or_bufnr:get_bufnr()
    end
    assert(bufnr ~= 0, "buf_or_bufnr was 0 or not a buffer.Buffer")

    self._prev_bufnr = vim.api.nvim_win_get_buf(self._winid)
    vim.api.nvim_win_set_buf(self._winid, bufnr)
end

function M.Window:restore()
    if self._close_on_restore then
        vim.api.nvim_win_close(self._winid, true)
        return
    end

    -- Restore any previous window options
    for k, v in pairs(self._prev_window_opts) do
        vim.api.nvim_win_set_option(self._winid, k, v)
        self._prev_window_opts[k] = nil
    end
    self._prev_window_opts = {}

    -- Restore the previous buffer
    if self._prev_bufnr and vim.api.nvim_buf_is_valid(self._prev_bufnr) then
        vim.api.nvim_win_set_buf(self._winid, self._prev_bufnr)
        self._prev_bufnr = nil
    end
end

function M.Window:jump()
    if self:is_current() then
        return
    end

    local tabnr = vim.api.nvim_win_get_tabpage(self._winid)
    if tabnr ~= vim.api.nvim_get_current_tabpage() then
        -- print("Jumping to tabpage " .. tabnr)
        vim.api.nvim_command(tabnr .. "tabnext")
    end

    local winnr = vim.api.nvim_win_get_number(self._winid)
    vim.api.nvim_command(winnr .. "wincmd w")
end

function M.Window:is_valid()
    return vim.api.nvim_win_is_valid(self._winid)
end

function M.Window:is_current()
    return vim.api.nvim_get_current_win() == self._winid
end

return M
