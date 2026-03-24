-- Per-window header (winbar) showing the file path relative to cwd
local M = {}

function M.setup()
  local function apply_hl()
    local wb = vim.api.nvim_get_hl(0, { name = "WinBar", link = false })
    vim.api.nvim_set_hl(0, "WinBarDir", { fg = wb.fg, bg = wb.bg })
    vim.api.nvim_set_hl(0, "WinBarFile", { fg = wb.fg, bg = wb.bg, bold = true })
  end

  apply_hl()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })

  local skip_ft = { oil = true, help = true, qf = true, TelescopePrompt = true }

  vim.o.winbar = "%{%v:lua.require('functions.header').render()%}"

  function M.render()
    local buf = vim.api.nvim_get_current_buf()
    local ft = vim.bo[buf].filetype
    if skip_ft[ft] or vim.bo[buf].buftype ~= "" then
      return ""
    end

    local path = vim.fn.expand("%:.")
    if path == "" then return "" end

    local dir = vim.fn.fnamemodify(path, ":h")
    local name = vim.fn.fnamemodify(path, ":t")

    if dir == "." then
      return "%#WinBarFile# " .. name
    end

    return "%#WinBarDir# " .. dir .. "/%#WinBarFile#" .. name
  end
end

return M
