local api = vim.api

local config = require('config')
local utils = require('utils')
local window = require('window')

local M = {}

-- Opens the given macro in the chat window.
-- If no macro with the given name exists, a new one is created.
function M.open_macro(macro_name)
  window.focus_window()
  api.nvim_command('edit ' .. config.default.files.macros_dir .. macro_name .. '.md')

  -- Setting buffer options
  local buf = api.nvim_get_current_buf()

  window.configure_buffer(buf)
end

-- Prompts the user for a macro name and opens it in the chat window.
function M.edit_macro()
  -- getting one character from the input
  local macro_name = vim.fn.nr2char(vim.fn.getchar())

  -- makin sure the character is a letter
  if not vim.fn.match(macro_name, '[a-zA-Z]') then
    print("Invalid macro name.")
    return
  end

  M.open_macro(macro_name)
end

-- Runs the macro with the given name on the currently selected text.
function M.run_macro(start_line, end_line)
  local macro_name = vim.fn.nr2char(vim.fn.getchar())

  local file_path = config.default.files.macros_dir .. macro_name .. '.md'

  local code_file_path = config.default.files.macros_dir .. 'code.txt'

  -- putting the selected lines in the code file
  -- api.nvim_command("w!" .. code_file_path)
  local selectedLines = vim.fn.getline(start_line, end_line)
  local file, error_message = io.open(code_file_path, "w+")
  print(os.getenv("HOME"))
  if file == nil then
    print(error_message)
    return
  end
  local text = "```" .. vim.bo.filetype .. "\n"
  for _, line in ipairs(selectedLines) do
    text = text .. line .. "\n"
  end
  text = text .. "```"
  file:write(text)
  file:close()

  local result = utils.run_copilot_script("macro " .. file_path .. " " .. code_file_path)

  -- removing the old selection
  api.nvim_command("normal! gvd")

  -- inserting the result
  local lines = vim.split(result, "\n")
  local current_line = vim.fn.line(".")
  api.nvim_buf_set_lines(0, current_line - 1, current_line - 1, false, lines)
end

return M
