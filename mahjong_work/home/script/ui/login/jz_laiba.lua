local modUIUtil = import("ui/common/util.lua")
local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pJzlaibaPanel = pJzlaibaPanel or class(loginPanel)

pJzlaibaPanel.init = function(self)
	loginPanel.init(self)
end

pJzlaibaPanel.initSizePos = function(self)
	self.btn_wechat:setImage(modUIUtil.getChannelRes("login_wechat.png"))
	self.btn_wechat:setSize(280, 96)
	self.btn_wechat:setOffsetY(gGameHeight * -0.08)
	self.wnd_logo:show(false)
end
