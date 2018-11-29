local modUserData = import("logic/userdata.lua")
local modEvent = import("common/event.lua")
local modMailRpc = import("logic/mail/rpc.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")
local modProcessData = import("logic/club/processdata.lua")
local modMail = import("logic/mail/mail.lua")

local pMailMain = pMailMain or class()

pMailMain.init = function(self)
	self.hashNumber = 10
	self:loadFileMails()
	self.updateMailFileIds = {  }
end

pMailMain.loadFileMails = function(self)
	if not self.idToMails then 
		self.idToMails = {}
	else
		return
	end
	for i = 0, self.hashNumber do
		local mails = self:loadMailData(i)
		if mails then
			for index, mail in pairs(mails) do
				if not self.idToMails[i] then
					self.idToMails[i] = {}
				end
				if not self:findIsAddMailById(mail.id) then
					table.insert(self.idToMails[i], modMail.pMail:new(mail, i, index))
				end
			end
		end
	end
end

pMailMain.findIsAddMailById = function(self, id)
	if not self.idToMails or table.size(self.idToMails) <= 0 then return end
	for _, mails in pairs(self.idToMails) do
		for _, mail in pairs(mails) do
			if mail.id == id then
				return true
			end
		end
	end
	return false
end

pMailMain.getNewMails = function(self, callback)
	local minId = 0
	if self.idToMails and table.size(self.idToMails) > 0 then
		minId = self:findNewMailId() + 1
	end
	self:getMailsByMinIdCount(minId, 100, function(mails)
		for idx, mail in ipairs(mails) do
			if not self.writeKey then
				self.writeKey = (self:loadKeyData() + 1) % self.hashNumber
			end
			if not self.idToMails[self.writeKey] then
				self.idToMails[self.writeKey] = {}
			end
			local index = table.getn(self.idToMails[self.writeKey]) + idx
			table.insert(self.idToMails[self.writeKey], modMail.pMail:new(mail, self.writeKey, index))
			self:updateMailStateAddUpdateFileIds(self.writeKey)
		end
		if callback then
			callback(mails)	
		end
	end)	
end

pMailMain.getMailsByMailType = function(self, t, callback)
	self:getNewMails(function()
		local tmps = {}
		for _, mails in pairs(self.idToMails) do
			for _, mail in pairs(mails) do
				if mail:getType() == t or not t then
					table.insert(tmps, mail)
				end
			end
		end
		if callback then
			callback(tmps)
		end
	end)
end

pMailMain.findNewMailId = function(self)
	if not self.idToMails or table.size(self.idToMails) <= 0 then
		return 0	
	end
	local maxId = 0
	for _, mails in pairs(self.idToMails) do
		for _, mail in pairs(mails) do
			if mail:getMailId() >= maxId then
				maxId = mail:getMailId()
			end
		end
	end
	return maxId
end

pMailMain.updateMailStateAddUpdateFileIds = function(self, id)
	if not id then return end
	if self:findIsAddId(id) then return end
	table.insert(self.updateMailFileIds, id)
end

pMailMain.findIsAddId = function(self, id)
	if not self.updateMailFileIds or table.getn(self.updateMailFileIds) <= 0 then
		self.updateMailFileIds = {  }
	end
	for _, fileId in pairs(self.updateMailFileIds) do
		if fileId == id then return true end
	end
	return false
end


pMailMain.getMailFileName = function(self, number)
	if not number then return end
	return sf("%d/mail_datas_%d.dat", modUserData.getUID(), number)
end

pMailMain.getKeyFileName = function(self)
	return sf("%d/mail_data_key.dat", modUserData.getUID())
end

pMailMain.saveKeyData = function(self, key)
	local data = {}
	data["key"] = key
	modProcessData.pProcessData:instance():saveData(data, self:getKeyFileName())
end

pMailMain.loadKeyData = function(self)
	local data = modProcessData.pProcessData:instance():loadData(self:getKeyFileName())
	if not data or not data["key"]then return 0 end
	return data["key"]
end

pMailMain.loadMailData = function(self, number)
	if not number then return end
	local data = modProcessData.pProcessData:instance():loadData(self:getMailFileName(number))
	return data
end

pMailMain.getMailsByMinIdCount = function(self, minId, count, callback)
	modMailRpc.getMails(minId, maxCount, function(success, reason, reply)
		if success then
			if callback then
				callback(reply.mails)
			end
		else
			infoMessage(reason)
		end
	end)
end

pMailMain.processJoinMail = function(self, id, isAccept, callback)
	if not id then return end
	modMailRpc.processJoinMail(id, isAccept, function(success)
		if callback then
			callback(success)
		end
	end)
end

pMailMain.processReturnGoldMail = function(self, id, isAccept, callback)
	if not id then return end
	modMailRpc.processReturnGoldMail(id, isAccept, function(success)
		if callback then
			callback(success)
		end
	end)
end

pMailMain.writeMails = function(self)
	if not self.idToMails and table.size(self.idToMails) <= 0 then return end
	if not self.updateMailFileIds or table.getn(self.updateMailFileIds) <= 0 then return end
	for _, id in pairs(self.updateMailFileIds) do
		local datas = self.idToMails[id]
		local tmps = self:mailObjConvertSaveMail(datas)
		modProcessData.pProcessData:instance():saveData(tmps, self:getMailFileName(id))
	end
	if self.writeKey then
		self:saveKeyData(self.writeKey)
		self.writeKey = nil
	end
	self.updateMailFileIds = {}
end

pMailMain.mailObjConvertSaveMail = function(self, datas)
	if not datas then return end
	local tmps = {}
	for idx, data in pairs(datas) do
		local td = {}
		td["id"] = data:getMailId()
		td["category"] = data:getCategory()
		td["type"] = data:getType()
		td["from_user_id"] = data:getFromUid()
		td["state"] = data:getState()
		td["created_date"] = data:getDate()
		td["text"] = data:getText()
		td["attach"] = data:getOriginAttach()
		table.insert(tmps, td)
	end
	return tmps
end


pMailMain.updateHasNewMails = function(self, callback)
	if not self.idToMails or table.size(self.idToMails) <=0 then
		if callback then
			callback(false)
		end
		return
	end
	local needProcess = false
	for _, mails in pairs(self.idToMails) do
		for _, mail in pairs(mails) do
			if mail:isNeedProccess() then
				needProcess = true
				break
			end
		end
	end
	if not needProcess then
		self:getNewMails(function(mails)
			needProcess = table.getn(mails) > 0
			if callback then
				callback(needProcess)
			end
			modEvent.fireEvent(EV_PROCESS_MAIL, needProcess)
		end)
	else
		if callback then
			callback(needProcess)
		end
	end
	modEvent.fireEvent(EV_PROCESS_MAIL, needProcess)
end


pMailMain.destory = function(self)
	self.hashNumber = 10
	self.writeKey = nil
	self.updateMailFileIds = nil
end

----------------------------- mgr ----------------------------
pMailMgr = pMailMgr or class(pSingleton)

pMailMgr.init = function(self)
	self.curMail = nil
end

getCurMail = function(self)
	if not pMailMgr:instance().curMail then
		pMailMgr:instance():newMail()
	end
	return pMailMgr:instance().curMail
end

pMailMgr.newMail = function(self)
	self.curMail = pMailMain:new()
end

pMailMgr.destory = function(self)
	self.curMail:destory()
	self.curMail = nil
	pMailMgr:cleanInstance()
end

