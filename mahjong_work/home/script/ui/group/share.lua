local modUtil = import("util/util.lua")
local modChannelMgr = import("logic/channels/main.lua")

pGroupSharePanel = pGroupSharePanel or class(pWindow, pSingleton)

pGroupSharePanel.init = function(self)
	self:load("data/ui/group_share.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self, false, true)
	self:initUI()
	self:regEvent()
end

pGroupSharePanel.initUI = function(self)
	self.wnd_text_1:setText(TEXT("分享到朋友圈"))
	self.wnd_text_2:setText(TEXT("分享到好友或群"))
end

pGroupSharePanel.regEvent = function(self)
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

pGroupSharePanel.share = function(self, shareType)
	shareType = shareType or 1
	local name = self.group:getProp("name")
	local id = self.group:getGrpId()
	local link = modChannelMgr.getCurChannel():getShareGroupUrl()
	local desc = self.group:getProp("desc")
	if puppy.sys.shareWeChat then
		puppy.sys.shareWeChat(shareType, TEXT(sf("%s【%06d】", name, id)), TEXT(desc), link)
	end
	log("info", TEXT(sf("%s【%06d】", name, id)), TEXT(desc), link)
	self:close()
end

pGroupSharePanel.open = function(self, group)
	self.group = group
end

pGroupSharePanel.close = function(self)
	pGroupSharePanel:cleanInstance()
end
