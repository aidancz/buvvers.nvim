# demo

[demo](https://github.com/user-attachments/assets/498bfeac-d643-4879-9ca9-5767112279c0)

display buffers vertically (use a floating window by default)

minimal and robust

inspired by [vuffers](https://github.com/Hajime-Suzuki/vuffers.nvim)

# default config

```lua
{
	buf_name = "[buvvers]",
	-- buffer name displayed on status line

	buf_opt = {
	-- buffer local options
		filetype = "buvvers",
	},

	buf_hook = function(buf) end,
	-- buffer hook

	win_open = function(buf)
	-- how should buvvers open its window?
		return
		vim.api.nvim_open_win(
			buf,
			false,
			{
				relative = "editor",
				anchor = "NE",
				border = "none",
				row = 0,
				col = vim.o.columns,
				width = math.floor(vim.o.columns / 8),
				height = vim.o.lines - 2,
				style = "minimal",
				focusable = false,
				zindex = 1,
			}
		)
	end,

	win_opt = {
	-- window local options
		winfixbuf = true,
		winfixwidth = true,
		winfixheight = true,
		wrap = true,
	},

	win_hook = function(win) end,
	-- window hook

	autocmd_additional_refresh_event = nil,
	-- additional autocmd event that trigger a refresh

	autocmd_winclosed_do = "refresh",
	-- what to do when you try to close the window?
	-- "refresh"|"close"

	autocmd_hook = function(augroup) end,
	-- autocmd hook

	highlight_group_current_buffer = "Visual",
	-- inside buvvers buffer, the current buffer is highlighted with this highlight group

	buffer_handle_list_to_buffer_name_list = require("buvvers.buffer_handle_list_to_buffer_name_list"),
	-- this is the core function of buvvers, see details below
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

the buffer & window & autocmd of buvvers are tied to each other

you can only enable / disable them all

so when you try to close the window of buvvers, you have to choose:

1. refresh buvvers (this makes it feel like you can't close the window)

```lua
require("buvvers").setup({
	autocmd_winclosed_do = "refresh",
})
require("buvvers").open()
```

2. close buvvers

```lua
require("buvvers").setup({
	autocmd_winclosed_do = "close",
})
require("buvvers").open()
```

## setup example 4:

if you want to change how the buvvers window behaves:

```lua
require("buvvers").setup({
	win_open = function(buf)
		return
		vim.api.nvim_open_win(
			buf,
			false,
			{
				relative = "editor",
				anchor = "SE",
				border = "bold",
				row = vim.o.lines - 2,
				col = vim.o.columns,
				width = 20,
				height = 8,
				style = "minimal",
				focusable = true,
				-- make the window focusable, this is useful if you have buffer local keybindings
				zindex = 1,
			}
		)
	end,
})
require("buvvers").open()
```

you can use a split window if you want

```lua
require("buvvers").setup({
	win_open = function(buf)
		return
		vim.api.nvim_open_win(
			buf,
			false,
			{
				win = -1,
				split = "right",
				width = math.floor(vim.o.columns / 8),
				style = "minimal",
			}
		)
	end,
})
require("buvvers").open()
```

## setup example 5:

the buvvers buffer does not have any keybindings by default

you can add keybindings yourself, for example:

> [!NOTE]
>
> make buvvers window focusable first

```lua
require("buvvers").setup({
	win_open = function(buf)
		return
		vim.api.nvim_open_win(
			buf,
			false,
			{
				relative = "editor",
				anchor = "SE",
				border = "bold",
				row = vim.o.lines - 2,
				col = vim.o.columns,
				width = 20,
				height = 8,
				style = "minimal",
				focusable = true,
				-- make the window focusable, this is useful if you have buffer local keybindings
				zindex = 1,
			}
		)
	end,
	buf_hook = function(buf)
		vim.keymap.set(
		-- bind `q` to disable buvvers
			"n",
			"q",
			require("buvvers").close,
			{
				buffer = buf,
				nowait = true,
			}
		)
		vim.keymap.set(
		-- bind `x` to remove buffer
		-- [mini.bufremove](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-bufremove.md) is required
			"n",
			"x",
			function()
				local listed_bufs = require("buvvers").get_listed_bufs()
				local buf_cursor = listed_bufs[vim.fn.line(".")]
				require("mini.bufremove").delete(buf_cursor, false)
			end,
			{
				buffer = buf,
				nowait = true,
			}
		)
		vim.keymap.set(
		-- bind `o` to open buffer
			"n",
			"o",
			function()
				local listed_bufs = require("buvvers").get_listed_bufs()
				local buf_cursor = listed_bufs[vim.fn.line(".")]
				local win_previous = vim.fn.win_getid(vim.fn.winnr("#"))
				-- https://github.com/nvim-neo-tree/neo-tree.nvim/blob/0b44040ec7b8472dfc504bbcec735419347797ad/lua/neo-tree/utils/init.lua#L643
				vim.api.nvim_win_set_buf(win_previous, buf_cursor)
				vim.api.nvim_set_current_win(win_previous)
			end,
			{
				buffer = buf,
				nowait = true,
			}
		)
	end,
})
require("buvvers").open()
```

## setup-example-6

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
		{"󰢱 ", "DiffDelete"},
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
		{"󰢱 ", "DiffDelete"},
		"buvvers.lua",
		" love",
		{" you", "DiffDelete"},
	},
}
```

the length of `buffer_name_list` should be equal to `buffer_handle_list`, of course

you can view the display result by:

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		return
		{
			{
				{"󰙱 ", "DiffAdd"},
				"dwm.c",
				" love",
				{" you", "DiffAdd"},
			},
			{
				{"󰢱 ", "DiffDelete"},
				"buvvers.lua",
				" love",
				{" you", "DiffDelete"},
			},
		}
	end,
})
require("buvvers").open()
```

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
require("buvvers").open()
```

this implementation has many limitations, but you're encouraged to give it a try :)

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

if you want to add a `󰈔 ` prefix

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		for n, name in ipairs(name_l) do
			name_l[n] = "󰈔 " .. name
		end

		return name_l
	end,
})
require("buvvers").open()
```

if you want to add a `󰈔 ` prefix, highlight with "ErrorMsg" highlight group

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
require("buvvers").open()
```

if you want to add a prefix decided by [mini.icons](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-icons.md)

```lua
require("buvvers").setup({
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		for n, name in ipairs(name_l) do
			local icon, hl = require("mini.icons").get("file", name)
			name_l[n] = {
				{icon .. " ", hl},
				name,
			}
		end

		return name_l
	end,
})
require("buvvers").open()
```

![20250308-191139-927463760](https://github.com/user-attachments/assets/3a768481-d5f1-44c0-b287-30046590d99d)

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
	autocmd_additional_refresh_event = {"BufModifiedSet", "BufWritePost"},
	-- https://github.com/neovim/neovim/issues/32817
})
require("buvvers").open()
```

buvvers doesn't refresh when a buffer's modification state changes

so it is required to set `autocmd_additional_refresh_event = {"BufModifiedSet", "BufWritePost"},`
