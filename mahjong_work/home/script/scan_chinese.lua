
local DEF_FIND_ALL_CHINESE = "scan_all_chinese"
local DEF_FIND_LEAK_CHINESE = "scan_leak_chinese"
local workMode = DEF_FIND_LEAK_CHINESE
--local workMode = DEF_FIND_ALL_CHINESE

local resultFilePath = "../../scan_chinese_result.txt"
local missResultFilePath = "../../missing_chinese_result.txt"

local localeFilePath = "./data/info/info_locale"

local tbRootPath = {
	programFileRootPath = "./logic",
	uiFileRootPath = "./ui",
	initFileRootPath = "./init",
	tableFileRootPath = "./data/info",
	netFileRootPath = "./net",
	utilFileRootPath = "./util",
}

local tbLogText = {
	"log",
	"logv",
	"error",
	"print",
}

local tbFilterFileName = {
	"info_locale",
	"scan_chinese",
}

table = table
table.protect = function( ... )
	return ...
end

local DATA = nil

function getLocaleData()
	require(localeFilePath)
	local ret = {}
	for _, info in pairs(data) do
		ret[info["cn"]] = info
	end
	return ret
end

function isRecorded(str)
	local result = false
	if not DATA then
		DATA = getLocaleData() or {}
	end

	if str then
		if DATA[ str ] then
			result = true
		end
	end

	return result
end

function getCmds()
	local result = {}

	for _, rootPath in pairs(tbRootPath) do
		local cmd = string.format("find %s *.lua", rootPath)
		table.insert(result, cmd)
	end

	return result
end

function getStrs(text, key)
	local tbBeginPos = {}
	local tbEndPos = {}
	local tbStrs = {}
	local isBegin = true

	for pos = 1, string.len(text) do
		local byte = string.byte(string.sub(text, pos, pos))
		if byte == key then
			if pos == 1 or string.byte(string.sub(text, pos-1, pos-1)) ~= 92 then
				if isBegin then
					table.insert(tbBeginPos, pos)
				else
					table.insert(tbEndPos, pos)
				end
				isBegin = not isBegin
			end
		end
	end

	for idx = 1, #tbBeginPos do
		local beginPos = tbBeginPos[ idx ]
		local endPos = tbEndPos[ idx ]
		if beginPos and endPos then
			-- 是否被TEXT包裹
			if string.sub(text, beginPos - 5, beginPos - 2) == "TEXT" then
				local res = string.sub(text, beginPos, endPos)
				table.insert(tbStrs, res)
			end
		end
	end

	return tbStrs
end

function getRealStr(str)
	return string.sub(str, 2, -2)
end

function isLogText(strLine)
	local result = false

	if strLine then
		for _, key in ipairs(tbLogText) do
			local posA, posB = string.find(strLine, key)
			if posB then
				local nextChar = string.sub(strLine, posB+1, posB+1)
				
				if string.byte(nextChar) == 40 then
					result = true
				end
				break
			end
		end
	end

	return result
end

function includeChinese(text)
	for pos = 1, string.len(text) do
		local byte = string.byte(string.sub(text, pos, pos))
		if byte > 128 then
			return true
		end
	end

	return false
end

function isLuaFile(strPath)
	local result = false

	if strPath then
		local suffixName = string.sub(strPath, -4, -1)
		if suffixName == ".lua" then
			result = true
		end

		for _, fileName in ipairs(tbFilterFileName) do
			local a, b = string.find(strPath, fileName)
			if a or b then
				result = false
				break
			end
		end
	end

	return result
end

function recordChinese(pathFile, tbRecord)
	for path in pathFile:lines() do
		if isLuaFile(path) then
			print("searching " .. path)
			for strLine in io.lines(path) do
				if not isLogText(strLine) then
					local tbStrsA = getStrs(strLine, 34)
					local tbStrsB = getStrs(strLine, 39)

					for _, str in pairs(tbStrsA) do
						if str and includeChinese(str) then
							local realStr = getRealStr(str)

							if workMode == DEF_FIND_ALL_CHINESE then
								tbRecord[ realStr.."\n" ] = true
							elseif workMode == DEF_FIND_LEAK_CHINESE then
								if not isRecorded(realStr) then
									tbRecord[ realStr.."\n" ] = true
								end
							end
						end
					end
					for _, str in pairs(tbStrsB) do
						if str and includeChinese(str) then
							local realStr = getRealStr(str)
							
							if workMode == DEF_FIND_ALL_CHINESE then
								tbRecord[ realStr.."\n" ] = true
							elseif workMode == DEF_FIND_LEAK_CHINESE then
								if not isRecorded(realStr) then
									tbRecord[ realStr.."\n" ] = true
								end
							end
						end
					end
				end
			end
		end
	end
end

function getSortResult(tb)
	local result = {}
	for key, _ in pairs(tb or {}) do
		table.insert(result, key)
	end

	table.sort(result, function(a, b)
		local minLenA = math.min(string.len(a), string.len(b))
		local flg = true

		for pos = 1, minLenA do
			local byteA = string.sub(a, pos, pos)
			local byteB = string.sub(b, pos, pos)

			if byteA ~= byteB then
				flg = byteA < byteB
			end
		end

		return flg
	end)

	return result
end

function start()
	local tbChinese = {}
	local tbCmd = getCmds()

	for _, cmd in ipairs(tbCmd) do
		local pathFile = io.popen(cmd)
		recordChinese(pathFile, tbChinese)
		pathFile:close()
	end
	
	local resultFile = nil
	if workMode == DEF_FIND_ALL_CHINESE then
		resultFile = io.open(resultFilePath, "w+")
	elseif workMode == DEF_FIND_LEAK_CHINESE then
		resultFile = io.open(missResultFilePath, "w+")
	end

	if resultFile then
		local tbResult = getSortResult(tbChinese)
		for _, val in ipairs(tbResult) do
			resultFile:write(val)
		end

		resultFile:close()
	end

	print("\n\n\t Completed.\n\n")
end

start()

