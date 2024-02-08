local config = {
  default = {
    mappings = {
      -------------------------
      -- OUTSIDE OF THE CHAT --
      -------------------------

      -- Opens the chat in the side window
      focus_window = '<LEADER>m',

      -- Toggles the fullscreen mode of the chat
      toggle_fullscreen = '<LEADER>M',

      -- Sends the selected text to the chat, and starts insert mode
      selected_to_chat = '<LEADER>m',

      -- Prompts the user for a character, and runs the macro on the selected text
      run_macro = '<LEADER>k',

      -- Prompts the user for a character, edit the macro
      edit_macro = '<LEADER>K',


      ---------------------
      -- INSIDE THE CHAT --
      ---------------------

      -- Goes the next / previous message
      next_hunk = ']]',
      prev_hunk = '[[',

      -- Cycles through the availables core instructions
      next_core = '}}',
      prev_core = '{{',

      -- Sends a message to the AI
      send_message = '<C-a>',

      -- Removes all the messages from the chat
      reset_chat = '<C-d>'
    },

    -- If the provided bun executable doesn't work for you, you can specify a path here
    bun_executable = nil,

    -- The core instructions to load at startup
    core_instructions = 'code',

    -- If true, the chat window will replace the current buffer.
    -- Otherwise, it will open in a vertical split.
    fullscreen = true,

    -- If true, the previous messages will be forgotten when sending the current selection to the chat
    reset_chat_on_selection_send = true,

    files = {
      -- The place where the current chat is saved
      chat_file = os.getenv("HOME") .. '/.config/ai-chat/chat.md',

      -- The directory where the macros are saved
      macros_dir = os.getenv("HOME") .. '/.config/ai-chat/macros/',

      -- The place where the core instructions are saved
      cores_dir = os.getenv("HOME") .. '/.config/ai-chat/cores/'
    }
  }
}

return config;
