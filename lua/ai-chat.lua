local api = vim.api

local M = {
  window = nil,
  gh_device_code
}

M.config = {
  mappings = {
    focus_window = '<LEADER>m',
    selected_to_chat = '<LEADER>m',
    run_macro = '<LEADER>k',
    edit_macro = '<LEADER>K',
  },

  files = {
    chat_file = os.getenv("HOME") .. '/.config/ai-chat/chat.txt',
    macros_dir = os.getenv("HOME") .. '/.config/ai-chat/macros/'
  }
}

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local function run_copilot_script(args)
  local path = script_path()

  if M.gh_device_code ~= nil then
    local handle = io.popen(path .. "/copilot/index.ts connect " .. M.gh_device_code)
    local result = handle:read("*a")
    handle:close()
    M.gh_device_code = nil
  end
  
  local handle = io.popen(path .. "/copilot/index.ts " .. args)
  local result = handle:read("*a")
  handle:close()

  -- if the result starts with the line @@@, it means we have to connect to GH
  if string.sub(result, 1, 3) == "@@@" then
    local lines = vim.split(result, "\n")
    local verification_uri = lines[2]
    local user_code = lines[3]
    local device_code = lines[4]

    M.gh_device_code = device_code

    print("You need to connect to GitHub")
    result = "Please visit " .. verification_uri .. " and enter " .. user_code .. "\n\nOnce this is done, ask me something!"
  end

  return result
end

function M.open_window()
  local width = 70

  -- Opening new buffer in a split window on the right
  api.nvim_command('set splitright')
  api.nvim_command('vsplit')
  api.nvim_win_set_width(0, width)

  -- Setting window options
  api.nvim_win_set_option(0, 'wrap', true)

  -- Creating buffer
  local buf = api.nvim_create_buf(false, true)

  -- Setting buffer content if it is empty
  local content = {
    '============ USER ============',
    '',
    ''
  }
  if api.nvim_buf_line_count(buf) == 0 then
    api.nvim_buf_set_lines(buf, 0, -1, false, content)
  end


  -- putting buffer in window
  api.nvim_win_set_buf(0, buf)

  M.window = api.nvim_get_current_win()

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
end

function M.open_chat()
  M.focus_window()
  api.nvim_command('edit ' .. M.config.files.chat_file)

  -- Setting buffer options
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'swapfile', false)
  api.nvim_buf_set_option(buf, 'filetype', 'ai-chat')

  api.nvim_command("normal! G")
end

function M.open_macro(macro_name)
  M.focus_window()
  api.nvim_command('edit ' .. M.config.files.macros_dir .. macro_name .. '.txt')

  -- Setting buffer options
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'swapfile', false)
  api.nvim_buf_set_option(buf, 'filetype', 'ai-chat')
end

function M.close_window()
  -- saving file
  api.nvim_command("silent!w")

  api.nvim_win_close(M.window, true)
  M.window = nil
end

function M.toggle_window()
  if not M.is_window_open() then
    M.open_window()
    M.focus_window()
  else
    M.close_window()
  end
end

function M.is_window_open()
  return M.window ~= nil and api.nvim_win_is_valid(M.window)
end

function M.focus_window()
  if not M.is_window_open() then
    M.open_window()
  end

  api.nvim_set_current_win(M.window)
end

function M.send_message()
  api.nvim_command("silent!w")

  local result = run_copilot_script("chat " .. M.config.files.chat_file)

  local lines = vim.split(result, "\n")

  table.insert(lines, 1, "")
  table.insert(lines, 1, "============= AI =============")
  table.insert(lines, 1, "")

  -- Putting the result at the end of the buffer
  local buf = api.nvim_get_current_buf()
  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)

  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, -1, line_count, false, {
    "",
    "============ USER ===========",
    "",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
  api.nvim_command("silent!w")
end

function M.ask(start_line, end_line)
  local selectedLines = vim.fn.getline(start_line, end_line)
  local filetype = vim.bo.filetype

  -- inserting lines at the start of the code snippet
  table.insert(selectedLines, 1, "```" .. filetype)
  table.insert(selectedLines, 1, "")
  table.insert(selectedLines, 1, "============= CODE ============")
  table.insert(selectedLines, 1, "")

  -- inserting lines at the end of the code snippet
  table.insert(selectedLines, "```")

  M.focus_window()
  M.open_chat()

  -- Putting the selected lines at the end of the buffer
  local buf = api.nvim_get_current_buf()
  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, line_count, line_count, false, selectedLines)

  line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, -1, line_count, false, {
    "",
    "============ USER ============",
    "",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
  api.nvim_command("silent!w")

  -- Entering insert mode
  api.nvim_command("startinsert")
end

function M.resetChat()
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_lines(buf, 0, -1, false, {
    "============ USER ============",
    "",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
end

function M.edit_macro()
  -- getting one character from the input
  local macro_name = vim.fn.nr2char(vim.fn.getchar())
  M.open_macro(macro_name)
end

function M.run_macro(start_line, end_line)
  local macro_name = vim.fn.nr2char(vim.fn.getchar())

  local file_path = M.config.files.macros_dir .. macro_name .. '.txt'

  local code_file_path = M.config.files.macros_dir .. 'code.txt'

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

  local path = script_path()
  local handle = io.popen(path .. "/copilot/index.ts macro " .. file_path .. " " .. code_file_path)
  local result = handle:read("*a")
  handle:close()

  -- removing the old selection
  api.nvim_command("normal! gvd")

  -- inserting the result
  local lines = vim.split(result, "\n")
  local current_line = vim.fn.line(".")
  api.nvim_buf_set_lines(0, current_line - 1, current_line - 1, false, lines)
end

function M.setup(user_opts)
  -- creating directory if not exists
  os.execute("mkdir -p " .. M.config.files.macros_dir)

  vim.api.nvim_command("command! AiOpen lua require('ai-chat').focus_window()")

  local opts = { noremap = true }

  api.nvim_set_keymap("n", M.config.mappings.focus_window, "<Cmd>lua require('ai-chat').open_chat()<CR>", opts)
  api.nvim_set_keymap("v", M.config.mappings.selected_to_chat, ":AiAsk<CR>", opts)
  api.nvim_set_keymap("v", M.config.mappings.run_macro, ":RunMacro<CR>", opts)
  api.nvim_set_keymap("n", M.config.mappings.run_macro, "V:RunMacro<CR>", opts)
  api.nvim_set_keymap("n", M.config.mappings.edit_macro, ":AiMacroEdit<CR>", opts)

  api.nvim_command("command! -range AiAsk lua require('ai-chat').ask(<line1>, <line2>)")
  api.nvim_command("command! -range RunMacro lua require('ai-chat').run_macro(<line1>, <line2>)")
  api.nvim_command("command! -range AiMacroEdit lua require('ai-chat').edit_macro()")

  -- setting maps specific to the ai-chat buffer using autocmd
  vim.api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> <C-a> <CMD>lua require('ai-chat').send_message()<CR>")
  vim.api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.focus_window .. " <CMD>lua require('ai-chat').close_window()<CR>")
  vim.api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> <C-d> <CMD>lua require('ai-chat').resetChat()<CR>")
  vim.api.nvim_command("autocmd FileType ai-chat cnoreabbrev <buffer> x <CMD>lua require('ai-chat').close_window()<CR>")
  vim.api.nvim_command("autocmd FileType ai-chat cnoreabbrev <buffer> q <CMD>lua require('ai-chat').close_window()<CR>")
end

return M
