local api = vim.api

local M = {}

local window = require('window')
local macros = require('macros')
local cores = require('cores')
local chat = require('chat')
local config = require('config')

M.edit_core = cores.edit_core
M.change_core = cores.change_core
M.list_cores = cores.list_cores
M.next_core = cores.next_core
M.prev_core = cores.prev_core

M.open_chat = chat.open_chat
M.send_message = chat.send_message
M.reset_chat = chat.reset_chat
M.selection_to_chat = chat.selection_to_chat
M.next_hunk = chat.next_hunk
M.prev_hunk = chat.prev_hunk

M.open_window = window.open_window
M.close_window = window.close_window
M.toggle_fullscreen = window.toggle_fullscreen

M.run_macro = macros.run_macro
M.edit_macro = macros.edit_macro

function M.setup(user_opts)
  config.default = vim.tbl_extend("force", config.default, user_opts or {})

  -- creating directory if not exists
  os.execute("mkdir -p " .. config.default.files.macros_dir)
  os.execute("mkdir -p " .. config.default.files.cores_dir)

  cores.verify_default_core_exist()

  api.nvim_command("command! AiOpen lua require('ai-chat').focus_window()")

  api.nvim_command("command! -nargs=1 AiCoreEdit lua require('ai-chat').edit_core('<args>')")
  api.nvim_command("command! -nargs=1 AiCoreSet lua require('ai-chat').change_core('<args>')")
  api.nvim_command("command! AiCoreList lua require('ai-chat').list_cores()")

  local opts = { noremap = true }

  api.nvim_set_keymap("n", config.default.mappings.focus_window, "<Cmd>lua require('ai-chat').open_chat()<CR>", opts)
  api.nvim_set_keymap("n", config.default.mappings.toggle_fullscreen, "<Cmd>lua require('ai-chat').toggle_fullscreen()<CR>", opts)
  api.nvim_set_keymap("v", config.default.mappings.selected_to_chat, ":AiAsk<CR>", opts)
  api.nvim_set_keymap("v", config.default.mappings.run_macro, ":RunMacro<CR>", opts)
  api.nvim_set_keymap("n", config.default.mappings.run_macro, "V:RunMacro<CR>", opts)
  api.nvim_set_keymap("n", config.default.mappings.edit_macro, ":AiMacroEdit<CR>", opts)

  api.nvim_command("command! -range AiAsk lua require('ai-chat').selection_to_chat(<line1>, <line2>)")
  api.nvim_command("command! -range RunMacro lua require('ai-chat').run_macro(<line1>, <line2>)")
  api.nvim_command("command! -range AiMacroEdit lua require('ai-chat').edit_macro()")


  -- setting maps specific to the ai-chat buffer using autocmd
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    config.default.mappings.send_message .. " <CMD>lua require('ai-chat').send_message()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    config.default.mappings.focus_window .. " <CMD>lua require('ai-chat').close_window()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    config.default.mappings.reset_chat .. " <CMD>lua require('ai-chat').reset_chat()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    config.default.mappings.next_core .. " <CMD>lua require('ai-chat').next_core()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    config.default.mappings.prev_core .. " <CMD>lua require('ai-chat').prev_core()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    config.default.mappings.next_hunk .. " <CMD>lua require('ai-chat').next_hunk()<CR>")
  api.nvim_command("autocmd FileType ai-chat nnoremap <buffer> " ..
    config.default.mappings.prev_hunk .. " <CMD>lua require('ai-chat').prev_hunk()<CR>")
  api.nvim_command("autocmd FileType ai-chat vnoremap <buffer> " ..
    config.default.mappings.next_hunk .. " <CMD>lua require('ai-chat').next_hunk()<CR>")
  api.nvim_command("autocmd FileType ai-chat vnoremap <buffer> " ..
    config.default.mappings.prev_hunk .. " <CMD>lua require('ai-chat').prev_hunk()<CR>")

  api.nvim_command("autocmd FileType ai-chat cnoreabbrev <buffer> x <CMD>lua require('ai-chat').close_window()<CR>")
  api.nvim_command("autocmd FileType ai-chat cnoreabbrev <buffer> q <CMD>lua require('ai-chat').close_window()<CR>")
end

return M
