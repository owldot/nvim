local M = {}
local _next_id = 1

local function get_term_buffers()
  local terms = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
      table.insert(terms, buf)
    end
  end
  table.sort(terms, function(a, b)
    return (vim.b[a].smart_term_id or math.huge) < (vim.b[b].smart_term_id or math.huge)
  end)
  return terms
end

local function find_term_by_id(id)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buftype == "terminal"
      and vim.b[buf].smart_term_id == id
    then
      return buf
    end
  end
end

local function spawn_terminal(in_split)
  if in_split then
    vim.cmd("botright vsplit | terminal")
  else
    vim.cmd("terminal")
  end
  local buf = vim.api.nvim_get_current_buf()
  local id = _next_id
  _next_id = _next_id + 1
  vim.b[buf].smart_term_id = id
  pcall(vim.api.nvim_buf_set_name, buf, "term[" .. id .. "]")
  return buf, id
end

local function focus_term(buf, id)
  local winid = vim.fn.bufwinid(buf)
  if winid ~= -1 then
    vim.api.nvim_set_current_win(winid)
    vim.notify("Switched to terminal #" .. id, vim.log.levels.INFO)
  else
    vim.cmd("botright vsplit")
    vim.api.nvim_set_current_buf(buf)
    vim.notify("Opened terminal #" .. id, vim.log.levels.INFO)
  end
end

function M.open_terminal(args)
  local id = tonumber(args)

  if id then
    local buf = find_term_by_id(id)
    if buf then
      focus_term(buf, id)
    else
      local _, new_id = spawn_terminal(true)
      vim.notify("Terminal #" .. id .. " not found, created #" .. new_id, vim.log.levels.WARN)
    end
    return
  end

  local terms = get_term_buffers()
  if #terms > 0 then
    local first_id = vim.b[terms[1]].smart_term_id
    focus_term(terms[1], first_id)
  else
    local _, new_id = spawn_terminal(true)
    vim.notify("Created terminal #" .. new_id, vim.log.levels.INFO)
  end
end

function M.new_terminal()
  local _, id = spawn_terminal(true)
  vim.notify("Created terminal #" .. id, vim.log.levels.INFO)
end

function M.replace_terminal(args)
  local id = tonumber(args)

  if id then
    local buf = find_term_by_id(id)
    if buf then
      vim.api.nvim_set_current_buf(buf)
      vim.notify("Replaced with terminal #" .. id, vim.log.levels.INFO)
    else
      local _, new_id = spawn_terminal(false)
      vim.notify("Terminal #" .. id .. " not found, created #" .. new_id, vim.log.levels.WARN)
    end
    return
  end

  local terms = get_term_buffers()
  if #terms > 0 then
    local first_id = vim.b[terms[1]].smart_term_id
    vim.api.nvim_set_current_buf(terms[1])
    vim.notify("Replaced with terminal #" .. first_id, vim.log.levels.INFO)
  else
    local _, new_id = spawn_terminal(false)
    vim.notify("Created terminal #" .. new_id, vim.log.levels.INFO)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("ST", function(opts)
    M.open_terminal(opts.args)
  end, { nargs = "?", force = true })

  vim.api.nvim_create_user_command("SNT", function()
    M.new_terminal()
  end, { force = true })

  vim.api.nvim_create_user_command("STR", function(opts)
    M.replace_terminal(opts.args)
  end, { nargs = "?", force = true })
end

return M
