local api = vim.api

local M = {
  window = nil,
  in_current_buffer = false,
  gh_device_code = nil
}

M.config = {
  mappings = {
    open_chat_in_current_buffer = '<LEADER>M',
    focus_window = '<LEADER>m',
    selected_to_chat = '<LEADER>m',
    run_macro = '<LEADER>k',
    edit_macro = '<LEADER>K',
    next_hunk = ']]',
    prev_hunk = '[[',
    next_core = '}}',
    prev_core = '{{',
    reset_chat = '<C-d>'
  },
  bun_executable = nil,

  core_instructions = 'code',

  files = {
    chat_file = os.getenv("HOME") .. '/.config/ai-chat/chat.md',
    macros_dir = os.getenv("HOME") .. '/.config/ai-chat/macros/',
    cores_dir = os.getenv("HOME") .. '/.config/ai-chat/cores/'
  }
}

local function get_plugin_path()
  local path = debug.getinfo(1, "S").source:sub(2)
  return path:match("(.*/)")
end

local function script_path()
  local dir_path = get_plugin_path()
  -- if there is no executable or bun_executable in the config, we will use the shipped bun executable
  local bun_path = string.format("%s ", vim.fn.exepath("bun") or M.config.bun_executable or "")
  return string.format("%s%scopilot/index.ts ", bun_path, dir_path)
end

local function copy_file(source, destination)
  local handle = io.open(source, "r")
  local content = handle:read("*a")
  handle:close()

  handle = io.open(destination, "w+")
  handle:write(content)
  handle:close()
end

local function run_copilot_script(args)
  local path = script_path()

  if M.gh_device_code ~= nil then
    local handle = io.popen(path .. "connect " .. M.gh_device_code)
    local result = handle:read("*a")
    handle:close()
    M.gh_device_code = nil
  end

  local command = path .. args

  if M.config.core_instructions ~= nil then
    local core_file = M.config.files.cores_dir .. M.config.core_instructions .. ".md"
    command = command .. " --core_instruction_file=" .. core_file
  end

  local handle = io.popen(command)
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
    result = "Please visit " ..
        verification_uri .. " and enter " .. user_code .. "\n\nOnce this is done, ask me something!\n"
  end

  return result
end

function M.open_window(in_current_buffer)
  if M.is_window_open() then
    M.close_window()
    return
  end

  in_current_buffer = in_current_buffer or false

  M.in_current_buffer = in_current_buffer

  if not in_current_buffer then
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

  if api.nvim_buf_line_count(buf) <= 3 then
    -- Setting buffer content if it is empty
    local content = {
      '============ USER ============',
      '',
      ''
    }
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

  -- applying markdown coloring
  api.nvim_command("runtime! syntax/markdown.vim")


  api.nvim_command("normal! G")
end

function M.open_macro(macro_name)
  M.focus_window()
  api.nvim_command('edit ' .. M.config.files.macros_dir .. macro_name .. '.md')

  -- Setting buffer options
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'swapfile', false)
  api.nvim_buf_set_option(buf, 'filetype', 'ai-chat')

  -- applying markdown coloring
  api.nvim_command("runtime! syntax/markdown.vim")
end

function M.close_window()
  -- saving file
  api.nvim_command("silent!w")

  if M.in_current_buffer then
    -- if we are in the current buffer, we forget the window ID
    M.window = nil
    M.in_current_buffer = false

    -- closing the buffer
    api.nvim_command("silent!bd")

    return
  end

  -- if it's the only window, we close vim
  if #api.nvim_list_wins() == 1 then
    api.nvim_command("q")
    return
  end

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

local function find_code_block_in_text(lines)
  -- Given a list of lines, returns the start and end line of the code block
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

function M.send_message()
  api.nvim_command("silent!w")

  local result = run_copilot_script("chat " .. M.config.files.chat_file)

  local lines = vim.split(result, "\n")

  table.insert(lines, 1, "")
  table.insert(lines, 1, "# ============= AI =============")
  table.insert(lines, 1, "")

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
    "# ============ USER ===========",
    "",
    ""
  })

  if code_start ~= nil then
    -- Copying the code block content
    local code_length = code_end - code_start
    api.nvim_win_set_cursor(0, { code_start, 0 })
    api.nvim_command("normal! y" .. code_length .. "j")
  end
  api.nvim_command("normal! G")
  api.nvim_command("silent!w")
end

function M.selection_to_chat(start_line, end_line)
  local selectedLines = vim.fn.getline(start_line, end_line)
  local filetype = vim.bo.filetype

  -- inserting lines at the start of the code snippet
  table.insert(selectedLines, 1, "```" .. filetype)
  table.insert(selectedLines, 1, "")
  table.insert(selectedLines, 1, "# ============= CODE ============")
  table.insert(selectedLines, 1, "")

  -- inserting lines at the end of the code snippet
  table.insert(selectedLines, "```")

  M.focus_window()
  M.open_chat()

  -- removing the old chat
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_lines(buf, 0, -1, false, { '' })

  -- Putting the selected lines at the end of the buffer
  local line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, line_count, line_count, false, selectedLines)

  line_count = api.nvim_buf_line_count(buf)
  api.nvim_buf_set_lines(buf, -1, line_count, false, {
    "",
    "# ============ USER ============",
    "",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
  api.nvim_command("silent!w")

  -- Entering insert mode
  api.nvim_command("startinsert")
end

function M.reset_chat()
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_lines(buf, 0, -1, false, {
    "# ============ USER ============",
    "",
    ""
  })

  -- setting cursor at the end of the buffer
  api.nvim_command("normal! G")
end

local function get_available_cores()
  local cores = vim.fn.glob(M.config.files.cores_dir .. "*.md", true, true)
  local core_names = {}
  for _, core in ipairs(cores) do
    -- Stripping the path and the extension
    local core_name = string.sub(core, string.len(M.config.files.cores_dir) + 1, -4)
    table.insert(core_names, core_name)
  end

  return core_names
end

local function get_default_cores()
  local plugin_dir = get_plugin_path()
  local default_cores_dir = plugin_dir .. "/default-core-instructions/"
  local default_cores_paths = vim.fn.glob(default_cores_dir .. "*.md", true, true)

  local default_cores = {}
  for _, core in ipairs(default_cores_paths) do
    -- Stripping the path and the extension
    local name = string.sub(core, string.len(default_cores_dir) + 1, -4)
    table.insert(default_cores, name)
  end

  return default_cores
end

function M.change_core(core_name)
  -- Changes the core instructions of the chat.
  local core_names = get_available_cores()

  if not vim.tbl_contains(core_names, core_name) then
    print("Core " .. core_name .. " does not exist")
    return
  end

  M.config.core_instructions = core_name

  print("Core changed to " .. core_name .. ". To make this change permanent, add it to the plugin configuration.")
end

function M.list_cores()
  -- Lists all of the cores available
  local core_names = get_available_cores()
  if #core_names == 0 then
    print("No cores available")
    return
  end

  print("Available cores:")
  print("- " .. table.concat(core_names, "\n- "))
end

function M.edit_core(core_name)
  -- Opening the core in the editor
  M.focus_window()
  api.nvim_command('edit ' .. M.config.files.cores_dir .. core_name .. '.md')

  -- Setting buffer options
  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'swapfile', false)
  api.nvim_buf_set_option(buf, 'filetype', 'ai-chat')

  -- applying markdown coloring
  api.nvim_command("runtime! syntax/markdown.vim")
end

function M.next_core()
  -- Changes the core instructions of the chat.
  local core_names = get_available_cores()
  local current_core = M.config.core_instructions

  if current_core == nil then
    print("No core selected")
    return
  end

  local current_core_index = vim.fn.index(core_names, current_core)
  local next_core_index = ((current_core_index + 1) % #core_names)
  local next_core = core_names[next_core_index + 1]

  print("Changing core to " .. next_core)
  M.config.core_instructions = next_core
end

function M.prev_core()
  -- Changes the core instructions of the chat.
  local core_names = get_available_cores()
  local current_core = M.config.core_instructions

  if current_core == nil then
    print("No core selected")
    return
  end

  local current_core_index = vim.fn.index(core_names, current_core)
  local prev_core_index = ((current_core_index - 1 + #core_names) % #core_names)
  local prev_core = core_names[prev_core_index + 1]

  print("Changing core to " .. prev_core)
  M.config.core_instructions = prev_core
end

-- Resets the specified core to the default one.
-- If no default core exists for the specified name, nothing happens.
function M.reset_core_to_default(core_name)
  -- finding all the available default cores
  local default_cores = get_default_cores()

  -- if there is no default core for the specified name, we do nothing
  if not vim.tbl_contains(default_cores, core_name) then
    return
  end

  -- copying the default core to the cores directory, overwriting the existing one
  local plugin_dir = get_plugin_path()
  local default_core_path = plugin_dir .. "/default-core-instructions/" .. core_name .. ".md"
  local core_path = M.config.files.cores_dir .. core_name .. ".md"

  copy_file(default_core_path, core_path)
end

-- Makes sure that all the default cores are present in the cores directory.
-- If not, copies them from the plugin directory.
local function verify_default_core_exist()
  local default_cores = get_default_cores()

  for _, core_name in ipairs(default_cores) do
    -- if there is no default core for the specified name, we do nothing
    local core_path = M.config.files.cores_dir .. core_name .. ".md"
    if vim.fn.filereadable(core_path) == 0 then
      -- copying the default core to the cores directory, overwriting the existing one
      local plugin_dir = get_plugin_path()
      local default_core_path = plugin_dir .. "/default-core-instructions/" .. core_name .. ".md"

      copy_file(default_core_path, core_path)
    end
  end
end

function M.edit_macro()
  -- getting one character from the input
  local macro_name = vim.fn.nr2char(vim.fn.getchar())
  M.open_macro(macro_name)
end

function M.run_macro(start_line, end_line)
  local macro_name = vim.fn.nr2char(vim.fn.getchar())

  local file_path = M.config.files.macros_dir .. macro_name .. '.md'

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
  local handle = io.popen(path .. "macro " .. file_path .. " " .. code_file_path)
  local result = handle:read("*a")
  handle:close()

  -- removing the old selection
  api.nvim_command("normal! gvd")

  -- inserting the result
  local lines = vim.split(result, "\n")
  local current_line = vim.fn.line(".")
  api.nvim_buf_set_lines(0, current_line - 1, current_line - 1, false, lines)
end

function M.next_hunk()
  -- searching for the next '^======' using vim native search
  vim.fn.search('^# ======', 'W')
end

function M.prev_hunk()
  -- searching for the next '^======' using vim native search
  vim.fn.search('^# ======', 'bW')
end

function M.setup(user_opts)
  M.config = vim.tbl_extend("force", M.config, user_opts or {})

  verify_default_core_exist()

  -- creating directory if not exists
  os.execute("mkdir -p " .. M.config.files.macros_dir)
  os.execute("mkdir -p " .. M.config.files.cores_dir)

  api.nvim_command("command! AiOpen lua require('ai-chat').focus_window()")

  api.nvim_command("command! -nargs=1 AiCoreEdit lua require('ai-chat').edit_core('<args>')")
  api.nvim_command("command! -nargs=1 AiCoreSet lua require('ai-chat').change_core('<args>')")
  api.nvim_command("command! AiCoreList lua require('ai-chat').list_cores()")

  local opts = { noremap = true }

  api.nvim_set_keymap("n", M.config.mappings.focus_window, "<Cmd>lua require('ai-chat').open_chat()<CR>", opts)
  api.nvim_set_keymap("n", M.config.mappings.open_chat_in_current_buffer,
    "<Cmd>lua require('ai-chat').open_window(true)<CR><CMD>lua require('ai-chat').open_chat()<CR>", opts)
  api.nvim_set_keymap("v", M.config.mappings.selected_to_chat, ":AiAsk<CR>", opts)
  api.nvim_set_keymap("v", M.config.mappings.run_macro, ":RunMacro<CR>", opts)
  api.nvim_set_keymap("n", M.config.mappings.run_macro, "V:RunMacro<CR>", opts)
  api.nvim_set_keymap("n", M.config.mappings.edit_macro, ":AiMacroEdit<CR>", opts)

  api.nvim_command("command! -range AiAsk lua require('ai-chat').selection_to_chat(<line1>, <line2>)")
  api.nvim_command("command! -range RunMacro lua require('ai-chat').run_macro(<line1>, <line2>)")
  api.nvim_command("command! -range AiMacroEdit lua require('ai-chat').edit_macro()")

  -- setting maps specific to the ai-chat buffer using autocmd
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> <C-a> <CMD>lua require('ai-chat').send_message()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.focus_window .. " <CMD>lua require('ai-chat').close_window()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.open_chat_in_current_buffer .. " <CMD>lua require('ai-chat').close_window()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.reset_chat .. " <CMD>lua require('ai-chat').reset_chat()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.next_core .. " <CMD>lua require('ai-chat').next_core()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.prev_core .. " <CMD>lua require('ai-chat').prev_core()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.next_hunk .. " <CMD>lua require('ai-chat').next_hunk()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    M.config.mappings.prev_hunk .. " <CMD>lua require('ai-chat').prev_hunk()<CR>")
  api.nvim_command("autocmd FileType ai-chat vnoremap <buffer> " ..
    M.config.mappings.next_hunk .. " <CMD>lua require('ai-chat').next_hunk()<CR>")
  api.nvim_command("autocmd FileType ai-chat vnoremap <buffer> " ..
    M.config.mappings.prev_hunk .. " <CMD>lua require('ai-chat').prev_hunk()<CR>")

  api.nvim_command("autocmd FileType ai-chat cnoreabbrev <buffer> x <CMD>lua require('ai-chat').close_window()<CR>")
  api.nvim_command("autocmd FileType ai-chat cnoreabbrev <buffer> q <CMD>lua require('ai-chat').close_window()<CR>")
end

return M
