return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
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
      local actions = require('telescope.actions')

      telescope.setup({
        defaults = {
          preview = {
            line_number = true,
          },

          mappings = {
            i = {
              ["<Leader>q"] = function(bufnr)
                actions.send_to_qflist(bufnr)
                actions.open_qflist(bufnr)
              end,
            },
            n = {
              ["<Leader>q"] = function(bufnr)
                actions.send_to_qflist(bufnr)
                actions.open_qflist(bufnr)
              end,
            },
          },
        },

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
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('spectre').setup({
        mapping = {
          close = {
            map = 'q',
            cmd = "<cmd>lua require('spectre').close()<CR>",
            desc = 'Close Spectre',
          },
        },
      })
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
        -- Winbar: match statusline bg, underline for bottom border
        set_hl('WinBar', palette.fg, palette.bg_blue)
        set_hl('WinBarNC', palette.fg, palette.bg1)
        set_hl('NormalNC', palette.fg, palette.bg3)
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
    'stevearc/oil.nvim',
    config = function()
      require('oil').setup({
        default_file_explorer = true,
        view_options = {
          show_hidden = true,
        },
      })
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
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

          -- Navigation (target = 'all' so staged hunks are included too)
          map('n', '[g', function()
            if vim.wo.diff then
              vim.cmd.normal({']c', bang = true})
            else
              gitsigns.nav_hunk('next', { target = 'all' })
            end
          end, { desc = 'Next hunk' })

          map('n', ']g', function()
            if vim.wo.diff then
              vim.cmd.normal({'[c', bang = true})
            else
              gitsigns.nav_hunk('prev', { target = 'all' })
            end
          end, { desc = 'Previous hunk' })

          map('n', '<leader>gb', function()
            gitsigns.blame_line({ full = true })
          end, { desc = 'Blame line' })

          map('n', '<leader>gd', function()
            local orig_win = vim.api.nvim_get_current_win()
            local before = vim.api.nvim_tabpage_list_wins(0)
            gitsigns.diffthis()
            vim.schedule(function()
              -- the diff window is whichever one didn't exist before
              local diff_win
              for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if not vim.tbl_contains(before, w) then
                  diff_win = w
                  break
                end
              end
              if not diff_win then return end

              vim.api.nvim_set_current_win(diff_win)

              -- q closes the diff scratch buffer
              vim.keymap.set('n', 'q', '<cmd>close<cr>',
                { buffer = vim.api.nvim_win_get_buf(diff_win), nowait = true })

              -- when the diff window closes, drop diff mode on the original
              vim.api.nvim_create_autocmd('WinClosed', {
                once = true,
                pattern = tostring(diff_win),
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

          map({ 'n', 'v' }, '<leader>ga', gitsigns.stage_hunk, { desc = 'Stage/unstage hunk' })
          map('n', '<leader>gg', function()
            local hunks = gitsigns.get_hunks(bufnr)
            if hunks and #hunks > 0 then
              gitsigns.stage_buffer()       -- unstaged hunks exist -> stage them all
            else
              gitsigns.reset_buffer_index() -- nothing left unstaged -> unstage buffer
            end
          end, { desc = 'Stage/unstage whole buffer' })

          -- Hunks (diffs) -> quickfix
          map('n', '<leader>gq', gitsigns.setqflist, { desc = 'Buffer hunks to quickfix' })
          map('n', '<leader>gQ', function() gitsigns.setqflist('all') end, { desc = 'All repo hunks to quickfix' })

          -- Reset (discard) changes
          map({ 'n', 'v' }, '<leader>gx', gitsigns.reset_hunk, { desc = 'Reset (discard) hunk' })
          map('n', '<leader>gX', gitsigns.reset_buffer, { desc = 'Reset (discard) whole buffer' })
        end
      })
    end,
  },

  {
    "lanadz/pinterm.nvim",
    cmd = { "Pt", "Ptn", "Ptr" },
    config = function()
      require("pinterm").setup()
    end,
  },

  {
    "lanadz/vimseq",
    config = function()
      require("vimseq").setup({
        -- vimseq expects the Logseq graph root; journals live under journals_dir.
        graph_dir = "~/logseq",
        journals_dir = "journals",
      })

      vim.api.nvim_create_user_command("VT", function()
        vim.cmd.VimseqToday()
      end, { desc = "Alias for VimseqToday" })

      vim.api.nvim_create_user_command("VST", function(args)
        require("vimseq.search").tag(args.args)
      end, { nargs = "+", desc = "Alias for VimseqSearchByTag" })
    end,
  },
}
