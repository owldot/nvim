-- Colors
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"

-- Wrap
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt.colorcolumn = "80"
  end,
})

local ruler = require("functions.ruler")
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "TextChangedI" }, {
  pattern = "*",
  callback = function()
    ruler.draw_col80(vim.api.nvim_get_current_buf())
  end,
})

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

local function set_statusline_section_highlight(mode)
  local ok_cfg, cfg = pcall(vim.fn["everforest#get_configuration"])
  if not ok_cfg then return end
  local p = vim.fn["everforest#get_palette"](cfg.background, cfg.colors_override)
  local set_hl = vim.fn["everforest#highlight"]

  local bg_by_mode = {
    n = p.bg_green,
    i = p.yellow,
    v = p.bg_visual,
    V = p.bg_visual,
    ['\22'] = p.bg_visual,
    c = p.bg_green,
  }
  local fg_by_mode = {
    n = p.fg,
    v = p.fg,
    V = p.fg,
    ['\22'] = p.fg,
    c = p.fg,
  }

  local bg = bg_by_mode[mode] or p.bg_green
  local fg = fg_by_mode[mode] or p.bg0
  set_hl('StatusLineMode', fg, bg)
  set_hl('StatusLineLC', fg, bg)
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
vim.keymap.set("v", "<leader>p", "\"_dP") -- paste without replacing register
-- Delete/change without yanking (use black hole register)
vim.keymap.set({"n", "v"}, "d", '"_d')
vim.keymap.set({"n", "v"}, "D", '"_D')
vim.keymap.set("n", "dd", '"_dd')
vim.keymap.set({"n", "v"}, "c", '"_c')
vim.keymap.set({"n", "v"}, "C", '"_C')
vim.keymap.set("n", "cc", '"_cc')
-- Use x to cut (yank + delete) when you need clipboard
vim.keymap.set({"n", "v"}, "x", "d")
vim.keymap.set("n", "xx", "dd")

vim.keymap.set("n", "<leader>o", ":Ex<CR>", { silent = true })

vim.keymap.set("n", "[b", ":bp<CR>", { silent = true })
vim.keymap.set("n", "]b", ":bn<CR>", { silent = true })

-- Visual surround: select text, press S, type wrap character
vim.keymap.set("v", "S", function()
  local char = vim.fn.getcharstr()
  local brackets = { ["("] = ")", ["{"] = "}", ["["] = "]", ["<"] = ">" }
  local reverse = { [")"] = "(", ["}"] = "{", ["]"] = "[", [">"] = "<" }
  local open, close
  if brackets[char] then
    open, close = char, brackets[char]
  elseif reverse[char] then
    open, close = reverse[char], char
  else
    open, close = char, char
  end
  local keys = string.format("<Esc>`>a%s<Esc>`<i%s<Esc>", close, open)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "n", false)
end)

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

-- delete buffer
vim.keymap.set('n', '<leader>x', ':bd<CR>')

-- map <leader><CR> to insert a blank line
vim.keymap.set('n', '<leader><CR>', 'o<Esc>', { silent = true, desc = 'Insert blank line' })

-- Exit terminal mode
vim.keymap.set('t', '<C-w>h', "<C-\\><C-n><C-w>h",{silent = true})
vim.keymap.set('t', '<C-w>j', "<C-\\><C-n><C-w>j",{silent = true})
vim.keymap.set('t', '<C-w>k', "<C-\\><C-n><C-w>k",{silent = true})
vim.keymap.set('t', '<C-w>l', "<C-\\><C-n><C-w>l",{silent = true})
vim.keymap.set('t', '<C-w>w', "<C-\\><C-n><C-w>w",{silent = true})
vim.keymap.set('t', '<C-w><C-w>', "<C-\\><C-n><C-w><C-w>",{silent = true})

-- Insert mode word motions
vim.keymap.set('i', '<C-f>', '<C-o>w')
vim.keymap.set('i', '<C-b>', '<C-o>b')

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
  vim.ui.select({ 'String', 'RegExp' }, { prompt = 'Search mode:' }, function(mode)
    mode = mode or 'String'  -- fallback to String on cancel
    local args = {}
    if mode == 'String' then
      args[#args + 1] = '--fixed-strings'
    end
    vim.ui.input({ prompt = 'Include glob (e.g. *.rb, leave empty for all): ' }, function(inc)
      if inc == nil then return end
      if inc ~= '' then
        local g = inc:find('^%*%*/') and inc or ('**/' .. inc)
        args[#args + 1] = '-g'
        args[#args + 1] = g
      end
      vim.ui.input({ prompt = 'Exclude glob (e.g. *.test.rb, leave empty to skip): ' }, function(excl)
        if excl == nil then return end
        if excl ~= '' then
          local eg = excl:find('^%*%*/') and ('!' .. excl) or ('!**/' .. excl)
          args[#args + 1] = '-g'
          args[#args + 1] = eg
        end
        builtin.live_grep({ additional_args = #args > 0 and args or nil })
      end)
    end)
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

-- Auto save on focus lost or buffer switch
vim.api.nvim_create_autocmd({"FocusLost", "BufLeave"}, {
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
