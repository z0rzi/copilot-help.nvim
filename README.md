# Ai Chat

Flexible way to chat with Copilot AI.

## Setup

Using lazy:

```lua
    return { 'z0rzi/ai-chat.nvim',
        config = function()
            require('ai-chat').setup {}
        end,
    },
```


Default configuration:
```lua
{
  mappings = {
    focus_window = '<LEADER>m',
    selected_to_chat = '<LEADER>m',
    run_macro = '<LEADER>k',
    edit_macro = '<LEADER>K',
    next_hunk = ']]',
    prev_hunk = '[[',
    reset_chat = '<C-d>'
  },

  files = {
    chat_file = os.getenv("HOME") .. '/.config/ai-chat/chat.md',
    macros_dir = os.getenv("HOME") .. '/.config/ai-chat/macros/'
  }
}
```

## Chat

Keymaps:

- `<LEADER>m` in normal mode to open the chat.
- `<LEADER>m` in visual mode to send the current text to the chat. All previous messages in the chat will be erased by default.

## Macros

You can also save "macros", meaning operations which you can then apply to specific pieces of code.

Here is an example of macro to add comment to code:

```
Add comments to this code.

The code itself should stay as is.

Do not add a comment at every line, just add a few multi-line comments to explain the code.
```

Keymaps:

- `<LEADER>K?` to create a new macro
- `<LEADER>k?` to use a macro
