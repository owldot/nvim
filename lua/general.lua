local colors = require('theme').colors

-- Colors
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"

vim.api.nvim_create_user_command('SchemeToggle', function()
  vim.o.background = (vim.o.background == 'dark') and 'light' or 'dark'
  vim.cmd.colorscheme('everforest')
  print('Scheme → ' .. vim.o.background)
end, {})

-- Clipboard
vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<leader>cf", ":let @+ = expand(\"%\")<CR>")

-- Mouse
vim.opt.mouse = "a"

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Highlight current line
vim.opt.cursorline = true

-- Invisible chars
vim.opt.list = true
vim.opt.listchars = {
  tab = "→ ",
  trail = "·",
  nbsp = "␣",
}

-- Indentation
vim.opt.fixendofline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.wrap = false
-- System
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- Status line
vim.opt.laststatus = 2
vim.opt.showmode = false  -- Hide default mode indicator

vim.opt.hlsearch = false
vim.opt.incsearch = true

_G.stl_git = function()
  local head = vim.b.gitsigns_head
  if head and head ~= ".invalid" then
    return " " .. head
  end
  local root = vim.fs.root(0, ".git")
  if not root then return "" end
  local branch = vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " branch --show-current 2>/dev/null"):gsub("\n", "")
  if branch ~= "" then return " " .. branch end
  return ""
end

_G.stl_mode = function()
  local modes = {
    n = "NORMAL",
    i = "INSERT",
    v = "VISUAL",
    V = "V-LINE",
    ["\22"] = "V-BLOCK",
    c = "COMMAND",
    R = "REPLACE",
    t = "TERMINAL",
  }
  return " " .. (modes[vim.fn.mode()] or "UNKNOWN") .. " "
end

_G.stl_lsp = function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end

  local status = vim.lsp.status()
  if status and status ~= "" and not status:find("%.invalid") then
    return " " .. status .. " "
  end

  local names = {}
  for _, c in ipairs(clients) do
    names[#names + 1] = c.name
  end
  return " [" .. table.concat(names, ",") .. "] "
end

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function()
    vim.cmd.redrawstatus()
  end,
})

vim.o.statusline = table.concat({
  "%#StatusLineMode#",
  "%{v:lua.stl_mode()}",   -- mode indicator with dynamic highlight
  "%*",
  " %<%f",                  -- file path (truncate here if needed)
  " %m",                    -- [+] if modified
  " %r",                    -- [RO] if readonly
  " %=",                    -- split left/right
  " %{v:lua.stl_git()}",    -- git branch
  "  %y",                   -- filetype
  " %{v:lua.stl_lsp()}", -- LSP status
  "%#StatusLineLC#",
  "  %l:%c",                -- line:col (mode color)
  "  %p%% ",                -- percent through file (mode color)
  "%*",
})

local statusline_mode_colors = {
  n = colors.bg_green,
  i = colors.yellow,
  v = colors.bg_visual,
  V = colors.bg_visual,
  ['\22'] = colors.bg_visual,
  c = colors.bg_green,
}

local statusline_mode_fg = {
  n = colors.fg,
  v = colors.fg,
  V = colors.fg,
  ['\22'] = colors.fg,
  c = colors.fg,
}

local function set_statusline_section_highlight(mode)
  local color = statusline_mode_colors[mode] or statusline_mode_colors.n
  local fg = statusline_mode_fg[mode] or colors.bg0
  for _, group in ipairs({ 'StatusLineMode', 'StatusLineLC' }) do
    vim.api.nvim_set_hl(0, group, { fg = fg, bg = color })
  end
end

set_statusline_section_highlight(vim.fn.mode():sub(1, 1))

vim.api.nvim_create_autocmd('ModeChanged', {
  callback = function()
    set_statusline_section_highlight(vim.fn.mode():sub(1, 1))
  end,
})

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    set_statusline_section_highlight(vim.fn.mode():sub(1, 1))
  end,
})

-- Command line completion
vim.opt.wildmenu = true
vim.opt.wildmode = { "longest", "list", "full" }

-- Insert mode completion UI (builtin PUM)
vim.o.completeopt = "menu,menuone,noselect"
-- Add ",popup" if on Neovim 0.10+ for floating PUM
pcall(function()
  if vim.fn.has("nvim-0.10") == 1 then
    vim.o.completeopt = vim.o.completeopt .. ",popup"
    -- optional sizing tweaks (0.10+)
    vim.o.pumheight = 8
    vim.o.pummaxwidth = 80
  end
end)
vim.opt.shortmess:append("c")

-- Session management - only save visible windows/files
vim.opt.sessionoptions = {
  "curdir",    -- current directory
  "tabpages",  -- all tab pages and their windows
  "winsize",   -- window sizes
}


-- Keymaps
vim.keymap.set("v", "<leader>p", "\"_dP") -- don't replace the register
vim.keymap.set("n", "<leader>d", "\"_d") -- don't replace the register
vim.keymap.set("v", "<leader>d", "\"_d") -- don't replace the register

vim.keymap.set("n", "<leader>o", ":Ex<CR>", { silent = true })

vim.keymap.set("n", "[b", ":bp<CR>", { silent = true })
vim.keymap.set("n", "]b", ":bn<CR>", { silent = true })

-- Move lines
vim.keymap.set("n", "<A-Down>", ":move .+1<CR>==", { silent = true })
vim.keymap.set("n", "<A-Up>", ":move .-2<CR>==", { silent = true })
vim.keymap.set("v", "<A-Down>", ":move '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "<A-Up>", ":move '<-2<CR>gv=gv", { silent = true })

-- Center on scroll
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Clear highlight
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>")

-- Exit terminal mode
vim.keymap.set('t', '<C-w>h', "<C-\\><C-n><C-w>h",{silent = true})
vim.keymap.set('t', '<C-w>j', "<C-\\><C-n><C-w>j",{silent = true})
vim.keymap.set('t', '<C-w>k', "<C-\\><C-n><C-w>k",{silent = true})
vim.keymap.set('t', '<C-w>l', "<C-\\><C-n><C-w>l",{silent = true})
vim.keymap.set('t', '<C-w>w', "<C-\\><C-n><C-w>w",{silent = true})
vim.keymap.set('t', '<C-w><C-w>', "<C-\\><C-n><C-w><C-w>",{silent = true})

-- Remap esc
vim.keymap.set('i', 'jk', '<Esc>')
vim.api.nvim_create_user_command('W', 'w', {})
vim.api.nvim_create_user_command('Q', 'q', {})
vim.api.nvim_create_user_command('Wq', 'wq', {})
vim.api.nvim_create_user_command('WQ', 'wq', {})

-- fff.nvim (fast file finder)
vim.keymap.set("n", "<leader>ff", function() require('fff').find_files() end, { desc = "Find files (fff)" })
vim.keymap.set("n", "<leader>fF", function() require('fff').find_in_git_root() end, { desc = "Find files in git root (fff)" })

-- Telescope (grep, buffers, help)
local builtin = require("telescope.builtin")
vim.keymap.set('n', '<leader>fs', function()
  vim.ui.input({ prompt = 'File glob (e.g. *.rb): ' }, function(glob)
    if glob == nil then return end
    local opts = {}
    if glob ~= '' then
      local g = glob:find('^%*%*/') and glob or ('**/' .. glob)
      opts.additional_args = { '-g', g }
    end
    builtin.live_grep(opts)
  end)
end, { desc = 'Live grep with mask' })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
vim.keymap.set("n", "<leader>ft", builtin.git_files, { desc = "Git files" })
vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = '[G]it [S]tatus' })

-- Convenient omni-completion trigger (maps <C-c> to Ctrl-x Ctrl-o)
vim.keymap.set("i", "<C-c>", function()
  local keys = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, true, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "LSP omni-completion" })

-- Git
vim.keymap.set("n", "<leader>gr", ":Gitsigns refresh<CR>", { desc = "Refresh git branch" })

-- Autocommands

-- Auto save on focus lost (not on buffer switch)
vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  command = "silent! update",
})

-- Autoformat and cleanup
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    -- Strip trailing whitespace
    vim.cmd([[:%s/\s\+$//e]])
  end,
})

-- Restore last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      vim.cmd("normal! g`\"")
    end
  end
})

-- Kill LSP clients immediately on quit (avoids slow graceful shutdown)
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      client.stop(true)
    end
  end,
})

-- Session save on exit
--vim.api.nvim_create_autocmd("VimLeavePre", {
--  callback = function()
--    vim.cmd('mksession! ~/.config/nvim/session.vim')
--  end
--})

-- -- Session restore on startup (deferred to not interfere with LSP)
-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = function()
--     local session_file = vim.fn.expand('~/.config/nvim/session.vim')
--     if vim.fn.argc() == 0 and vim.fn.filereadable(session_file) == 1 then
--       vim.cmd('source ' .. session_file)
--     end
--   end,
-- })

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "rust", "ruby" },
  callback = function()
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
    vim.opt_local.foldlevel = 99
  end,
})
