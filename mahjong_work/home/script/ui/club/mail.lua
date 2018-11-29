local modClubMgr = import("logic/club/main.lua")
local modUIUtil = import("ui/common/util.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")
local modMailMgr = import("logic/mail/main.lua")
local modEvent = import("common/event.lua")

pMail = pMail or class(pWindow)

pMail.init = function(self, mailInfo, host)
	self:load("data/ui/club_desk_list_mail_card.lua")
	self.mailInfo = mailInfo
	self.host = host
	self:initUI()
	self:regEvent()
end


pMail.initUI = function(self)
	--self.btn_refuse:setText("拒绝")
	--self.btn_ok:setText("同意")
	self:isShowBtn()
	if self.mailInfo:isNormalMail() then
		self:setSize(self:getWidth(), self:getHeight() - 80)
	end
	self.wnd_txt:setText(sf("【%s】", os.date("%m-%d  %H:%M", self.mailInfo:getDate())) .. self.mailInfo:getText())
end

pMail.showBtn = function(self, isShow)
	self.btn_refuse:show(isShow)
	self.btn_ok:show(isShow)
end

pMail.isShowBtn = function(self)
	if not self.mailInfo then return end
	self:showBtn(self:getIsShowMailBtn())	
end

pMail.getIsShowMailBtn = function(self)
	if self.mailInfo:isNormalMail() then
		return false
	end
	if self.mailInfo:isProcessed() then
		return false
	end
	return true
end

pMail.regEvent = function(self)
	self.btn_refuse:addListener("ec_mouse_click", function() 
		self:process(false)
	end)

	self.btn_ok:addListener("ec_mouse_click", function() 
		self:process(true)
	end)
end

pMail.process = function(self, isAccept)
	self.mailInfo:process(isAccept, function(success)
		if success then
			self:processSuccess()
		end
	end)
end

pMail.processSuccess = function(self)
	local text = { [true] = "已同意", [false] = "已拒绝" }
--	infoMessage(text[isAccept])
	self:showBtn(false)
--	modMailMgr.getCurMail():writeMails()

--[[	if self.host then 
		self.host:updateMailState(self.mailInfo, { ["state"] = modMailProto.Mail.PROCESSED })
	end
	modMailMgr.getCurMail():updateHasNewMails(function(hasNewMails)
		modEvent.fireEvent(EV_PROCESS_MAIL, hasNewMails)
	end)]]--
end
