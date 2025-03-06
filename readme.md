# demo

https://github.com/user-attachments/assets/d03747f9-9188-404f-a172-a570616b1e12

inspired by [vuffers](https://github.com/Hajime-Suzuki/vuffers.nvim)

minimal, robust, easy to modify

# default config

```
{
	buvvers_buf_name = "buvvers",
	buvvers_win = {
		win = -1,
		split = "right",
		width = math.ceil(vim.o.columns / 8),
		focusable = false,
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
	},
	name_prefix = function(buffer_handle)
		return "- "
	end,
	highlight_group_current_buffer = "Visual",
}
```

- buvvers_buf_name: name displayed at status line
- buvvers_win: the `config` parameter of `vim.api.nvim_open_win`
- buvvers_win_opt: window options
- name_prefix: a function takes a buffer handle (buffer number) and returns a string used as the prefix of the display name of the buffer
- highlight_group_current_buffer: bar highlight of current buffer

# setup

## setup example 1:

```
require("buvvers").setup()
```

after setup, these api functions are available:

| function                                    | description                      |
|---------------------------------------------|----------------------------------|
| `require("buvvers").open`                   | ensure enable buvvers            |
| `require("buvvers").close`                  | ensure disable buvvers           |
| `require("buvvers").toggle`                 | toggle buvvers                   |
| `require("buvvers").get_buvvers_buf_handle` | get buvvers buffer handle        |
| `require("buvvers").get_current_buf_handle` | get cursor hovered buffer handle |

for example, you can run `:lua require("buvvers").open()` to enable buvvers
