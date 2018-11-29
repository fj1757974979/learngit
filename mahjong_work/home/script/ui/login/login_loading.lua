local modEasing = import("common/easing.lua")
local modEvent = import("common/event.lua")
local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")

local hasChannelRes = {
	tj_lexian = true,
	ds_queyue = true,
	za_queyue = true,
	jz_laiba = true,
	yy_doudou = true,
	ly_youwen = true,
	xy_hanshui = true,
	rc_xianle = true,
	test = true,
	nc_tianjiuwang = true,
	qs_pinghe = true,
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

pLoginLoadingPanel = pLoginLoadingPanel or class(pWindow, pSingleton)

pLoginLoadingPanel.init = function(self)
	self:load("data/ui/update.lua")
	self:setParent(gWorld:getUIRoot())
	logv("warn",modUIUtil.getChannelRes("login_bg.jpg"))
	-- self.wnd_background:setImage(modUIUtil.getChannelRes("login_bg.jpg"))
	logv("warn",getChannelRes("login_bg.jpg"))
	self.wnd_background:setImage(getChannelRes("login_bg.jpg"))
	self:show(false)
	self:setZ(-20000)
	self:setRenderLayer(3)

	self.initHdr = modEvent.handleEvent("INIT_DONE", function()
		if not self.running then
			self:close()
		else
			self.canClose = true
		end
	end)

	self:addListener("ec_mouse_click", function(e)
		if self.retryFlag then
			self.retryFlag = false
			local modUpdate = import("init/update.lua")
			modUpdate.autoUpdate()
		end
	end)

	adjustSize(self.wnd_background, gGameWidth, gGameHeight)
end

pLoginLoadingPanel.setRetryFlag = function(self, flag)
	self.retryFlag = flag
end

pLoginLoadingPanel.startAnimation = function(self)
	self:show(true)
	self.progress:setPercent(0)
	self.started = true
	self.running = true

	self.hdr = runProcess(1, function()
		if self.canClose then
			self:close()
		else
			self.running = false
		end
	end)
end

pLoginLoadingPanel.setProgress = function(self, percent)
	if self.progressHdr then
		self.progressHdr:stop()
		self.progressHdr = nil
	end
	self.progressHdr = runProcess(1, function()
		local t = 30
		local f = self.progress:getPercent()
		local d = percent - f
		for i = 1, t do
			local nf = modEasing.linear(i, f, d, t)
			self.progress:setPercent(nf)
			yield()
		end
	end)
end

pLoginLoadingPanel.setHint = function(self, txt, isErr)
	if isErr then
		self.hint:getTextControl():setColor(0xFFFF0000)
	else
		self.hint:getTextControl():setColor(0xFFFFFFFF)
	end
	self.hint:setText(TEXT(txt))
end

pLoginLoadingPanel.close = function(self)
	self.doCloseFlg = true
	self:setHint(TEXT(105))
	self.hint:getTextControl():setColor(0xFF00FF00)
	setTimeout(15, function()
		self:doClose()
	end)
end

pLoginLoadingPanel.doClose = function(self)
	runProcess(1, function()
		for i=1,5 do yield() end
		for i=255,0, -10 do
			self:setAlpha(i)
			for _,child in pairs(self) do
				if is_type_of(child, pObject) then
					child:setAlpha(i)
					if child.getTextControl then
						child:getTextControl():setAlpha(i)
					end
				end
			end
			yield()
		end
		self:hide()
	end)
end

pLoginLoadingPanel.hide = function(self)
	self.started = false

	if self.runForever then
		self.runForever:stop()
		self.runForever = nil
	end

	if self.hdr then
		self.hdr:stop()
		self.hdr = nil
	end

	if self.txtHdr then
		self.txtHdr:stop()
		self.txtHdr = nil
	end

	pLoginLoadingPanel:cleanInstance(self)
end

pLoginLoadingPanel.setCurrentVersion = function(self, version)
	if not version then
		self.txt_current_version:show(false)
	else
		self.txt_current_version:show(true)
		self.txt_current_version:setText(sf(TEXT(159), version))
	end
end

pLoginLoadingPanel.setNewestVersion = function(self, version)
	if not version then
		self.txt_newest_version:show(false)
	else
		self.txt_newest_version:show(true)
		self.txt_newest_version:setText(sf(TEXT(160), version))
	end
end
