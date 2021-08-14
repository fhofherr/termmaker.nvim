local M = {}

local event = require("termmaker.event")

M.default_opts = {
    filetype = "termmaker",
    list_buffer = true,
    t_mappings = {},
}

-- Buffer events
M.win_leave = "buf_win_leave"

M.Buffer = {}
M.Buffer.__index = M.Buffer

setmetatable(M.Buffer, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function M.Buffer.new(opts)
    local self = setmetatable({}, M.Buffer)
    event.make_source(self)

    opts = vim.tbl_extend("keep", opts or {}, M.default_opts)
    self._bufnr = vim.api.nvim_create_buf(true, opts.list_buffer)

    if opts then
        if opts.filetype then
            vim.api.nvim_buf_set_option(self._bufnr, "filetype", opts.filetype)
        end
    end

    -- Note: the implementation of add_autocmd ensures that the first element
    -- of the varargs is the buffer number.
    event.add_autocmd("BufWinLeave", function(_, ...)
        self.notify_all(M.win_leave, ...)
        return self:is_valid()
    end, {
        buffer = self._bufnr,
    })

    for lhs, rhs in ipairs(opts.t_mappings) do
        vim.api.nvim_buf_set_keymap(self._bufnr, "t", lhs, rhs, { silent = true, noremap = true })
    end

    return self
end

function M.Buffer:is_valid()
    return vim.api.nvim_buf_is_valid(self._bufnr)
end

function M.Buffer:get_bufnr()
    return self._bufnr
end

function M.Buffer:kill()
    if not self:is_valid() then
        return
    end
    vim.api.nvim_buf_delete(self._bufnr, { force = true })
end

return M
