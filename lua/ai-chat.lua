local api = vim.api

local M = {}

M.config = {
  window_open = 0,
  mappings = {
    focus_window = '<LEADER>m',
    selected_to_chat = '<LEADER>m',
  }
}

function M.open_window()
  if M.config.window_open == 1 then
    return
  end
  M.config.window_open = 1

  -- Opens a window on the right side of the screen
  local width = math.floor(vim.o.columns * 0.3)

  local buf = api.nvim_create_buf(false, true)

  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = vim.o.lines,
    col = vim.o.columns - width,
    row = 0,
    style = "minimal",
    border = "single",
  })
end

function M.close_window()
  M.config.window_open = 0
end

function M.toggle_window()
  if M.config.window_open == 0 then
    M.open_window()
  else
    M.close_window()
  end
end

function M.focus_window()
  if M.config.window_open == 0 then
    M.open_window()
  end
end

function M.setup(user_opts)
  M.config = vim.tbl_extend("force", M.config, user_opts or {})

  -- Messy, change with nvim_exec once merged
  local vim_func = [[
  function! CommentOperator(type) abort
    let reg_save = @@
    execute "lua require('nvim_comment').operator('" . a:type. "')"
    let @@ = reg_save
  endfunction
  ]]

  vim.api.nvim_call_function("execute", { vim_func })
  vim.api.nvim_command("command! -range CommentToggle lua require('nvim_comment').comment_toggle(<line1>, <line2>)")

  local opts = { noremap = true }

  api.nvim_set_keymap("n", M.config.mappings.focus_window, "<Cmd>lua require('ai-chat').focus_window()<CR>", opts)
end

return M
