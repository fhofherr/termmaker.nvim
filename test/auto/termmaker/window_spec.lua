local buffer = require("termmaker.buffer")
local window = require("termmaker.window")

describe("factory", function()
    local cur_winid

    before_each(function() cur_winid = vim.api.nvim_get_current_win() end)

    describe("#current_window", function()
        it("creates a wrapper for the current window", function()
            local win = window.factory.current_window()

            assert.is.equal(cur_winid, win._winid)
        end)
    end)

    describe("#new_window", function()
        it("uses :new to create a new window", function()
            local win = window.factory.new_window()

            assert.is_not.equal(cur_winid, win._winid)
            assert.is_true(win:is_valid())
        end)

        it("allows to pass an optional modifier", function()
            local win = window.factory.new_window({modifier = "belowright"})

            assert.is_not.equal(cur_winid, win._winid)
            assert.is_true(win:is_valid())

            vim.api.nvim_set_current_win(cur_winid)
            vim.api.nvim_command("wincmd j")
            assert.is_true(win:is_current())
        end)
    end)
end)

describe("Window", function()
    local win, initial_winid

    before_each(function()
        initial_winid = vim.api.nvim_get_current_win()
        win = window.Window(initial_winid)
    end)

    after_each(function() win:restore() end)

    it("wraps the current neovim window", function()
        assert.is.equal(initial_winid, win._winid)
    end)

    describe("#is_current", function()
        it("returns true if the window is the current one", function()
            assert.is_true(win:is_current())
        end)
    end)

    describe("#set_opts", function()
        it("modifies the window options", function()
            local number_val = not vim.api.nvim_win_get_option(initial_winid, "number")
            local relativenumber_val = not vim.api.nvim_win_get_option(initial_winid, "relativenumber")

            win:set_opts({
                number = number_val,
                relativenumber = relativenumber_val,
            })

            assert.is.equal(number_val, vim.api.nvim_win_get_option(initial_winid, "number"))
            assert.is.equal(relativenumber_val, vim.api.nvim_win_get_option(initial_winid, "relativenumber"))
        end)
    end)

    describe("#restore", function()
        it("restores the window's previous buffer", function()
            local cur_bufnr = vim.api.nvim_get_current_buf()
            local buf = buffer.Buffer()

            win:set_buf(buf:get_bufnr())
            win:restore()

            assert.is.equal(cur_bufnr, vim.api.nvim_win_get_buf(win._winid))
        end)

        it("restores any changed window options", function()
            local val = vim.api.nvim_win_get_option(win._winid, "number")

            win:set_opts({ number = not val })
            win:restore()

            assert.is.equal(val, vim.api.nvim_win_get_option(win._winid, "number"))
        end)
    end)

    describe("#jump", function()
        it("jumps to the window on the same tab page", function()
            vim.api.nvim_command("split")
            local other_winid = vim.api.nvim_get_current_win()

            assert.is_not.equal(initial_winid, other_winid)
            win:jump()
            assert.is.equal(initial_winid, vim.api.nvim_get_current_win())

            vim.api.nvim_win_close(other_winid, true)
        end)

        it("jumps to the window on another tab page", function()
            local initial_tab_page = vim.api.nvim_get_current_tabpage()

            vim.api.nvim_command("tabnew")
            local other_tab_page = vim.api.nvim_get_current_tabpage()
            local other_winid = vim.api.nvim_get_current_win()

            assert.is_not.equal(initial_tab_page, other_tab_page)
            assert.is_not.equal(initial_winid, other_winid)

            win:jump()

            assert.is.equal(initial_tab_page, vim.api.nvim_get_current_tabpage())
            assert.is.equal(initial_winid, vim.api.nvim_get_current_win())

            vim.api.nvim_win_close(other_winid, true)
            -- The other tab page should be gone. This is not really relevant
            -- for the test, but I want to know if my assumption turns out to
            -- be wrong.
            assert.is.equal(1, #vim.api.nvim_list_tabpages())
        end)
    end)
end)
