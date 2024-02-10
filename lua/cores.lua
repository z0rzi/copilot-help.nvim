local api = vim.api

local utils = require('utils')
local config = require('config')
local window = require('window')

local M = {}

-- Gives all the available cores. Meaning the default ones, and the ones added by the user.
local function get_available_cores()
  local cores = vim.fn.glob(config.default.files.cores_dir .. "*.md", true, true)
  local core_names = {}
  for _, core in ipairs(cores) do
    -- Stripping the path and the extension
    local core_name = string.sub(core, string.len(config.default.files.cores_dir) + 1, -4)
    table.insert(core_names, core_name)
  end

  return core_names
end

-- Gives all the default cores, present in the plugin directory.
local function get_default_cores()
  local plugin_dir = utils.get_plugin_path()
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

-- Changes the currently used core in the chat
function M.change_core(core_name)
  -- Changes the core instructions of the chat.
  local core_names = get_available_cores()

  if not vim.tbl_contains(core_names, core_name) then
    print("Core " .. core_name .. " does not exist")
    return
  end

  config.default.core_instructions = core_name

  print("Core changed to " .. core_name .. ". To make this change permanent, add it to the plugin configuration.")
end

-- Lists all of the available cores in the vim command line.
function M.list_cores()
  local core_names = get_available_cores()
  if #core_names == 0 then
    print("No cores available")
    return
  end

  print("Available cores:")
  print("- " .. table.concat(core_names, "\n- "))
end

-- Open the core file in the chat window.
-- If the core file doesn't exist yet, it creates a new one.
function M.edit_core(core_name)
  window.focus_window()
  api.nvim_command('edit ' .. config.default.files.cores_dir .. core_name .. '.md')

  -- Setting buffer options
  local buf = api.nvim_get_current_buf()

  window.configure_buffer(buf)
end

-- Changes to the next core instructions for the chat
function M.next_core()
  local core_names = get_available_cores()
  local current_core = config.default.core_instructions

  if current_core == nil then
    print("No core selected")
    return
  end

  local current_core_index = vim.fn.index(core_names, current_core)
  local next_core_index = ((current_core_index + 1) % #core_names)
  local next_core = core_names[next_core_index + 1]

  print("Changing core to " .. next_core)
  config.default.core_instructions = next_core
end

-- Changes to the previous core instructions for the chat
function M.prev_core()
  local core_names = get_available_cores()
  local current_core = config.default.core_instructions

  if current_core == nil then
    print("No core selected")
    return
  end

  local current_core_index = vim.fn.index(core_names, current_core)
  local prev_core_index = ((current_core_index - 1 + #core_names) % #core_names)
  local prev_core = core_names[prev_core_index + 1]

  print("Changing core to " .. prev_core)
  config.default.core_instructions = prev_core
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
  local plugin_dir = utils.get_plugin_path()
  local default_core_path = plugin_dir .. "/default-core-instructions/" .. core_name .. ".md"
  local core_path = config.default.files.cores_dir .. core_name .. ".md"

  utils.copy_file(default_core_path, core_path)
end

-- Makes sure that all the default cores are present in the cores directory.
-- If not, copies them from the plugin directory.
function M.verify_default_core_exist()
  local default_cores = get_default_cores()

  for _, core_name in ipairs(default_cores) do
    -- if there is no default core for the specified name, we do nothing
    local core_path = config.default.files.cores_dir .. core_name .. ".md"
    if vim.fn.filereadable(core_path) == 0 then
      -- copying the default core to the cores directory, overwriting the existing one
      local plugin_dir = utils.get_plugin_path()
      local default_core_path = plugin_dir .. "/default-core-instructions/" .. core_name .. ".md"

      utils.copy_file(default_core_path, core_path)
    end
  end
end

return M
