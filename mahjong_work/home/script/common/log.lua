local json = import("json.lua")

lua_print = print
local table_printed = {}
local not_print_key = {
	__base_list = true,
	__objmt = true,
	__class = true,
}
local print_table_detail = false

function write_table(arg)
	table_printed[arg] = true
	io.write("{ ")
	for k,v in pairs(arg) do
		if not not_print_key[k] then

			if type(k) == "number" then
				io.write( "["..tostring(k).."]" )
			else
				io.write( tostring(k) )
			end
			io.write("=")
			if type(v) == "string" then
				local arg = v
				io.write("'")
				if #arg>1000 then
					arg = string.format("%s...(此处省略%d字)", string.sub(arg,1,1000),arg:len()-1000)
				elseif #arg==0 then
					arg = "\"\""			
				end
				
				arg = arg:utf8_to_gb2312()
				
				io.write(arg)
				--[[
				for i=1,string.len(v) do
					local ch = v:byte(i)
					if ch <= 31 then
						io.write( string.format("\\%02d", ch) )
					else
						io.write( string.char(ch) )
					end
				end
				--]]
				io.write("'")
			elseif type(v) == "table" and not table_printed[v] then
				write_table(v)
			else
				io.write( tostring(v) )
			end
			io.write(",")
		end
	end
	io.write(" }")
end

function _print(...)
	args = {...}
	for i= 1, #args do
		local arg = args[i]
		if type(arg) == "string" then
			if #arg>1000 then
				arg = string.format("%s...(此处省略%d字)", string.sub(arg,1,1000),arg:len()-1000)
			elseif #arg==0 then
				arg = "\"\""			
			end
			arg = arg:utf8_to_gb2312()
			io.write(arg)
			
		elseif type(arg) == "number" or type(arg) == "boolean" then
			io.write( tostring(arg) )
		elseif type(arg) == "table" then

			if print_table_detail then
				write_table(arg)
				table_printed = {}
			else
				lua_print(arg)
			end
		else
			io.write( tostring(arg).."["..type(arg).."]" )
		end
		if i<#args then io.write("\t") end
	end
end

-- purple 紫色
-- cyan 青色
local log_conf = {
	info = { color = "green", print = true },
	warn = { color = "blue", print = true },
	error = { color = "red", print = true },
	net = { color = "yellow", print = true },
}

function init_log()
	--[[
	local log_type_str = gameconfig:getConfigStr("log", "log_type", '["info"]')
	local log_type_table = json.from_jstr(log_type_str)

	for _,type in ipairs(log_type_table) do
		local type_conf = gameconfig:getConfigStr("log", type, '{"color":"green", "print":true}')
		local type_table = json.from_jstr(type_conf)
		log_conf[type] = type_table
	end
	--]]
	-- log to file
	local log_file = gameconfig:getConfigStr("log", "log_file", "")
	if #log_file > 0 then
		old_io_write = io.write
		log_file = io.open(log_file, "w")
		io.write = function(...)
			log_file:write(...)
			log_file:flush()
			old_io_write(...)
		end
	end
end

-- local console = puppy.console.instance()
function _log(type, ...)
	local switchs = string.split(type, "|")
	local need_print = false
	local color = "white"
	for _, sw in ipairs(switchs) do
		if log_conf[ sw ] and log_conf[ sw ].print then
			need_print = true
			color = log_conf[ sw ].color
			break
		end
	end
	
	if not need_print then
		return false
	end

	local info = debug.getinfo(3,"Sl")
	_print(string.format("%s(%d)", info.source, info.currentline))
	_print("[")
	for i, sw in ipairs(switchs) do
		if not log_conf[ sw ] then
			console:set_text_color("white")
			_print(sw)
		else
			console:set_text_color( log_conf[ sw ].color )
			_print(sw)
		end
		console:set_text_color("white")
		if i<#switchs then _print("|") end
	end
	_print("]: ")
	console:set_text_color(color)
	_print(...)
	return true
end

-- 打外部客户端的时候，要注销掉log函数
function log(type, ...)
	if app:getPlatform() ~= "macos" then
		return
	end

	print_table_detail = false
	if  _log(type, ...) then
		_print("\n")
	end
	console:set_text_color("white")
end

function logv(type, ...)
	if app:getPlatform() ~= "macos" then
		return
	end

	print_table_detail = true
	if _log(type, ...) then
		_print("\n")
	end
	console:set_text_color("white")
end

-- 
function start_log(type)
	print_table_detail = true
	_log(type)
end

function end_log()
	_print("\n")
	console:set_text_color("white")
end


tprint = function( tb )
	if type(tb) ~= "table" then		
		return
	end
	
	local tb_deep =  20
	local cur_deep = 0
	local tb_cache = {}
	local function print_table(tb_data)
		-- 存储当前层table
		if type(tb_data) ~= "table"  then
			log("Error", "存储类型必须为table:", tb )
			return
		end
		if tb_cache[tb] then
			log("Error", "无法继续存储，table中包含循环引用，", tb )
			return
		end
		local k, v
		cur_deep = cur_deep + 1
		if cur_deep > tb_deep then
			cur_deep = cur_deep -  1
			return	"..."
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
			elseif type(k) == "string" then
				arg = string.format("[\"%s\"]", string.gsub(k,"\\","\\\\"))
			else
				arg = string.format("[\"%s\"]", string.gsub(tostring(k),"\\","\\\\"))
			end

			if type(v) == "number" then
				value = string.format("%f", v)
			elseif type(v) == "string" then
				value = string.format("\"%s\"", string.gsub(v,"\\","\\\\"))		
			elseif type(v) == "table" then
				value = print_table(v)
			else 
				value = tostring(v)
			end
			
			
			if arg and value then
				str = str..string.format("%s%s = %s,\n", tab, arg, value)
			end
		end
		tb_cache[tb_data] = true
		cur_deep = cur_deep -  1
		return str..tab.."}"
	end
	
	local tb_str = print_table(tb)
	_print( tb_str )
		
	return true
end

__init__ = function(self)
	export("log", log)
	export("logv", logv)
	init_log()
end
