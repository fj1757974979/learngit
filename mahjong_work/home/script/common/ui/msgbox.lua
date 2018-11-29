local modEasing = import("common/easing.lua")

gMsgId = 0

local msgToId = {}
local idToWnd = {}

local genMsgId = function()
	gMsgId = gMsgId + 1
	return gMsgId
end

local curMsgId = function()
	return gMsgId
end

local w, h = 444, 55

showMessage = function(message, fontSize, bold, timeout, noImg)
	--[[
	if msgToId[message] then
		return
	end
	]]--

	-- 所有窗口向上移动
	for _, wnd in pairs(idToWnd) do
		local curOffsetY = wnd:getOffsetY()
		local h = wnd:getHeight()
		wnd:setOffsetY(curOffsetY - h)
	end

	local msgId = genMsgId()
	local wnd = pWindow()
	wnd:setRenderLayer(4)
	wnd:enableEvent(false)
	wnd.id = msgId
	wnd.msg = message
	msgToId[message] = msgId
	idToWnd[msgId] = wnd

	wnd:setParent(gWorld:getUIRoot())
	wnd:setRenderLayer(C_MAX_RL)
	wnd:setZ(C_MAX_Z)
	wnd:setSize(w, h)
	wnd:setText(message)
	local th = wnd:getTextControl():getHeight()
	wnd:setSize(w, math.max(th, 100))
	--wnd:setColor(0x7700ff00)
	--wnd:setColor(0x76000000)
	wnd:setColor(0xFFFFFFFFF)
	wnd:setImage("ui:messagebox.png")
	wnd:getTextControl():setColor(0xFFFFFFFF)
	--wnd:getTextControl():setStrokeColor(0xFFFFFFFF)
	wnd:getTextControl():setShadowColor(0xFF000000)
	wnd:getTextControl():setEdgeDistance(20)
	wnd:setFont("Heiti", fontSize or 30, bold or 2)
	if noImg then
		wnd:showSelf(false)
	end
	--wnd:getTextControl():setShadowColor(0xFFFFFFFF)
	wnd:setXSplit(true)
	wnd:setYSplit(true)
	wnd:setSplitSize(50)
	wnd:setPosition(gGameWidth/2 - w/2, gGameHeight/2 - h/2)
	wnd.destroy = function(self)
		runProcess(1, function()
			local t = 15
			for i = 1, t do
				local a = modEasing.linear(i, 76, -76, t)
				self:setAlphaRecursion(a)
				yield()
			end
			local msg = self.msg
			local id = self.id
			msgToId[msg] = nil
			idToWnd[id] = nil
			wnd:setParent(nil)
		end)
	end

	timeout = timeout or 90
	if timeout > 0 then
		setTimeout(timeout, function()
			wnd:destroy()
		end)
	end
	return wnd
end


showLoadingBox = function(message, apparent, noDelay, host)
	local wnd = pWindow()
	-- wnd:load("data/ui/loading_msg_box.lua")
	wnd:load("data/ui/loading_box.lua")
	wnd:setParent(gWorld:getUIRoot())
	wnd:setZ(C_MAX_Z)
	wnd:setRenderLayer(C_MAX_RL)
	-- wnd:setColor(0xFFFFFFFF)
	wnd:setColor(0x0)
	--wnd:getTextControl():setColor(0xFFFFFFFF)
	wnd:setPosition(gGameWidth/2 - w/2, gGameHeight/2 - h/2)
	local modUtil = import("util/util.lua")
	modUtil.makeModelWindow(wnd, apparent)

	if not noDelay then
		wnd:show(false)
	end

	local rotX, rotY = wnd.wnd_rot:getX(), wnd.wnd_rot:getY()
	local rotW, rotH = wnd.wnd_rot:getWidth(), wnd.wnd_rot:getHeight()
	wnd.wnd_rot:setKeyPoint(rotW/2, rotH/2)
	-- wnd.wnd_rot:setOffsetX(rotW/2)
	-- wnd.wnd_rot:setOffsetY(rotH/2)
	wnd.wnd_rot:setPosition(rotX + rotW/2, rotY + rotH/2)

	wnd.startRot = function(self)
		self:stopRot()
		self.rotHdr = runProcess(1, function()
			local scale = 0.4
			local base = 0.5
			local init = 0.01
			local i = init
			while true do
				local old = self.wnd_rot:getRot()
				local new = old + math.pi/30
				self.wnd_rot:setRot(0, 0, new)
				-- local s = base + i
				-- self.wnd_rot:setScale(s, s)
				i = i + init
				if i > base + scale then
					init = -math.abs(init)
				elseif i < base then
					init = math.abs(init)
				end
				yield()
			end
		end):update()
	end

	wnd.stopRot = function(self)
		if self.rotHdr then
			self.rotHdr:stop()
			self.rotHdr = nil
		end
	end

	wnd.open = function(self)
		if not noDelay then
			self:showChild(true)
			self:showSelf(false)
			self.wnd_rot:show(false)
			-- self.wnd_cloud:show(false)
			self.wnd_txt:show(false)
			self.wnd_di:show(false)
			if wnd._showTimeout then
				wnd._showTimeout:stop()
			end
			wnd._showTimeout = setTimeout(15, function()
				self:showSelf(true)
				self.wnd_rot:show(true)
				-- self.wnd_cloud:show(true)
				self.wnd_txt:show(true)
				self.wnd_di:show(true)
				wnd._showTimeout = nil
			end)
		else
			self:show(true)
		end
		self:startRot()
	end

	wnd.close = function(self)
		self:stopRot()
		if wnd._showTimeout then
			wnd._showTimeout:stop()
			wnd._showTimeout = nil
		end
		self:show(false)
	end

	wnd.setMsg = function(self, msg)
		self.wnd_txt:setText(msg)
		local tw = self.wnd_txt:getTextControl():getWidth()
		local ww = 50
		self.wnd_rot:setOffsetX(-tw + ww/2)
		self.wnd_txt:getTextControl():setOffsetX(ww/2)
	end

	wnd:setMsg(message)
	wnd:open()

	wnd.oldSetParent = wnd.oldSetParent or wnd.setParent
	wnd.setParent = function(self, parent)
		if parent == nil then
			self:close()
		end
		self:oldSetParent(parent)
		if host then
			host:onDelWnd(self)
		end
	end

	return wnd
end

pLoadingBox = pLoadingBox or class(pSingleton)

pLoadingBox.init = function(self)
	self.stack = new_weak_table()
end

pLoadingBox.showLoadingBox = function(self, msg, noDelay)
	local wnd = showLoadingBox(msg, true, noDelay, self)
	if #self.stack > 0 then
		self.stack[#self.stack]:show(false)
	end
	table.insert(self.stack, wnd)
	return wnd
end

pLoadingBox.onDelWnd = function(self, wnd)
	table.remove(self.stack, #self.stack)
	if #self.stack > 0 then
		self.stack[#self.stack]:show(true)
	end
end

