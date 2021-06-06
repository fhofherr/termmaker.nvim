local M = {}

M.factory = {}

function M.factory.current_window()
    return M.Window(vim.api.nvim_get_current_win())
end

M.Window = {}
M.Window.__index = M.Window

setmetatable(M.Window, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function M.Window.new(winid)
    assert(winid, "Window number must not be nil")
    assert(winid ~= 0, "Window number must not be 0")

    local self = setmetatable({}, M.Window)
    self._prev_bufnr = nil
    self._prev_opts = {}

    self._winid = winid

    return self
end

function M.Window:set_buf(bufnr)
    assert(bufnr, "Buffer number must not be nil")
    assert(bufnr ~= 0, "Buffer number must not be 0")

    self._prev_bufnr = vim.api.nvim_win_get_buf(self._winid)
    vim.api.nvim_win_set_buf(self._winid, bufnr)
end

function M.Window:set_opts(opts)
    for k, v in pairs(opts) do
        if not self._prev_opts[k] then
            self._prev_opts[k] = vim.api.nvim_win_get_option(self._winid, k)
        end
        vim.api.nvim_win_set_option(self._winid, k, v)
    end
end

function M.Window:restore()
    if self._prev_bufnr and vim.api.nvim_buf_is_valid(self._prev_bufnr) then
        vim.api.nvim_win_set_buf(self._winid, self._prev_bufnr)
        self._prev_bufnr = nil
    end
    for k, v in pairs(self._prev_opts) do
        vim.api.nvim_win_set_option(self._winid, k, v)
        self._prev_opts[k] = nil
    end
end

function M.Window:jump()
    local tabnr = vim.api.nvim_win_get_tabpage(self._winid)
    if tabnr ~= vim.api.nvim_get_current_tabpage() then
        print("Jumping to tabpage " .. tabnr)
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
