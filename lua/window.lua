local api = vim.api

local config = require('config')

local M = {
  window_id = nil,
}

local function switch_to_closest_buffer()
  local buf_list = api.nvim_list_bufs()
  local current_buf = api.nvim_get_current_buf()

  for _, buf in ipairs(buf_list) do
    if buf ~= current_buf then
      api.nvim_set_current_buf(buf)
      return true
    end
  end

  return false
end


function M.configure_buffer(buf)
  -- Setting buffer options
  api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  api.nvim_buf_set_option(buf, 'swapfile', false)
  api.nvim_buf_set_option(buf, 'filetype', 'ai-chat')

  -- applying markdown coloring
  api.nvim_command("runtime! syntax/markdown.vim")
end

-- Closes the chat window
function M.close_window()
  -- saving file
  api.nvim_command("silent!w")

  -- Closing the buffer
  api.nvim_command("silent!bd!")

  -- forgetting the window id
  M.window_id = nil
end

-- Toggles the chat window
function M.toggle_window()
  if not M.is_window_open() then
    M.open_window()
    M.focus_window()
  else
    M.close_window()
  end
end

-- Returns true if the chat window is open, whether it is focused or not
function M.is_window_open()
  return M.window_id ~= nil and api.nvim_win_is_valid(M.window_id)
end

-- Focuses the chat window
function M.focus_window()
  if not M.is_window_open() then
    M.open_window()
  end

  api.nvim_set_current_win(M.window_id)
end

-- Opens the chat window, and adds the === USER === header if the buffer is empty
function M.open_window()
  local fullscreen = config.default.fullscreen or false

  if not fullscreen then
    -- Opening new buffer in a split window on the right
    local width = 70

    -- Opening new buffer in a split window on the right
    api.nvim_command('set splitright')
    api.nvim_command('vsplit')
    api.nvim_win_set_width(0, width)
  end

  -- Setting window options
  api.nvim_win_set_option(0, 'wrap', true)

  -- Creating buffer
  local buf = api.nvim_create_buf(false, true)

  -- putting buffer in window
  api.nvim_win_set_buf(0, buf)

  M.window_id = api.nvim_get_current_win()

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
end

-- Toggles the fullscreen mode
function M.toggle_fullscreen()
  -- saving file
  api.nvim_command("silent!w")

  local fullscreen = config.default.fullscreen or false
  if M.is_window_open() then
    -- If the chat window is open, we have to change the layout

    M.focus_window()

    local buf = api.nvim_get_current_buf()

    if fullscreen then
      -- we want to switch to a split window

      -- we try to switch the current window to the last buffer
      if not switch_to_closest_buffer() then
        -- if there are no other buffers, we open a blank one
        api.nvim_command("enew")
      end

      -- Opening the buffer on the right
      local width = 70

      api.nvim_command('set splitright')
      api.nvim_command('vsplit')
      api.nvim_win_set_width(0, width)

      api.nvim_win_set_buf(0, buf)
    else
      -- we want to switch to a fullscreen window

      -- we close the current window
      api.nvim_win_close(0, true)

      -- we open the buffer in the current window
      api.nvim_win_set_buf(0, buf)
    end

    M.window_id = api.nvim_get_current_win()
  end

  if fullscreen then
    print("Fullscreen mode disabled")
  else
    print("Fullscreen mode enabled")
  end

  config.default.fullscreen = not fullscreen
end

return M
