local modMailMain = import("logic/mail/main.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")
local modMailPanel = import("ui/club/mail.lua")
local modMailMgr = import("logic/mail/main.lua")

local MAIL_TYPE_NORMAIL = 0
local MAIL_TYPE_JOIN_CLUB = 1
local MAIL_TYPE_RETURN = 2
local MAIL_STATE_NO_PROC = 0
local MAIL_STATE_NEED_PROC = 1
local MAIL_STATE_PROCESSED = 2
local MAIL_CATEGORY_GENERAL = 0
local MAIL_CATEGORY_CLUB = 1

pMail = pMail or class()

pMail.init = function(self, protoMail, fileId, fileIdPos)
	self.mailTypes = {
		[modMailProto.Mail.NORMAL] = MAIL_TYPE_NORMAIL,
		[modMailProto.Mail.JOIN_CLUB] = MAIL_TYPE_JOIN_CLUB,
		[modMailProto.Mail.RETURN_GOLD_COINS_TO_CLUB] = MAIL_TYPE_RETURN,
	}
	self.mailStates = {
		[modMailProto.Mail.NO_NEED_PROCESSING] = MAIL_STATE_NO_PROC,
		[modMailProto.Mail.NEED_PROCESSING] = MAIL_STATE_NEED_PROC,
		[modMailProto.Mail.PROCESSED] = MAIL_STATE_PROCESSED
	}
	self.mailCategorys = {
		[modMailProto.Mail.GENERAL] = MAIL_CATEGORY_GENERAL,
		[modMailProto.Mail.CLUB] = MAIL_CATEGORY_CLUB
	}
	self:initValues(protoMail)
	self.fileId = fileId
	self.fileIdPos = fileIdPos
end

pMail.initValues = function(self, protoMail)
	self.id = protoMail.id
	self.category = self.mailCategorys[protoMail.category] 
	self.t = self.mailTypes[protoMail.type] 
	self.state = self.mailStates[protoMail.state]
	self.fromUid = protoMail.from_user_id
	self.date = protoMail.created_date
	self.text = protoMail.text
	self.attach = protoMail.attach
end

pMail.getMailId = function(self)
	return self.id
end

pMail.getFileId = function(self)
	return fileId
end

pMail.setFileId = function(self, id)
	self.fileId = id
end

pMail.getFileIdPos = function(self)
	return self.fileIdPos
end

pMail.setFileIdPos = function(self, pos)
	self.fileIdPos = pos
end

pMail.getCategory = function(self)
	return self.category
end

pMail.getType = function(self)
	return self.t
end

pMail.getState = function(self)
	return self.state
end

pMail.changeState = function(self, s)
	self.state = s
end

pMail.getFromUid = function(self)
	return self.fromUid
end

pMail.getDate = function(self)
	return self.date
end

pMail.getText = function(self)
	return self.text
end

pMail.isJoinMail = function(self)
	return self.t == MAIL_TYPE_JOIN_CLUB
end

pMail.isReturnMail = function(self)
	return self.t == MAIL_TYPE_RETURN
end

pMail.isNeedProccess = function(self)
	return self.state == MAIL_STATE_NEED_PROC
end

pMail.isNormalMail = function(self)
	return self.t == MAIL_TYPE_NORMAIL
end

pMail.isProcessed = function(self)
	return self.state == MAIL_STATE_PROCESSED
end

pMail.getClubId = function(self)
	return self:getAttach().club_id
end

pMail.getOriginAttach = function(self)
	return self.attach
end

pMail.getAttach = function(self)
	local mailType = self:getType()
	local joinAttach = nil
	if mailType == MAIL_TYPE_JOIN_CLUB then
		joinAttach = modMailProto.Mail_JoinClubAttach()
		joinAttach:ParseFromString(self.attach)
	elseif mailType == MAIL_TYPE_RETURN then
		joinAttach = modMailProto.Mail_ReturnGoldCoinsToClubAttach()
		joinAttach:ParseFromString(self.attach)
	end
	return joinAttach
end

pMail.getMailPanel = function(self)
	if not self.mailPanel then
		self:newMailPanel()
	end
	return self.mailPanel
end

pMail.newMailPanel = function(self, host)
	if self.mailPanel then
		self.mailPanel:setParent(nil)
	end
	self.mailPanel = nil
	self.mailPanel = modMailPanel.pMail:new(self, host)
	return self.mailPanel
end

pMail.process = function(self, isAccept, callback)
	if self:isJoinMail() then
		self:mailJoinProcess(isAccept, callback)
	elseif self:isReturnMail() then
		self:mailReturnGoldProcess(isAccept, callback)
	end
end

pMail.mailJoinProcess = function(self, isAccept, callback)
	modMailMgr.getCurMail():processJoinMail(self.id, isAccept, function(success)
		self:processSuccessWork(success, isAccept, callback)
	end)
end

pMail.mailReturnGoldProcess = function(self, isAccept, callback)
	modMailMgr.getCurMail():processReturnGoldMail(self.id, isAccept, function(success)
		self:processSuccessWork(success, isAccept, callback)
	end)
end

pMail.processSuccessWork = function(self, success, isAccept, callback)
	if not success then
		if callback then
			callback(false)
		end
		logv("error", " success:", success, isAccept)
		return
	end
	if isAccept then
		self:updateClubInfo()
	end
	self:changeState(self.mailStates[modMailProto.Mail.PROCESSED])
	modMailMgr.getCurMail():updateMailStateAddUpdateFileIds(self.fileId)
	if callback then
		callback(true)
	end
end

pMail.updateClubInfo = function(self)
	local modClubMgr = import("logic/club/main.lua")
	modClubMgr.getCurClub():updateClubInfoById(self:getClubId(), function() 
	end)
end


pMail.desotroy = function(self)
	if self.mailPanel then
		self.mailPanel:setParent(nil)
	end
	self.mailPanel = nil
	self.id = nil 
	self.category = nil 
	self.t = nil
	self.state = nil 
	self.fromUid = nil 
	self.date = nil 
	self.text = nil 
	self.attach = nil 
	self.fileId = nil 
	self.fileIdPos = nil 
end
