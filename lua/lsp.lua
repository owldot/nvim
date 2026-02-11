local caps = vim.lsp.protocol.make_client_capabilities()
caps.general.positionEncodings = { "utf-16" }

local format_on_save_group = vim.api.nvim_create_augroup("LspFormatOnSave", {})

vim.lsp.config.ruby_lsp = {
  cmd = { "ruby-lsp" },
  root_markers = { "Gemfile" },
  filetypes = { "ruby" },
}
vim.lsp.enable({ "ruby_lsp" })

vim.lsp.config.sorbet = {
  cmd = { "srb", "tc", "--lsp" },
  root_markers = { "sorbet/" },
  filetypes = { "ruby" },
}
vim.lsp.enable({ "sorbet" })


vim.lsp.config.rust_analyzer = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json" },
  settings = {
   ["rust-analyzer"] = {
     cargo = { allFeatures = true },
     procMacro = { enable = true },
     rustup = { toolchain = "nightly" }
    },
  },
}
vim.lsp.enable({ "rust_analyzer" })

-- Configure diagnostics display
vim.diagnostic.config({
  signs = true,
  underline = true,
  update_in_insert = true,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    -- Navigation
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)

    -- Documentation
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)

    -- Diagnostics
    vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

    -- Code actions
    vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)

    if client and client.server_capabilities.documentFormattingProvider then
      vim.api.nvim_clear_autocmds({ group = format_on_save_group, buffer = ev.buf })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_on_save_group,
        buffer = ev.buf,
        callback = function()
          vim.lsp.buf.format({ async = false, bufnr = ev.buf })
        end,
      })
    end
  end
})
