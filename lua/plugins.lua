local colors = require('theme').colors

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = vim.fn.executable('make') == 1,
      },
      'nvim-telescope/telescope-live-grep-args.nvim',
    },
    config = function()
      local telescope = require('telescope')
      telescope.setup({
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      pcall(telescope.load_extension, 'fzf')
      pcall(telescope.load_extension, 'live_grep_args')
    end,
  },


  {
    'sainnhe/everforest',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.everforest_better_performance = 1

      local function apply_everforest_highlights()
        vim.api.nvim_set_hl(0, 'WinSeparator', { fg = colors.yellow, bg = 'NONE' })
        vim.api.nvim_set_hl(0, 'StatusLine', { fg = colors.fg, bg = colors.bg_blue })
        vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = colors.fg, bg = colors.bg1 })
        vim.api.nvim_set_hl(0, 'DiagnosticOk', { fg = colors.green, bg = 'NONE' })
      end

      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'everforest',
        callback = apply_everforest_highlights,
      })

      vim.cmd('colorscheme everforest')
      apply_everforest_highlights()
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, treesitter = pcall(require, 'nvim-treesitter.configs')
      if ok then
        treesitter.setup({
          ensure_installed = { "ruby", "lua", "vim", "vimdoc", "rust", "javascript", "typescript" },
          auto_install = true,
          highlight = {
            enable = true,
          },
          indent = {
            enable = true,
          },
        })
      end
    end,
  },

  {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = function()
      require('git-conflict').setup({
        default_mappings = true,
        highlights = {
          incoming = 'DiffAdd',
          current = 'DiffText',
        },
      })
      -- Everforest-friendly conflict colors
      vim.api.nvim_set_hl(0, 'GitConflictCurrent', { bg = colors.git_current })
      vim.api.nvim_set_hl(0, 'GitConflictCurrentLabel', { bg = colors.git_current_label })
      vim.api.nvim_set_hl(0, 'GitConflictIncoming', { bg = colors.git_incoming })
      vim.api.nvim_set_hl(0, 'GitConflictIncomingLabel', { bg = colors.git_incoming_label })
    end,
  },

  {
    'dmtrKovalenko/fff.nvim',
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    config = function()
      require('fff').setup({
        prompt = '> ',
        max_results = 100,
        preview = { enabled = true },
        git = { status_text_color = true },
      })
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup({
        on_attach = function(bufnr)
          local gitsigns = require('gitsigns')

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then
              vim.cmd.normal({']c', bang = true})
            else
              gitsigns.nav_hunk('next')
            end
          end)

          map('n', '[c', function()
            if vim.wo.diff then
              vim.cmd.normal({'[c', bang = true})
            else
              gitsigns.nav_hunk('prev')
            end
          end)

          map('n', '<leader>hb', function()
            gitsigns.blame_line({ full = true })
          end)

          map('n', '<leader>hd', gitsigns.diffthis)
        end
      })
    end,
  },
}
