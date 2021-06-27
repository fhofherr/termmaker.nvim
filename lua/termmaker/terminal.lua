local M = {}

local window = require("termmaker.window")
local buffer = require("termmaker.buffer")

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

function M.Terminal.new(opts)
    local window_factory = window.factory.current_window
    if opts and opts.window_factory then
        if type(opts.window_factory) == "string" then
            window_factory = window.factory[opts.window_factory]
        else
            window_factory = opts.window_factory
        end
    end
    return setmetatable({
        _buf = nil,
        _win = nil,
        _job_id = 0,
        _window_factory = window_factory or window.factory.current_window,
    }, M.Terminal)
end

function M.Terminal:open()
    if not self._buf or not self._buf:is_valid() then
        self._buf = buffer.Buffer({
            filetype = "termmaker" -- TODO make buffer filetype configurable?
        })
        self._buf:add_autocmd({"BufWinLeave"}, function()
            self:close()
        end)
    end
    if self:has_window() then
        self._win:jump()
    else
        self._win = self._window_factory()
        self._win:set_window_opts({
            winfixheight = false,
            number = false,
            relativenumber = false,
        })
        self._win:set_buf(self._buf:get_bufnr())
    end
    if self._job_id == 0 then
        self._job_id = vim.fn.termopen(
            {vim.env.SHELL},
            {
                on_exit = function() self:_on_exit() end
            }
        )
    end
end

function M.Terminal:_on_exit()
    self:close()
    self._buf:kill()
    self._job_id = 0
end

function M.Terminal:close()
    if not self:has_window() then
        return
    end
    self._win:restore()
    self._win = nil
end

function M.Terminal:kill()
    self:close()
    if self._job_id ~= 0 then
        vim.fn.jobstop(self._job_id)
        -- Do not wait for the terminal to stop. According to :h jobstop
        -- Neovim will send SIGKILL if the job did not terminate after a
        -- timeout. We are thus happy to know, that Neovim does all it can
        -- to get rid of the job.
        self._job_id = 0
    end
end

function M.Terminal:toggle()
    if self:has_window() and self._win:is_current() then
        self:close()
    else
        self:open()
    end
end

function M.Terminal:has_window()
    return self._win and self._win:is_valid()
end

return M
