local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modEvent = import("common/event.lua")
local modMailMgr = import("logic/mail/main.lua")

pDeskMenu = pDeskMenu or class(pWindow, pSingleton)

pDeskMenu.init = function(self)
	self:load("data/ui/club_desk_chk.lua")
	self:setParent(gWorld:getUIRoot())
	self:showDianWnd(false)
	self.isShow = false
	self:regEvent()
end

pDeskMenu.initUI = function(self, lastMark)
	self.chk_desk["mark"] = "desk"  
	self.chk_record["mark"] = "record" 
	self.chk_member["mark"] = "member" 
	self.chk_mail["mark"] = "mail" 
	self.chk_info["mark"] =	"info"
	if not lastMark then lastMark = "desk" end 
	local list = { self.chk_desk, self.chk_record, self.chk_member, self.chk_mail, self.chk_info} 
	for _, chk in pairs(list) do
		if chk["mark"] == lastMark then
			chk:setCheck(true)
			break
		end
	end
	--self.txt_desk:setText("牌局")
	--self.txt_record:setText("数据")
	--self.txt_member:setText("成员")
	--self.txt_mail:setText("邮件")
	--self.txt_info:setText("资料")
end

pDeskMenu.showDianWnd = function(self, isShow)
	self.wnd_dian:show(isShow)
end

pDeskMenu.regEvent = function(self)
	local list = { self.chk_desk, self.chk_record, self.chk_mail, self.chk_info, self.chk_member }
	for _, chk in pairs(list) do
		chk:addListener("ec_mouse_click", function()
			self.host:menuClick(chk["mark"], self)
			self.host:saveLastClick(chk["mark"])
	--		self:destroy()
		end)
	end
end

pDeskMenu.isRefreshGrounds = function(self, mark)
	if not mark then return end
	return mark == self.chk_desk["mark"]
end

pDeskMenu.isClearDianWnd = function(self, mark)
	if not mark then return end
	if mark == self.chk_mail["mark"] then
		self:showDianWnd(false)
	end
end

pDeskMenu.updateHasNewMails = function(self)
	modMailMgr.getCurMail():updateHasNewMails(function(hasNewMails)
		self:showDianWnd(hasNewMails)
	end)
end

pDeskMenu.open = function(self, host, clubInfo, lastMark)
	self:setParent(host)
	self.isShow = not self.isShow
	self:show(self.isShow)
	if not self.isShow then 
		return 
	end
	self.clubInfo = clubInfo
	self.host = host
	self:initUI(lastMark)
	self:updateHasNewMails()
end

pDeskMenu.destroy = function(self)
	pDeskMenu:cleanInstance()
end

pDeskMenu.close = function(self)
	self:show(false)
	self.isShow = false
end

