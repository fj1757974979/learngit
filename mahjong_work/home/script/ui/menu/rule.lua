local modUIUtil = import("ui/common/util.lua")
local modWndList = import("ui/common/list.lua")
local modUtil = import("util/util.lua")
local modBattleMgr = import("logic/battle/main.lua")

pRule = pRule or class(pWindow, pSingleton)

pRule.init = function(self)
	self:load("data/ui/ruleinfo.lua")
	self.controls = {}
	self:setParent(gWorld:getUIRoot())
	self.infos = {}
	self.wnd_name_bg:setPosition(gGameWidth * 0,95, 0)
	self.wnd_name_bg:setOffsetY(-gGameHeight * 0.01)
	if modUtil.getOpChannel() == "qs_pinghe" then		
		self.wnd_name_bg:setText("平和本地玩法")
	else
		self.wnd_name_bg:setText("转转麻将玩法规则")
	end
	self.wnd_name_bg:show(false)
	modUIUtil.makeModelWindow(self, false, true)
	self:setRenderLayer(C_MAX_RL)
	self:setZ(C_MAX_Z)
	modUIUtil.setClosePos(self.btn_return)
	self.btn_return:addListener("ec_mouse_click",function() self:close()  end)

	local webp = self.wnd_list_2
	webp:setPosition(webp:getX(), self.wnd_name_bg:getY())
	webwindow = pWebWindow()
	webwindow:setParent(webp)
	webwindow:setWorldSize(gGameWidth, gGameHeight)
	webwindow:setSize(webp:getWidth(), webp:getHeight())
	webwindow:setPosition(0, 0)
	self.webwindow = webwindow
	self.webwindow:show(true)
end


pRule.showWeb = function(self)
	if self.webwindow then
		self.webwindow:show(true)
		local url = modUIUtil.getRuleLink(modUtil.getOpChannel())
		logv("error",url)
		self.webwindow:loadUrl(url)
	end
	self:show(true)
end

pRule.close = function(self)
	if self.webwindow then
		self.webwindow:show(false)
	end
	self:show(false)
end
