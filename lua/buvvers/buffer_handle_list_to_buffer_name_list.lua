local M = {}
local H = {}

-- file_path_prepend_parent("/a/b/c/def/b/c", "b/c")     => "def/b/c"
-- file_path_prepend_parent("/a/b/c/def/b/c", "def/b/c") => "c/def/b/c"
H.file_path_prepend_parent = function(full_path, current_path)
	local full_path_r = string.reverse(full_path)
	local current_path_r = string.reverse(current_path)

	local _, i1_r = string.find(full_path_r, current_path_r, 1, true)

	if i1_r == #full_path_r then
		return full_path
	end

	local before_path_r = string.sub(full_path_r, (i1_r + 1), #full_path_r)
	local j
	local j1 = string.find(before_path_r, "/", 1, true)
	local j2 = string.find(before_path_r, "/", (j1 + 1), true)
	if j1 ~= 1 then
	-- file_path_prepend_parent("/a/b/c/def/b/c", "")
		j = j1 - 1
	elseif j2 == nil then
	-- file_path_prepend_parent("/a/b/c/def/b/c", "a/b/c/def/b/c")
	-- file_path_prepend_parent("C:/Users/jdoe", "Users/jdoe")
		j = #before_path_r
	else
	-- file_path_prepend_parent("/a/b/c/def/b/c", "b/c")
		j = j2 - 1
	end

	local i2_r = i1_r + j

	return string.reverse(string.sub(full_path_r, 1, i2_r))
end

-- some list processing functions
H.null_p = function(l)
	return next(l) == nil
end
H.car = function(l)
	return l[1]
end
H.cdr = function(l)
	local l_copy = vim.deepcopy(l)
	table.remove(l_copy, 1)
	return l_copy
end
H.cons = function(a, l)
	local l_copy = vim.deepcopy(l)
	table.insert(l_copy, 1, a)
	return l_copy
end

H.member_p = function(a, l)
	if	H.null_p(l)	then	return false
	elseif	H.car(l) == a	then	return true
	else				return H.member_p(a, H.cdr(l))
	end
end

H.multirember = function(a, l)
	if	H.null_p(l)	then	return {}
	elseif	H.car(l) == a	then	return H.multirember(a, H.cdr(l))
	else				return H.cons(H.car(l), H.multirember(a, H.cdr(l)))
	end
end

H.find_duplicates = function(l)
	if	H.null_p(l)	then
		return {}
	elseif	H.member_p(H.car(l), H.cdr(l))	then
		return H.cons(H.car(l), H.find_duplicates(H.multirember(H.car(l), l)))
	else
		return H.find_duplicates(H.cdr(l))
	end
end

H.prepend_once = function(full_name_l, name_l, name_duplicates_l)
	local l = {}
	for i, j in ipairs(name_l) do
		if H.member_p(j, name_duplicates_l) then
			table.insert(l, H.file_path_prepend_parent(full_name_l[i], j))
		else
			table.insert(l, j)
		end
	end
	return l
end

H.get_unnamed_buffer_name = function(buffer_handle)
-- https://github.com/echasnovski/mini.tabline/blob/46108e2d32b0ec8643ee46df14badedb33f3defe/lua/mini/tabline.lua#L340

	-- -- we can reliably get the buffer name if it is displayed in a window
	-- for _, winid in ipairs(vim.api.nvim_list_wins()) do
	-- 	if buffer_handle == vim.api.nvim_win_get_buf(winid) then
	-- 		return vim.api.nvim_eval_statusline("%F", {winid = winid}).str
	-- 	end
	-- end

	-- guess otherwise
	local buftype = vim.api.nvim_get_option_value("buftype", {buf = buffer_handle})
	if buftype == "" then
		return "[No Name]"
	end
	if buftype == "quickfix" then
		if vim.fn.getqflist({qfbufnr = true}).qfbufnr == buffer_handle then
			return "[Quickfix List]"
		else
			return "[Location List]"
		end
	end

	-- fallback
	return string.format("[%s]", buftype)
end

M.buffer_handle_list_to_buffer_name_list = function(handle_list)

-- # prepare full_name_l & name_l

	local full_name_l = {}
	local name_l = {}
	for _, i in ipairs(handle_list) do
		local full_name = vim.api.nvim_buf_get_name(i)
		if
			vim.api.nvim_get_option_value("buftype", {buf = i}) == ""
			-- is_normal_buffer
			or
			vim.uv.fs_stat(full_name) ~= nil
			-- is_actual_file
		then
			full_name = vim.fs.normalize(full_name)
			-- hi ms-windows users :)
			table.insert(full_name_l, full_name)
			table.insert(name_l, vim.fs.basename(full_name))
		else
			table.insert(full_name_l, full_name)
			table.insert(name_l, full_name)
		end
	end
-- | buffer                                  | is_normal_buffer | is_actual_file | full_name_l                            | name_l                          |
-- |-----------------------------------------|------------------|----------------|----------------------------------------|---------------------------------|
-- | `nvim`                                  | true             | false          | ""                                     | ""                              |
-- | `nvim cat.txt` (cat.txt does not exist) | true             | false          | "$PWD/cat.txt"                         | "cat.txt"                       |
-- | `nvim cat.txt` (cat.txt exists)         | true             | true           | "$PWD/cat.txt"                         | "cat.txt"                       |
-- | `:copen`                                | false            | false          | ""                                     | ""                              |
-- | `:lopen`                                | false            | false          | ""                                     | ""                              |
-- | `:terminal`                             | false            | false          | "term://~//112393:/usr/bin/zsh"        | "term://~//112393:/usr/bin/zsh" |
-- | `:help`                                 | false            | true           | "/usr/share/nvim/runtime/doc/help.txt" | "help.txt"                      |

-- # deduplicate name_l

	local name_duplicates_l
	while true do
		name_duplicates_l = H.find_duplicates(name_l)

		name_duplicates_l = H.multirember("", name_duplicates_l)
		-- allow multiple unnamed buffers
		-- unnamed buffers: [No Name] [Quickfix List] ...

		if H.null_p(name_duplicates_l) then
			break
		else
			name_l = H.prepend_once(full_name_l, name_l, name_duplicates_l)
		end
	end

-- # give unnamed buffer name

	for n, name in ipairs(name_l) do
		if name == "" then
			name_l[n] = H.get_unnamed_buffer_name(handle_list[n])
		end
	end

	return name_l
end

return M.buffer_handle_list_to_buffer_name_list
