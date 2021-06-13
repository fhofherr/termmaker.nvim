-- Usage: nvim -u test/manual/minimal_init.lua

-- Add the current working directory to the runtime path.
-- This way the termmaker plugin can be used without installing it.
vim.cmd("set rtp+=.")

-- Set hidden ... otherwise toggling terminals will not work.
vim.o.hidden = true

-- Create a test terminal which can be accessed using :lua test_term
window = require("termmaker.window")
_G.test_term = require("termmaker.terminal").Terminal({
    window_factory = window.factory.new_window
})
