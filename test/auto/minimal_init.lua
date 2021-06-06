local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
  vim.api.nvim_command('packadd packer.nvim')
end

vim.cmd("packadd packer.nvim")

local packer = require("packer")
packer.init({
    display = { non_interactive = true }
})
packer.startup(function(use)
    use "nvim-lua/plenary.nvim"
end)

vim.cmd("set rtp+=.")

-- The hidden option is required for termmaker to work
vim.o.hidden = true
