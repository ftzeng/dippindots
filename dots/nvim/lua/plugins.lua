-- Automatically install Lazy plugin manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },
    },
  },

  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lsp-signature-help',
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip'
    },
  },

  { -- Debugging, breakpoints, etc
    -- sudo apt install lldb
    'mfussenegger/nvim-dap',
    dependencies = {
        'rcarriga/nvim-dap-ui',
    }
  },

  { -- Testing
    'nvim-neotest/neotest',
    dependencies = {
        'rouge8/neotest-rust',
        'nvim-neotest/neotest-python',
    }
  },

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' } },

  -- Build fzf; requires `make`
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
    cond = function()
      return vim.fn.executable 'make' == 1
    end,
  },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
  },

  -- "gc" to comment visual regions
  -- "gcc" to comment line
  { 'numToStr/Comment.nvim', opts = {} },

  -- Faster movement
  { 'phaazon/hop.nvim', opts = {} },

  -- Better text objects/motions
  { 'kylechui/nvim-surround', opts = {} },
  { 'wellle/targets.vim' },

  -- File navigation
  { 'stevearc/oil.nvim', },

  -- Colorscheming
  { 'rktjmp/lush.nvim', },
  {
	'nvim-treesitter/playground',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },
  {
	'frnsys/futora',
	dev = true,
  	lazy = false,
	priority=1000,
	dependencies = {
      "rktjmp/lush.nvim",
	},
  },
}, {})

vim.opt.termguicolors = true
vim.cmd('colorscheme futora')