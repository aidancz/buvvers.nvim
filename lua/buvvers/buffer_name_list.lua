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
	local j = string.find(before_path_r, "/", 1, true)
	if j ~= 1 then
		j = j - 1
	elseif j == #before_path_r then
		-- do nothing
	else
		j = string.find(before_path_r, "/", (j + 1), true)
		j = j - 1
	end
	local i2_r = i1_r + j

	return string.reverse(string.sub(full_path_r, 1, i2_r))
end

-- some list processing
H.null_p = function(l)
	return next(l) == nil
end
H.car = function(l)
	return l[1]
end
H.cdr = function(l)
	local l_copy = vim.deepcopy(l, true)
	table.remove(l_copy, 1)
	return l_copy
end
H.cons = function(a, l)
	local l_copy = vim.deepcopy(l, true)
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

M.buffer_handle_list_to_buffer_name_list = function(handle_list)
	local full_name_l = {}
	local name_l = {}
	for _, i in ipairs(handle_list) do
		local full_name = vim.api.nvim_buf_get_name(i)
		local base_name = vim.fs.basename(full_name)
		table.insert(full_name_l, full_name)
		table.insert(name_l, base_name)
	end

	local name_duplicates_l
	while true do
		name_duplicates_l = H.find_duplicates(name_l)
		if H.null_p(name_duplicates_l) then
			break
		else
			name_l = H.prepend_once(full_name_l, name_l, name_duplicates_l)
		end
	end

	return name_l
end

return M
