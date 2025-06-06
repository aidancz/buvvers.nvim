local M = {}
local H = {}

-- # config & setup

M.config = {
	buf_name = "[buvvers]",
	buf_opt = {
		-- modifiable = false,
		filetype = "buvvers",
	},
	buf_hook = function(buf) end,
	win_open = function(buf)
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
		winfixbuf = true,
		winfixwidth = true,
		winfixheight = true,
		-- winblend = 0,
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
	win_hook = function(win) end,
	autocmd_additional_refresh_event = nil,
	autocmd_winclosed_do = "refresh",
	autocmd_hook = function(augroup) end,
	highlight_group_current_buffer = "Visual",
	buffer_handle_list_to_buffer_name_list = require("buvvers.buffer_handle_list_to_buffer_name_list"),
}

M.setup = function(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})
end

-- # cache

M.cache = {
	listed_bufs = nil,
	buf_handle = nil,
	buf_hl_text_ns_id = vim.api.nvim_create_namespace("buvvers_buf_hl_text"),
	buf_hl_line_ns_id = vim.api.nvim_create_namespace("buvvers_buf_hl_line"),
	buf_hl_line_id = nil,
	win_handle = nil,
	augroup = vim.api.nvim_create_augroup("buvvers", {clear = true}),
}

-- # function: data

M.get_listed_bufs = function()
	local listed_bufs = {}
	for _, i in ipairs(vim.api.nvim_list_bufs()) do
		if vim.fn.buflisted(i) ~= 0 then
		-- any buffer has two independent flags: loaded and listed
		-- loaded is related to memory, whether the buffer is actual existent
		-- listed is related to visual, whether the buffer want to be seen
			table.insert(listed_bufs, i)
		end
	end
	return listed_bufs
end

M.listed_bufs_update = function()
	M.cache.listed_bufs = M.get_listed_bufs()
end

-- # function: buffer

M.buf_is_valid = function()
	return
		M.cache.buf_handle ~= nil
		and
		vim.api.nvim_buf_is_valid(M.cache.buf_handle)
end

M.buf_set_false = function()
	if M.buf_is_valid() then
		vim.api.nvim_buf_delete(M.cache.buf_handle, {force = true})
	else
		-- do nothing
	end
end

M.buf_set_true = function()
	if M.buf_is_valid() then
		-- do nothing
	else
		M.cache.buf_handle = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(M.cache.buf_handle, M.config.buf_name)
		for option, value in pairs(M.config.buf_opt) do
			vim.api.nvim_set_option_value(option, value, {buf = M.cache.buf_handle})
		end
		M.config.buf_hook(M.cache.buf_handle)
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

M.buf_update = function()
	local name_l = M.config.buffer_handle_list_to_buffer_name_list(M.cache.listed_bufs)
	local line_l, highlight_l = M.parse_buffer_name_list(name_l)

	-- set lines
	vim.api.nvim_set_option_value("modifiable", true, {buf = M.cache.buf_handle})
	vim.api.nvim_buf_set_lines(
		M.cache.buf_handle,
		0,
		-1,
		true,
		line_l
	)
	vim.api.nvim_set_option_value("modifiable", false, {buf = M.cache.buf_handle})

	-- set highlights
	for _, i in ipairs(highlight_l) do
		vim.api.nvim_buf_set_extmark(
			M.cache.buf_handle,
			M.cache.buf_hl_text_ns_id,
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

M.buf_hl_line = function(lnum)
	M.cache.buf_hl_line_id =
		vim.api.nvim_buf_set_extmark(
			M.cache.buf_handle,
			M.cache.buf_hl_line_ns_id,
			(lnum-1),
			0,
			{
				id = M.cache.buf_hl_line_id,
				hl_group = M.config.highlight_group_current_buffer,
				hl_eol = true,
				priority = 0,
				end_row = (lnum-1) + 1,
				end_col = 0,
			}
		)
end

M.buf_hl_line_not = function()
	if M.cache.buf_hl_line_id == nil then
		-- do nothing
	else
		vim.api.nvim_buf_del_extmark(
			M.cache.buf_handle,
			M.cache.buf_hl_line_ns_id,
			M.cache.buf_hl_line_id
		)
	end
end

M.buf_hl_line_update = function()
	local current_buffer_handle = vim.api.nvim_get_current_buf()
	for n, i in ipairs(M.cache.listed_bufs) do
		if i == current_buffer_handle then
			M.buf_hl_line(n)
			return
		end
	end

	-- if not return
	M.buf_hl_line_not()
end

-- # function: window

M.win_is_valid = function()
	return
		M.cache.win_handle ~= nil
		and
		vim.api.nvim_win_is_valid(M.cache.win_handle)
end

M.win_set_false = function()
	if M.win_is_valid() then
		vim.api.nvim_win_close(M.cache.win_handle, true)
	else
		-- do nothing
	end
end

M.win_set_true = function()
	if M.win_is_valid() then
		-- do nothing
	else
		M.cache.win_handle = M.config.win_open(M.cache.buf_handle)
		for option, value in pairs(M.config.win_opt) do
			vim.api.nvim_set_option_value(option, value, {win = M.cache.win_handle})
		end
		M.config.win_hook(M.cache.win_handle)
	end
end

M.win_cursor_update = function()
	local current_buffer_handle = vim.api.nvim_get_current_buf()
	for n, i in ipairs(M.cache.listed_bufs) do
		if i == current_buffer_handle then
			vim.api.nvim_win_set_cursor(M.cache.win_handle, {n, 0})
			break
		end
	end

	-- if not return
	-- do nothing
end

-- # function: main

M.pure_open1 = function()
	M.buf_set_true()
	M.win_set_true()
end

M.pure_open2 = function()
	M.listed_bufs_update()
	M.buf_update()
end

M.pure_open3 = function()
	M.buf_hl_line_update()
	M.win_cursor_update()
end

M.pure_open = function()
	M.pure_open1()
	M.pure_open2()
	M.pure_open3()
end

M.pure_close = function()
	M.buf_set_false()
	M.win_set_false()
end

M.pure_toggle = function()
	if M.win_is_valid() then
		M.pure_close()
	else
		M.pure_open()
	end
end

-- # function: autocmd

M.autocmd_is_valid = function()
	local autocmds = vim.api.nvim_get_autocmds({group = M.cache.augroup})
	return next(autocmds) ~= nil
end

M.autocmd_set_false = function()
	if M.autocmd_is_valid() then
		vim.api.nvim_clear_autocmds({group = M.cache.augroup})
	else
		-- do nothing
	end
end

M.autocmd_set_true = function()
	if M.autocmd_is_valid() then
		-- do nothing
	else
		vim.api.nvim_create_autocmd(
			{
				"BufAdd",
				"BufDelete",
				"BufFilePost",
			},
			{
				group = M.cache.augroup,
				callback = function()
					vim.schedule(function()
					-- BufAdd:    https://github.com/neovim/neovim/issues/29419
					-- BufDelete: wait until the buffer is deleted
						M.pure_open2()
						M.pure_open3()
					end)
				end,
			}
		)
		vim.api.nvim_create_autocmd(
			{
				"BufEnter",
			},
			{
				group = M.cache.augroup,
				callback = function()
					vim.schedule(function()
					-- since BufAdd    use vim.schedule, BufEnter should too
					-- since BufDelete use vim.schedule, BufEnter should too
						M.pure_open3()
					end)
				end,
			}
		)
		if M.config.autocmd_additional_refresh_event ~= nil then
			vim.api.nvim_create_autocmd(
				M.config.autocmd_additional_refresh_event,
				{
					group = M.cache.augroup,
					callback = function()
						vim.schedule(function()
							M.pure_open2()
							M.pure_open3()
						end)
					end,
				}
			)
		end
		vim.api.nvim_create_autocmd(
			{
				"WinClosed",
			},
			{
				group = M.cache.augroup,
				callback = function(event)
					local closing_window_handle = tonumber(event.match)
					if closing_window_handle == M.cache.win_handle then
						if M.config.autocmd_winclosed_do == "refresh" then
							vim.schedule(M.open)
						else
							M.close()
						end
					end
				end,
			}
		)
		-- vim.api.nvim_create_autocmd(
		-- 	{
		-- 		"TabEnter",
		-- 	},
		-- 	{
		-- 		group = M.cache.augroup,
		-- 		callback = function()
		-- 			-- TODO: move the window when entering a tab page
		-- 			-- https://github.com/neovim/neovim/issues/33790
		-- 		end,
		-- 	}
		-- )
		M.config.autocmd_hook(M.cache.augroup)
	end
end

-- # api

M.open = function()
	M.pure_open()
	M.autocmd_set_true()
end

M.close = function()
	M.autocmd_set_false()
	M.pure_close()
end

M.toggle = function()
	if M.win_is_valid() then
		M.close()
	else
		M.open()
	end
end

-- # return

return M
