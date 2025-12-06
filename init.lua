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
      local actions = require("telescope.actions")
      require("telescope").setup{
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
            },
          },
        },
      }
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
      
      -- SPC s p: Search project with file extension filtering
      -- Usage: something#.ts (include .ts) or something#!.test.ts (exclude .test.ts)
      -- Composable: something#.ts#!.test.ts (include .ts, exclude .test.ts)
      vim.keymap.set("n", "<leader>sp", function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local make_entry = require("telescope.make_entry")
        
        pickers.new({}, {
          prompt_title = "Live Grep (# for filters)",
          finder = finders.new_job(function(prompt)
            if not prompt or prompt == "" then
              return nil
            end
            
            local search_term = prompt
            local args = { "rg", "--color=never", "--no-heading", "--with-filename", 
                          "--line-number", "--column", "--smart-case" }
            
            -- Extract and process filter patterns
            for pattern in prompt:gmatch("#([^#]+)") do
              if pattern:match("^!") then
                -- Exclude pattern: #!.test.ts
                table.insert(args, "--glob=!" .. pattern:sub(2))
              else
                -- Include pattern: #.ts
                table.insert(args, "--glob=*" .. pattern)
              end
              search_term = search_term:gsub("#" .. vim.pesc(pattern), "")
            end
            
            search_term = search_term:gsub("^%s+", ""):gsub("%s+$", "")
            if search_term == "" then
              return nil
            end
            
            table.insert(args, "--")
            table.insert(args, search_term)
            
            return args
          end, make_entry.gen_from_vimgrep({}), nil, nil),
          sorter = conf.generic_sorter({}),
          previewer = conf.grep_previewer({}),
          attach_mappings = function(_, map)
            map("i", "<C-j>", actions.move_selection_next)
            map("i", "<C-k>", actions.move_selection_previous)
            return true
          end,
        }):find()
      end, { desc = "Search project (grep with filters)" })
    end,
  },

  -- Neovim icons: Required for better UI in Neogit and Telescope
  { "nvim-tree/nvim-web-devicons" },

  -- One Dark theme
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    config = function()
      require("onedark").setup({
        style = "dark",
      })
      require("onedark").load()
    end,
  },

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
      
      -- Fix Neogit diff colors for better readability
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "NeogitStatus",
        callback = function()
          vim.cmd([[
            highlight NeogitDiffAdd guifg=#a6e3a1 guibg=NONE
            highlight NeogitDiffDelete guifg=#f38ba8 guibg=NONE
            highlight NeogitDiffContext guifg=#cdd6f4 guibg=NONE
            highlight NeogitHunkHeader guifg=#89b4fa guibg=#313244
            highlight NeogitHunkHeaderHighlight guifg=#89b4fa guibg=#45475a
          ]])
        end,
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- TypeScript/JavaScript language server
      vim.lsp.config("ts_ls", {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
      })
      vim.lsp.enable("ts_ls")
      
      -- LSP keybindings
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
      vim.keymap.set("n", "gf", vim.lsp.buf.references, { desc = "Find references" })
      vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename symbol" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
    end,
  },

  -- Dired: File manager inspired by Emacs Dired
  {
    "X3eRo0/dired.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("dired").setup({
        path_separator = "/",
        show_hidden = true,
        show_icons = true,
        show_banner = false,
        show_colors = true,
        keybinds = {
          dired_enter = "l",
          dired_back = "h",
          dired_up = "_",
          dired_rename = "R",
          dired_create = "d",
          dired_delete = "D",
          dired_delete_range = "D",
          dired_copy = "C",
          dired_copy_range = "C",
          dired_copy_marked = "MC",
          dired_move = "X",
          dired_move_range = "X",
          dired_move_marked = "MX",
          dired_paste = "P",
          dired_mark = "M",
          dired_mark_range = "M",
          dired_delete_marked = "MD",
          dired_shell_cmd = "!",
          dired_shell_cmd_marked = "&",
          dired_toggle_hidden = ".",
          dired_toggle_sort_order = ",",
          dired_toggle_icons = "*",
          dired_toggle_colors = "c",
          dired_toggle_hide_details = "(",
          dired_quit = "q",
        },
      })
      vim.keymap.set("n", "<leader>d", ":Dired<CR>", { desc = "Open Dired" })
      vim.keymap.set("n", "-", ":Dired<CR>", { desc = "Open Dired" })
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

-- Window navigation keybindings
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Move to window below" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Move to window above" })
vim.keymap.set("n", "<leader>wd", "<C-w>q", { desc = "Close window" })
vim.keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>ws", "<C-w>s", { desc = "Horizontal split" })

-- Auto-change to git root directory
local function change_to_git_root()
  local current_file = vim.fn.expand("%:p:h")
  if current_file == "" then
    return
  end
  
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(current_file) .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root ~= "" then
    vim.cmd("cd " .. vim.fn.fnameescape(git_root))
  end
end

vim.api.nvim_create_autocmd({"BufEnter"}, {
  callback = change_to_git_root,
})
