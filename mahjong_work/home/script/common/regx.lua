local max_chat_pattern_len = 1000
local max_name_pattern_len = 500
local chat_regx_set = chat_regx_set or nil
local name_regx_set = name_regx_set or nil
local precaution_regx_set = nil -- 防盗号过滤

local libname = "cn"

initNameRegexSet = function()
	if not name_regx_set then
		name_regx_set = {}
		local path = sf("script:locale/%s/forbid_name.txt", libname)
		local pattern = iomanager:get_file_content(path) or ""
		local all_pattern = string.gsub(pattern, "\n", "")
		local all_words = string.split(all_pattern, "|")
		--logv("error", all_words)
		local index = 1
		local sub_pattern = ""
		for _, word in ipairs(all_words) do
			if sub_pattern ~= "" then
				sub_pattern = sub_pattern .. "|"
			end
			sub_pattern = sub_pattern .. word
			index = index + 1
			if index >= max_name_pattern_len then
				local regx = puppy.regex.pRegex:new()
				local ret = regx:setPattern(sub_pattern)
				if not ret then
					log("error", "=========== set chat pattern fail! ==========")
					log("error", sub_pattern)
					return
				end
				table.insert(name_regx_set, regx)
				index = 1
				sub_pattern = ""
			end
		end
		if string.len(sub_pattern) > 0 then
			local regx = puppy.regex.pRegex:new()
			local ret = regx:setPattern(sub_pattern)
			if not ret then
				log("error", "=========== set chat pattern fail! ==========")
				log("error", sub_pattern)
				return
			end
			table.insert(name_regx_set, regx)
		end
	end
end

initChatRegexSet = function()
	if not chat_regx_set then
		chat_regx_set = {}
		local path = sf("script:locale/%s/forbid_chat.txt", libname)
		local pattern = iomanager:get_file_content(path) or ""
		local all_pattern = string.gsub(pattern, "\n", "")
		local all_words = string.split(all_pattern, "|")
		--logv("error", all_words)
		local index = 1
		local sub_pattern = ""
		for _, word in ipairs(all_words) do
			if sub_pattern ~= "" then
				sub_pattern = sub_pattern .. "|"
			end
			sub_pattern = sub_pattern .. word
			index = index + 1
			if index >= max_chat_pattern_len then
				local regx = puppy.regex.pRegex:new()
				local ret = regx:setPattern(sub_pattern)
				if not ret then
					log("error", "=========== set chat pattern fail! ==========")
					log("error", sub_pattern)
					return 
				end
				table.insert(chat_regx_set, regx)
				index = 1
				sub_pattern = ""
			end
		end
		if string.len(sub_pattern) > 0 then
			local regx = puppy.regex.pRegex:new()
			local ret = regx:setPattern(sub_pattern)
			if not ret then
				log("error", "=========== set chat pattern fail! ==========")
				log("error", sub_pattern)
				return 
			end
			table.insert(chat_regx_set, regx)
		end
	end
end

isValidString = function(str)
	if not puppy.regex or not puppy.regex.pRegex then
		-- 兼容旧版本
		return true
	end

	if not chat_regx_set then
		initChatRegexSet()
	end

	for _, regx in ipairs(chat_regx_set) do
		if regx:match(str) then
			return false
		end
	end

	return true
end

isValidName = function(name)
	if not puppy.regex or not puppy.regex.pRegex then
		logv("error", "======= old version engine ========")
		return true
	end

	if not name_regx_set then
		initNameRegexSet()
	end

	for _, regx in ipairs(name_regx_set) do
		if regx:match(name) then
			return false
		end
	end

	return true
end

isValidNameLen = function(name, maxLen)
	local utf8_str = utf8(name)
	local len = utf8_str:len()
	if len > maxLen then
		log("info", "len")
		return false
	end
	return true
end

--[[
function build_regx(regx, file)
	local regx_set = regx
	local regexs = iomanager:get_file_content(file) or ""
	regexs = string.gsub(regexs, "\\", "\\\\")
	regexs = string.split(regexs, "\n") or {}
 	regexs = map(applyn(string.sub, 2, 0, 3, -2), regexs)
	regexs = filter( compose(apply(lt, 0), len), regexs)
	foldl(function(set, str) set:add_pattern(str) return set end, regx_set, regexs)
	return regx_set
end


function load(libname)
	name_regx_set = puppy.util.regx_set:new()
	chat_regx_set = puppy.util.regx_set:new()
	precaution_regx_set = puppy.util.regx_set:new()
	build_regx(name_regx_set, {"script", string.format("locale/%s/forbid_name.txt", libname)})
	build_regx(chat_regx_set, {"script", string.format("locale/%s/forbid_chat.txt", libname)})
	build_regx(precaution_regx_set, {"script", string.format("locale/%s/forbid_friend.txt", libname)})
end

function filter_string(str)
	str = chat_regx_set:replace(str, "!@$%^")
	return str
end

function is_valid_string(str)
	if chat_regx_set:match(str) then return false end
	return true
end

-- 是否存在防盗号过滤词
function is_precaution_string(str)
	
	if precaution_regx_set:match(str) then return true end
	return false
end

function is_valid_name(str)
	--if not is_valid_string(str) then return false end
	--if name_regx_set:match(str) then return false end

	local utf8_str = utf8(str)
	local len = utf8_str:len()
	-- 长度要求在2到14之间
	if len < 4 or len > 28 then
		log("info", "len")
		return false
	end

	-- 去掉不可见字符
	for i=1,len do
		local ch = string.byte(utf8_str:get_char(i), 1)
		if ch < 32 then
			log("info", "ch < 32")
			return false
		end
	end
	return true
end

function check_has_user_info(str,ctx)
	if (ctx.ums and string.find(str, ctx.ums)) or (ctx.pwd and string.find(str, ctx.pwd)) then 
		return true
	end
	return false			
end
]]--

__init__ = function(self)
	--load("cn")
end
