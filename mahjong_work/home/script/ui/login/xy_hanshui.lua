local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")

local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pXyhanshuiPanel = pXyhanshuiPanel or class(loginPanel)

pXyhanshuiPanel.initSizePos = function(self)
	local channelId = modUtil.getOpChannel()
	self.wnd_logo:setImage(modUIUtil.getChannelRes("logo.png"))
	self.btn_wechat:setImage(modUIUtil.getChannelRes("login_wechat.png"))
	self.wnd_logo:setAlignX(ALIGN_CENTER)
	self.wnd_logo:setAlignY(ALIGN_MIDDLE)
	self.wnd_logo:setOffsetY(-gGameHeight * 0.1)
	self.wnd_logo:setSize(624, 250)
	self.btn_wechat:setSize(351, 110)
	self.btn_wechat:setOffsetY(gGameHeight * -0.08)
end
