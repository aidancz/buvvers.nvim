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
	-- these keys are merged via `vim.tbl_deep_extend`, unless otherwise specified



	buvvers_buf_name = "[buvvers]",
	-- buvvers buffer name displayed on status line

	buvvers_buf_opt = {
	-- buvvers buffer local options
	},

	buvvers_win = {
	-- the `config` parameter of `vim.api.nvim_open_win`
	-- this key is merged via `vim.tbl_extend`
		win = -1,
		split = "right",
		width = math.ceil(vim.o.columns / 8),
		style = "minimal",
	},

	buvvers_win_opt = {
	-- buvvers window local options
		winfixbuf = true,
		winfixwidth = true,
		winfixheight = true,
		wrap = true,
	},

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

> note:
>
> you can disable buvvers by:
>
> 1. call `require("buvvers").close` or `require("buvvers").toggle`
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

## setup example 3-1:

if you want to change how the buvvers window looks:

```lua
require("buvvers").setup({
	buvvers_win = {
	-- the `config` parameter of `vim.api.nvim_open_win`
	-- this key is merged via `vim.tbl_extend`
		win = -1,
		split = "below",
		height = 4,
		style = "minimal",
	},
})
require("buvvers").open()
```

## setup example 3-2:

you can even use a floating window thanks to the power of `vim.api.nvim_open_win`:

```lua
require("buvvers").setup({
	buvvers_win = {
	-- the `config` parameter of `vim.api.nvim_open_win`
	-- this key is merged via `vim.tbl_extend`
		relative = "editor",
		row = 3,
		col = 3,
		width = 16,
		height = 16,
		style = "minimal",
	},
})
require("buvvers").open()
```

## setup example 4:

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

### setup example 4-1:

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

this implementation has many limitations, but you're encouraged to give it a try :)

### setup example 4-2:

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

### setup example 4-3:

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

### setup example 4-4:

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

### setup example 4-5:

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

### setup example 4-6:

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
})
```

however, this won't work as expected because buvvers doesn't refresh when a buffer's modification state changes

to refresh buvvers, use:

| function                          | description     |
|-----------------------------------|-----------------|
| `require("buvvers").buvvers_open` | refresh buvvers |

note the function name is `require("buvvers").buvvers_open`, not `require("buvvers").open`

i will cover how to set an autocmd to refresh automatically [later](#setup-example-5-2)

## setup example 5:

## setup example 5-1:

the buvvers buffer does not have any keybindings by default

you can add keybindings yourself with these functions

| function                                 | description                                                |
|------------------------------------------|------------------------------------------------------------|
| `require("buvvers").buvvers_get_buf`     | get buvvers buffer                                         |
| `require("buvvers").buvvers_buf_get_buf` | inside the buvvers buffer, get the buffer of line number n |

for example, bind "d" to delete buffer and "o" to open buffer:

> [mini.bufremove](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-bufremove.md) is required

```lua
require("buvvers").setup()

vim.keymap.set("n", "<leader>bl", require("buvvers").toggle)
-- bind `<leader>bl` to toggle buvvers

local add_buffer_keybindings = function()
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
vim.api.nvim_create_augroup("buvvers_config", {clear = true})
vim.api.nvim_create_autocmd(
	"User",
	{
		group = "buvvers_config",
		pattern = "BuvversBufEnabled",
		callback = add_buffer_keybindings,
	}
)
-- use `BuvversBufEnabled` to add buffer local keybindings

require("buvvers").open()
-- enable buvvers at startup
```

the reason why we need "BuvversBufEnabled" autocmd in this example is:

when buvvers is closed, its buffer is deleted, causing the buffer-local keybindings to be lost

---

these are the supported autocmds:

| autocmd               | description                     |
|-----------------------|---------------------------------|
| BuvversBufEnabled     | when buvvers buffer is enabled  |
| BuvversWinEnabled     | when buvvers window is enabled  |
| BuvversAutocmdEnabled | when buvvers autocmd is enabled |

## setup example 5-2:

this is the full setup of the setup mentioned [before](#setup-example-4-6)

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

local add_autocmds = function()
	vim.api.nvim_create_autocmd(
		{
			"BufModifiedSet",
		},
		{
			group = "buvvers",
			callback = require("buvvers").buvvers_open,
		}
	)
end
vim.api.nvim_create_augroup("buvvers_config", {clear = true})
vim.api.nvim_create_autocmd(
	"User",
	{
		group = "buvvers_config",
		pattern = "BuvversAutocmdEnabled",
		callback = add_autocmds,
	}
)
-- use `BuvversAutocmdEnabled` to add a autocmd that refresh buvvers when `BufModifiedSet` event is triggered

require("buvvers").open()
-- enable buvvers at startup
```

the reason why we need "BuvversAutocmdEnabled" autocmd in this example is:

when buvvers is closed, its autocmds are deleted
