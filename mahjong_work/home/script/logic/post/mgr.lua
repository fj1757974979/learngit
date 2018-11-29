local modMailData = import("logic/post/data.lua")
local modMail = import("logic/post/mail.lua")
local modMailRpc = import("logic/post/rpc.lua")
local modEvent = import("common/event.lua")

local T_NORMAL = 0
local T_JOIN_GROUP = 3

local mailCls = {
	[T_NORMAL] = modMail.pMail,
	[T_JOIN_GROUP] = modMail.pMailJoinClub,
}

pMailMgr = pMailMgr or class(pSingleton)

pMailMgr.init = function(self)
	self.data = modMailData.pMailData:new()
	self.mails = {}
	self.maxMailId = 0
	self.initFlag = false
	self.waitProcessCnt = 0
	self:loadMails()
	self.__new_mail_hdr = modEvent.handleEvent(EV_NEW_MAIL, function(lastMailId)
		self:getMails(nil, function() end)
	end)
end

pMailMgr.loadMails = function(self)
	local mailsData = self.data:getAllMailData()
	for _, data in ipairs(mailsData) do
		self:addMail(data)
	end
end

pMailMgr.addMail = function(self, mailInfo, save)
	local cls = mailCls[mailInfo.type]
	if cls then
		local mail = cls:new(self, mailInfo)
		local mailId = mail:getId()
		if mailId > self.maxMailId then
			self.maxMailId = mailId
		end
		self.mails[mail:getId()] = mail
		if save then
			mail:save()
		end
		if mail:needOperate() then
			self.waitProcessCnt = self.waitProcessCnt + 1
		end
	end
end

pMailMgr.delMail = function(self, mailId)
	self.mails[mailId] = nil
end

pMailMgr.getMail = function(self, mailId)
	return self.mails[mailId]
end

pMailMgr.getMails = function(self, minMailId, callback)
	if self.initFlag then
		callback(true, "")
		return
	end
	minMailId = minMailId or (self.maxMailId + 1)
	modMailRpc.getMails(minMailId, 1000, function(success, reason, ret)
		if success then
			--self.initFlag = true
			for _, mail in ipairs(ret) do
				local info = modMail.protoToMailInfo(mail)
				self:addMail(info, true)
			end
		end
		if self.waitProcessCnt > 0 then
			modEvent.fireEvent(EV_PROCESS_POST, true)
		end
		callback(success, reason)
	end)
end

pMailMgr.saveMail = function(self, mail)
	self.data:saveData(mail:getId(), mail:getInfo())
end

pMailMgr.onProcessMail = function(self, mail)
	self.waitProcessCnt = math.max(0, self.waitProcessCnt - 1)
	if self.waitProcessCnt <= 0 then
		modEvent.fireEvent(EV_PROCESS_POST, false)
	end
end

pMailMgr.hasMailToProcess = function(self)
	return self.waitProcessCnt > 0
end

pMailMgr.getAllMails = function(self)
	return self.mails
end
