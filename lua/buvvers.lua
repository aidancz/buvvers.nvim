local M = {}
local H = {}

-- # config & setup

M.config = {
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
		wrap = false,
		winfixwidth = true,
		winfixheight = true,
	},
	buffer_handle_to_buffer_name = function(handle)
		local full_name = vim.api.nvim_buf_get_name(handle)
		local base_name = vim.fs.basename(full_name)
		return base_name
	end,
}

M.setup = function(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})
	-- M.create_buvvers_autocmd()
end

-- # cache

M.cache = {
	listed_buffer_handles = {},
	buvvers_buf_handle = nil,
	buvvers_buf_highlight_extmark_ns_id = vim.api.nvim_create_namespace("buvvers_buf_highlight_extmark"),
	buvvers_win_handle = nil,
	buvvers_augroup = vim.api.nvim_create_augroup("buvvers", {clear = true}),
}

-- # function: data

M.update_listed_buffer_handles = function()
	M.cache.listed_buffer_handles = {}

	for _, i in ipairs(vim.api.nvim_list_bufs()) do
		if vim.fn.buflisted(i) ~= 0 then
		-- any buffer has two independent flags: loaded and listed
		-- loaded is related to memory, whether the buffer is actual existent
		-- listed is related to visual, whether the buffer want to be seen
			table.insert(
				M.cache.listed_buffer_handles,
				i
			)
		end
	end
end

-- # function: buffer

M.buvvers_buf_is_valid = function()
	return
		M.cache.buvvers_buf_handle ~= nil
		and
		vim.api.nvim_buf_is_valid(M.cache.buvvers_buf_handle)
end

M.buvvers_buf_set_false = function()
	if M.buvvers_buf_is_valid() then
		vim.api.nvim_buf_delete(M.cache.buvvers_buf_handle, {force = true})
	else
		-- do nothing
	end
end

M.buvvers_buf_set_true = function()
	if M.buvvers_buf_is_valid() then
		-- do nothing
	else
		M.cache.buvvers_buf_handle = vim.api.nvim_create_buf(false, true)
	end
end

H.highlight_line = function(lnum)
	vim.api.nvim_buf_set_extmark(
		M.cache.buvvers_buf_handle,
		M.cache.buvvers_buf_highlight_extmark_ns_id,
		(lnum-1),
		0,
		{
			hl_group = "Visual",
			hl_eol = true,
			end_row = (lnum-1) + 1,
			end_col = 0,
		}
	)
end

M.update_buvvers_buf = function()
	local lines = {}
	for _, i in ipairs(M.cache.listed_buffer_handles) do
		table.insert(
			lines,
			M.config.buffer_handle_to_buffer_name(i)
		)
	end
	vim.api.nvim_buf_set_lines(M.cache.buvvers_buf_handle, 0, -1, true, lines)

	local current_buffer_handle = vim.api.nvim_get_current_buf()
	for n, i in ipairs(M.cache.listed_buffer_handles) do
		if i == current_buffer_handle then
			H.highlight_line(n)
			break
		end
	end
end

-- # function: window

M.buvvers_win_is_valid = function()
	return
		M.cache.buvvers_win_handle ~= nil
		and
		vim.api.nvim_win_is_valid(M.cache.buvvers_win_handle)
end

M.buvvers_win_set_false = function()
	if M.buvvers_win_is_valid() then
		vim.api.nvim_win_close(M.cache.buvvers_win_handle, true)
	else
		-- do nothing
	end
end

M.buvvers_win_set_true = function()
	if M.buvvers_win_is_valid() then
		-- do nothing
	else
		M.cache.buvvers_win_handle = vim.api.nvim_open_win(M.cache.buvvers_buf_handle, false, M.config.buvvers_win)
		for option, value in pairs(M.config.buvvers_win_opt) do
			vim.api.nvim_set_option_value(option, value, {win = M.cache.buvvers_win_handle})
		end
	end
end

-- # function: main

M.buvvers_open = function()
	M.update_listed_buffer_handles()
	M.buvvers_buf_set_true()
	M.update_buvvers_buf()
	M.buvvers_win_set_true()
end

M.buvvers_close = function()
	M.buvvers_buf_set_false()
	M.buvvers_win_set_false()
end

M.buvvers_toggle = function()
	if M.buvvers_win_is_valid() then
		M.buvvers_close()
	else
		M.buvvers_open()
	end
end

-- # function: autocmd

M.buvvers_autocmd_set_false = function()
	vim.api.nvim_clear_autocmds({group = M.cache.buvvers_augroup})
end

M.buvvers_autocmd_set_true = function()
	vim.api.nvim_create_autocmd(
		{"BufEnter", "BufAdd", "BufDelete", "WinClosed"},
		{
			group = M.cache.buvvers_augroup,
			callback = function()
				vim.schedule(function()
				-- HACK: wait until the current working directory is set (affect vim.fn.bufname)
				-- HACK: wait until the window has been closed (affect WinClosed autocmd)
					M.buvvers_open()
				end)
			end,
		})
end

-- # api

M.open = function()
	M.buvvers_autocmd_set_true()
	M.buvvers_open()
end

M.close = function()
	M.buvvers_autocmd_set_false()
	M.buvvers_close()
end

M.toggle = function()
	if M.buvvers_win_is_valid() then
		M.close()
	else
		M.open()
	end
end

-- # return

return M
