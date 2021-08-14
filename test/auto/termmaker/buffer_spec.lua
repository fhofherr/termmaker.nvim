local buffer = require("termmaker.buffer")

describe("Buffer", function()
    local buf

    before_each(function()
        buf = buffer.Buffer()
    end)
    after_each(function()
        buf:kill()
    end)

    it("represents a neovim buffer", function()
        assert.is_true(vim.api.nvim_buf_is_valid(buf:get_bufnr()))
        assert.is_true(buf:is_valid())
    end)

    describe("#kill", function()
        it("deletes the buffer", function()
            assert.is_true(buf:is_valid())
            buf:kill()
            assert.is_false(buf:is_valid())
        end)
    end)
end)
