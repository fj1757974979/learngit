local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modShareMgr = import("logic/share/club_share_mgr.lua")

pClubSharePanel = pClubSharePanel or class(pWindow, pSingleton)

pClubSharePanel.init = function(self)
	self:load("data/ui/club_share.lua")
	self:setParent(gWorld:getUIRoot())
	self:initUI()
	self:regEvent()
	modUIUtil.makeModelWindow(self, false, true)
end

pClubSharePanel.regEvent = function(self)

	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_share_timeline:addListener("ec_mouse_click", function()
		self:share(1)
	end)

	self.btn_share_friend:addListener("ec_mouse_click", function()
		self:share(2)
	end)

end

pClubSharePanel.share = function(self, shareType)
	if not shareType then return end
	local name = self.shareMgr:getName()
	local id = self.shareMgr:getId()
	local link = self.shareMgr:getLink()
	local desc = self.shareMgr:getDesc()
	if puppy.sys.shareWeChat then
		puppy.sys.shareWeChat(shareType, TEXT(sf("%s【%06d】", name, id)), TEXT(desc), link)
	end
	log("info", TEXT(sf("%s【%06d】", name, id)), TEXT(desc), link)
	self:close()
end


pClubSharePanel.open = function(self, mgr)
	self.shareMgr = mgr
end

pClubSharePanel.initUI = function(self)
	self.wnd_text_1:setText("分享到朋友圈")
	self.wnd_text_2:setText("分享到好友或群")
end

pClubSharePanel.close = function(self)
	if self.shareMgr then
		self.shareMgr:destroy()
		self.shareMgr = nil
	end
	pClubSharePanel:cleanInstance()
end

