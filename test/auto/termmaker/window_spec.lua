local buffer = require("termmaker.buffer")
local window = require("termmaker.window")

describe("Window", function()
    local wo_number
    local win
    local initial_winid

    before_each(function()
        initial_winid = vim.api.nvim_get_current_win()
        wo_number = vim.api.nvim_win_get_option(initial_winid, "number")
        win = window.Window({
            window_options = {
                number = not wo_number
            }
        })
    end)

    after_each(function() win:restore() end)

    it("wraps the current neovim window by default", function()
        local win = window.Window()
        assert.is.equal(initial_winid, win._winid)
    end)

    describe("#is_current", function()
        it("returns true if the window is the current one", function()
            assert.is_true(win:is_current())
        end)
    end)

    describe("#restore", function()
        it("restores the window's previous buffer", function()
            local cur_bufnr = vim.api.nvim_get_current_buf()
            local buf = buffer.Buffer()

            win:show_buffer(buf)
            win:restore()

            assert.is.equal(cur_bufnr, vim.api.nvim_win_get_buf(win._winid))
        end)

        it("restores any changed window options", function()
            win:restore()
            assert.is.equal(wo_number, vim.api.nvim_win_get_option(win._winid, "number"))
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
