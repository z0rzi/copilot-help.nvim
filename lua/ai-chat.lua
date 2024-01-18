local api = vim.api

local M = {}

M.config = {
  window_open = 0,
  mappings = {
    focus_window = '<LEADER>m',
    selected_to_chat = '<LEADER>m',
  },

  window = nil,
  buffer = nil,

  file = '/tmp/ai-chat.txt',
}

function M.open_window()
  if M.config.window_open == 1 then
    return
  end
  M.config.window_open = 1

  local width = 70

  -- Creating buffer
  local buf = api.nvim_create_buf(false, true)

  -- Opening new buffer in a split window on the right
  api.nvim_command('set splitright')
  api.nvim_command('vsplit')
  api.nvim_win_set_width(0, width)
  api.nvim_win_set_buf(0, buf)

  -- opening file in buffer
  api.nvim_command('edit ' .. M.config.file)

  -- Setting buffer options
  -- api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'swapfile', false)
  api.nvim_buf_set_option(buf, 'filetype', 'ai-chat')

  -- Setting window options
  api.nvim_win_set_option(0, 'wrap', true)
  -- api.nvim_win_set_option(0, 'cursorline', true)

  -- Setting buffer content if it is empty
  local content = {
    '============ USER ============',
    ''
  }
  if api.nvim_buf_line_count(buf) == 0 then
    api.nvim_buf_set_lines(buf, 0, -1, false, content)
  end

  M.config.window = api.nvim_get_current_win()
  M.config.buffer = buf

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
end

function M.close_window()
  -- saving file
  api.nvim_command("w")

  M.config.window_open = 0

  api.nvim_win_close(M.config.window, true)
  M.config.window = nil
  M.config.buffer = nil
end

function M.toggle_window()
  if M.config.window_open == 0 then
    M.open_window()
    M.focus_window()
  else
    M.close_window()
  end
end

function M.focus_window()
  if M.config.window_open == 0 then
    M.open_window()
  end

  api.nvim_set_current_win(M.config.window)
  api.nvim_set_current_buf(M.config.buffer)
end

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

function M.send_message()
  api.nvim_command("w")

  local path = script_path()
  local handle = io.popen(path .. "/copilot/index.ts")
  local result = handle:read("*a")
  handle:close()

  local lines = vim.split(result, "\n")

  table.insert(lines, 1, "")
  table.insert(lines, 1, "============= AI ============")
  table.insert(lines, 1, "")

  -- Putting the result at the end of the buffer
  local buf = api.nvim_get_current_buf()
  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)

  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, -1, line_count, false, {
    "============ USER ===========",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
  api.nvim_command("w")
end

function M.ask(start_line, end_line)
  local selectedLines = vim.fn.getline(start_line, end_line)

  table.insert(selectedLines, 1, "")
  table.insert(selectedLines, 1, "============= CODE ============")
  table.insert(selectedLines, 1, "")

  M.focus_window()

  -- Putting the result at the end of the buffer
  local buf = api.nvim_get_current_buf()
  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, line_count, line_count, false, selectedLines)

  line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, -1, line_count, false, {
    "============ USER ===========",
    "",
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
  api.nvim_command("w")

  -- Entering insert mode
  api.nvim_command("startinsert")
end

function M.resetChat()
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_lines(buf, 0, -1, false, {
    "============ USER ===========",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
end

function M.setup_maps()
  local opts = { noremap = true }

  api.nvim_set_keymap("n", M.config.mappings.focus_window, "<Cmd>lua require('ai-chat').focus_window()<CR>", opts)
  api.nvim_set_keymap("v", M.config.mappings.selected_to_chat, ":AiAsk<CR>", opts)

  api.nvim_command("command! -range AiAsk lua require('ai-chat').ask(<line1>, <line2>)")

  -- setting maps specific to the ai-chat buffer using autocmd
  vim.api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> <C-a> <CMD>lua require('ai-chat').send_message()<CR>")
  vim.api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.focus_window .. " <CMD>lua require('ai-chat').close_window()<CR>")
  vim.api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> <C-d> <CMD>lua require('ai-chat').resetChat()<CR>")
  vim.api.nvim_command("autocmd FileType ai-chat cnoreabbrev <buffer> x <CMD>lua require('ai-chat').close_window()<CR>")
  vim.api.nvim_command("autocmd FileType ai-chat cnoreabbrev <buffer> q <CMD>lua require('ai-chat').close_window()<CR>")
end

function M.setup(user_opts)
  -- M.config = vim.tbl_extend("force", M.config, user_opts or {})

  -- vim.api.nvim_call_function("execute", { vim_func })
  -- vim.api.nvim_command("command! -range CommentToggle lua require('nvim_comment').comment_toggle(<line1>, <line2>)")
  vim.api.nvim_command("command! AiOpen lua require('ai-chat').focus_window()")

  M.setup_maps()
end

return M
