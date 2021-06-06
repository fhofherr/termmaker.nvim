local M = {}

-- Terminal represents a single terminal inside neovim.
--
-- An instance of Terminal may be visible in a window or may currently be
-- hidden.
M.Terminal = {}
M.Terminal.__index = M.Terminal

setmetatable(M.Terminal, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function M.Terminal.new()
    local self = setmetatable({}, M.Terminal)
    self.bufnr = 0
    self.winnr = 0
    return self
end

function M.Terminal:open()
    if self.bufnr == 0 or not vim.api.nvim_buf_is_valid(self.bufnr) then
        -- TODO make listing the buffer configurable
        self.bufnr = vim.api.nvim_create_buf(true, false)
    end
    if self.winnr == 0 or not vim.api.nvim_win_is_valid(self.winnr) then
        -- TODO remember the previous state of the window
        -- TODO restore window state when unloading terminal buffer
        -- TODO ensure window state is handled properly if terminal is loaded by other means (e.g. Telescope) => autocommands?
        self.winnr = vim.api.nvim_get_current_win()
        -- TODO move cursor to buffers window if it is already open
    end
    self.prev_buf = vim.api.nvim_get_current_buf() -- TODO let strategy remember that
    vim.api.nvim_win_set_buf(self.winnr, self.bufnr)
    vim.fn.termopen({vim.env.SHELL})
end

function M.Terminal:close()
    if self.winnr == 0 then
        return
    end
    if self.prev_buf then
        vim.api.nvim_win_set_buf(self.winnr, self.prev_buf)
    end
    -- TODO restore window options => strategy dependent
    self.winnr = 0
end

local test_term
function M.test_toggle()
    if test_term then
        test_term:close()
        test_term = nil
    else
        test_term = M.Terminal()
        test_term:open()
    end
end

return M
