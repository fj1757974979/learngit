local modJson = import("common/json4lua.lua")

pProcessData = pProcessData or class(pSingleton)

pProcessData.init = function(self)
end

pProcessData.saveData = function(self, data, filename)
	if not data or not filename then return end
	logv("warn", "save", data)
	data = modJson.encode(data)

	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	local buff= puppy.pBuffer:new()
	buff:initFromString(data, len(data))

	local ret = ioMgr:save(buff, "tmp:" .. filename, 0)
	logv("info", "save user mails data " .. filename)
end


pProcessData.loadData = function(self, filename)
	if not filename then return end
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	if not ioMgr:fileExist("tmp:" .. filename) then
		return nil
	end

	local data = ioMgr:getFileContent("tmp:" .. filename)
	if data and data ~= "" then
		local setData = modJson.decode(data)
		log("info", "load data" .. filename)
		return setData
	else
		return nil
	end
end
