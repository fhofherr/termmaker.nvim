local M = {}

-- Source is an object that notifies observers of events they have
-- registered for.
--
-- Source can either be instantiated directly or be used to extend
-- another class.
M.Source = {}
M.Source.__index = M.Source
setmetatable(M.Source, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function M.make_source(o)
    src = M.Source.new()
    o.register = function(_, event_name, observer)
        src:register(event_name, observer)
    end
    o.notify_all = function(_, event_name, ...)
        src:notify_all(event_name, ...)
    end
end

function M.Source.new()
    local self = setmetatable({}, M.Source)

    self._observers = {}

    return self
end

function M.Source:register(event_name, observer)
    if not self._observers[event_name] then
        self._observers[event_name] = {}
    end
    local idx = #self._observers[event_name] + 1
    self._observers[event_name][idx] = observer
end

function M.Source:notify_all(event_name, ...)
    local observers = self._observers[event_name]
    if not observers then
        return
    end

    for i, observer in ipairs(observers) do
        local keep_notified = observer(event_name, ...)
        if not keep_notified then
            observers[i] = nil
        end
    end

    self._observers[event_name] = observers
end

-- The global_source is a special source that notifies all registered
-- observers of global events which are not tied to a specific source.
--
-- A list of potential global events can be found below.
local global_source = M.Source()

-- register adds observer to the global event source.
function M.register(event_name, observer)
    global_source:register(event_name, observer)
end

-- notify_all notifies all observers registered with the global event
-- source of an event.
function M.notify_all(event_name, ...)
    global_source:notify_all(event_name, ...)
end

-- add_autocmd adds an auto command that calls observer when it occurs.
function M.add_autocmd(autocmd_name, observer, opts)
    -- Checks if pred is true before calling f.
    --
    -- Wrapping observer using an anonymous function leads to endless recursion.
    -- Using check_pred avoids this.
    local check_pred = function(f, pred)
        return function(event_name, ...)
            if not pred(event_name, ...) then
                return true
            end
            return f(event_name, ...)
        end
    end

    local cmd_str = "autocmd " .. autocmd_name
    local arg_str = "'" .. autocmd_name .. "'"

    if opts and opts.buffer then
        cmd_str = string.format("%s <buffer=%d>", cmd_str, opts.buffer)
        arg_str = string.format("%s, %d", arg_str, opts.buffer)
        observer = check_pred(observer, function(event_name, bufnr)
            return opts.buffer == bufnr
        end)
    end

    M.register(autocmd_name, observer)

    cmd_str = cmd_str .. string.format(" lua require('termmaker.event').notify_all(%s)", arg_str)
    vim.api.nvim_command(cmd_str)
end

return M
