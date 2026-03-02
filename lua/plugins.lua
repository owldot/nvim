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
    end,
  },


  {
    'sainnhe/everforest',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.everforest_better_performance = 1

      local function apply_everforest_highlights()
        -- Increase contrast for split separators so horizontal lines are visible
        -- Use theme background instead of NONE to avoid blending
        vim.api.nvim_set_hl(0, 'WinSeparator', { fg = colors.yellow, bg = colors.bg1 })
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
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    build = ":TSUpdate",
    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = { lookahead = true },
      })
      local select = require('nvim-treesitter-textobjects.select')
      local keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
      }
      for keymap, query in pairs(keymaps) do
        vim.keymap.set({ "x", "o" }, keymap, function()
          select.select_textobject(query)
        end)
      end
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    config = function()
      require'treesitter-context'.setup({
        enable = true,
        multiwindow = false,
        max_lines = 2,
        min_window_height = 0,
        line_numbers = true,
        multiline_threshold = 1,
        trim_scope = 'outer',
        mode = 'cursor',
        separator = nil,
        zindex = 20,
        on_attach = function(bufnr)
          vim.keymap.set('n', ']f',  function()
            require("treesitter-context").go_to_context(vim.v.count1)
          end)
        end
      })
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
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon add" })
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu" })

      vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Harpoon 1" })
      vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Harpoon 2" })
      vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Harpoon 3" })
      vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Harpoon 4" })
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
          map('n', '[g', function()
            if vim.wo.diff then
              vim.cmd.normal({']c', bang = true})
            else
              gitsigns.nav_hunk('next')
            end
          end, { desc = 'Next hunk' })

          map('n', '<leader>gb', function()
            gitsigns.blame_line({ full = true })
          end, { desc = 'Blame line' })

          map('n', '<leader>gd', function()
            local orig_win = vim.api.nvim_get_current_win()
            gitsigns.diffthis()
            vim.schedule(function()
              local new_win = vim.api.nvim_get_current_win()
              -- If gitsigns left us in the original, switch to the diff split
              if new_win == orig_win then
                vim.cmd('wincmd p')
              end
              -- When this diff window closes, turn off diff on the original
              vim.api.nvim_create_autocmd('WinClosed', {
                once = true,
                pattern = tostring(vim.api.nvim_get_current_win()),
                callback = function()
                  if vim.api.nvim_win_is_valid(orig_win) then
                    vim.api.nvim_win_call(orig_win, function()
                      vim.cmd('diffoff')
                    end)
                  end
                end,
              })
            end)
          end, { desc = 'Diff this' })

          map('n', '<leader>ga', gitsigns.stage_hunk, { desc = 'Stage hunk' })
        end
      })
    end,
  },
}
