local modJson = import("common/json4lua.lua")
local modUserData = import("logic/userdata.lua")

pMailData = pMailData or class()

pMailData.init = function(self)
	self.base = 10
	self.mails = {}
	for i = 1, self.base do
		self.mails[i] = {}
	end
	self:loadData()
end

pMailData.getAllMailData = function(self)
	local ret = {}
	for i = 1, self.base do
		local set = self.mails[i]
		for _, data in pairs(set) do
			table.insert(ret, data)
		end
	end
	return ret
end

pMailData.loadData = function(self)
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	for i = 1, self.base do
		local path = sf("tmp:%d_post_data_%d.dat", modUserData.getUID(), i)
		if ioMgr:fileExist(path) then
			local data = ioMgr:getFileContent(path)
			if data and data ~= "" then
				local set = modJson.decode(data)
				for _, mailInfo in pairs(set) do
					self.mails[i][mailInfo["id"]] = mailInfo
				end
			end
		end
	end
end

pMailData.saveData = function(self, mailId, mailInfo)
	local idx = mailId % self.base + 1
	local set = self.mails[idx]
	if set then
		set[mailId] = mailInfo
		local path = sf("tmp:%d_post_data_%d.dat", modUserData.getUID(), idx)
		local pApp = puppy.world.pApp.instance()
		local ioMgr = pApp:getIOServer()
		local data = modJson.encode(set)
		local buff = puppy.pBuffer:new()
		buff:initFromString(data, len(data))
		self.buff = buff
		if ioMgr:save(buff, path, 0) then
			log("info", "saved post mails data for idx", idx)
		else
			log("error", "can't save post mails data for idx", idx)
		end
	end
end
