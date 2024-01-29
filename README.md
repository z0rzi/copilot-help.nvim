# Ai Chat

Flexible way to chat with Copilot AI.


https://github.com/z0rzi/ai-chat.nvim/assets/22566633/c0e2f6bf-9cae-4665-82a1-3d53cc58ef70

This plugin is written in LUA for the interface part, and in TypeScript for the communication with copilot.

It is shipped with a typescript runtime (`bun`) for Linux. For other operating systems, either make sure the `bun` runtime is in your `$PATH` or specify an executable path using `bun_executable` in the config.

## ⚠️ Disclaimer ⚠️

This plugin is a POC more than an actual plugin. It has not been tested, the code is not well commented, and could be improved a lot.

If you wish to contribute, please, do so!

## Setup

Using lazy:

```lua
    return { 'z0rzi/ai-chat.nvim',
        config = function()
            require('ai-chat').setup {}
        end,
    },
```

You will then have to connect to github using the chat interface, as seen below:

https://github.com/z0rzi/ai-chat.nvim/assets/22566633/0a1e410f-a968-42a7-bf50-0d826f5d471e



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
  bun_executable = nil,

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
- `<LEADER>a` sends the current user message to copilot.
- `<LEADER>d` clears the prompt.

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

## Core Instructions

You can change the core instructions given to the AI.

The core instruction is a message provided to the AI at the start of the conversation, to define his identity.

The default core instructions of the AI are defined in the `lua/copilot/constants.ts` file.

For example :
```
:AiCoreEdit comedian
```

```markdown
comedian.md

You are a virtual comedian.
Your role is to make people laugh.
Whatever the user asks you, try your best to make a pun out of it.
Never give informative answer.
If the user doesn't understand a joke, try your best to explain it.
```

```
:AiCoreSet comedian
```

Congratulations, your AI Assistant is now a comedian!
