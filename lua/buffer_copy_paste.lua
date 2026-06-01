vim.api.nvim_create_user_command("BufferCapture", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.buftype = "nofile"
end, {})

vim.keymap.set("n", "<leader>ty", ":BufferCapture<CR>", { silent = true })
