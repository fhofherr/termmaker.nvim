local terminal = require("termmaker.terminal")
local window = require("termmaker.window")

describe("Terminal", function()
    local term

    before_each(function()
        term = terminal.Terminal()
    end)

    after_each(function()
        term:kill()
    end)

    it("is initially hidden", function()
        assert.is_nil(term._win)
    end)

    it("has no buffer assgined", function()
        assert.is_nil(term._buf)
    end)

    it("has no terminal job assigned initially", function()
        assert.is.equal(0, term._job_id)
    end)

    it("uses current_window as its default window factory", function()
        assert.is.equal(window.factory.current_window, term._window_factory)
    end)

    describe("#open", function()
        it("initializes a new buffer", function()
            term:open()
            assert.is.not_nil(term._buf)
        end)

        it("initializes and jumps to a new window", function()
            term:open()
            assert.is.not_nil(term._win)
            assert.is_true(term._win:is_current())

            assert.is_false(vim.api.nvim_win_get_option(term._win._winid, "winfixheight"))
            assert.is_false(vim.api.nvim_win_get_option(term._win._winid, "number"))
            assert.is_false(vim.api.nvim_win_get_option(term._win._winid, "relativenumber"))
        end)

        it("creates a new terminal job", function()
            term:open()
            assert.is_true(term._job_id > 0)
        end)

        it("adds a call to #close on BufWinLeave", function()
            term:open()
            term._buf._autocmds.BufWinLeave[1]()
            assert.is_nil(term._win)
        end)
    end)

    describe("#close", function()
        it("hides the terminal", function()
            term:open()
            term:close()
            assert.is_nil(term._win)
        end)
    end)

    describe("#toggle", function()
        it("opens the terminal if it is closed", function()
            term:close()
            term:toggle()

            assert.is.not_nil(term._win)
        end)

        it("closes the terminal if it is open", function()
            term:open()
            term:toggle()

            assert.is_nil(term._win)
        end)
    end)
end)
