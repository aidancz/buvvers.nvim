local M = {}
local H = {}

-- # config & setup

M.config = {
	buvvers_buf_name = "[buvvers]",
	buvvers_buf_opt = {
		-- modifiable = false,
		filetype = "buvvers",
	},
	buvvers_win = {
		win = -1,
		split = "right",
		width = math.ceil(vim.o.columns / 8),
		-- focusable = false,
		-- `focusable` has no effect yet, see https://github.com/neovim/neovim/issues/29365
		style = "minimal",
	},
	buvvers_win_enter = false,
	buvvers_win_opt = {
		winfixbuf = true,
		winfixwidth = true,
		winfixheight = true,
		-- foldcolumn = "0",
		-- signcolumn = "no",
		-- number = false,
		-- relativenumber = false,
		-- list = false,
		wrap = true,
		-- breakindent = true,
		-- breakindentopt = "shift:4",
		-- scrolloff = 3,
	},
	highlight_group_current_buffer = "Visual",
	buffer_handle_list_to_buffer_name_list = require("buvvers.buffer_handle_list_to_buffer_name_list"),
}

M.setup = function(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})
end

-- # cache

M.cache = {
	listed_buffer_handles = nil,
	buvvers_buf_handle = nil,
	buvvers_buf_highlight_text_ns_id = vim.api.nvim_create_namespace("buvvers_buf_highlight_text"),
	buvvers_buf_highlight_line_ns_id = vim.api.nvim_create_namespace("buvvers_buf_highlight_line"),
	buvvers_buf_highlight_line_id = nil,
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
		vim.api.nvim_exec_autocmds("User", {pattern = "BuvversBufDisabled"})
	else
		-- do nothing
	end
end

M.buvvers_buf_set_true = function()
	if M.buvvers_buf_is_valid() then
		-- do nothing
	else
		M.cache.buvvers_buf_handle = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(M.cache.buvvers_buf_handle, M.config.buvvers_buf_name)
		for option, value in pairs(M.config.buvvers_buf_opt) do
			vim.api.nvim_set_option_value(option, value, {buf = M.cache.buvvers_buf_handle})
		end
		vim.api.nvim_exec_autocmds("User", {pattern = "BuvversBufEnabled"})
	end
end

M.parse_buffer_name_list = function(name_l)
	local line_l = {}
	local highlight_l = {}

	for idx, name in ipairs(name_l) do
		if name == nil then
			table.insert(line_l, "")
		elseif type(name) == "string" then
			table.insert(line_l, name)
		elseif type(name) == "table" then
			local str = ""
			for _, name_part in ipairs(name) do
				if name_part == nil then
					-- do nothing
				elseif type(name_part) == "string" then
					str = str .. name_part
				elseif type(name_part) == "table" then
					table.insert(
						highlight_l,
						{
							hl_group = name_part[2],
							line = (idx-1),
							col_start = #str,
							col_end = #str + #name_part[1]
						}
					)
					str = str .. name_part[1]
				end
			end
			table.insert(line_l, str)
		end
	end

	return line_l, highlight_l
end

M.update_buvvers_buf = function()
	local name_l = M.config.buffer_handle_list_to_buffer_name_list(M.cache.listed_buffer_handles)
	local line_l, highlight_l = M.parse_buffer_name_list(name_l)

	-- set lines
	vim.api.nvim_set_option_value("modifiable", true, {buf = M.cache.buvvers_buf_handle})
	vim.api.nvim_buf_set_lines(
		M.cache.buvvers_buf_handle,
		0,
		-1,
		true,
		line_l
	)
	vim.api.nvim_set_option_value("modifiable", false, {buf = M.cache.buvvers_buf_handle})

	-- set highlights
	for _, i in ipairs(highlight_l) do
		vim.api.nvim_buf_set_extmark(
			M.cache.buvvers_buf_handle,
			M.cache.buvvers_buf_highlight_text_ns_id,
			i.line,
			i.col_start,
			{
				hl_group = i.hl_group,
				end_row = i.line,
				end_col = i.col_end,
			}
		)
	end
end

M.highlight_line = function(lnum)
	M.cache.buvvers_buf_highlight_line_id =
		vim.api.nvim_buf_set_extmark(
			M.cache.buvvers_buf_handle,
			M.cache.buvvers_buf_highlight_line_ns_id,
			(lnum-1),
			0,
			{
				id = M.cache.buvvers_buf_highlight_line_id,
				hl_group = M.config.highlight_group_current_buffer,
				hl_eol = true,
				priority = 0,
				end_row = (lnum-1) + 1,
				end_col = 0,
			}
		)
end

M.dehighlight_line = function()
	if M.cache.buvvers_buf_highlight_line_id == nil then
		-- do nothing
	else
		vim.api.nvim_buf_del_extmark(
			M.cache.buvvers_buf_handle,
			M.cache.buvvers_buf_highlight_line_ns_id,
			M.cache.buvvers_buf_highlight_line_id
		)
	end
end

M.update_buvvers_buf_selection = function()
	local current_buffer_handle = vim.api.nvim_get_current_buf()
	for n, i in ipairs(M.cache.listed_buffer_handles) do
		if i == current_buffer_handle then
			M.highlight_line(n)
			return
		end
	end

	-- if not return
	M.dehighlight_line()
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
		vim.api.nvim_exec_autocmds("User", {pattern = "BuvversWinDisabled"})
	else
		-- do nothing
	end
end

M.buvvers_win_set_true = function()
	if M.buvvers_win_is_valid() then
		-- do nothing
	else
		M.cache.buvvers_win_handle = vim.api.nvim_open_win(
			M.cache.buvvers_buf_handle,
			M.config.buvvers_win_enter,
			M.config.buvvers_win
		)
		-- because `vim.api.nvim_open_win` is not allowed when `textlock` is active
		-- this function need to be wrapped during startup
		--
		-- e.g. run `nvim --clean -u minimal.lua`, where `minimal.lua` is:
		--
		-- vim.api.nvim_open_win(
		-- 	0,
		-- 	false,
		-- 	{
		-- 		split = "left"
		-- 	}
		-- )
		--
		-- the cursor should be in the right window, since the second parameter is `false`
		for option, value in pairs(M.config.buvvers_win_opt) do
			vim.api.nvim_set_option_value(option, value, {win = M.cache.buvvers_win_handle})
		end
		vim.api.nvim_exec_autocmds("User", {pattern = "BuvversWinEnabled"})
	end
end

M.update_buvvers_win_cursor = function()
	local current_buffer_handle = vim.api.nvim_get_current_buf()
	for n, i in ipairs(M.cache.listed_buffer_handles) do
		if i == current_buffer_handle then
			vim.api.nvim_win_set_cursor(M.cache.buvvers_win_handle, {n, 0})
			break
		end
	end

	-- if not return
	-- do nothing
end

-- # function: main

M.buvvers_open1 = function()
	M.buvvers_buf_set_true()
	M.buvvers_win_set_true()
end

M.buvvers_open2 = function()
	M.update_listed_buffer_handles()
	M.update_buvvers_buf()
end

M.buvvers_open3 = function()
	M.update_buvvers_buf_selection()
	M.update_buvvers_win_cursor()
end

M.buvvers_open = function()
	M.buvvers_open1()
	M.buvvers_open2()
	M.buvvers_open3()
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

M.buvvers_autocmd_is_valid = function()
	local autocmds = vim.api.nvim_get_autocmds({group = M.cache.buvvers_augroup})
	return next(autocmds) ~= nil
end

M.buvvers_autocmd_set_false = function()
	if M.buvvers_autocmd_is_valid() then
		vim.api.nvim_clear_autocmds({group = M.cache.buvvers_augroup})
		vim.api.nvim_exec_autocmds("User", {pattern = "BuvversAutocmdDisabled"})
	else
		-- do nothing
	end
end

M.buvvers_autocmd_set_true = function()
	if M.buvvers_autocmd_is_valid() then
		-- do nothing
	else
		vim.api.nvim_create_autocmd(
			{
				"BufAdd",
				"BufDelete",
				"BufFilePost",
			},
			{
				group = M.cache.buvvers_augroup,
				callback = function()
					vim.schedule(function()
					-- BufAdd:    https://github.com/neovim/neovim/issues/29419
					-- BufDelete: wait until the buffer is deleted
						M.buvvers_open2()
						M.buvvers_open3()
					end)
				end,
			}
		)
		vim.api.nvim_create_autocmd(
			{
				"BufEnter",
			},
			{
				group = M.cache.buvvers_augroup,
				callback = function()
					vim.schedule(function()
					-- since BufAdd    use vim.schedule, BufEnter should too
					-- since BufDelete use vim.schedule, BufEnter should too
						M.buvvers_open3()
					end)
				end,
			}
		)
		vim.api.nvim_create_autocmd(
			{
				"WinClosed",
			},
			{
				group = M.cache.buvvers_augroup,
				callback = function(event)
					local closing_window_handle = tonumber(event.match)
					if closing_window_handle == M.cache.buvvers_win_handle then
						M.buvvers_autocmd_set_false()
						M.buvvers_close()
					end
				end,
			}
		)
		vim.api.nvim_exec_autocmds("User", {pattern = "BuvversAutocmdEnabled"})
	end
end

-- # api

M.open = function()
	M.buvvers_open()
	M.buvvers_autocmd_set_true()
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

M.buvvers_get_buf = function()
	if M.buvvers_buf_is_valid() then
		return M.cache.buvvers_buf_handle
	else
		return nil
	end
end

M.buvvers_buf_get_buf = function(lnum)
	if M.buvvers_buf_is_valid() then
		return M.cache.listed_buffer_handles[lnum]
	else
		return nil
	end
end

M.buvvers_get_win = function()
	if M.buvvers_win_is_valid() then
		return M.cache.buvvers_win_handle
	else
		return nil
	end
end

-- # return

return M
