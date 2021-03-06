local M = {}

local buffer = require("termmaker.buffer")
local event = require("termmaker.event")
local window = require("termmaker.window")

local default_opts = {
    cmd = { vim.env.SHELL },
    env = nil,
    clear_env = false,
    kill_on_exit = true,
    window_opts = {
        window_factory = window.current(),
    }
}

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
    local self = setmetatable({}, M.Terminal)

    opts = vim.tbl_extend("keep", opts or {}, default_opts)

    self._buf = nil
    self._win = nil
    self._job_id = 0
    self._opts = opts

    if opts.kill_on_exit then
        event.add_autocmd("ExitPre", function()
            self:kill()
        end)
    end

    return self
end

function M.Terminal:open()
    if not self:has_buffer() then
        self:_init_buffer()
    end
    if not self:has_window() then
        self:_init_window()
    end

    self._win:jump()
    if self._job_id == 0 then
        self._job_id = vim.fn.termopen(self._opts.cmd, {
            env = self._opts.env,
            clear_env = self._opts.clear_env,
            on_exit = function()
                self:_on_exit()
            end,
        })
    end
end

function M.Terminal:_init_buffer()
    self._buf = buffer.Buffer(self._opts.buffer_opts)
    self._buf:register(buffer.win_leave, function()
        self:close()
        return false
    end)
end

function M.Terminal:_init_window()
    self._win = window.Window(self._opts.window_opts)
    self._win:show_buffer(self._buf)
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
        -- Only close the window if it is the current window. Otherwise
        -- it is more likely that the user wanted to select it, which is
        -- done by open.
        self:close()
    else
        self:open()
    end
end

function M.Terminal:has_window()
    return self._win and self._win:is_valid()
end

function M.Terminal:has_buffer()
    return self._buf and self._buf:is_valid()
end

return M
