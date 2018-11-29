table.random = function(t)
	return t[math.random(1,table.size(t))]
end

table.push_back = function(t, ...)
	local vals = {...}
	for _,val in ipairs(vals) do
		table.insert(t, val)
	end
end

table.exist = function(t, val)
	for _, v in pairs(t) do
		if v == val then return true end
	end
	return false
end

table.pop_back = function(t)
	return table.remove(t, -1)
end

table.push_front = function(t, ...)
	local vals = {...}
	for _,val in ipairs(vals) do
		table.insert(t, 1, val)
	end
	return t
end

table.pop_front = function(t)
	return table.remove(t, 1)
end

table.keys = function(t)
	local result = {}
	local index = 1
	for k,v in pairs(t or {}) do
		--table.push_back(result, k)
		result[index] = k
		index = index + 1
	end
	return result
end

table.values = function(t)
	local result = {}
	local index = 1
	for k,v in pairs(t or {}) do
		--table.push_back(result, v)
		result[index] = v
		index = index + 1
	end
	return result
end

table.merge = function(dest, src)
	if type(dest) ~= "table" or type(src) ~= "table" then
		return
	end
	for k, v in pairs(src) do
		dest[k] = v
	end
	return dest
end

table.pack = function(...)
	return {...}
end

table.unpack = function(t)
	return unpack(t)
end

function copy(t)
	if not is_table(t) then return t end

	local ret = {}
	for k,v in pairs(t) do
		ret[k]=v
	end
	return ret
end

function table.merge(to, from)
	for k,v in pairs(from) do
		to[k] = v
	end
end

output_value = function(value)
	if not value then return "nil" end
	local str, value_type
	value_type = type(value)
	if value_type == "number" then
		str = string.format("[ %f ]n", value)
	elseif value_type == "string" then
		str = string.format("[ \"%s\" ]s", value)
	elseif value_type == "table" then
		str = string.format("[ 0x%s ]t", string.sub(tostring(value), 8))
	elseif value_type == "function" then
		str = string.format("[ 0x%s ]f", string.sub(tostring(value), 11))
	elseif value_type == "userdata" then
		str = string.format("[ 0x%s ]u", string.sub(tostring(value), 11))
	else
		str = string.format("[ '%s' ]%s", tostring(value), type(value))
	end
	return str
end


table.save_fd = function(file, tb, tb_deep, func_save_item)
	if type(tb) ~= "table" or not file then		
		return
	end

	tb_deep =  tb_deep or 20
	local cur_deep = 0
	local tb_cache = {}
	local function save_table(tb_data)
		-- 存储当前层table
		if type(tb_data) ~= "table"  then
			log("Error", "存储类型必须为table:", tb, path, tb_deep)
			return
		end
		if tb_cache[tb] then
			log("Error", "无法继续存储，table中包含循环引用，", tb, path, tb_deep)
			return
		end
		local k, v
		cur_deep = cur_deep + 1
		if cur_deep > tb_deep then
			log("Error", "待存储table超过可允许的table深度", tb, path, tb_deep)
			cur_deep = cur_deep -  1
			return
		end
		local tab = string.rep(" ", (cur_deep-1)*4)
		local str = "{\n"

		-- 调整table存储顺序，按照key排序
		local keys_num = {}
		local keys_str = {}
		for k, v in pairs(tb_data) do
			if type(k) == "number" then
				table.insert(keys_num, k)
			elseif type(k) == "string" then
				table.insert(keys_str, k)
			end
		end
		table.sort(keys_str)
		table.sort(keys_num)

		local keys = {}
		for i, k in ipairs(keys_num) do
			table.insert(keys, k)
		end
		for i, k in ipairs(keys_str) do
			table.insert(keys, k)
		end
		for k, v in pairs(tb_data) do
			if type(k) ~= "number" and type(k) ~= "string" then
				table.insert(keys, k)
			end
		end

		-- 保存调整后的table
		local i
		for i, k in ipairs(keys) do
			v = tb_data[k]
			local arg, value
			if type(k) == "number" then
				arg = string.format("[%d]", k)   --认为key一定是整数
			end
			if type(k) == "string" then
				arg = string.format("[\"%s\"]", string.gsub(k,"\\","\\\\"))
			end
			if type(k) == "boolean" then
				value = tostring(k)
			end
			if type(v) == "number" then
				value = string.format("%f", v)
			end
			if type(v) == "string" then
				value = string.format("\"%s\"", string.gsub(v,"\\","\\\\"))
			end			
			if type(v) == "table" then
				value = save_table(v)
			end
			if type(v) == "boolean" then
				value = tostring(v)
			end
			if arg and value then
				item_str = func_save_item and func_save_item(tab, arg, value) or string.format("%s%s = %s,\n", tab, arg, value)
				str = str..item_str
			end
		end
		tb_cache[tb_data] = true
		cur_deep = cur_deep -  1
		return str..tab.."}"
	end

	local tb_str = "data = \n"..save_table(tb)
	file:write(tb_str)

	return true
end

table.save = function(tb, path, tb_deep, is_compile, is_compress, func_save_item)
	-- make dir exists
	local dirname = os.path.dirname(path)
	os.makedirs(dirname)

	local file = io.open(path, "wb")
	if not file then
		error("table.save打开文件错误:"..path)
	end

	-- table.save_fd参数依次为：file, tb, tb_deep, func_save_item
	local rtn = table.save_fd(file, tb, tb_deep, func_save_item)
	file:close()
	return rtn
end

table.clone = function(src)
	 if type(src) ~= "table" then
		 return src
	 end
	 local copy_table
	 local level = 0
	 local function clone_table(t)
		 level = level + 1
		 if level > 20 then
			 error("table clone failed, source table is too deep!")
		 end
		 local k, v
		 local rel = {}
		 for k, v in table.pairs(t) do
			 if type(v) == "table" then
				 rel[k] = clone_table(v)
			 else
				 rel[k] = v
			 end
		 end
		 level = level - 1
		 return rel
	 end
	 return clone_table(src)
end

table.size = function(t)
	local ret = 0
	if type(t) == "table" then
		for _, __ in pairs(t) do
			ret = ret + 1
		end
	end
	return ret
end

table.randNum = function(t, num)

end

-- 数组乱序
table.shuffle = function(t)
	local n = table.size(t)

	while n >= 2 do
		local k = math.random(n) -- 1 <= k <= n
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end

	return t
end

table.protect = function(t, notRecurse, reset)
	--do return t end

	t = t or {}
	local ret = {
		data = {},
		encodedData = {},
		passWord = math.pow(2, math.random(1, 8)),
	}
	local encode = function(val, passwd)
		return val * passwd + passwd
	end

	local decode = function(val, passwd)
		return (val - passwd)/ passwd
	end
	setmetatable(ret, {
			     __index = function(t, k)
				     local val = t.data[k]
				     -- 如果有备份数据就检测之
				     if type(val) == "number" and t.encodedData[k] then
					     local copyVal = t.encodedData[k]
					     local realVal = decode(copyVal, t.passWord)
					     if realVal ~= val then
						     t.data[k] = realVal
						     -- reset
						     if reset then
							     reset(k, v)
						     end
					     end
					     return realVal
				     end
				     return val
			     end,
			     __newindex = function(t, k, v)
				     if type(v) == "number" then
					     t.encodedData[k] = encode(v, t.passWord)
					     -- log("info", v, t.encodedData[k], t.passWord)
				     end
				     if type(v) == "table" then
					     if notRecurse then
						     t.data[k] = v
					     else
						     t.data[k] = table.protect(v)
					     end
				     else
					     t.data[k] = v
				     end
			     end,
			     __pairs = function(t, ...)
				     return pairs(t.data, ...)
			     end,
				 __ipairs = function(t, ...)
					 return ipairs(t.data, ...)
				 end,
		     })
	for k,v in pairs(t) do
		ret[k] = v
	end
	return ret
end

table.isEmpty = function(t)
	return _G.next(t) == nil
end

oldpairs = oldpairs or pairs
oldipairs = oldipairs or ipairs
table.pairs = function(t, ...)
	local mt = getmetatable(t)
	return (mt and mt.__pairs or oldpairs)(t, ...)
end
table.ipairs = function(t, ...)
	local mt = getmetatable(t)
	return (mt and mt.__ipairs or oldipairs)(t, ...)
end

_G["oldpairs"] = oldpairs
_G["pairs"] = table.pairs
_G["ipairs"] = table.ipairs
