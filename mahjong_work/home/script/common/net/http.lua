local modJson = import("common/json4lua.lua")

curlPost = function(url, strData)
	pCurlEasyInit()
	pCurlEasySetoptStr(CURLOPT_URL, url)
	pCurlEasySetoptInt(CURLOPT_POST, 1)
	pCurlEasySetoptStr(CURLOPT_POSTFIELDS, strData)

	ret = pCurlEasyPerform()
	if ret ~= 0 then return nil end

	res = pCurlEasyGetData()
	pCurlEasyCleanup()
	return res
end

curlGet = function(url)
	pCurlEasyInit()
	pCurlEasySetoptStr(CURLOPT_URL, url)
	pCurlEasySetoptInt(CURLOPT_POST, 0)

	ret = pCurlEasyPerform()
	if ret ~= 0 then return nil end

	res = pCurlEasyGetData()
	pCurlEasyCleanup()
	return res
end

local postDataEncode = function(tData)
	if type(tData) == "table" then
		local res
		local temp = {}
		for k, v in pairs(tData) do
			if type(v) == "table" then
				table.insert(temp, k .. "=" .. modJson.encode(v))
			else
				table.insert(temp, k .. "=" ..v)
			end
		end
		res = table.concat(temp, "&")
		--res = string.gsub(res, "\"", "")
		return res
	else
		return nil
	end
end

httpPostSync = function(url, tData)
	local str = postDataEncode(tData)
	local res = curlPost(url, str)
	if not res then return nil end

	local status, ret = pcall(function() 
		local r = modJson.decode(res)
		return r
	end)

	if not status then 
		logv("info", "[httpPostSync] json decode ret fail [exception: " .. ret .. "]")
		return nil
	end

	if ret == "null" or not ret then
		logv("info", "[httpPostSync] json decode ret " .. res .. "fail", ret)
		return nil
	end
	return ret
end

httpGetSync = function(url)
	local res = curlGet(url)
	if not res then return nil end

	local status, ret = pcall(function() 
		local r = modJson.decode(res)
		return r
	end)

	if not status then 
		logv("info", "[httpGetSync] json decode ret " .. res .. "fail [exception: " .. ret .. "]")
		return nill
	end

	if ret == "null" or not ret then
		return nil
	end
	return ret
end

