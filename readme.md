# demo

https://github.com/user-attachments/assets/d03747f9-9188-404f-a172-a570616b1e12

display buffers vertically

inspired by [vuffers](https://github.com/Hajime-Suzuki/vuffers.nvim)

minimal, robust, easy to modify

# default config

```
{
	buvvers_buf_name = "[buvvers]",
	buvvers_buf_opt = {
		-- modifiable = false,
	},
	buvvers_win = {
		win = -1,
		split = "right",
		width = math.ceil(vim.o.columns / 8),
		-- focusable = false,
		-- `focusable` has no effect yet, see https://github.com/neovim/neovim/issues/29365
	},
	buvvers_win_opt = {
		foldcolumn = "0",
		signcolumn = "no",
		number = false,
		relativenumber = false,
		wrap = true,
		-- breakindent = true,
		-- breakindentopt = "shift:4",
		list = false,
		winfixwidth = true,
		winfixheight = true,
		winfixbuf = true,
	},
	name_prefix = function(buffer_handle)
		return "- "
	end,
	highlight_group_current_buffer = "Visual",
}
```

- buvvers_buf_name: buvvers buffer name displayed at status line
- buvvers_buf_opt: buffer options
- buvvers_win: the `config` parameter of `vim.api.nvim_open_win`
- buvvers_win_opt: window options
- name_prefix: a function takes a buffer handle (buffer number) and returns a string used as the prefix of the display name of the buffer
- highlight_group_current_buffer: selection highlight of current buffer

# setup

## setup example 1:

```
require("buvvers").setup()
```

that's it! you can call these functions:

| function                    | description     |
|-----------------------------|-----------------|
| `require("buvvers").open`   | enable buvvers  |
| `require("buvvers").close`  | disable buvvers |
| `require("buvvers").toggle` | toggle buvvers  |

for example, you can run `:lua require("buvvers").open()` to enable buvvers

> note:
>
> you can disable buvvers by:
>
> 1. call `require("buvvers").close`
> 2. close buvvers window
>
> both ways clear buffer & window & autocmd, like buvvers is never opened before

## setup example 2:

if you want to enable buvvers at startup, and bind a key to toggle buvvers:

```
require("buvvers").setup()
require("buvvers").open()

vim.keymap.set("n", "<c-s-b>", require("buvvers").toggle)
-- bind ctrl-shift-b to toggle buvvers
```

## setup example 3:

if you don't like the default "- " prefix:

```
require("buvvers").setup({
	name_prefix = function(buffer_handle)
		return "○ "
	end,
})
-- change the prefix to "○ "
```

```
require("buvvers").setup({
	name_prefix = function(buffer_handle)
		local icon = "󰈔"
		local hl = "ErrorMsg"
		return {
			icon .. " ",
			hl,
		}
	end,
})
-- change the prefix to "󰈔 ", highlight with "ErrorMsg" highlight group
```

```
require("buvvers").setup({
	name_prefix = function(buffer_handle)
		local icon, hl = MiniIcons.get("file", vim.api.nvim_buf_get_name(buffer_handle))
		return {
			icon .. " ",
			hl,
		}
	end,
})
-- change the prefix decided by [mini.icons](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-icons.md)
```

## setup example 4:

the buvvers buffer does not have any keybindings by default

you can add keybindings yourself with these api and "BuvversAttach" autocmd

| function                                    | description               |
|---------------------------------------------|---------------------------|
| `require("buvvers").get_buvvers_buf_handle` | get buvvers buffer handle |
| `require("buvvers").get_current_buf_handle` | get current buffer handle |

---

for example, bind "d" to delete buffer and "o" to open buffer:

> [mini.bufremove](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-bufremove.md) is required in this example

```
vim.api.nvim_create_autocmd(
	"User",
	{
		group = vim.api.nvim_create_augroup("buvvers_keymap", {clear = true}),
		pattern = "BuvversAttach",
		callback = function()
			vim.keymap.set(
				"n",
				"d",
				function()
					local current_buf_handle = require("buvvers").get_current_buf_handle()
					MiniBufremove.delete(current_buf_handle, false)
				end,
				{
					buffer = require("buvvers").get_buvvers_buf_handle(),
					nowait = true,
				}
			)
			vim.keymap.set(
				"n",
				"o",
				function()
					local current_buf_handle = require("buvvers").get_current_buf_handle()
					local previous_win_handle = vim.fn.win_getid(vim.fn.winnr("#"))
					-- https://github.com/nvim-neo-tree/neo-tree.nvim/blob/0b44040ec7b8472dfc504bbcec735419347797ad/lua/neo-tree/utils/init.lua#L643
					vim.api.nvim_win_set_buf(previous_win_handle, current_buf_handle)
					vim.api.nvim_set_current_win(previous_win_handle)
				end,
				{
					buffer = require("buvvers").get_buvvers_buf_handle(),
					nowait = true,
				}
			)
		end,
	})
```
