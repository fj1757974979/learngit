local modMenuMain = import("ui/menu/main.lua")
local menuMain = modMenuMain.pMainMenu
local modGroupMgr = import("logic/group/mgr.lua")
local modGroupEntry = import("ui/group/entry.lua")
local modGroupMainPanel = import("ui/group/main.lua")
local modMailMgr = import("logic/post/mgr.lua")
local modEvent = import("common/event.lua")

pMainZaqueyue = pMainZaqueyue or class(menuMain)

pMainZaqueyue.init = function(self)
	menuMain.init(self)
end

pMainZaqueyue.isShowAuth = function(self)
	self.btn_auth:show(false)
end

pMainZaqueyue.isHideInviteWnd = function(self)
	return true
end

pMainZaqueyue.showDianWnd = function(self, isShow)
end

pMainZaqueyue.initTemplate = function(self)
	menuMain.initTemplate(self)
	self:hintMail(false)
end

pMainZaqueyue.hintMail = function(self, isShow)
	if self.wnd_dian then
		self.wnd_dian:show(isShow)
	end
end

pMainZaqueyue.regEvent = function(self)
	menuMain.regEvent(self)

	self.btn_mini_group:addListener("ec_mouse_click", function()
		modGroupMgr.pGroupMgr:instance():initGroups(function()
			local groupCnt = modGroupMgr.pGroupMgr:instance():getGroupCnt()
			if groupCnt <= 0 then
				modGroupEntry.pGroupEntryPanel:instance():open()
			else
				modGroupMainPanel.pGroupMainPanel:instance():open()
			end
		end)
	end)

	self.__post_mail_hdr = modEvent.handleEvent(EV_PROCESS_POST, function(isShow)
		self:hintMail(isShow)
	end)
end

pMainZaqueyue.updateHasNewMails = function(self)
	modMailMgr.pMailMgr:instance():getMails(nil, function() end)
end

pMainZaqueyue.close = function(self)
	menuMain.close(self)
end

