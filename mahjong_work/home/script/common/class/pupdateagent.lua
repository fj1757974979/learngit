puppy.pUpdateAgent.onCheckUpdateDone = function(self, code)
	if self.checkUpdateCb then
		setTimeout(1, function()
			self.checkUpdateCb(code)
			self.checkUpdateCb = nil
		end)
	end
end

puppy.pUpdateAgent.oldCheckUpdate = puppy.pUpdateAgent.oldCheckUpdate or puppy.pUpdateAgent.checkUpdate

puppy.pUpdateAgent.checkUpdate = function(self, callback)
	self.checkUpdateCb = callback
	log("error", "checking update")
	self:oldCheckUpdate()
end

puppy.pUpdateAgent.onUpdateFileDone = function(self, path, code)
	if self.updateFileCb then
		self.updateFileCb(path, code)
	end
	logv("error", self.idx, self.cnt)
	if self.idx and self.list and self.cnt then
		self.idx = self.idx + 1
		if self.cnt >= self.idx then
			setTimeout(1, function()
				self:updateFile(self.list[self.idx])
			end)
		end
	end
end


puppy.pUpdateAgent.updateFileList = function(self, fileList, callback)
	if self.updateFileListJson then
		local opChannel = gameconfig:getConfigStr("global", "op_channel", "")
		local modJson = import("common/json4lua.lua")
		local list = {
			channel = opChannel,
			files = fileList,
		}
		self:updateFileListJson(modJson.encode(list))
	else
		self.updateFileCb = callback
		self.list = fileList
		self.idx = 1
		self.cnt = table.size(fileList)
		logv("error", self.idx, self.cnt)
		if self.cnt >= self.idx then
			self:updateFile(fileList[self.idx])
		end
	end
end

puppy.pUpdateAgent.oldUpdateDone = puppy.pUpdateAgent.oldUpdateDone or puppy.pUpdateAgent.updateDone

puppy.pUpdateAgent.updateDone = function(self)
	self.checkUpdateCb = nil
	self.updateFileCb = nil
	self.idx = nil
	self.cnt = nil
	self.list = nil
	self:oldUpdateDone()
end

