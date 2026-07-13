-- Text-to-speech: pipe the current selection (or whole buffer) into ~/bin/tts.
--
-- Runs as a background job so generation/playback never blocks the editor.
-- The selection is streamed over the job's stdin (no clipboard, no Cmd+C), so
-- this works in terminal nvim where the Hammerspoon Cmd+C grab cannot see the
-- visual selection.
--
-- Mappings:
--   x  <leader>s  speak the visual selection
--   n  <leader>s  speak the whole buffer
--   n  <leader>S  stop (also :TtsStop, and the Hammerspoon ctrl+alt+cmd+X hotkey)

local M = {}

local function run(args, input)
  local cmd = table.concat({
    'export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"',
    'export SHOPIFY_PROXY_KEY="$(/opt/dev/bin/devx llm-gateway print-token --key)"',
    '"$HOME/bin/tts" ' .. (args or ""),
  }, "\n")

  local job = vim.fn.jobstart({ "/bin/zsh", "-lc", cmd }, {
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify("TTS failed (exit " .. code .. "), see ~/tts/tts.log", vim.log.levels.ERROR)
        end)
      end
    end,
  })

  if job <= 0 then
    vim.notify("TTS: could not start job", vim.log.levels.ERROR)
    return
  end

  if input then
    vim.fn.chansend(job, input)
    vim.fn.chanclose(job, "stdin") -- EOF so the script's `cat` finishes
  end
end

local function speak(text)
  if not text or text:gsub("%s", "") == "" then
    vim.notify("TTS: nothing to speak", vim.log.levels.WARN)
    return
  end
  vim.notify("TTS: generating…")
  run(nil, text)
end

function M.speak_selection()
  -- Yank the active visual selection to register z, then restore z.
  local save, save_type = vim.fn.getreg("z"), vim.fn.getregtype("z")
  vim.cmd('noautocmd normal! "zy')
  local text = vim.fn.getreg("z")
  vim.fn.setreg("z", save, save_type)
  speak(text)
end

function M.speak_buffer()
  speak(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
end

function M.stop()
  run("--stop")
end

vim.keymap.set("x", "<leader>s", M.speak_selection, { silent = true, desc = "TTS: speak selection" })
vim.keymap.set("n", "<leader>s", M.speak_buffer, { silent = true, desc = "TTS: speak buffer" })
vim.keymap.set("n", "<leader>S", M.stop, { silent = true, desc = "TTS: stop" })
vim.api.nvim_create_user_command("TtsStop", M.stop, { desc = "Stop TTS playback/generation" })

return M
