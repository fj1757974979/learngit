local modEasing = import("common/easing.lua")
local modUtil = import("util/util.lua")

pWndContainer = pWndContainer or class()

pWndContainer.init = function(self, wnd, list)
	self.wnd = wnd
	self.list = list
	self.idx = idx
	wnd:setParent(list.dragWnd)
	wnd:setAlignX(ALIGN_LEFT)
	wnd:setAlignY(ALIGN_TOP)
	wnd:setOffsetX(0)
	wnd:setOffsetY(0)
	wnd.__container_idx = idx
end

pWndContainer.getIdx = function(self)
	return self.idx
end

pWndContainer.setIdx = function(self, idx)
	self.idx = idx
	self.wnd.__container_idx = idx
end

pWndContainer.setPosition = function(self, x, y)
	self.wnd:setPosition(x, y)
end

pWndContainer.enableEvent = function(self, flag)
	self.wnd:enableEvent(flag)
end

pWndContainer.getSize = function(self)
	return self.wnd:getWidth(), self.wnd:getHeight()
end

pWndContainer.setSize = function(self, w, h)
	self.wnd:setSize(w, h)
end

pWndContainer.setKeyPoint = function(self, kx, ky)
	self.wnd:setKeyPoint(kx, ky)
end

pWndContainer.getX = function(self)
	return self.wnd:getX()
end

pWndContainer.getY = function(self)
	return self.wnd:getY()
end

pWndContainer.destroy = function(self)
	if self.wnd.destroy then
		self.wnd:destroy()
	end
	self.wnd:setParent(nil)
	self.wnd = nil
	self.list = nil
end

pWndContainer.addListener = function(self, event, callback)
	elf.wnd:addListener(event, function(e)
		if callback then
			callback(e)
		end
	end)
end

pWndContainer.getWnd = function(self)
	return self.wnd
end

------------------------------------------------------

pWndList = pWndList or class(pWindow)

pWndList.init = function(self, w, h, lineCnt, xgap, ygap, t)
	self:setColor(0)
	self:setClipDraw(true)
	self:setSize(w, h)
	self.width = w
	self.height = h
	self.lineCnt = lineCnt
	self.rcursor = 1
	self.ccursor = 1
	self.curMaxW = 0
	self.curMaxH = 0
	self.xcursor = 0
	self.ycursor = 0
	self.xgap = xgap
	self.ygap = ygap
	self.unitW = (w - (lineCnt - 1) * xgap) / lineCnt
	self.unitH = (h - (lineCnt - 1) * ygap) / lineCnt
	self.t = t or T_DRAG_LIST_VERTICAL
	self.dragWnd = pWindow:new()
	self.dragWnd:setParent(self)
	--self.dragWnd:setColor(0xFFFF0000)
	self.dragWnd:setColor(0)
	self.dragWnd:setPosition(0, 0)
	self.containers = {}
	self:regEvent()
	self.curChosenWnd = nil
	self.sortFunc = nil
end

pWndList.getWndCnt = function(self)
	return table.size(self.containers)
end

pWndList.setEqualHWMode = function(self)
	self.equalHWmode = true
end

pWndList.setSortFunc = function(self, func)
	self.sortFunc = func
end

pWndList.__mutextChoose = function(self, container)
end

pWndList.setMutextChooseMode = function(self, chosenImg)
end

pWndList.setMultiChooseMode = function(self, chosenImg, cnt)
end

pWndList.calcHashIdx = function(self, row, col)
	if not row then
		row = self.rcursor
	end
	if not col then
		col = self.ccursor
	end
	if self.t == T_DRAG_LIST_VERTICAL then
		return row * 1000 + col
	else
		return col * 1000 + row
	end
end

pWndList.getCoordByIdx = function(self, idx)
	if self.t == T_DRAG_LIST_VERTICAL then
		return math.floor(idx / 1000), idx % 1000
	else
		return idx % 1000, math.floor(idx / 1000)
	end
end

pWndList.addWnd = function(self, wnd)
	local container = pWndContainer:new(wnd, self)
	local w, h = container:getSize()
	if self.t == T_DRAG_LIST_VERTICAL then
		w = self.unitW
		if self.equalHWmode then
			h = w
		end
		if self.ccursor > self.lineCnt then
			self.xcursor = 0
			self.ycursor = self.ycursor + self.curMaxH + self.ygap
			self.rcursor = self.rcursor + 1
			self.ccursor = 1
			self.curMaxH = 0
		end
		local kx, ky = w/2, h/2
		container:setPosition(self.xcursor + kx, self.ycursor + ky)
		container:setIdx(self:calcHashIdx())
		self.ccursor = self.ccursor + 1
		self.xcursor = self.xcursor + w + self.xgap
		if self.curMaxH < h then
			self.curMaxH = h
		end
		local dragH = self.ycursor + self.curMaxH
		self.dragWnd:setSize(self.width, dragH)
		self.minPos = self.height - dragH
		if self.minPos > 0 then
			self.minPos = 0
		end
	else
		h = self.unitH
		if self.equalHWmode then
			w = h
		end
		if self.rcursor > self.lineCnt then
			self.xcursor = self.xcursor + self.curMaxW + self.xgap
			self.ycursor = 0
			self.rcursor = 1
			self.ccursor = self.ccursor + 1
			self.curMaxW = 0
		end
		local kx, ky = w/2, h/2
		container:setPosition(self.xcursor + kx, self.ycursor + ky)
		container:setIdx(self:calcHashIdx())
		self.rcursor = self.rcursor + 1
		self.ycursor = self.ycursor + h + self.ygap
		if self.curMaxW < w then
			self.curMaxW = w
		end
		local dragW = self.xcursor + self.curMaxW
		self.dragWnd:setSize(dragW, self.height)
		self.minPos = self.width - dragW
		if self.minPos > 0 then
			self.minPos = 0
		end
	end
	container:setKeyPoint(w/2, h/2)
	self.containers[container:getIdx()] = container
	container:setSize(w, h)
end

pWndList.delWnd = function(self, wnd, animation)
	local idx = wnd.__container_idx
	local row, col = self:getCoordByIdx(idx)
	local getPrevIdx = function(idx)
		local row, col = self:getCoordByIdx(idx)
		if self.t == T_DRAG_LIST_VERTICAL then
			col = col - 1
			if col < 1 then
				col = self.lineCnt
				row = row - 1
			end
		else
			row = row - 1
			if row < 1 then
				row = self.lineCnt
				col = col - 1
			end
		end
		local ret = self:calcHashIdx(row, col)
		return ret
	end
	local getNextIdx = function(idx)
		local row, col = self:getCoordByIdx(idx)
		if self.t == T_DRAG_LIST_VERTICAL then
			col = col + 1
			if col > self.lineCnt then
				col = 1
				row = row + 1
			end
		else
			row = row + 1
			if row > self.lineCnt then
				row = 1
				col = col + 1
			end
		end
		local ret = self:calcHashIdx(row, col)
		--log("info", idx, "--->", ret)
		return ret
	end
	local container = self.containers[idx]
	if not container then
		return
	end
	-- 重排列
	local prev = container
	-- 删除的窗口之后的每个窗口的位置
	local positions = {}
	while true do
		local nidx = getNextIdx(prev:getIdx())
		local ncontainer = self.containers[nidx]
		if not ncontainer then
			break
		end
		positions[nidx] = {prev:getX(), prev:getY()}
		prev = ncontainer
	end
	container:destroy()
	self.containers[idx] = nil
	if animation then
		local maxIdx = -1
		local movePos = {}
		for idx, pos in modUtil.iterateNumKeyTable(positions) do
			local prevIdx = getPrevIdx(idx)
			local container = self.containers[idx]
			container:setIdx(prevIdx)
			container.__f_pos = {container:getX(), container:getY()}
			container.__t_pos = pos
			self.containers[prevIdx] = container
			table.insert(movePos, prevIdx)
			if maxIdx < idx then
				maxIdx = idx
			end
		end
		self.containers[maxIdx] = nil
		if self.__arrange_hdr then
			self.__arrange_hdr:stop()
			self.__arrange_hdr = nil
		end
		self.dragWnd:enableEvent(false)
		self.__arrange_hdr = runProcess(1, function()
			local t = 5
			for i = 1, t do
				for _, idx in ipairs(movePos) do
					local container = self.containers[idx]
					local x = modEasing.linear(i, container.__f_pos[1], container.__t_pos[1] - container.__f_pos[1], t)
					local y = modEasing.linear(i, container.__f_pos[2], container.__t_pos[2] - container.__f_pos[2], t)
					container:setPosition(x, y)
				end
				yield()
			end
			for _, idx in ipairs(movePos) do
				local container = self.containers[idx]
				container.__f_pos = nil
				container.__t_pos = nil
			end
			self.dragWnd:enableEvent(true)
		end)
	else
		local maxIdx = -1
		for idx, pos in modUtil.iterateNumKeyTable(positions) do
			local prevIdx = getPrevIdx(idx)
			local container = self.containers[idx]
			container:setPosition(pos[1], pos[2])
			container:setIdx(prevIdx)
			self.containers[prevIdx] = container
			if maxIdx < idx then
				maxIdx = idx
			end
		end
		self.containers[maxIdx] = nil
	end
	-- 更新dragWnd大小
	-- TODO 非equalHW的模式
	if self.t == T_DRAG_LIST_VERTICAL then
		self.ccursor = self.ccursor - 1
		if self.ccursor < 1 then
			self.ccursor = self.lineCnt
			self.rcursor = self.rcursor - 1
		end
		self.xcursor = self.xcursor - self.xgap - self.unitW
		if self.xcursor < 0 then
			self.xcursor = self.width - self.unitW
			self.ycursor = self.ycursor - self.ygap - self.curMaxH
		end
		local dragH = self.ycursor + self.curMaxH
		if self.xcursor <= 0 then
			dragH = self.ycursor - self.ygap
		end
		self.dragWnd:setSize(self.width, dragH)
		self.minPos = self.height - dragH
		if self.minPos > 0 then
			self.minPos = 0
		end
		--log("info", self.xcursor, self.ycursor, self.minPos, dragH)
	else
		self.rcursor = self.rcursor - 1
		if self.rcursor < 1 then
			self.rcursor = self.lineCnt
			self.ccursor = self.ccursor - 1
		end
		local dragW = self.xcursor + self.curMaxW
		if self.ycursor <= 0 then
			dragW = self.xcursor - self.xgap
		end
		self.dragWnd:setSize(dragW, self.height)
		self.minPos = self.width - dragW
		if self.minPos > 0 then
			self.minPos = 0
		end
	end
end

pWndList.getWnd = function(self, row, col)
	local idx = self:calcHashIdx(row, col)
	if self.containers[idx] then
		return self.containers[idx]:getWnd()
	else
		return nil
	end
end

pWndList.addWnds = function(self, wnds)
	for _, wnd in ipairs(wnds) do
		self:addWnd(wnd)
	end
end

pWndList.regEvent = function(self)
	self.dragWnd:addListener("ec_mouse_left_down", function(e)
		self:onLeftDown(e)
	end)

	self.dragWnd:addListener("ec_mouse_drag", function(e)
		self:onDrag(e:dx(), e:dy())
	end)

	self.dragWnd:addListener("ec_mouse_left_up", function(e)
		self:onLeftUp(e)
	end)
end

pWndList.getPos = function(self)
	local pos = nil
	if self.t == T_DRAG_LIST_VERTICAL then
		pos = self.dragWnd:getY()
	else
		pos = self.dragWnd:getX()
	end
	return pos
end

pWndList.setPos = function(self, pos, easingFlag)
	pos = math.max(pos, self.minPos)
	if not easingFlag then
		if self.t == T_DRAG_LIST_VERTICAL then
			self.dragWnd:setPosition(0, math.max(pos, self.minPos))
		else
			self.dragWnd:setPosition(math.max(pos, self.minPos), 0)
		end
	else
		self.dragWnd:enableEvent(false)
		self.__set_pos_hdr = runProcess(1, function()
			local t = 20
			local fpos = self:getPos()
			for i = 1, t do
				local p = modEasing.linear(i, fpos, pos - fpos, t)
				self:setPos(p)
				yield()
			end
			self.__set_pos_hdr = nil
			self.dragWnd:enableEvent(true)
		end)
	end
end

pWndList.onLeftDown = function(self, e)
	if not self.dragWnd then
		return
	end
	self.speed = nil
	self:stopAllMoveProcess()
end

pWndList.onLeftUp = function(self, e)
	if not self.dragWnd then
		return
	end
	self:stopAllMoveProcess()
	local pos = self:getPos()
	if pos > 0 or pos < self.minPos or not self.speed then
		self:rollback()
		return
	end
	local speed = self.speed
	self.speed = nil
	local maxSpeed = 100
	speed = math.max(math.min(speed, maxSpeed), - maxSpeed)
	local sign = 1
	if speed < 0 then sign = -1 end
	local acc = (speed * speed * 1 / 1000 + 1) * sign

	self.inertiaHdr = setInterval(1, function()
		local pos = self:getPos()
		local _acc = 0
		if pos > 0 then
			_acc = (pos - self.minPos) * 0.1 * sign
		elseif pos < self.minPos then
			_acc = (self.minPos - pos) * 0.1 * sign
		end
		pos = pos + speed
		speed = speed - acc - _acc
		self:setPos(pos)
		if sign * speed <= 2 then
			self.inertiaHdr:stop()
			self.inertiaHdr = nil
			self:rollback()
		end
	end)
end

pWndList.onDrag = function(self, dx, dy)
	if not self.dragWnd then
		return
	end
	local pos = nil
	if self.t == T_DRAG_LIST_VERTICAL then
		self.speed = dy
		pos = self.dragWnd:getY()
	else
		self.speed = dx
		pos = self.dragWnd:getX()
	end
	local dpos = self.speed
	if pos > 0 or pos < self.minPos then
		dpos = dpos / 3
	end
	if self.t == T_DRAG_LIST_VERTICAL then
		self.dragWnd:setPosition(0, pos + dpos)
	else
		self.dragWnd:setPosition(pos + dpos, 0)
	end
end

pWndList.rollback = function(self)
	if not self.dragWnd then
		return
	end
	self:stopAllMoveProcess()
	self.rollbackHdr = runProcess(1, function()
		local duration = 5
		local fpos = self:getPos()
		local c = 0
		if fpos > 0 then
			c = -fpos
		elseif fpos < self.minPos then
			c = self.minPos - fpos
		end
		for i = 1, duration do
			local pos = modEasing.outQuad(i, fpos, c, duration)
			if fpos > 0 and pos < 0 then
				self:setPos(0)
				break
			elseif fpos < self.minPos and pos > self.minPos then
				self:setPos(self.minPos)
				break
			else
				self:setPos(pos)
			end
			yield()
		end
		self.rollbackHdr = nil
	end)
end

pWndList.rollToPos = function(self, pos)
	if not self.dragWnd then
		return
	end
	self:stopAllMoveProcess()
	self.rollToPosHdr = runProcess(1, function()
		local t = 20
		local fpos = self:getPos()
		local c = pos - fpos
		for i = 1, t do
			local p = modEasing.outQuint(i, fpos, c, t)
			self:setPos(p)
			yield()
		end
		self.rollToPosHdr = nil
	end)
end

pWndList.rollToTop = function(self)
	self:rollToPos(0)
end

pWndList.rollToBottom = function(self)
	self:rollToPos(self.minPos)
end

pWndList.stopAllMoveProcess = function(self)
	if self.rollToPosHdr then
		self.rollToPosHdr:stop()
		self.rollToPosHdr = nil
	end
	if self.rollbackHdr then
		self.rollbackHdr:stop()
		self.rollbackHdr = nil
	end
	if self.inertiaHdr then
		self.inertiaHdr:stop()
		self.inertiaHdr = nil
	end
end

pWndList.destroy = function(self)
	self:stopAllMoveProcess()
	if self.__set_pos_hdr then
		self.__set_pos_hdr:stop()
		self.__set_pos_hdr = nil
	end
	for _, container in pairs(self.containers) do
		container:destroy()
	end
	self.containers = {}
	self.dragWnd:setParent(nil)
	self.dragWnd = nil
	self:setParent(nil)
end
