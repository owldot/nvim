-- Visual surround: select text, press S, type wrap character
-- Change surround: cs{old}{new}
-- Delete surround: ds{char}

local brackets = { ["("] = ")", ["{"] = "}", ["["] = "]", ["<"] = ">" }
local reverse = { [")"] = "(", ["}"] = "{", ["]"] = "[", [">"] = "<" }

-- Resolve a typed char to an { open, close } pair.
-- Bracket keys/values surround with the bracket pair; anything else
-- (quotes, *, _, etc.) surrounds with itself on both sides.
local function resolve_pair(char)
  if brackets[char] then
    return char, brackets[char]
  elseif reverse[char] then
    return reverse[char], char
  else
    return char, char
  end
end

-- Visual surround: select text, press S, type wrap character
vim.keymap.set("v", "S", function()
  local char = vim.fn.getcharstr()
  local open, close = resolve_pair(char)
  local keys = string.format("<Esc>`>a%s<Esc>`<i%s<Esc>", close, open)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "n", false)
end)

-- Find the nearest pair of delimiters around the cursor on the current line.
-- Returns 0-indexed { open_col, close_col } or nil if not found.
local function find_pair(open, close)
  local line = vim.api.nvim_get_current_line()
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

  if open == close then
    -- Symmetric delimiter (quotes, *, _...): find the nearest enclosing
    -- occurrence by scanning left then right from the cursor.
    local left = nil
    for i = cursor_col, 1, -1 do
      if line:sub(i, i) == open then
        left = i
        break
      end
    end
    if not left then return nil end
    local right = nil
    for i = left + 1, #line do
      if line:sub(i, i) == close then
        right = i
        break
      end
    end
    if not right or right <= cursor_col then return nil end
    return { left - 1, right - 1 }
  end

  -- Asymmetric delimiter: walk outward tracking nesting depth.
  local left, depth = nil, 0
  for i = cursor_col + 1, 1, -1 do
    local c = line:sub(i, i)
    if c == close and i - 1 ~= cursor_col then
      depth = depth + 1
    elseif c == open then
      if depth == 0 then
        left = i
        break
      end
      depth = depth - 1
    end
  end
  if not left then return nil end

  local right, d2 = nil, 0
  for i = left + 1, #line do
    local c = line:sub(i, i)
    if c == open then
      d2 = d2 + 1
    elseif c == close then
      if d2 == 0 then
        right = i
        break
      end
      d2 = d2 - 1
    end
  end
  if not right then return nil end
  return { left - 1, right - 1 }
end

-- Delete surround: ds{char}
vim.keymap.set("n", "ds", function()
  local char = vim.fn.getcharstr()
  local open, close = resolve_pair(char)
  local pos = find_pair(open, close)
  if not pos then return end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_text(0, row - 1, pos[2], row - 1, pos[2] + 1, {})
  vim.api.nvim_buf_set_text(0, row - 1, pos[1], row - 1, pos[1] + 1, {})
  vim.api.nvim_win_set_cursor(0, { row, pos[1] })
end)

-- Change surround: cs{old}{new}
vim.keymap.set("n", "cs", function()
  local old_char = vim.fn.getcharstr()
  local new_char = vim.fn.getcharstr()
  local open, close = resolve_pair(old_char)
  local new_open, new_close = resolve_pair(new_char)
  local pos = find_pair(open, close)
  if not pos then return end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_text(0, row - 1, pos[2], row - 1, pos[2] + 1, { new_close })
  vim.api.nvim_buf_set_text(0, row - 1, pos[1], row - 1, pos[1] + 1, { new_open })
  vim.api.nvim_win_set_cursor(0, { row, pos[1] })
end)
