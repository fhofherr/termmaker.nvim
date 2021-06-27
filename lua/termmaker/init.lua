local M = {}

local terminal = require("termmaker.terminal")
local default_terminal = terminal.Terminal()

function M.toggle()
    default_terminal:toggle()
end

function M.setup(opts)
    if opts.default_terminal then
        default_terminal = terminal.Terminal(opts.default_terminal)
    end
    vim.api.nvim_command("command! TermMakerToggle lua require('termmaker').toggle()<CR>")
end

return M
