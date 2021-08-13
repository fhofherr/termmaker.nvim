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

M.Window = {}
M.Window.__index = M.Window

setmetatable(M.Window, {
	__call = function(cls, ...)
		return cls.new(...)
	end,
})

function M.Window.new(opts)
	local self = setmetatable({}, M.Window)

    local window_factory = M.current()
    if opts and opts.window_factory then
        window_factory = opts.window_factory
    end
	self._winid, self._close_on_restore = window_factory()

	self._prev_window_opts = {}
	if opts and opts.window_options then
		for k, v in pairs(opts.window_options) do
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
