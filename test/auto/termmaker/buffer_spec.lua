local buffer = require("termmaker.buffer")

describe("#autocmd", function()
    local buf

    before_each(function() buf = buffer.Buffer() end)
    after_each(function() buf:kill() end)

    it("executes the named autocmds for the buffer", function()
        local called = false
        local f = function() called = true end

        buf:add_autocmd("BufWinEnter", f)
        buffer.autocmd(buf:get_bufnr(), "BufWinEnter")
        assert.is_true(called)
    end)
end)

describe("#is_registered", function()
    local buf

    before_each(function() buf = buffer.Buffer() end)
    after_each(function() buf:kill() end)

    it("returns true if the buffer is known to the module", function()
        assert.is_true(buffer.is_registered(buf))
        assert.is_true(buffer.is_registered(buf:get_bufnr()))
        buf:kill()
    end)

    it("returns false if the buffer is not known", function()
        assert.is_false(buffer.is_registered(nil))
        assert.is_false(buffer.is_registered(0))
        assert.is_false(buffer.is_registered(65536))
    end)

    it("returns false if the buffer was already deregistered", function()
        buf:_deregister()
        assert.is_false(buffer.is_registered(buf))
    end)
end)

describe("Buffer", function()
    local buf

    before_each(function() buf = buffer.Buffer() end)
    after_each(function() buf:kill() end)

    it("represents a neovim buffer", function()
        assert.is_true(vim.api.nvim_buf_is_valid(buf:get_bufnr()))
        assert.is_true(buf:is_valid())
        assert.is_true(buffer.is_registered(buf))
        assert.is_true(buffer.is_registered(buf:get_bufnr()))
    end)

    it("adds an autcmd to deregister the buffer on wipeout", function()
        local cmds = buf._autocmds.BufWipeout
        assert.is.equal(1, #cmds)

        cmds[1]()
        assert.is_false(buffer.is_registered(buf))
    end)

    describe("#add_autocmd", function()
        it("adds autocommands by name", function()
            local called = false
            local f = function()
                called = true
            end
            buf:add_autocmd("BufWinEnter", f)

            assert.is.equal(1, #buf._autocmds.BufWinEnter)
            buf._autocmds.BufWinEnter[1]()
            assert.is_true(called)
        end)
    end)

    describe("#kill", function()
        it("deletes the buffer", function()
            assert.is_true(buf:is_valid())
            buf:kill()
            assert.is_false(buf:is_valid())
            assert.is_false(buffer.is_registered(buf))
        end)
    end)
end)
