local modJson = import("common/json4lua.lua")

gUserConfig = gUserConfig or nil

local defaultConfig = {
	musicFlag = true,
	soundFlag = true,
	debugFlag = false,
}

loadConfig = function()

	if gUserConfig then return gUserConfig end

	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	local data = ioMgr:getFileContent("tmp:config.dat")
	if data and data ~= "" then
		gUserConfig = modJson.decode(data)
	end
	return defaultConfig
end

saveConfig = function()
	-- 存文件
	local config = loadConfig()
	local data = modJson.encode(config)
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	local buff = puppy.pBuffer:new()
	buff:initFromString(data, len(data))
	local ret = ioMgr:save(buff, "tmp:config.dat", 0)
	logv("info", "save config success", config)
end

getConfig = function(key)
	local config = loadConfig()
	return config[key]
end

setConfig = function(key, value)
	local config = loadConfig()
	config[key] = value
	-- saveConfig(config)
end