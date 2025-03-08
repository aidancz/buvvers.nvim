local M = {}
local H = {}

-- # config & setup

M.config = {
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
		style = "minimal",
	},
	buvvers_win_opt = {
		-- foldcolumn = "0",
		-- signcolumn = "no",
		-- number = false,
		-- relativenumber = false,
		-- list = false,
		wrap = true,
		-- breakindent = true,
		-- breakindentopt = "shift:4",
		winfixwidth = true,
		winfixheight = true,
		winfixbuf = true,
	},
	highlight_group_current_buffer = "Visual",
	buffer_handle_list_to_buffer_name_list = function(handle_l)
		local name_l

		local default_function = require("buvvers.buffer_handle_list_to_buffer_name_list")
		name_l = default_function(handle_l)

		return name_l
	end,
}

M.setup = function(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})
end

-- # cache

M.cache = {
	listed_buffer_handles = nil,
	buvvers_buf_handle = nil,
	buvvers_buf_highlight_text_ns_id = vim.api.nvim_create_namespace("buvvers_buf_highlight_text"),
	buvvers_buf_highlight_extmark_ns_id = vim.api.nvim_create_namespace("buvvers_buf_highlight_extmark"),
	buvvers_buf_highlight_extmark_id = nil,
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
		vim.api.nvim_buf_set_name(M.cache.buvvers_buf_handle, M.config.buvvers_buf_name)
		for option, value in pairs(M.config.buvvers_buf_opt) do
			vim.api.nvim_set_option_value(option, value, {buf = M.cache.buvvers_buf_handle})
		end
		vim.api.nvim_exec_autocmds("User", {pattern = "BuvversAttach"})
	end
end

M.update_buvvers_buf = function()
	local name_l = M.config.buffer_handle_list_to_buffer_name_list(M.cache.listed_buffer_handles)

	-- set text
	vim.api.nvim_set_option_value("modifiable", true, {buf = M.cache.buvvers_buf_handle})
	vim.api.nvim_buf_set_lines(
		M.cache.buvvers_buf_handle,
		0,
		-1,
		true,
		vim.tbl_map(
			function(i)
				if type(i) == "string" then
					return i
				elseif type(i) == "table" then
					local name = ""
					for _, j in ipairs(i) do
						if type(j) == "string" then
							name = name .. j
						elseif type(j) == "table" then
							name = name .. j[1]
						end
					end
					return name
				end
			end,
			name_l
		)
	)
	vim.api.nvim_set_option_value("modifiable", false, {buf = M.cache.buvvers_buf_handle})

	-- highlight text
	for n, i in ipairs(name_l) do
		if type(i) == "string" then
			-- do nothing
		elseif type(i) == "table" then
			local name = ""
			for _, j in ipairs(i) do
				if type(j) == "string" then
					name = name .. j
				elseif type(j) == "table" then
					vim.api.nvim_buf_add_highlight(
						M.cache.buvvers_buf_handle,
						M.cache.buvvers_buf_highlight_text_ns_id,
						j[2],
						n - 1,
						#name,
						#name + #j[1]
					)
					name = name .. j[1]
				end
			end
		end
	end
end

M.highlight_line = function(lnum)
	M.cache.buvvers_buf_highlight_extmark_id =
		vim.api.nvim_buf_set_extmark(
			M.cache.buvvers_buf_handle,
			M.cache.buvvers_buf_highlight_extmark_ns_id,
			(lnum-1),
			0,
			{
				id = M.cache.buvvers_buf_highlight_extmark_id,
				hl_group = M.config.highlight_group_current_buffer,
				hl_eol = true,
				priority = 0,
				end_row = (lnum-1) + 1,
				end_col = 0,
			}
		)
end

M.dehighlight_line = function()
	vim.api.nvim_buf_del_extmark(
		M.cache.buvvers_buf_handle,
		M.cache.buvvers_buf_highlight_extmark_ns_id,
		M.cache.buvvers_buf_highlight_extmark_id
	)
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
	M.update_listed_buffer_handles()
	M.buvvers_buf_set_true()
	M.update_buvvers_buf()
	M.buvvers_win_set_true()
end

M.buvvers_open2 = function()
	M.update_buvvers_buf_selection()
	M.update_buvvers_win_cursor()
end

M.buvvers_open = function()
	M.buvvers_open1()
	M.buvvers_open2()
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
	else
		-- do nothing
	end
end

M.buvvers_autocmd_set_true = function()
	if M.buvvers_autocmd_is_valid() then
		-- do nothing
	else
		vim.api.nvim_create_autocmd(
			{"BufAdd", "BufDelete"},
			{
				group = M.cache.buvvers_augroup,
				callback = function()
					vim.schedule(function()
					-- BufEnter:  https://github.com/neovim/neovim/issues/29419
					-- BufDelete: wait until the buffer is deleted
						M.buvvers_open1()
					end)
				end,
			})
		vim.api.nvim_create_autocmd(
			{"BufEnter"},
			{
				group = M.cache.buvvers_augroup,
				callback = function()
					vim.schedule(function()
					-- since BufEnter  use vim.schedule, BufEnter should too
					-- since BufDelete use vim.schedule, BufEnter should too
						M.buvvers_open2()
					end)
				end,
			})
		vim.api.nvim_create_autocmd(
			{"WinClosed"},
			{
				group = M.cache.buvvers_augroup,
				callback = function(event)
					local closing_window_handle = tonumber(event.match)
					if closing_window_handle == M.cache.buvvers_win_handle then
						M.buvvers_autocmd_set_false()
						M.buvvers_close()
					end
				end,
			})
	end
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
