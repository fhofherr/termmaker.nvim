-- Usage: nvim -u test/manual/minimal_init.lua

-- Add the current working directory to the runtime path.
-- This way the termmaker plugin can be used without installing it.
vim.cmd("set rtp+=.")

-- Set hidden ... otherwise toggling terminals will not work.
vim.o.hidden = true

require("termmaker").setup()
