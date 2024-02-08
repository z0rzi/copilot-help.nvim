local api = vim.api

local M = {}

local window = require('window')
local config = require('config')
local utils = require('utils')

local USER_HEADER = "# ============ USER ============"
local AI_HEADER = "# ============= AI ============="

-- Opens the chat file in the chat window.
function M.open_chat()
  window.focus_window()
  api.nvim_command('edit ' .. config.default.files.chat_file)

  local buf = api.nvim_get_current_buf()

  window.configure_buffer(buf)

  if api.nvim_buf_line_count(buf) <= 3 then
    -- Setting buffer content if it is empty
    local content = {
      USER_HEADER,
      '',
      ''
    }
    api.nvim_buf_set_lines(buf, 0, -1, false, content)
  end


  api.nvim_command("normal! G")
end

-- Erasing the conversation from the chat buffer
function M.reset_chat()
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_lines(buf, 0, -1, false, {
    USER_HEADER,
    "",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
end

-- Given a list of lines, returns the start and end line of the code block
local function find_code_block_in_text(lines)
  local start_line = nil
  local end_line = nil

  for i, line in ipairs(lines) do
    if string.sub(line, 1, 3) == "```" then
      if start_line == nil then
        start_line = i + 1
      else
        end_line = i - 1
        break
      end
    end
  end

  return start_line, end_line
end

-- Sends the messages in the chat buffer to the AI
function M.send_message()
  -- saving the chat buffer
  api.nvim_command("silent!w")

  local result = utils.run_copilot_script("chat " .. config.default.files.chat_file)

  local lines = vim.split(result, "\n")

  table.insert(lines, 1, "")
  table.insert(lines, 1, AI_HEADER)
  table.insert(lines, 1, "")

  -- Saving the position of the code in the answer
  local code_start, code_end = find_code_block_in_text(lines)
  local lnum = vim.fn.line("$")
  code_start = code_start and code_start + lnum or nil
  code_end = code_end and code_end + lnum or nil

  -- Putting the result at the end of the buffer
  local buf = api.nvim_get_current_buf()
  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)

  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, -1, line_count, false, {
    "",
    USER_HEADER,
    "",
    ""
  })

  if code_start ~= nil then
    -- Copying the code block content
    local code_length = code_end - code_start
    api.nvim_win_set_cursor(0, { code_start, 0 })
    api.nvim_command("normal! y" .. code_length .. "j")
    print("Code bloc yanked")
  end
  api.nvim_command("normal! G")
  api.nvim_command("silent!w")
end

-- searching for the next '^======' using vim native search
function M.next_hunk()
  vim.fn.search('^# ======', 'W')
end

-- searching for the previous '^======' using vim native search
function M.prev_hunk()
  vim.fn.search('^# ======', 'bW')
end

-- Sends the selected code to the chat, and enters insert mode
function M.selection_to_chat(start_line, end_line)
  local selectedLines = vim.fn.getline(start_line, end_line)
  local filetype = vim.bo.filetype

  -- inserting lines at the start of the code snippet
  table.insert(selectedLines, 1, "```" .. filetype)
  table.insert(selectedLines, 1, "")
  table.insert(selectedLines, 1, AI_HEADER)
  table.insert(selectedLines, 1, "")

  -- inserting lines at the end of the code snippet
  table.insert(selectedLines, "```")

  window.focus_window()
  M.open_chat()

  local buf = api.nvim_get_current_buf()

  if config.default.reset_chat_on_selection_send then
    -- removing the old messages
    api.nvim_buf_set_lines(buf, 0, -1, false, { '' })
  end

  -- Putting the selected lines at the end of the buffer
  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, line_count, line_count, false, selectedLines)

  line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, -1, line_count, false, {
    "",
    USER_HEADER,
    "",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
  api.nvim_command("silent!w")

  -- Entering insert mode
  api.nvim_command("startinsert")
end


return M
