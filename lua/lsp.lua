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
-- vim.lsp.enable({ "ruby_lsp" })

-- Sorbet

local sorbet_operations = {}

local function handle_sorbet_operation(_, params, ctx)
  if not params or not ctx then return end

  local operations = sorbet_operations[ctx.client_id] or {}
  if params.status == "end" then
    operations = vim.tbl_filter(function(operation)
      return operation.operationName ~= params.operationName
    end, operations)
  else
    operations[#operations + 1] = params
  end
  sorbet_operations[ctx.client_id] = operations

  vim.schedule(function() vim.cmd.redrawstatus() end)
end

_G.sorbet_operation_status = function(client_id)
  local operations = sorbet_operations[client_id]
  local operation = operations and operations[#operations]
  return operation and (operation.description or operation.operationName) or nil
end

vim.lsp.config.sorbet = {
  cmd = { "srb", "tc", "--lsp", "--cache-dir=.sorbet-cache" },
  root_markers = { "sorbet" },
  filetypes = { "ruby" },
  capabilities = caps,
  init_options = {
    supportsOperationNotifications = true,
    highlightUntyped = false,
  },
  handlers = {
    ["sorbet/showOperation"] = handle_sorbet_operation,
  },
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
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "single",
    source = "always",
    header = "",
    prefix = "",
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Use builtin LSP as omnifunc for insert-mode completion (Ctrl-x Ctrl-o)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    local opts = { buffer = ev.buf }
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    -- Open definition in a split (vertical: <C-w>gd, horizontal: <C-w>gD).
    -- Uses on_list so no split is opened when there's no result.
    local function definition_in_split(split_cmd)
      return function()
        vim.lsp.buf.definition({
          on_list = function(list)
            if not list.items or vim.tbl_isempty(list.items) then return end
            vim.cmd(split_cmd)
            vim.fn.setqflist({}, " ", list)
            vim.cmd("cfirst")
          end,
        })
      end
    end

    -- Navigation
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<C-w>gd", definition_in_split("vsplit"), opts)
    vim.keymap.set("n", "<C-w>gD", definition_in_split("split"), opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)

    -- Documentation
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ border = "single" }) end, opts)
    vim.keymap.set("n", "<C-k>", function() vim.lsp.buf.signature_help({ border = "single" }) end, opts)

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
