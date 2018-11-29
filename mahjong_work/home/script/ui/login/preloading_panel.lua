local modUtil = import("util/util.lua")

local gPreloadingPanel = nil

local hasChannelRes = {
	tj_lexian = true,
	ds_queyue = true,
	za_queyue = true,
	jz_laiba = true,
	yy_doudou = true,
	ly_youwen = true,
	xy_hanshui = true,
	rc_xianle = true,
	nc_tianjiuwang = true,
	qs_pinghe = true,
	test = true,
}

getChannelRes = function(name)
	local opChannel = modUtil.getOpChannel()
	if hasChannelRes[opChannel] then
		local path = "ui:channel_res/" .. modUtil.getOpChannel() .. "/" .. name
		if app:getIOServer():fileExist(path) then
			return path
		else
			return "ui:" .. name
		end
	else
		local path = "ui:" .. name
		if app:getIOServer():fileExist(path) then
			return path
		else
			return nil
		end
	end
end

adjustSize = function(wnd, tw, th)
	local w, h = wnd:getWidth(), wnd:getHeight()
	local diffx = tw - w
	local diffy = th - h
	if diffx > diffy then
		local nw = w + diffx
		local nh = h + diffx * h/w
		wnd:setSize(nw, nh)
	else
		local nh = h + diffy
		local nw = w + diffy * w/h
		wnd:setSize(nw, nh)
	end
end

pPreloadingPanel = pPreloadingPanel or class(pWindow)

pPreloadingPanel.init = function(self)
	self:load("data/ui/preload.lua")
	self:setParent(gWorld:getUIRoot())
	self:show(false)
	self:setZ(-200)
	self.wnd_background:setImage(getChannelRes("login_bg.jpg"))

	adjustSize(self, gGameWidth, gGameHeight)
end

pPreloadingPanel.setAllAlpha = function(self, a)
	self:setAlpha(a)
end

pPreloadingPanel.open = function(self)
	self:setParent(gWorld:getUIRoot())
	self:setAllAlpha(0xFF)
	self:show(true)
end

pPreloadingPanel.setTips = function(self, tips)
	local modMsgBox = import("common/ui/msgbox.lua")
	if not self.msgBox then
		self.msgBox = modMsgBox.showLoadingBox(tips, true)
	end
	if tips then
		self.msgBox:setMsg(tips)
	else
		self.msgBox:setParent(nil)
		self.msgBox = nil
	end
end

pPreloadingPanel.close = function(self)
	if self.msgBox then
		self.msgBox:setParent(nil)
		self.msgBox = nil
	end
	self:setParent(nil)
	if gPreloadingPanel then
		gPreloadingPanel = nil
	end
end

pPreloadingPanel.instance = function(cls)
	if not gPreloadingPanel then
		gPreloadingPanel = cls:new()
	end
	return gPreloadingPanel
end

---------------------------------------------------------

getPreloadPanel = function()
	return pPreloadingPanel:instance()
end

