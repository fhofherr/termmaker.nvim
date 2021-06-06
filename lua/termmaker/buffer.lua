local M = {}

local buffers = {}

function M.autocmd(bufnr, cmd_name)
    local buf = buffers[bufnr]

    if buf and buf._autocmds[cmd_name] then
        for _, f in ipairs(buf._autocmds[cmd_name]) do
            f()
        end
    end
end

function M.is_registered(buf_or_bufnr)
    local bufnr

    if type(buf_or_bufnr) == "number" then
        bufnr = buf_or_bufnr
    elseif buf_or_bufnr then
        bufnr = buf_or_bufnr._bufnr
    else
        return false
    end
    return buffers[bufnr] ~= nil
end

M.Buffer = {}
M.Buffer.__index = M.Buffer

setmetatable(M.Buffer, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function M.Buffer.new()
    local self = setmetatable({}, M.Buffer)

    -- TODO make listing the buffer configurable
    self._bufnr = vim.api.nvim_create_buf(true, false)
    buffers[self._bufnr] = self

    self._autocmds = {}
    self:add_autocmd("BufWipeout", function()
        self:_deregister()
    end)

    return self
end

function M.Buffer:add_autocmd(names, fn)
    if type(names) == "string" then
        names = {names}
    end

    for _,name in ipairs(names) do
        local autocmds = self._autocmds[name]
        if not autocmds then
            local cmd_str = string.format(
            "autocmd %s <buffer=%d> lua require('termmaker.buffer').autocmd(%d, '%s')",
            name, self._bufnr, self._bufnr, name
            )
            vim.api.nvim_command(cmd_str)
            autocmds = {}
        end
        autocmds[#autocmds+1] = fn
        self._autocmds[name] = autocmds
    end
end

function M.Buffer:is_valid()
    return vim.api.nvim_buf_is_valid(self._bufnr)
end

function M.Buffer:get_bufnr()
    return self._bufnr
end

function M.Buffer:_deregister()
    buffers[self._bufnr]  = nil
end

function M.Buffer:kill()
    if not self:is_valid() then
        return
    end
    vim.api.nvim_buf_delete(self._bufnr, { force = true })
end

return M
