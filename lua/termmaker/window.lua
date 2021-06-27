local M = {}

M.factory = {}

function M.factory.current_window(opts)
    return M.Window(vim.api.nvim_get_current_win(), opts)
end

function M.factory.new_window(opts)
    local cmd = "new"
    if opts and opts.modifier then
        cmd = ":" .. opts.modifier .. " " .. cmd
    end
    vim.api.nvim_command(cmd)
    if not opts then
        opts = {}
    end
    opts.pre_restore = function(win)
        if vim.api.nvim_win_is_valid(win._winid) then
            vim.api.nvim_win_close(win._winid, true)
            return true
        end
    end

    return M.factory.current_window(opts)
end

M.Window = {}
M.Window.__index = M.Window

setmetatable(M.Window, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function M.Window.new(winid, opts)
    assert(winid, "Window number must not be nil")
    assert(winid ~= 0, "Window number must not be 0")

    local self = setmetatable({}, M.Window)
    self._prev_bufnr = nil
    self._prev_window_opts = {}
    self._pre_restore = (opts and opts.pre_restore)

    self._winid = winid

    return self
end

function M.Window:set_buf(bufnr)
    assert(bufnr, "Buffer number must not be nil")
    assert(bufnr ~= 0, "Buffer number must not be 0")

    self._prev_bufnr = vim.api.nvim_win_get_buf(self._winid)
    vim.api.nvim_win_set_buf(self._winid, bufnr)
end

function M.Window:set_window_opts(opts)
    for k, v in pairs(opts) do
        if not self._prev_window_opts[k] then
            self._prev_window_opts[k] = vim.api.nvim_win_get_option(self._winid, k)
        end
        vim.api.nvim_win_set_option(self._winid, k, v)
    end
end

function M.Window:restore()
    if self._pre_restore and self._pre_restore(self) then
        return
    end
    if self._prev_bufnr and vim.api.nvim_buf_is_valid(self._prev_bufnr) then
        vim.api.nvim_win_set_buf(self._winid, self._prev_bufnr)
        self._prev_bufnr = nil
    end
    for k, v in pairs(self._prev_window_opts) do
        vim.api.nvim_win_set_option(self._winid, k, v)
        self._prev_window_opts[k] = nil
    end
    self._prev_window_opts = {}
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
