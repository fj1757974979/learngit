
----------------------------------------------------------------------
-- 辅助函数, 切分字符串
-- this function come from: http://lua-users.org/wiki/SplitJoin
----------------------------------------------------------------------
function string.split(str, pat)
   local t = {}  
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- 字符串里面有可能包含常量字符串
-- 对常量字符串解码
-- 常量字符串的格式 #(编号#:参数1#,参数2#,参数3#,...#)
--fs_require("script/data", "info/mission/init.lua")
-- const_string_table
string.decode = function(str)
	return string.gsub(str, "#%(.*#%)", function (str)
		local arr = string.split(str, "#[%(|#)]")
		local ret_str = {}
		for i=1,#arr do
			if i%2 == 1 then
				local t = string.split(arr[i], "#[%,|:]")
				local const_string = const_string_table[t[1]] or ""
				-- 参数替换
				arr[i] = string.gsub(const_string, "$[0-9]", function(str)
					local arg_num = string.byte(str, 2) - string.byte("0", 1) + 1
					if arg_num > #t then
						log("error|onlyu", "参数个数不对")
					end
					return t[arg_num+1] or ""					
				end)
			end
		end
		str = ""
		for i=1,#arr do
			str = str .. arr[i]
		end
		return str
	end)
end

string.url_encode = function(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str 
end 

string.url_decode = function(str)
	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)",
		function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end

string.utf8_to_gb2312 = function(str)
	-- return win32.UTF8ToGB2312(str)
	-- fix me
	return str
end

string.gb2312_to_utf8 = function(str)
	-- return win32.GB2312ToUTF8(str)
	-- fix me
	return str
end

-- 获得某个字符串的字符列表
-- 比如abc你好,返回{'a','b','c',TEXT('你'),TEXT('好')}
string.get_char_list = function(text)
	local char_list = {}
	local len_list = {}

	local i = 1
	local len = string.len(text)
	while i <= len do
		local first_char = string.byte(text, i)
		if first_char < 128 then
			table.insert(char_list, string.sub(text, i, i))
			table.insert(len_list, 1)
			i = i + 1
		else
			local s = i

			while bit.dword_and(first_char, 0x80) ~= 0 do
				if i > len then
					break
				end

				i = i + 1

				first_char = bit.dword_lshift(first_char, 1)
			end

			table.insert(char_list, string.sub(text, s, i-1))
			table.insert(len_list, 2)
		end
	end
	
	return char_list, len_list
end

string.trim = function(str)
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end
