> thank you for your love and support for buvvers! 😊❤️
>
> buvvers is stable now, but some config options may change slightly
>
> if you run into issues, check this readme
>
> i won't modify configurable options unless absolutely necessary—rest assured!

# demo

[demo](https://github.com/user-attachments/assets/d03747f9-9188-404f-a172-a570616b1e12)

display buffers vertically

minimal, robust, highly customizable, easily modifiable source code

inspired by [vuffers](https://github.com/Hajime-Suzuki/vuffers.nvim)

# default config

```lua
{
	buvvers_buf_name = "[buvvers]",
	-- buvvers buffer name displayed on status line

	buvvers_buf_opt = {
	-- buvvers buffer local options
	},

	buvvers_win = {
	-- the `config` parameter of `vim.api.nvim_open_win`
		win = -1,
		split = "right",
		width = math.ceil(vim.o.columns / 8),
		style = "minimal",
	},

	buvvers_win_opt = {
	-- buvvers window local options
		wrap = true,
		winfixwidth = true,
		winfixheight = true,
		winfixbuf = true,
	},

	highlight_group_current_buffer = "Visual",
	-- inside buvvers buffer, the current buffer is highlighted with this highlight group

	buffer_handle_list_to_buffer_name_list = function(handle_l)
	-- this is the core function of buvvers, see details below
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		return name_l
	end,
}
```

# setup

## setup example 1:

```lua
require("buvvers").setup()
```

that's it!

you can call these functions:

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
> 2. delete buvvers buffer
> 3. close buvvers window
>
> these ways are equivalent
>
> they completely clear everything related to buvvers (buffer, window, and autocmd), as if buvvers was never opened before

## setup example 2:

if you want to bind a key to toggle buvvers, and enable buvvers at startup:

```lua
require("buvvers").setup()

vim.keymap.set("n", "<leader>bl", require("buvvers").toggle)
-- bind `<leader>bl` to toggle buvvers

require("buvvers").open()
-- enable buvvers at startup
```

## setup example 3:

you can customize the display buffer names by modifying `buffer_handle_list_to_buffer_name_list` function

the function's input is a `buffer_handle_list`, for example:

```lua
-- example 1:
{1, 6, 7, 8}

-- example 2:
{1, 6, 7, 8, 9, 10}
```

the function's output is a `buffer_name_list`, for example:

```lua
-- example 1:
{
	"dwm.c",
	"buvvers.lua",
}

-- example 2:
{
	{
		"󰙱 ",
		"dwm.c",
	},
	{
		"󰢱 ",
		"buvvers.lua",
	},
}

-- example 3:
{
	{
		{"󰙱 ", "DiffAdd"}, -- DiffAdd is a highlight group
		"dwm.c",
	},
	{
		{"󰢱 ", "DiffChange"},
		"buvvers.lua",
	},
}

-- example 4:
{
	{
		{"󰙱 ", "DiffAdd"},
		"dwm.c",
		" love",
		{" you", "DiffAdd"},
	},
	{
		{"󰢱 ", "DiffChange"},
		"buvvers.lua",
		" love",
		{" you", "DiffChange"},
	},
}
```

the length of `buffer_name_list` should be equal to `buffer_handle_list`, of course

### setup example 3-1:

now, if you were the author of buvvers, how can you write such function?

you may say: "ahh, this is easy"

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l = {}
		for _, i in ipairs(handle_l) do
			table.insert(name_l, vim.fn.bufname(i))
		end
		return name_l
	end,
})
```

this implementation has many limitations, but you're encouraged to give it a try anyway

### setup example 3-2:

buvvers has a default implementation built in, these 2 setups are equivalent:

```lua
require("buvvers").setup()
```

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = require("buvvers.buffer_handle_list_to_buffer_name_list"),
})
```

the default implementation features:

1. unique name
2. handle unnamed buffers
3. handle special buftype

typically, you want to adjust the default function:

### setup example 3-3:

if you want to add a "○ " prefix

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		for n, name in ipairs(name_l) do
			name_l[n] = "○ " .. name
		end

		return name_l
	end,
})
```

### setup example 3-4:

if you want to add a "󰈔 " prefix, highlight with "ErrorMsg" highlight group

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		for n, name in ipairs(name_l) do
			name_l[n] = {
				{"󰈔 ", "ErrorMsg"},
				name,
			}
		end

		return name_l
	end,
})
```

### setup example 3-5:

if you want to add a prefix decided by [mini.icons](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-icons.md)

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		for n, name in ipairs(name_l) do
			local icon, hl = MiniIcons.get("file", name)
			name_l[n] = {
				{icon .. " ", hl},
				name,
			}
		end

		return name_l
	end,
})
```

### setup example 3-6:

if you want to add a prefix that indicate whether a buffer is modified

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		for n, name in ipairs(name_l) do
			local is_modified = vim.api.nvim_get_option_value("modified", {buf = handle_l[n]})
			local prefix
			if is_modified then
				prefix = "[+]"
			else
				prefix = "[ ]"
			end
			name_l[n] = {
				prefix,
				" ",
				name,
			}
		end

		return name_l
	end,
})
```

however, this won't work as expected because buvvers doesn't refresh when a buffer's modification state changes

to refresh buvvers, use:

| function                          | description     |
|-----------------------------------|-----------------|
| `require("buvvers").buvvers_open` | refresh buvvers |

note the function name is `require("buvvers").buvvers_open`, not `require("buvvers").open`

i will cover how to set an autocmd to refresh automatically [later](#setup-example-4-2)

## setup example 4:

## setup example 4-1:

the buvvers buffer does not have any keybindings by default

you can add keybindings yourself with these functions and "BuvversAttach" autocmd

| function                                 | description                                                                      |
|------------------------------------------|----------------------------------------------------------------------------------|
| `require("buvvers").buvvers_get_buf`     | get buvvers buffer                                                               |
| `require("buvvers").buvvers_buf_get_buf` | get the buffer that is displayed in the buvvers buffer at a specific line number |

for example, bind "d" to delete buffer and "o" to open buffer:

> [mini.bufremove](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-bufremove.md) is required

```lua
require("buvvers").setup()

vim.keymap.set("n", "<leader>bl", require("buvvers").toggle)
-- bind `<leader>bl` to toggle buvvers

local buvvers_customize = function()
	vim.keymap.set(
		"n",
		"d",
		function()
			local cursor_buf_handle = require("buvvers").buvvers_buf_get_buf(vim.fn.line("."))
			MiniBufremove.delete(cursor_buf_handle, false)
		end,
		{
			buffer = require("buvvers").buvvers_get_buf(),
			nowait = true,
		}
	)
	vim.keymap.set(
		"n",
		"o",
		function()
			local cursor_buf_handle = require("buvvers").buvvers_buf_get_buf(vim.fn.line("."))
			local previous_win_handle = vim.fn.win_getid(vim.fn.winnr("#"))
			-- https://github.com/nvim-neo-tree/neo-tree.nvim/blob/0b44040ec7b8472dfc504bbcec735419347797ad/lua/neo-tree/utils/init.lua#L643
			vim.api.nvim_win_set_buf(previous_win_handle, cursor_buf_handle)
			vim.api.nvim_set_current_win(previous_win_handle)
		end,
		{
			buffer = require("buvvers").buvvers_get_buf(),
			nowait = true,
		}
	)
end
vim.api.nvim_create_autocmd(
	"User",
	{
		group = vim.api.nvim_create_augroup("buvvers_customize", {clear = true}),
		pattern = "BuvversAttach",
		callback = buvvers_customize,
	})
-- use "BuvversAttach" to add buffer local keybindings

require("buvvers").open()
-- enable buvvers at startup
```

the reason we need to bind keys in an autocmd is that when buvvers is closed, its buffer is deleted, causing the keybindings to be lost

## setup example 4-2:

this is the full setup of the setup mentioned [before](#setup-example-3-6)

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		for n, name in ipairs(name_l) do
			local is_modified = vim.api.nvim_get_option_value("modified", {buf = handle_l[n]})
			local prefix
			if is_modified then
				prefix = "[+]"
			else
				prefix = "[ ]"
			end
			name_l[n] = {
				prefix,
				" ",
				name,
			}
		end

		return name_l
	end,
})

vim.keymap.set("n", "<leader>bl", require("buvvers").toggle)
-- bind `<leader>bl` to toggle buvvers

local buvvers_customize = function()
	vim.api.nvim_create_autocmd(
		{
			"BufModifiedSet",
		},
		{
			group = vim.api.nvim_create_augroup("buvvers", {clear = false}),
			callback = require("buvvers").buvvers_open,
		}
	)
end
vim.api.nvim_create_autocmd(
	"User",
	{
		group = vim.api.nvim_create_augroup("buvvers_customize", {clear = true}),
		pattern = "BuvversAttach",
		callback = buvvers_customize,
	})
-- use "BuvversAttach" to add a autocmd that refresh buvvers when BufModifiedSet event is triggered

require("buvvers").open()
-- enable buvvers at startup
```

the reason we need to set autocmd in an autocmd is that when buvvers is closed, its autocmd is deleted, causing the autocmd to be lost
