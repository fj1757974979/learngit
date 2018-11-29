local modJson = import("common/json4lua.lua")

local filename = "tmp:hint.dat"

pHintSaveMgr = pHintSaveMgr or class(pSingleton)

pHintSaveMgr.init = function(self)
	local app = puppy.world.pApp.instance()
	local ioMgr = app:getIOServer()
	if not ioMgr:fileExist(filename) then
		self.savedHints = {}
	else
		local data = ioMgr:getFileContent(filename)
		if data and data ~= "" then
			self.savedHints = modJson.decode(data)
		end
	end
end

pHintSaveMgr.flushToFile = function(self)
	local app = puppy.world.pApp.instance()
	local ioMgr = app:getIOServer()
	local buff = puppy.pBuffer:new()
	local data = modJson.encode(self.savedHints)
	buff:initFromString(data, len(data))
	self.buff = buff
	ioMgr:save(self.buff, filename, 0)
end

pHintSaveMgr.addHint = function(self, hintName)
	if not self.savedHints[hintName] then
		self.savedHints[hintName] = true
		self:flushToFile()
	end
end

pHintSaveMgr.delHint = function(self, hintName)
	if self.savedHints[hintName] then
		self.savedHints[hintName] = nil
		self:flushToFile()
	end
end

pHintSaveMgr.checkSavedHints = function(self)
	local modHintMgr = import("logic/hint/mgr.lua")
	local hintMgr = modHintMgr.pHintMgr:instance()
	for hintName, _ in pairs(self.savedHints) do
		hintMgr:fireHint(hintName, true)
	end
end
