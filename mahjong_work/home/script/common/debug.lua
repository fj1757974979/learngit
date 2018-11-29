docommand = function(self, cmd)
	cmd = string.gsub(cmd, "\n", "")
	if true or app:is_debug() then
		local func = loadstring(cmd)
		if func then
			func()
		else
			parse_do_command(cmd)
		end
	else
		parse_do_command(cmd)
	end	
end

debug_get_value = function(t)
	--log("info", t)
	local var = tonumber(t)
	if var then
		return var
	end

	if string.sub(t,1,1) == "\"" then
		return string.sub(t, 2,-2)
	end

	if t == "true" then
		return true
	end

	if t == "false" then
		return false
	end

	var = t:split("%.")
	--logv("info", var)
	local ret = _G
	for _,key in ipairs(var) do
		--log("info", key, ret)
		ret = ret[key]
	end
	return ret
end

set = function(name, value)
	_G[name] = value
end

show_console = function(flag)
	puppy.console:instance():show(flag)
end

show_debug = function(flag)
	main_ctx:show_debug(flag)
end

save_texture = function()
	main_ctx:save_texture()
end

local processed_table = {}
function count_table_size(t, deep)
	if processed_table[t] then return 0 end
	if deep == 0 then return 0 end
	--processed_table[t] = true
	local child = 0
	for k,v in pairs(t) do
		child = child + 1
		if is_table(v) then
			child = child + count_table_size(v, deep -1)
		end
	end
	return child
end

local MaxDeep = 3
local function _Log(...)
        log("info", ...)
end

function dump(headstr, tbl, _deep)
        if _deep > MaxDeep then return end

        for n, v in pairs(tbl) do
                if type(v) == "table" then 
			_Log(headstr, n)
			dump( string.format("%s_%s", tostring(headstr), tostring(n)), v, _deep + 1)
                else 
                        _Log(headstr,n,v)
		end
	end

end


function dump_global(headstr, t, deep)
	headstr = headstr or "_G"
	t = t or _G
	local count = 0
	local str = ""
	local child_size = {}
	processed_table = { [_G] = true}
	for k,v in pairs(t) do
		count = count + 1
		if is_table(v) then
			table.insert(child_size,{k, count_table_size(v, deep)})
			--str = str .. string.format("%s:%d\n", tostring(k), count_table_size(v, 5))
		end
	end

	table.sort(child_size, function(a, b)
		return a[2] > b[2]
	end)
	local f = io.open("tmp/global.txt", "a")
	f:write("\r\n\r\n\r\n\r\n")
	f:write( "============================".. headstr .."=====================\r\n")
	f:write(string.format("global size %d\n", count))
	for _, v in ipairs(child_size) do
		if v[2] > 100 then
			f:write(tostring(v[2]) .. "\t" .. tostring(v[1]).. "\r\n")
		end
	end
	f:close()
end

function parse_do_command(cmd)
	local t = cmd:split(" ")
	local func =  debug_get_value(t[1])
	local t1 = {}

	for i=2,#t do
		table.insert(t1, debug_get_value(t[i]))
	end

	if is_function(func) then
		ans = func(unpack(t1))
		if ans then
			log("info", "result:", ans)
		end
	else
		log("error", string.format("command not find:%s", cmd))
	end
end

function throw(msg)
	a.a = 1
end

gc = function()
	collectgarbage("collect")
end

dump_objects = function()
	log("error", "all objects:")
	local ret = {}
	for cls, _ in pairs(allClasses) do
		-- log("error", "class ", cls.__class_name, "object count:", #table.keys(cls.__objs))
		table.insert(ret, {cls.__class_name, #table.keys(cls.__objs)})
	end

	table.sort(ret, function(t1, t2)
		return t1[2] > t2[2]
	end)

	for _, v in ipairs(ret) do
		log("error", v[2], v[1])
	end
end

__init__ = function(self)
	console.docommand = docommand
	export("throw", throw)
	export("gc", gc)
end
