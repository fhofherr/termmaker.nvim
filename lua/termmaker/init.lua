local M = {}

local terminal = require("termmaker.terminal")
local window = require("termmaker.window")

local default_opts = {
    buffer_opts = {
        filetype = terminal.filetype,
    },
    window_opts = {
        window_factory = window.auto_split()
    }
}
local default_terminal = terminal.Terminal(default_opts)

-- toggle the default terminal on or off
function M.toggle()
    default_terminal:toggle()
end

-- setup configures the default terminal
function M.setup(opts)
    opts = vim.tbl_extend("keep", opts or {}, default_opts)

    -- Overwrite default terminal with a new one based on opts
    default_terminal = terminal.Terminal(opts)
    vim.api.nvim_command("command! TermMakerToggle lua require('termmaker').toggle()<CR>")
end

return M
