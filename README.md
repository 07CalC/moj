# 🕹️ moj.nvim

Play retro games like **Snake** 🐍 and **Flappy Bird** 🐦 inside Neovim using floating windows.  
A fun little break without leaving your editor.

![2025-06-20-235644_hyprshot](https://github.com/user-attachments/assets/56e18b7d-e140-41ce-a7ac-0c58f1951f83)

---

## ✨ Features

- 🎮 Snake and Flappy Bird in Neovim!
- 🎨 Respects your current theme colors
- 🧊 Runs in a floating window
- 🛑 Graceful game over 
- 🪶 Lightweight, no dependencies

---

## 📦 Installation

### Lazy.nvim

```lua
{
  "07CalC/moj",
  cmd = "Moj",
  init = function()
    require("moj") -- ensures command gets defined
  end,
}
```

### Packer.nvim

```lua
use {
  "07CalC/moj",
  config = function()
    require("moj")
  end
}
```

## 🚀 Usage
### Run from Neovim command mode:
```vim
:Moj snake
:Moj flappy
```

## 📁 File Structure
```bash
moj/
├── lua/
│   └── moj/
│       ├── init.lua        -- command + game router
│       ├── snake.lua       -- snake game
│       └── flappy.lua      -- flappy bird game
├── README.md
```

## 🧑‍💻 Author
Made by 07CalC — just for fun.
Feel free to star ⭐, fork 🍴, or contribute 🛠️!
