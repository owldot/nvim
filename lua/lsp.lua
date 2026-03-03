local caps = vim.lsp.protocol.make_client_capabilities()
caps.general.positionEncodings = { "utf-16" }

local format_on_save_group = vim.api.nvim_create_augroup("LspFormatOnSave", {})

-- RUBY
local ruby_lsp_bin
if vim.env.GEM_HOME then
  ruby_lsp_bin = vim.fn.expand(vim.env.GEM_HOME .. "/bin/ruby-lsp")
else
  ruby_lsp_bin = ""
end

if ruby_lsp_bin ~= "" and vim.fn.executable(ruby_lsp_bin) == 0 then
  vim.notify("ruby-lsp not found, attempting to install...", vim.log.levels.INFO)
  vim.fn.jobstart("gem install ruby-lsp; gem install ruby-lsp-rails", {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Successfully installed ruby-lsp.", vim.log.levels.INFO)
      else
        vim.notify("Failed to install ruby-lsp.", vim.log.levels.ERROR)
      end
    end,
  })
end

vim.lsp.config.ruby_lsp = {
  cmd = { "ruby-lsp" },
  root_markers = { "Gemfile" },
  filetypes = { "ruby" },
  capabilities = caps,
  on_error = function(code, err)
    if code == vim.lsp.client_errors.NO_RESULT_CALLBACK_FOUND then return end
    vim.notify(string.format("ruby_lsp error %d: %s", code, err), vim.log.levels.ERROR)
  end,
  init_options = {
    addonSettings = {
      ["Ruby LSP Rails"] = {
        enablePendingMigrationsPrompt = false,
      },
    },
  },
}
vim.lsp.enable({ "ruby_lsp" })

-- Sorbet

vim.lsp.config.sorbet = {
  cmd = { "srb", "tc", "--lsp" },
  root_markers = { "sorbet/" },
  filetypes = { "ruby" },
  capabilities = caps,
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
-- Helper: rounded border with slight padding
local function padded_border(hl)
  hl = hl or "FloatBorder"
  return {
    {"┌", hl}, {"─", hl}, {"┐", hl}, {"│", hl},
    {"┘", hl}, {"─", hl}, {"└", hl}, {"│", hl},
  }
end

vim.diagnostic.config({
  signs = true,
  underline = true,
  update_in_insert = true,
  severity_sort = true,
  float = {
    -- bright rounded border; padding achieved via style in handlers below
    border = padded_border(),
    source = "always",
    header = "",
    prefix = "",
  },
})

-- Rounded borders for LSP hover/signature windows with padding
local function with_border(handler)
  return vim.lsp.with(handler, {
    border = padded_border(),
    max_width = 100,
    max_height = 25,
  })
end
vim.lsp.handlers["textDocument/hover"] = with_border(vim.lsp.handlers.hover)
vim.lsp.handlers["textDocument/signatureHelp"] = with_border(vim.lsp.handlers.signature_help)

-- Rounded borders for LSP hover/signature windows
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

-- Force-hover helper that always uses our border regardless of global handlers
local function bordered_hover()
  local params = vim.lsp.util.make_position_params()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then return end
  local handler = function(err, result, ctx, config)
    config = config or {}
    config.border = padded_border()
    config.max_width = 100
    config.max_height = 25
    return vim.lsp.handlers.hover(err, result, ctx, config)
  end
  vim.lsp.buf_request(0, 'textDocument/hover', params, handler)
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Use builtin LSP as omnifunc for insert-mode completion (Ctrl-x Ctrl-o)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    local opts = { buffer = ev.buf }
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    -- Navigation
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)

    -- Documentation (force buffer-local K to prefer our handler)
    pcall(vim.keymap.del, 'n', 'K', { buffer = ev.buf })
    vim.keymap.set("n", "K", bordered_hover, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts)

    -- Re-assert bordered handlers in case another plugin modified them
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = {
      {"┌","FloatBorder"},{"─","FloatBorder"},{"┐","FloatBorder"},{"│","FloatBorder"},
      {"┘","FloatBorder"},{"─","FloatBorder"},{"└","FloatBorder"},{"│","FloatBorder"},
    } })
    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = {
      {"┌","FloatBorder"},{"─","FloatBorder"},{"┐","FloatBorder"},{"│","FloatBorder"},
      {"┘","FloatBorder"},{"─","FloatBorder"},{"└","FloatBorder"},{"│","FloatBorder"},
    } })

    -- Diagnostics
    vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

    -- Code actions and workspace
    vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
    vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)

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
