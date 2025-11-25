-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Plugin setup
require("lazy").setup({
  -- Plenary: Required by Telescope and Neogit
  { "nvim-lua/plenary.nvim" },

  -- Telescope: Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup{}
      local builtin = require("telescope.builtin")
      
      -- SPC SPC: Global file search
      vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "Find files (global)" })
      
      -- SPC f f: Find sibling files (prefill current directory)
      vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({
          default_text = vim.fn.expand("%:h") .. "/",
        })
      end, { desc = "Find files (current dir)" })
      
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
    end,
  },

  -- Neovim icons: Required for better UI in Neogit and Telescope
  { "nvim-tree/nvim-web-devicons" },

  -- Diffview: Recommended for Neogit diffs
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Neogit: Git interface
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local neogit = require("neogit")
      neogit.setup({
        integrations = {
          telescope = true,
          diffview = true,
        },
      })
      vim.keymap.set("n", "<leader>gg", neogit.open, { desc = "Open Neogit" })
      vim.keymap.set("n", "<leader>gc", ":Neogit commit<CR>", { desc = "Neogit commit" })
    end,
  },
})

-- Basic editor settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.autochdir = true
