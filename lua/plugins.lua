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
      -- Everforest options must be set before :colorscheme
      vim.g.everforest_better_performance = 1
      vim.g.everforest_dim_inactive_windows = 1
      vim.g.everforest_sign_column_background = 'linenr'
      -- Contrast: use medium for both light and dark
      vim.g.everforest_background = 'medium'

      local function apply_everforest_highlights()
        local ok_cfg, cfg = pcall(vim.fn["everforest#get_configuration"])
        if not ok_cfg then return end
        local palette = vim.fn["everforest#get_palette"](cfg.background, cfg.colors_override)
        local set_hl = vim.fn["everforest#highlight"]

        -- Increase contrast for split separators so horizontal lines are visible
        set_hl('WinSeparator', palette.yellow, palette.bg1)
        set_hl('StatusLine', palette.fg, palette.bg_blue)
        set_hl('StatusLineNC', palette.fg, palette.bg1)
        set_hl('DiagnosticOk', palette.green, palette.none)
        set_hl('NormalFloat', palette.none, palette.bg1)
        set_hl('FloatBorder', palette.yellow, palette.bg1)
        -- Make inactive windows slightly lighter than bg_dim so they don't look heavy
        set_hl('NormalNC', palette.fg, palette.bg1)
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

      -- Everforest-friendly conflict colors using the live palette
      local function apply_git_conflict_highlights()
        local ok_cfg, cfg = pcall(vim.fn["everforest#get_configuration"])
        if not ok_cfg then return end
        local palette = vim.fn["everforest#get_palette"](cfg.background, cfg.colors_override)
        local set_hl = vim.fn["everforest#highlight"]

        -- Use themed tints for current/incoming backgrounds
        set_hl('GitConflictCurrent', palette.none, palette.bg_green)
        set_hl('GitConflictCurrentLabel', palette.none, palette.bg2)
        set_hl('GitConflictIncoming', palette.none, palette.bg_blue)
        set_hl('GitConflictIncomingLabel', palette.none, palette.bg2)
      end

      apply_git_conflict_highlights()
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'everforest',
        callback = apply_git_conflict_highlights,
      })
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
        preview_config = {
          border = "single",
          style = 'minimal',
          relative = 'cursor',
          row = 1,
          col = 1,
        },
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
