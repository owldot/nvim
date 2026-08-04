-- agentterm.lua -- lightweight CLI-agent terminals (pi / claude / codex / ...)
--
-- Every mapping does the same thing in normal and visual mode. Two groups:
--
--   session management (mode independent): aa toggle, an/aN new, al list,
--                                           ax kill, a1..a9 jump
--   context sending    (mode aware payload): ar reference, ac reference+code
--
-- "Context" is the visual selection, or the current line in normal mode, and
-- renders as `path/to/file.rb:12-40 `. Nothing auto-closes.

local M = {}

M.config = {
  default_agent = "pi",
  agents = {
    pi       = { cmd = { "pi" } },
    claude   = { cmd = { "claude" } },
    codex    = { cmd = { "codex" } },
    opencode = { cmd = { "opencode" } },
    devx     = { cmd = { "devx", "pi" } },
  },
  split = "botright vsplit", -- try "botright split" for a horizontal one
  width = 0.40,              -- fraction of columns (vertical splits only)
  height = 0.35,             -- fraction of lines (horizontal splits only)
  insert_on_focus = true,
  esc_passthrough = true,    -- let <Esc> reach the agent TUI (use <C-\><C-n> to leave)
  ready_delay = 250,         -- ms after the TUI's first output before pasting
  ready_timeout = 2500,      -- ms hard cap in case the TUI prints nothing

  -- What gets pasted into the agent prompt. Return text WITHOUT a newline so
  -- it lands in the input box unsubmitted and you keep typing after it.
  ref = function(ctx)
    if ctx.line1 == ctx.line2 then
      return ("%s:%d "):format(ctx.path, ctx.line1)
    end
    return ("%s:%d-%d "):format(ctx.path, ctx.line1, ctx.line2)
  end,

  -- Variant used by <leader>ac: reference + the actual code.
  ref_with_code = function(ctx)
    local head = ctx.line1 == ctx.line2
      and ("%s:%d"):format(ctx.path, ctx.line1)
      or ("%s:%d-%d"):format(ctx.path, ctx.line1, ctx.line2)
    return table.concat({
      head,
      "```" .. (ctx.filetype or ""),
      table.concat(ctx.lines, "\n"),
      "```",
      "",
    }, "\n")
  end,
}

-- sessions ------------------------------------------------------------------

M.sessions = {} -- ordered list: { id, buf, job, agent, root, ready, queue, dead }
local next_id = 1
local last_id = nil

local function by_id(id)
  for _, s in ipairs(M.sessions) do
    if s.id == id then return s end
  end
end

local function alive(s)
  return s and not s.dead and vim.api.nvim_buf_is_valid(s.buf)
end

function M.prune()
  M.sessions = vim.tbl_filter(function(s)
    return vim.api.nvim_buf_is_valid(s.buf)
  end, M.sessions)
  if last_id and not by_id(last_id) then last_id = nil end
end

local function last_session()
  M.prune()
  local s = last_id and by_id(last_id)
  if s then return s end
  return M.sessions[#M.sessions]
end

-- context -------------------------------------------------------------------

local function git_root(path)
  local start = (path ~= "" and vim.fs.dirname(path)) or vim.uv.cwd()
  local dot = vim.fs.find(".git", { path = start, upward = true })[1]
  return dot and vim.fs.dirname(dot) or vim.uv.cwd()
end

local function relpath(path, root)
  if path == "" then return "[No Name]" end
  local rel = vim.fs.relpath and vim.fs.relpath(root, path)
  if rel then return rel end
  local prefix = root:gsub("([^%w])", "%%%1") .. "/"
  local stripped = path:gsub("^" .. prefix, "")
  return stripped
end

--- Snapshot the source buffer BEFORE any window/buffer switching happens.
local function capture(line1, line2)
  local buf = vim.api.nvim_get_current_buf()
  local abs = vim.api.nvim_buf_get_name(buf)
  return {
    abspath = abs,
    root = git_root(abs),
    line1 = line1,
    line2 = line2,
    lines = vim.api.nvim_buf_get_lines(buf, line1 - 1, line2, false),
    filetype = vim.bo[buf].filetype,
  }
end

--- Visual range without relying on '< '> (which lag one selection behind).
local function visual_range()
  local a = vim.fn.line("v")
  local b = vim.fn.line(".")
  if a > b then a, b = b, a end
  return a, b
end

-- window --------------------------------------------------------------------

local function open_split()
  local horizontal = M.config.split:match("vsplit") == nil
  vim.cmd(M.config.split)
  local win = vim.api.nvim_get_current_win()
  if horizontal then
    vim.api.nvim_win_set_height(win, math.floor(vim.o.lines * M.config.height))
    vim.wo[win].winfixheight = true
  else
    vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * M.config.width))
    vim.wo[win].winfixwidth = true
  end
  return win
end

local function decorate(buf, win)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].spell = false
  vim.bo[buf].bufhidden = "hide"
end

-- send ----------------------------------------------------------------------

local function paste_seq(text)
  -- Bracketed paste keeps multi-line text as one prompt entry instead of
  -- submitting on every newline.
  if text:find("\n") then
    return "\27[200~" .. text .. "\27[201~"
  end
  return text
end

--- Send text to a session's prompt (queued if the TUI is still booting).
function M.send(session, text)
  if not alive(session) then
    vim.notify("agentterm: session is dead", vim.log.levels.WARN)
    return
  end
  if not session.ready then
    table.insert(session.queue, text)
    return
  end
  pcall(vim.api.nvim_chan_send, session.job, paste_seq(text))
end

local function mark_ready(session)
  if session.ready or session.dead then return end
  session.ready = true
  for _, text in ipairs(session.queue) do
    pcall(vim.api.nvim_chan_send, session.job, paste_seq(text))
  end
  session.queue = {}
end

-- spawn / focus --------------------------------------------------------------

function M.spawn(agent_name, opts)
  opts = opts or {}
  agent_name = agent_name or M.config.default_agent
  local agent = M.config.agents[agent_name]
  if not agent then
    vim.notify("agentterm: unknown agent " .. agent_name, vim.log.levels.ERROR)
    return
  end

  local root = opts.root or git_root(vim.api.nvim_buf_get_name(0))
  local id = next_id
  next_id = next_id + 1

  local win = open_split()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_win_set_buf(win, buf)
  decorate(buf, win)

  local session = {
    id = id, buf = buf, agent = agent_name, root = root,
    ready = false, queue = {}, dead = false,
  }

  session.job = vim.fn.jobstart(agent.cmd, {
    term = true,
    cwd = root,
    on_stdout = function()
      if not session.ready then
        vim.defer_fn(function() mark_ready(session) end, M.config.ready_delay)
      end
    end,
    on_exit = function()
      session.dead = true
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          pcall(vim.api.nvim_buf_set_name, buf,
            ("agent://%s#%d [exited]"):format(agent_name, id))
        end
      end)
    end,
  })

  if session.job <= 0 then
    vim.notify("agentterm: failed to start " .. agent_name, vim.log.levels.ERROR)
    return
  end

  pcall(vim.api.nvim_buf_set_name, buf, ("agent://%s#%d"):format(agent_name, id))
  vim.b[buf].agentterm_id = id
  -- Offset so pinterm's `:Pt <id>` can still reach these (`:Pt 101` -> agent #1)
  -- without colliding with plain pinterm terminals, and so pinterm's sort/notify
  -- never sees a nil id.
  vim.b[buf].pinterm_id = 100 + id

  if M.config.esc_passthrough then
    vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = buf, desc = "Send Esc to agent" })
  end
  vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { buffer = buf, desc = "Leave terminal mode" })

  -- fallback in case the TUI buffers its first paint
  vim.defer_fn(function() mark_ready(session) end, M.config.ready_timeout)

  table.insert(M.sessions, session)
  last_id = id
  if M.config.insert_on_focus then vim.cmd("startinsert") end
  return session
end

--- Focus a session, opening a split if it is not currently visible.
function M.focus(session, opts)
  opts = opts or {}
  if not vim.api.nvim_buf_is_valid(session.buf) then return end
  last_id = session.id

  local win = vim.fn.bufwinid(session.buf)
  if win ~= -1 then
    vim.api.nvim_set_current_win(win)
  else
    win = open_split()
    vim.api.nvim_win_set_buf(win, session.buf)
    decorate(session.buf, win)
  end

  if opts.insert ~= false and M.config.insert_on_focus and not session.dead then
    vim.schedule(function() vim.cmd("startinsert") end)
  end
  return win
end

--- Hide the session's window(s) without touching the buffer.
function M.hide(session)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == session.buf then
      if #vim.api.nvim_tabpage_list_wins(0) > 1 then
        vim.api.nvim_win_close(win, false)
      end
    end
  end
end

-- public actions -------------------------------------------------------------

--- Normal mode <leader>aa: toggle focus of the most recent session.
function M.toggle(agent_name)
  local session = last_session()
  if not session then
    M.spawn(agent_name)
    return
  end
  if vim.api.nvim_get_current_buf() == session.buf then
    M.hide(session)
  else
    M.focus(session)
  end
end

--- Send the current file/selection reference to a session (spawn if needed).
--- opts: { line1, line2, with_code, agent, session, new }
function M.ask(opts)
  opts = opts or {}
  local line1 = opts.line1 or vim.fn.line(".")
  local line2 = opts.line2 or line1
  -- snapshot first: spawning/focusing makes the terminal the current buffer
  local ctx = capture(line1, line2)

  local session = opts.session
  if not alive(session) then
    session = (not opts.new) and last_session() or nil
    if session and session.dead then session = nil end
  end
  if not session then
    session = M.spawn(opts.agent, { root = ctx.root })
    if not session then return end
  else
    M.focus(session)
  end

  ctx.path = relpath(ctx.abspath, session.root)
  local fmt = opts.with_code and M.config.ref_with_code or M.config.ref
  M.send(session, fmt(ctx))
end

--- Harpoon-style picker over live agent sessions.
function M.list()
  M.prune()
  if #M.sessions == 0 then
    vim.notify("agentterm: no sessions", vim.log.levels.INFO)
    return
  end
  vim.ui.select(M.sessions, {
    prompt = "Agent sessions",
    format_item = function(s)
      return ("#%d  %-8s %s%s"):format(
        s.id, s.agent, vim.fn.fnamemodify(s.root, ":~"), s.dead and "  [exited]" or "")
    end,
  }, function(choice)
    if choice then M.focus(choice) end
  end)
end

--- Jump to the nth session in creation order.
function M.jump(n)
  M.prune()
  local session = M.sessions[n]
  if not session then
    vim.notify("agentterm: no session #" .. n, vim.log.levels.WARN)
    return
  end
  M.focus(session)
end

--- Kill a session's job and wipe its buffer.
function M.kill(session)
  session = session or last_session()
  if not session then return end
  pcall(vim.fn.jobstop, session.job)
  if vim.api.nvim_buf_is_valid(session.buf) then
    vim.api.nvim_buf_delete(session.buf, { force = true })
  end
  M.prune()
end

--- Pick an agent, then spawn a fresh session.
function M.pick_agent()
  local names = vim.tbl_keys(M.config.agents)
  table.sort(names)
  vim.ui.select(names, { prompt = "New agent session" }, function(choice)
    if choice then M.spawn(choice) end
  end)
end

-- setup ----------------------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  local map = vim.keymap.set
  local both = { "n", "x" }

  local ESC = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  local function in_visual()
    local m = vim.fn.mode()
    return m == "v" or m == "V" or m == "\22"
  end
  local function leave_visual()
    if in_visual() then vim.api.nvim_feedkeys(ESC, "nx", false) end
  end

  --- Selection when visual, current line when normal.
  local function ctx_range()
    if in_visual() then
      local l1, l2 = visual_range() -- must read line("v") before leaving visual
      vim.api.nvim_feedkeys(ESC, "nx", false)
      return l1, l2
    end
    local l = vim.fn.line(".")
    return l, l
  end

  -- context sending -- same key, payload follows the mode
  map(both, "<leader>ar", function()
    local l1, l2 = ctx_range()
    M.ask({ line1 = l1, line2 = l2 })
  end, { desc = "Agent: send reference (selection / current line)" })

  map(both, "<leader>ac", function()
    local l1, l2 = ctx_range()
    M.ask({ line1 = l1, line2 = l2, with_code = true })
  end, { desc = "Agent: send reference + code" })

  -- session management -- identical in both modes
  map(both, "<leader>aa", function() leave_visual(); M.toggle() end,
    { desc = "Agent: toggle last session" })
  map(both, "<leader>an", function() leave_visual(); M.spawn() end,
    { desc = "Agent: new session (default agent)" })
  map(both, "<leader>aN", function() leave_visual(); M.pick_agent() end,
    { desc = "Agent: new session (pick agent)" })
  map(both, "<leader>al", function() leave_visual(); M.list() end,
    { desc = "Agent: list sessions" })
  map(both, "<leader>ax", function() leave_visual(); M.kill() end,
    { desc = "Agent: kill last session" })
  for i = 1, 9 do
    map(both, "<leader>a" .. i, function() leave_visual(); M.jump(i) end,
      { desc = "Agent: jump to #" .. i })
  end

  vim.api.nvim_create_user_command("Agent", function(a)
    M.spawn(a.args ~= "" and a.args or nil)
  end, {
    nargs = "?",
    complete = function()
      local names = vim.tbl_keys(M.config.agents); table.sort(names); return names
    end,
    desc = "Spawn an agent terminal",
  })
  vim.api.nvim_create_user_command("AgentList", function() M.list() end, {})
  vim.api.nvim_create_user_command("AgentAsk", function(a)
    M.ask({ line1 = a.line1, line2 = a.line2, with_code = a.bang })
  end, { range = true, bang = true, desc = "Send range reference to agent" })

  return M
end

return M
