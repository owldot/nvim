-- Draw a │ at column 80 using virtual text (no plugins)
local ns = vim.api.nvim_create_namespace("col80")
vim.api.nvim_set_hl(0, "Col80Ruler", { fg = "#3b4048" })

local function draw_col80(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_count, false)
  for i, line in ipairs(lines) do
    local len = vim.fn.strdisplaywidth(line)
    if line ~= "" and len < 80 then
      local pad = string.rep(" ", 79 - len)
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
        virt_text = { { pad .. "│", "Comment" } },
        virt_text_pos = "eol",
      })
    end
  end
end

return { draw_col80 = draw_col80 }
