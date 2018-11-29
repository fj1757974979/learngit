local modMsg = import("common/ui/msgbox.lua")
local modEasing = import("common/easing.lua")
local modEvent = import("common/event.lua")

getBox = function(obj)
	local x,y = obj:getPos()
	return {x - obj.width/2, y - obj.height/2,
		x + obj.width/2, y + obj.height/2}
end

isIn = function(point, box)
	return point[1] >= box[1] and point[1] <= box[3]
		and point[2] >= box[2] and point[2] <= box[4]
end

isCover = function(box1, box2)
	return isIn({box1[1], box1[2]}, box2) or isIn({box1[1], box1[4]}, box2) or isIn({box1[3], box1[2]}, box2) or isIn({box1[3], box1[4]}, box2)
end

distance = function(src, dest)
	if not src or not dest then
		return 99999999999
	end
	local dx = src[1] - dest[1]
	local dy = src[2] - dest[2]
	return math.sqrt(dx*dx + dy*dy)
end

objDistance = function(obj1, obj2)
	return distance({obj1:getX(), obj1:getY()},
			{obj2:getX(), obj2:getY()})
end

PI = 3.1415
getRot = function(src, dest)
	local x1,y1 = src[1], src[2]
	local x2,y2 = dest[1], dest[2]

	return atanEx(x2-x1, y2-y1)
end

isInDistance = function(obj1, obj2, dis)
	local x1,y1 = obj1:getX(), obj1:getY()
	local x2,y2 = obj2:getX(), obj2:getY()
	return distance({x1,y1}, {x2,y2}) <= dis + 10
end

createShape = function(width, height, color)
	local shape = puppy.gui.pWindow:new()
	shape:setSize(width,height)
	shape:setColor(color)
	shape:setPosition(-width/2,-height/2)
	return shape
end

adjustObjFlyDir = function(obj, fromPos, toPos)
	local angle = atanEx(toPos[1] - fromPos[1], toPos[2] - fromPos[2])
	local r = angle
	obj:setRot(0, 0, r)
end

local DIR_LEFT = -1
local DIR_RIGHT = 1

local getCharDir = function(char)
	if char.getDirIndex then
		local indx = char:getDirIndex()
		if indx and indx <= 3 then
			return DIR_LEFT
		else
			return DIR_RIGHT
		end
	else
		return DIR_LEFT
	end
end

playEffect = function(self, path, x, y, times, keep, z)
	x = x or 0
	y = y or 0
	z = z or 0
	times = times or 1
	local effect = pSprite()
	effect:setTexture(path, 0)
	effect:setParent(self)
	effect:setPosition(x, y)
	effect:setZ(z)
	if keep then
		effect:play(times, false)
	else
		effect:play(times, true)
	end
	--[[
	local sx = effect:getSX()
	local sy = effect:getSY()
	if self.getArmatureDisplay then
		local display = self:getArmatureDisplay()
		if display and display:getSX() < 0 then
			sx = -sx
		end
	end
	effect:setScale(sx, sy)
	]]--
	return effect
end

stopEffect = function(self, effect)
	if effect then
		effect:setParent(nil)
	end
end

local playerID = 1000
newPlayerID = function()
	playerID = playerID + 1
	return playerID
end

deepCopy = function(obj)
	if type(obj) ~= "table" then
		return obj
	end
	local newObj = {}
	for k, v in pairs(obj) do
		newObj[deepCopy(k)] = deepCopy(v)
	end
	--return setmetatable(newObj, deepCopy(getmetatable(obj)))
	return newObj
end

infoMessage = function(msg, fontSize, bold, timeout, noImg)
	if msg then
		return modMsg.showMessage(msg, fontSize, bold, timeout, noImg)
	end
	return nil
end

loadingMessage = function(msg, noDelay)
	return modMsg.pLoadingBox:instance():showLoadingBox(TEXT(msg), noDelay)
end

pointInRect = function(p, topLeftP, botRightP)
	if p[1] > topLeftP[1] then
		if p[1] < botRightP[1] then
			if p[2] > topLeftP[2] then
				if p[2] < botRightP[2] then
					return true
				end
			end
		end
	end
	return false
end

isRectInRect = function(rect1,rect2)
	local w1 = rect1.x + rect1.w
	local h1 = rect1.y + rect1.h
	local w2 = rect2.x + rect2.w
	local h2 = rect2.y + rect2.h
	if (rect1.x >= rect2.x and rect1.x <= w2) or (w1 >= rect2.x and w1 <= w2) then
		if (rect1.y >= rect2.y and rect1.y <= h2) or (h1 >= rect2.y and h1 <= h2) then
			return true
		end
	end
	return false
end

pointInEllipse = function(p, centerP, a, b)
	local x, y = p[1], p[2]
	local x0, y0 = centerP[1], centerP[2]
	local ellipse = function(x, y)
		local ret = ((x-x0)*(x-x0))/(a*a) + ((y-y0)*(y-y0))/(b*b)
		return ret < 1
	end

	return ellipse(x, y)
end

pointInCircle = function(p, centerP, r)
	local x, y = p[1], p[2]
	local x0, y0 = centerP[1], centerP[2]
	local circle = function(x, y)
		local ret = ((x-x0)*(x-x0)) + ((y-y0)*(y-y0))
		return ret < r*r
	end

	return circle(x, y)
end

-- slope 斜率
-- b y轴偏移
-- scope 直线上下的范围，非0
pointInLineScope = function(p, slope, b, scope)
	local x, y = p[1], p[2]
	local dy = y - slope * x - b
	return dy < scope and dy > -scope
end

interPointsOfLineEllipse = function(slope, lB, eP, eA, eB)
	--[[
	log("error", "slope", slope)
	local y = math.sqrt(1/(slope * slope / eA / eA + 1 / eB / eB))
	local x = y * slope
	do return {eP[1] + x, eP[2] + y}, {eP[1] - x, eP[2] - y} end
	]]--

	local eX, eY = eP[1], eP[2]
	local k = slope
	local a = eA*eA + eB*eB*k*k
	local b = 2*k*eB*eB*(lB-eY) - 2*eX*eA*eA
	local c = eA*eA*eX*eX + eB*eB*(lB-eY)*(lB-eY) - eA*eA*eB*eB

	local delta = b*b - 4*a*c
	-- 无交点
	if delta < 0 then return nil end

	local x1, x2, y1, y2
	if a == 0 then
		if b == 0 then return nil end
		x1 = -b/c
	else
		x1 = (-b + math.sqrt(delta))/(2*a)
		x2 = (-b - math.sqrt(delta))/(2*a)
	end

	y1 = k*x1 + lB
	if x2 then
		y2 = k*x2 + lB
	end

	if delta > 0 then
		return {x1, y1}, {x2, y2}
	else
		return {x1, y1}, nil
	end
end

-------
pFrameMgr = pFrameMgr or class(pSingleton)

pFrameMgr.init = function(self)
	self.framePerSec = 60
end

pFrameMgr.frameToSec = function(self, frame, noCeilFlag)
	if noCeilFlag then
		return frame / self.framePerSec
	else
		return math.ceil(frame / self.framePerSec)
	end
end

pFrameMgr.secToFrame = function(self, sec)
	return math.ceil(sec * self.framePerSec)
end

pFrameMgr.getFrameRate = function(self)
	return self.framePerSec
end
-------

getFrameRate = function()
	return pFrameMgr:instance():getFrameRate()
end

frameToSec = function(frame, noCeilFlag)
	return pFrameMgr:instance():frameToSec(frame, noCeilFlag)
end

secToFrame = function(sec)
	return pFrameMgr:instance():secToFrame(sec)
end

s2f = secToFrame
f2s = frameToSec

local callLoad = function(wnd)
	local x, y = wnd:getX(), wnd:getY()
	local ox, oy = wnd:getOffsetX(), wnd:getOffsetY()
	local rx, ry = wnd:getRX(), wnd:getRY()
	local z = wnd:getZ()
	wnd:onLoadInView(wnd.__delay_show_flag)
	wnd:setPosition(x, y)
	wnd:setOffsetX(ox)
	wnd:setOffsetY(oy)
	wnd:setRX(rx)
	wnd:setRY(ry)
	wnd:setZ(z)
end

local checkInView = function(vx, vy, vw, vh, wnd)
	local w = wnd.__w
	local h = wnd.__h
	if not w or not h then
		if wnd.onLoadInView and not wnd.__loaded then
			callLoad(wnd)
			wnd.__loaded = true
		end
		return true
	end

	local xdiff = 100
	local ydiff = 0

	local x = wnd:getX(true)
	local y = wnd:getY(true)

	local ret = (x <= vx + vw + xdiff and x + w >= vx - xdiff
		and y <= vy + vh + ydiff and y + h >= vy - ydiff)
	--local ret = (y <= vy + vh + ydiff and y + h >= vy - ydiff)

	if ret then
		if wnd.onLoadInView and not wnd.__loaded then
			callLoad(wnd)
			wnd.__loaded = true
		end
	end

	return ret
end

makeDragChangePage = function(self,w,interval,func, wnds)
	local span = w + interval
	if not span then return end
    local dragWndStarX,dragWndStarY = self:getX(),self:getY()
	local curPage = 1
	local parent = showPageWnd or self
	local ratio = 4
	self.maxRight = self:getWidth() - self:getParent():getWidth()
	local showThisPagePic = function(page)
	end

	self.disableDrag = function(self, flg)
		self.__disable = flg
	end

	local stopMoveWnd = function()
		if self.wndMove then
			self.wndMove:stop()
			self.wndMove = nil
		end
	end

	local moveWnd = function(curPage,speed, silent)
		stopMoveWnd()
		if not curPage or curPage < 1 or curPage > self.maxPage then return end
		local moveTo = -( span * (curPage - 1 ))
		if not speed then
			if moveTo then
				dragWndStarX = moveTo
			end
			self:setPosition(dragWndStarX,dragWndStarY)
			showThisPagePic(curPage)
			if not silent and func then
				func(curPage,self.maxPage)
			end
			return
		end
		self.wndMove = runProcess(1,function()
			for i = 0 ,span ,math.abs(speed) do
				if speedX == 0 then break end
				dragWndStarX = dragWndStarX + speed

				if dragWndStarX > 0 then
					dragWndStarX = 0
					break
				elseif dragWndStarX < -(self.maxRight) then
					dragWndStarX = -(self.maxRight)
					break
				elseif speed < 0 and  dragWndStarX < moveTo or speed > 0 and dragWndStarX > moveTo  then
					dragWndStarX = moveTo
					break
				end
				self:setPosition(dragWndStarX,dragWndStarY)
				yield()
			end
			if moveTo then
				dragWndStarX = moveTo
			end
			self:setPosition(dragWndStarX,dragWndStarY)
			showThisPagePic(curPage)
			if not silent and func then
				func(curPage,self.maxPage)
			end

		end)
	end

	self.moveWnd = moveWnd

	local wndBack = function(curX,page)
		local speed = 0
		local backTo = -(span * (page - 1))
		if  backTo > curX then
			speed = 50
		elseif  backTo < curX then
			speed = - 50
		else
			speed = 0
		end
		if self.backMove then
			self.backMove:stop()
			self.backMove = nil
		end
		self.backMove  = runProcess(1,function()
			for i = curX , backTo ,speed do
				if speed == 0 then break end
				dragWndStarX = dragWndStarX + speed
				if speed < 0 and  dragWndStarX < backTo or speed > 0 and dragWndStarX > backTo  then
					dragWndStarX = backTo
					break
				end

				self:setPosition(dragWndStarX,dragWndStarY)
				yield()
			end
			dragWndStarX = backTo
			self:setPosition(dragWndStarX,dragWndStarY)
			showThisPagePic(page)
			if func then
				func(page,self.maxPage)
			end
		end)
	end

	self.isMoving = function(self)
		return self.speed ~= 0
	end

	showThisPagePic(1)
	self.gotoMaxPage = modEvent.handleEvent("GOTO_MAXPAGE",function()
		if curPage < self.maxPage then
			curPage = self.maxPage
			moveWnd(self.maxPage,span)
		end
	end)
	self.moveToPage = function(self, page, silent)
		if page >= 1 and page <= self.maxPage then
			if curPage ~= page then
				curPage = page
				moveWnd(curPage, span, silent)
			end
		end
	end
	self.event = modEvent.handleEvent("DRAGWND_TO_NEXTPAGE",function()
		if curPage + 1 <= self.maxPage then
			curPage = curPage + 1
			moveWnd(curPage ,-75)
		end
	end)

	local viewParent = self:getParent()

	local checkWndsInView = function()
		local vw, vh = viewParent:getWidth(), viewParent:getHeight()
		local vx, vy = viewParent:getX(true), viewParent:getY(true)
		for _, wnd in ipairs(wnds) do
			if not checkInView(vx, vy, vw, vh, wnd) then
				wnd:show(false)
			else
				wnd:show(true)
			end
		end
	end

	checkWndsInView()

	self.checkWndsInView = checkWndsInView


	self:addListener("ec_mouse_left_down",function(e)
		self.speedX = 0
		self.starX = dragWndStarX
		self.maxRight = self:getWidth() - self:getParent():getWidth()
		self.time = os.clock()
	end)

	self:addListener("ec_mouse_drag",function(e)
		if self.__disable then
			return
		end
		self.speedX = e:dx()
	    dragWndStarX = dragWndStarX + e:dx()
		if dragWndStarX > 0 and dragWndStarX > span/ratio then
			dragWndStarX = span /ratio
		elseif dragWndStarX < -(self.maxRight) and dragWndStarX < - (self.maxRight + span /ratio) then
			dragWndStarX = - (self.maxRight + span /ratio)
			modEvent.fireEvent("PAGE_LIST_RIGHT_MAX", self, e:dx())
		end
		self:setPosition(dragWndStarX ,dragWndStarY)

		checkWndsInView()
	end)

	self:addListener("ec_mouse_left_up",function(e)
		local speed = 50
		local dragWndW = self:getWidth()
		local leftMiddle = dragWndW * (curPage - 1 )/self.maxPage - span/2 < 0 and 0 or - (dragWndW *(curPage - 1)/self.maxPage - span/2)
		local rightMiddle = dragWndW * (curPage - 1)/self.maxPage + span/2 > dragWndW and - dragWndW or - (dragWndW * (curPage - 1)/self.maxPage + span/2)

		if self.starX > dragWndStarX and math.abs(self.starX - dragWndStarX) > span then
			curPage = curPage + 1 >= self.maxPage and self.maxPage or curPage +1
		elseif self.starX < dragWndStarX and math.abs(dragWndStarX - self.starX) > span then
			curPage = curPage - 1 <= 1 and 1 or curPage -  1
		end
		local oldPage = curPage

		local time = os.clock() - self.time
		if time >= 0.25 then
			if dragWndStarX > 0 or dragWndStarX < -(self.maxRight) then
				wndBack(dragWndStarX,oldPage)
			elseif dragWndStarX < rightMiddle then
				curPage = curPage + 1 > self.maxPage and self.maxPage or curPage + 1
				speed = - math.max(speed,math.abs(self.speedX))
				moveWnd(curPage,speed)
			elseif dragWndStarX > leftMiddle then
				curPage = curPage - 1 < 0 and 0 or curPage - 1
				speed = math.max(speed,self.speedX)
				moveWnd(curPage,speed)
			else
				wndBack(dragWndStarX,oldPage)
			end
		else

			if self.speedX < 0 then
				curPage = curPage +	1 > self.maxPage and self.maxPage or curPage + 1
				speed = - math.max(speed, math.abs(self.speedX))
			elseif self.speedX > 0 then
				curPage = curPage - 1 < 1 and 1 or curPage - 1
				speed = math.max(speed,self.speedX)
			else
				speed = 0
			end

			if dragWndStarX > 0 or dragWndStarX < - (self.maxRight) then
				wndBack(dragWndStarX,oldPage)
			else
				moveWnd(curPage,speed)
			end
		end
		modEvent.fireEvent("PAGE_LIST_LEFT_UP", self)
	end)

end

local installSliderBar = function(self, viewParent)
	self.initSliderBar = function(self)
		self:showSliderBar()
		if not self.__ban_slider_bar then
			self.__slider_bar:setAlpha(0)
			self.__slider:setAlpha(0)
		end
	end

	self.showSliderBar = function(self)
		if self.__ban_slider_bar then
			return
		end

		if self.__slider_bar then
			self.__slider_bar:show(true)
			return
		end

		local wndBtm = pWindow()
		wndBtm:setImage("ui:gj_slidebar_di.png")
		wndBtm:setParent(viewParent)
		wndBtm:setSize(2, viewParent:getHeight() - 20)
		wndBtm:setPosition(2, 5)

		self.__slider_bar = wndBtm

		local wndBar = pWindow()
		wndBar:setImage("ui:gj_slidebar_tiao.png")
		wndBar:setParent(wndBtm)
		wndBar:setAlignX(ALIGN_CENTER)
		wndBar:setPosition(0, 0)
		wndBar:setYSplit(true)
		wndBar:setSplitSize(15)
		wndBar:setSize(4, 41)

		self.__slider = wndBar

		self:adjSliderBar()
	end

	self.adjSliderBar = function(self)
		if not self.__slider_bar or self.__ban_slider_bar then
			return
		end
		self.posWndMinStartY = gGameHeight - self:getHeight()
		if self.minDiff then
			self.posWndMinStartY = self.posWndMinStartY - self.minDiff
		end
		if self.__slider_fadeout_timeout then
			self.__slider_fadeout_timeout:stop()
			self.__slider_fadeout_timeout = nil
		end
		-- 比例
		if not self.__slider.__maxH then
			local ph = viewParent:getHeight()
			local h = self:getHeight()
			local maxH = 0
			if ph >= h then
				maxH = self.__slider_bar:getHeight()
			else
				maxH = self.__slider_bar:getHeight() * ph / h
			end
			if maxH < 30 then
				maxH = 30
			end
			self.__slider:setSize(self.__slider:getWidth(), maxH)
			self.__slider.__maxH = maxH
		end
		-- 位置、大小
		local y = self:getY()
		local ySpace = self.__slider_bar:getHeight() - self.__slider.__maxH
		if y <= self.posWndDefStartY and y >= self.posWndMinStartY then
			self.__slider:setScale(1, 1)
			local rate = y / self.posWndMinStartY
			if self.posWndMinStartY == 0 then
				rate = 0
			end
			local y = ySpace * rate
			self.__slider:setPosition(self.__slider:getX(), y)
		else
			local diff = 0
			if y > self.posWndDefStartY then
				diff = y - self.posWndDefStartY
				self.__slider:setKeyPoint(0, 0)
				self.__slider:setOffsetY(0)
				self.__slider:setPosition(0, 0)
			elseif y < self.posWndMinStartY then
				diff = self.posWndMinStartY - y
				self.__slider:setKeyPoint(0, self.__slider.__maxH)
				self.__slider:setOffsetY(self.__slider.__maxH)
				self.__slider:setPosition(0, ySpace)
			end
			local h = self:getHeight()
			local scale = (h - diff) / h
			if scale < 0 then
				scale = 0
			end
			self.__slider:setScale(1, scale)
		end
	end

	self.hideSliderBar = function(self)
		if self.__slider_bar then
			self.__slider_bar:show(false)
		end
	end

	self.banSliderBar = function(self, flag)
		self.__ban_slider_bar = flag
		if self.__slider_fadeout_timeout then
			self.__slider_fadeout_timeout:stop()
			self.__slider_fadeout_timeout = nil
		end
		if self.__slider_fadein_hdr then
			self.__slider_fadein_hdr:stop()
			self.__slider_fadein_hdr = nil
		end
		if self.__slider_fadeout_hdr then
			self.__slider_fadeout_hdr:stop()
			self.__slider_fadeout_hdr = nil
		end
		if self.__slider_bar then
			self.__slider_bar:setParent(nil)
			self.__slider:setParent(nil)
			self.__slider_bar = nil
			self.__slider = nil
		end
	end

	self.fadeInSliderBar = function(self)
		if self.__ban_slider_bar then
			return
		end
		if self.__slider_fadeout_hdr then
			self.__slider_fadeout_hdr:stop()
			self.__slider_fadeout_hdr = nil
		end
		if not self.__slider_fadein_hdr then
			self.__slider_fadein_hdr = runProcess(1, function()
				local fa = self.__slider_bar:getAlpha()
				local ta = 255
				local t = 10
				for i = 1, t do
					local na = modEasing.outQuint(i, fa, ta - fa, t)
					self.__slider_bar:setAlpha(na)
					self.__slider:setAlpha(na)
					yield()
				end
			end):update()
		end
	end

	self.fadeOutSliderBar = function(self)
		if self.__ban_slider_bar then
			return
		end
		if self.__slider_fadeout_timeout then
			self.__slider_fadeout_timeout:stop()
			self.__slider_fadeout_timeout = nil
		end
		self.__slider_fadeout_timeout = setTimeout(s2f(1.5), function()
			if self.__slider_fadein_hdr then
				self.__slider_fadein_hdr:stop()
				self.__slider_fadein_hdr = nil
			end
			if not self.__slider_fadeout_hdr then
				self.__slider_fadeout_hdr = runProcess(1, function()
					local fa = self.__slider_bar:getAlpha()
					local ta = 0
					local t = 20
					for i = 1, t do
						local na = modEasing.outQuint(i, fa, ta - fa, t)
						self.__slider_bar:setAlpha(na)
						self.__slider:setAlpha(na)
						yield()
					end
				end)
			end
		end)
	end

end

makeDrag = function(self, minDiff, noOverDrag, wnds)
	self.posWnd = self
	local posWndDefStartX = self:getX()
	local posWndDefStartY = self:getY()
	local posWndMinStartX = gGameWidth - self:getWidth()
	if minDiff then
		posWndMinStartX = posWndMinStartX - minDiff
	end
	self.posWndDefStartX = posWndDefStartX
	self.posWndDefStartY = posWndDefStartY

	local viewParent = self:getParent()

	self.disableDrag = function(self, flg)
		self.__disable = flg
	end
	self:addListener("ec_mouse_left_down", function(e)
		self.xSpeed = nil
		posWndMinStartX = gGameWidth - self:getWidth()
		if minDiff then
			posWndMinStartX = posWndMinStartX - minDiff
		end
	end)

	local checkOverDrag = function(x)
		if noOverDrag then
			if x > posWndDefStartX then
				x = posWndDefStartX
			elseif x < posWndMinStartX then
				x = posWndMinStartX
			end
		end

		return x
	end


	local checkWndsInView = function()
		local vw, vh = viewParent:getWidth(), viewParent:getHeight()
		local vx, vy = viewParent:getX(true), viewParent:getY(true)
		for _, wnd in ipairs(wnds) do
			if not checkInView(vx, vy, vw, vh, wnd) then
				wnd:show(false)
			else
				wnd:show(true)
			end
		end
	end

	checkWndsInView()

	self:addListener("ec_mouse_drag", function(e)
		if self.__disable then
			return
		end
		self.xSpeed = e:dx()
		local dx = e:dx()
		local x = self.posWnd:getX()
		if x > posWndDefStartX or x < posWndMinStartX then
			dx = dx / 3
		end
		self.posWnd:setPosition(checkOverDrag(x + dx), self.posWnd:getY())

		checkWndsInView()
	end)

	local rollBack = function()
		local t = 1
		local duration = 5

		local x = self.posWnd:getX()
		local originX = x
		if x > posWndDefStartX then
			local c = x - posWndDefStartX
			self.rollBackProcess = setInterval(1, function()
				x = self.posWnd:getX()
				if x <= posWndDefStartX or t > duration then
					self.posWnd:setPosition(posWndDefStartX, posWndDefStartY)
					self.rollBackProcess:stop()
				else
					x = modEasing.outQuad(t, originX, c, duration)
					x = 2 * originX - x
					t = t + 1
					if x < posWndDefStartX then
						x = posWndDefStartX
					end

					self.posWnd:setPosition(x, posWndDefStartY)
				end
				checkWndsInView()
			end)
		elseif x < posWndMinStartX then
			local c = posWndMinStartX - x
			self.rollBackProcess = setInterval(1, function()
				x = self.posWnd:getX()
				if x >= posWndMinStartX or t > duration then
					self.posWnd:setPosition(posWndMinStartX, posWndDefStartY)
					self.rollBackProcess:stop()
				else
					x = modEasing.outQuad(t, originX, c, duration)
					t = t + 1
					if x > posWndMinStartX then
						x = posWndMinStartX
					end

					self.posWnd:setPosition(x, posWndDefStartY)
				end
				checkWndsInView()
			end)
		end
	end

	self.rollToPos = function(self, x, easing, nocheck, callback)
		local y = self:getY()
		if not easing then
			self:setPosition(x, y)
			checkWndsInView()
			safeCallBack(callback)
		else
			if self.__roll_to_pos_hdr then
				self.__roll_to_pos_hdr:stop()
				self.__roll_to_pos_hdr = nil
			end
			self.__roll_to_pos_hdr = runProcess(1, function()
				local fx = self:getX()
				local t = 5
				for i = 1, t do
					local cx = modEasing.outQuint(i, fx, x - fx, t)
					self:setPosition(cx, y)
					if not nocheck then
						checkWndsInView()
					end
					yield()
				end
				safeCallBack(callback)
			end):update()
		end
	end

	local onLeftUp = nil
	onLeftUp = function(e)
		if self.inertiaProcess then
			self.inertiaProcess:stop()
			self.inertiaProcess = nil
		end

		if self.rollBackProcess then
			self.rollBackProcess:stop()
			self.rollBackProcess = nil
		end

		--logv("info", posWndMinStartX, posWndDefStartX, self.xSpeed)

		local x = self.posWnd:getX()
		if x > posWndDefStartX or x < posWndMinStartX or not self.xSpeed then
			rollBack()
			return
		end

		-- 加速拖放延迟
		local xSpeed = self.xSpeed
		self.xSpeed = nil

		if noOverDrag then return end

		local maxSpeed, negMaxSpeed = 100, -100

		local sign = 1
		if xSpeed > maxSpeed then xSpeed = maxSpeed end
		if xSpeed < negMaxSpeed then xSpeed = negMaxSpeed end
		if xSpeed < 0 then sign = -1 end
		local acc = (xSpeed * xSpeed * 1/1000 + 1) * sign

		self.inertiaProcess = setInterval(1, function()
			local x = self.posWnd:getX()
			local acc2 = 0
			if x > posWndDefStartX then
				acc2 = (x - posWndDefStartX) * 0.1 * sign
			elseif x < posWndMinStartX then
				acc2 = (posWndMinStartX - x) * 0.1 * sign
			end

			x = x + xSpeed
			xSpeed = xSpeed - acc - acc2

			self.posWnd:setPosition(x, posWndDefStartY)
			checkWndsInView()

			if sign * xSpeed <= 2 then
				self.inertiaProcess:stop()
				rollBack()
			end
		end)
	end

	self:addListener("ec_mouse_left_up", onLeftUp)
end

makeDragVertical = function(self, minDiff, noOverDrag, wnds)
	self.posWnd = self
	local posWndDefStartX = self:getX()
	local posWndDefStartY = self:getY()
	self.minDiff = minDiff
	self.posWndMinStartY = gGameHeight - self:getHeight()
	if minDiff then
		self.posWndMinStartY = self.posWndMinStartY - minDiff
	end
	self.posWndDefStartX = posWndDefStartX
	self.posWndDefStartY = posWndDefStartY

	local viewParent = self:getParent()

	self.disableDrag = function(self, flg)
		self.__disable = flg
	end

	installSliderBar(self, viewParent)

	self:initSliderBar()

	self:addListener("ec_mouse_left_down", function(e)
		self.ySpeed = nil
		self.posWndMinStartY = gGameHeight - self:getHeight()
		if self.minDiff then
			self.posWndMinStartY = self.posWndMinStartY - self.minDiff
		end
	end)

	self.lastInViewWndIdx = {minIdx=nil, maxIdx=nil}

	self.checkWndsInView = function(delayShowFlag)
		local vw, vh = viewParent:getWidth(), viewParent:getHeight()
		local vx, vy = viewParent:getX(true), viewParent:getY(true)
		local wnds = self.__wnds
		local totalWndCnt = table.size(wnds)

		local minIdx, maxIdx = self.lastInViewWndIdx["minIdx"], self.lastInViewWndIdx["maxIdx"]
		if minIdx and maxIdx then
			for i = minIdx, totalWndCnt do
				local wnd = wnds[i]
				wnd.__delay_show_flag = delayShowFlag
				if checkInView(vx, vy, vw, vh, wnd) then
					self.lastInViewWndIdx["minIdx"] = i
					break
				else
					wnd:show(false)
				end
			end

			local firstHit = false
			for i = minIdx, 1, -1 do
				local wnd = wnds[i]
				wnd.__delay_show_flag = delayShowFlag
				if checkInView(vx, vy, vw, vh, wnd) then
					self.lastInViewWndIdx["minIdx"] = i
					firstHit = true
				else
					wnd:show(false)
					if firstHit then
						break
					end
				end
			end

			for i = maxIdx, 1, -1 do
				local wnd = wnds[i]
				wnd.__delay_show_flag = delayShowFlag
				if checkInView(vx, vy, vw, vh, wnd) then
					self.lastInViewWndIdx["maxIdx"] = i
					break
				else
					wnd:show(false)
				end
			end

			firstHit = false
			for i = maxIdx, totalWndCnt do
				local wnd = wnds[i]
				wnd.__delay_show_flag = delayShowFlag
				if checkInView(vx, vy, vw, vh, wnd) then
					self.lastInViewWndIdx["maxIdx"] = i
					firstHit = true
				else
					wnd:show(false)
					if firstHit then
						break
					end
				end
			end

			for i = self.lastInViewWndIdx["minIdx"], self.lastInViewWndIdx["maxIdx"] do
				local wnd = wnds[i]
				wnd:show(true)
			end
		else
			for idx, wnd in ipairs(wnds or {}) do
				wnd.__idx = idx
				wnd.__delay_show_flag = delayShowFlag
				if not checkInView(vx, vy, vw, vh, wnd) then
					wnd:show(false)
				else
					wnd:show(true)
					local minIdx = self.lastInViewWndIdx["minIdx"] or 1/0
					if minIdx > idx  then
						self.lastInViewWndIdx["minIdx"] = idx
					end
					local maxIdx = self.lastInViewWndIdx["maxIdx"] or 0
					if maxIdx < idx then
						self.lastInViewWndIdx["maxIdx"] = idx
					end
				end
			end
		end

	end

	self.checkWndsInView()

	self:addListener("ec_mouse_drag", function(e)
		if self.__disable then
			return
		end
		self.ySpeed = e:dy()
		local dy = e:dy()
		local y = self.posWnd:getY()
		if y > posWndDefStartY or y < self.posWndMinStartY then
			dy = dy / 3
		end
		gLastScrollSoundTime = gLastScrollSoundTime or 0
		local frame = app:getCurrentFrame()
		if math.abs(frame - gLastScrollSoundTime) > 10 then
			gLastScrollSoundTime = frame
		end
		self.posWnd:setPosition(self.posWnd:getX(), y + dy)

		self.checkWndsInView()

		self:fadeInSliderBar()
		self:adjSliderBar()
	end)

	local rollBack = function()
		local t = 1
		local duration = 5

		local y = self.posWnd:getY()
		local originY = y
		if y > posWndDefStartY then
			local c = y - posWndDefStartY
			self.rollBackProcess = setInterval(1, function()
				y = self.posWnd:getY()
				if y <= posWndDefStartY or t > duration then
					self.posWnd:setPosition(posWndDefStartX, posWndDefStartY)
					self.rollBackProcess:stop()
					self:adjSliderBar()
					self:fadeOutSliderBar()
				else
					y = modEasing.outQuad(t, originY, c, duration)
					y = 2 * originY - y
					t = t + 1
					if y < posWndDefStartY then
						y = posWndDefStartY
					end

					self.posWnd:setPosition(posWndDefStartX, y)
					self:adjSliderBar()
				end
				self.checkWndsInView()
			end)
		elseif y < self.posWndMinStartY then
			local c = self.posWndMinStartY - y
			self.rollBackProcess = setInterval(1, function()
				y = self.posWnd:getY()
				if y >= self.posWndMinStartY or t > duration then
					self.posWnd:setPosition(posWndDefStartX, self.posWndMinStartY)
					self.rollBackProcess:stop()
					self:adjSliderBar()
					self:fadeOutSliderBar()
				else
					y = modEasing.outQuad(t, originY, c, duration)
					t = t + 1
					if y > self.posWndMinStartY then
						y = self.posWndMinStartY
					end

					self.posWnd:setPosition(posWndDefStartX, y)
					self:adjSliderBar()
				end
				self.checkWndsInView()
			end)
		else
			self:fadeOutSliderBar()
		end
	end

	self.rollToTop = function(self, targetY)
		local x = self:getX()
		local y = self:getY()
		local ty = targetY or posWndDefStartY
		local c = ty - y
		if self.__roll_to_top_hdr then
			self.__roll_to_top_hdr:stop()
		end
		self.__roll_to_top_hdr = runProcess(1, function()
			local t = 20
			for i = 1, t do
				local cy = modEasing.outQuint(i, y, c, t)
				self:setPosition(x, cy)
				self.checkWndsInView()
				self:adjSliderBar()
				yield()
			end
			self.__roll_to_top_hdr = nil
		end)
	end

	self.moveToBottom = function()
		local x = self:getX()
		local ty = self.posWndMinStartY
		self:setPosition(x, ty)
		self.checkWndsInView()
		self:adjSliderBar()
	end

	self.rollToBottom = function()
		local x = self:getX()
		local y = self:getY()
		local ty = self.posWndMinStartY
		local c = ty - y
		if self.__roll_to_bottom_hdr then
			self.__roll_to_bottom_hdr:stop()
		end
		self.__roll_to_bottom_hdr = runProcess(1, function()
			local t = 20
			for i = 1, t do
				local cy = modEasing.outQuint(i, y, c, t)
				self:setPosition(x, cy)
				self.checkWndsInView()
				self:adjSliderBar()
				yield()
			end
			self.__roll_to_bottom_hdr = nil
		end)
	end

	local onLeftUp = nil
	self.rollToPos = function(self, y, callback, easing, delayShowFlag)
		local x = self:getX()
		if not easing then
			self:setPosition(x, y)
			self.checkWndsInView()
			self:adjSliderBar()
			if callback then
				callback()
			end
			onLeftUp()
		else
			local fy = self:getY()
			runProcess(1, function()
				local t = 10
				for i = 1, t do
					local cy = modEasing.inQuint(i, fy, y - fy, t)
					self:setPosition(x, cy)
					self.checkWndsInView(delayShowFlag)
					self:adjSliderBar()
					yield()
				end
				onLeftUp()
				if callback then
					callback()
				end
			end)
		end
	end

	onLeftUp = function(e)
		if self.inertiaProcess then
			self.inertiaProcess:stop()
			self.inertiaProcess = nil
		end

		if self.rollBackProcess then
			self.rollBackProcess:stop()
			self.rollBackProcess = nil
		end

		local y = self.posWnd:getY()
		if y > posWndDefStartY or y < self.posWndMinStartY or not self.ySpeed then
			rollBack()
			return
		end
		-- 加速拖放延迟
		local ySpeed = self.ySpeed
		self.ySpeed = nil

		local maxSpeed, negMaxSpeed = 100, -100

		local sign = 1
		if ySpeed > maxSpeed then ySpeed = maxSpeed end
		if ySpeed < negMaxSpeed then ySpeed = negMaxSpeed end
		if ySpeed < 0 then sign = -1 end
		local acc = (ySpeed * ySpeed * 1/1000 + 1) * sign

		self.inertiaProcess = setInterval(1, function()
			local y = self.posWnd:getY()
			local acc2 = 0
			if y > posWndDefStartY then
				acc2 = (y - posWndDefStartY) * 0.1 * sign
			elseif y < self.posWndMinStartY then
				acc2 = (self.posWndMinStartY - y) * 0.1 * sign
			end

			y = y + ySpeed
			ySpeed = ySpeed - acc - acc2

			self.posWnd:setPosition(posWndDefStartX, y)
			self.checkWndsInView()
			self:adjSliderBar()

			if sign * ySpeed <= 2 then
				self.inertiaProcess:stop()
				rollBack()
			end
		end)
	end

	self:addListener("ec_mouse_left_up", onLeftUp)

	self.fadeIn = function(self)
		local isInProcess = function()
			if self.__fade_in_hdr then
				return true
			end
			if not table.isEmpty(self.__all_sub_hdr or {}) then
				return true
			end
			return false
		end

		if isInProcess() then
			return
		end

		local listWnds = {}
		for _, wnd in ipairs(wnds) do
			if wnd:isShow() then
				table.insert(listWnds, wnd)
				wnd:setOffsetX(wnd:getWidth())
				if not wnd.__get_x then
					wnd.__get_x = wnd.getX
				end
				if not wnd.__get_y then
					wnd.__get_y = wnd.getY
				end
				wnd.__origin_x = wnd:getX(true)
				wnd.__origin_y = wnd:getY(true)
				wnd.getX = function(self, derived)
					if not derived then
						return wnd:__get_x(derived)
					else
						if isInProcess() then
							return self.__origin_x
						else
							return wnd:__get_x(derived)
						end
					end
				end
				wnd.getY = function(self, derived)
					if not derived then
						return wnd:__get_y(derived)
					else
						if isInProcess() then
							return self.__origin_y
						else
							return wnd:__get_y(derived)
						end
					end
				end
			end
		end
		if self.__fade_in_hdr then
			self.__fade_in_hdr:stop()
		end
		for hdr, _ in pairs(self.__all_sub_hdr or {}) do
			hdr:stop()
		end
		self.__all_sub_hdr = {}
		self.__fade_in_hdr = runProcess(1, function()
			local cnt = table.size(listWnds)
			local t = 8
			for c = 1, cnt do
				local hdr
				hdr = runProcess(1, function()
					local wnd = listWnds[c]
					local toOx = 0
					local diff = wnd:getWidth()
					for i = 1, t do
						local nx = modEasing.outQuint(i, toOx + diff, -diff, t)
						wnd:setOffsetX(nx)
						yield()
					end
					self.__all_sub_hdr[hdr] = nil
				end)
				self.__all_sub_hdr[hdr] = true
				for i = 1, 2 do
					yield()
				end
			end
			self.__fade_in_hdr = nil
		end)
	end

	self.displayOneByOne = function(self, callback)
		self.__display_one_by_one_cb = callback
		local isInProcess = function()
			if self.__display_hdr then
				return true
			end
			return false
		end

		if isInProcess() then
			return
		end

		self.__cur_idx = 1
		local parent = self:getParent()
		local ph = parent:getHeight()

		for _, wnd in ipairs(wnds) do
			wnd:show(false)
		end

		local callCb = function()
			if callback then
				callback()
			end
			self.__display_one_by_one_cb = nil
		end

		function handleOneWnd()
			if self.__cur_idx < 0 then
				callCb()
				return
			end
			local wnd = wnds[self.__cur_idx]
			if not wnd then
				self.__cur_idx = -1
				callCb()
				return
			end
			local cb = function()
				wnd:show(true)
				if wnd.onDisplayOneByOne then
					wnd:onDisplayOneByOne(handleOneWnd)
				else
					setTimeout(10, handleOneWnd)
				end
			end
			local h = wnd:getHeight()
			local diff = ph - self.__cur_idx * h - (self.__cur_idx - 1) * self.__gap
			if diff < 0 then
				local toy = diff
				self:rollToPos(toy, cb, true, true)
			else
				cb()
			end
			self.__cur_idx = self.__cur_idx + 1
		end

		handleOneWnd()
	end

	self.cancelDisplayOneByOne = function(self)
		if self.__display_one_by_one_cb then
			self.__display_one_by_one_cb()
			self.__display_one_by_one_cb = nil
		end

		self.__cur_idx = -1

		self.moveToBottom()

		for _, wnd in ipairs(wnds) do
			if wnd.onCancelDisplayOneByOne then
				wnd:onCancelDisplayOneByOne()
			end
		end
	end
end

makeSceneDrag = function(scene)
	listenerFun , scene.dragListener = scene:addListener("ec_mouse_drag", function(e)
		local x, y, dx, dy = 0,0,0,0
		if e:touchCount() == 1 then
			if scene.canDrag then
				dx = e:dx()
				dy = e:dy()
			end
		elseif e:touchCount() == 2 then
			local point1 = e:getTouchPoint(0)
			local point2 = e:getTouchPoint(1)
			local x1,y1 = point1:x(), point1:y()
			local dx1,dy1 = point1:dx(), point1:dy()
			local px1, py1 = x1 - dx1, y1 - dy1

			local x2,y2 = point2:x(), point2:y()
			local dx2,dy2 = point2:dx(), point2:dy()
			local px2, py2 = x2 - dx2, y2 - dy2

			local scale = distance({x2, y2}, {x1, y1}) / distance({px2,py2}, {px1, py1})

			local center = {x = (px1 + px2) / 2, y = (py1 + py2) / 2}
			local sceneCenter = scene:getLocalCoord((px1 + px2) / 2,
							      (py1 + py2) / 2)
			local oldScale = scene:getSX()
			local finalScale = max({oldScale * scale,
					       gGameWidth/scene:getWidth(),
					       gGameHeight/scene:getHeight()})
			finalScale = min({finalScale, 2})

			local scaleFactor = finalScale / oldScale
			scene:setScale(finalScale, finalScale)
			dx = sceneCenter.x * (oldScale - finalScale)
			dy = sceneCenter.y * (oldScale - finalScale)
		end

		x = scene:getX() + dx
		y = scene:getY() + dy

		-- 编辑器允许超过边界
		if not scene.enableOutBound then
			local sx,sy = scene:getSX(), scene:getSY()
			if x > 0 then x = 0 end
			if x + scene:getWidth()*sx < gGameWidth then x = - scene:getWidth()*sx + gGameWidth end
			if y > 0 then y = 0 end
			if y + scene:getHeight()*sy < gGameHeight then y = - scene:getHeight()*sy + gGameHeight end
		end
		scene:setPosition(x, y)
	end)
end

getCurScreenCenterPoint = function()
	local scene = gWorld:getSceneRoot()
	local center = scene:getViewCenter()
	return {center:x(), center:y()}
end

loadScene = function(sceneObj, sceneId, argFlg, onLoadCb)
	log("info", "loading scene: ", sceneId)
	sceneObj.onLoad = function(scene, arg)
		if arg == "block" then
			onLoadCb(scene, arg)
			sceneObj.sceneId = sceneId
		end
	end
	sceneObj:loadCfg(sceneId, argFlg)
end

easeZoomScene = function(scene, sx, sy, tox, toy, timeSec, callback, speedLine)
	local osx, osy = scene:getSX(), scene:getSY()
	local viewCenter = getCurScreenCenterPoint()
	local vcx, vcy = -viewCenter[1], -viewCenter[2]
	tox = tox or vcx
	toy = toy or vcy
	local rate = osy / osx
	local k = -1
	if tox ~= vcx then
		k = (toy - vcy) / (tox - vcx)
	end
	return runSceneProcess(1, function()
		local speedWnd = nil
		local speedW = gGameWidth * 5/4
		local speedH = gGameHeight * 5/4
		if speedLine then
			speedWnd = pWindow()
			speedWnd:setParent(gWorld:getUIRoot())
			speedWnd:setSize(speedW, speedH)
			speedWnd:setZ(-100)
			speedWnd:setImage("ui:xgsuduxian.png")
		end

		local fc = secToFrame(timeSec)
		for i = 0, fc do
			local csx = modEasing.linear(i, osx, sx - osx, fc)
			local csy = csx * rate
			scene:setScale(csx, csy)

			if tox ~= vcx or toy ~= vcy then
				local x, y
				if k == -1 then
					y = modEasing.linear(i, vcy, toy - vcy, fc)
					x = tox
				else
					x = modEasing.linear(i, vcx, tox - vcx, fc)
					y = k * (x - vcx) + vcy
				end
				scene:moveToPosition(-x, -y)
			else
				scene:moveToPosition(-vcx, -vcy)
			end

			if speedWnd then
				local speed = 30
				local w, h = speedWnd:getWidth(), speedWnd:getHeight()
				w = w + speed
				h = h + speed
				local x, y = (gGameWidth - w) / 2, (gGameHeight - h) / 2
				speedWnd:setPosition(x, y)
				speedWnd:setSize(w, h)
			end

			yield()
		end

		if speedWnd then
			speedWnd:setParent(nil)
		end

		if callback then
			callback()
		end
	end)
end

easeMoveScene = function(scene, toX, toY, timeSec, callback)
	--log("error", "============= ", toX, toY, timeSec)
	local localPoint = scene:getViewCenter()
	local x, y = localPoint:x(), localPoint:y()

	--[[
	local speed = 50
	local distance = math.pow(((x-toX)*(x-toX) + (y-toY)*(y-toY)), 0.5)
	local total = math.ceil(distance / speed)
	]]--

	local k = (toY - y)/(toX - x)
	local setPos = function(t, ox, oy, c, d)
		if toX ~= ox then
			local tx = modEasing.linear(t, ox, c, d)
			local ty = k*(tx-ox)+oy
			--scene:setPosition(tx, ty)
			scene:moveToPosition(tx, ty)
			return true
		else
			if toY ~= oy then
				local ty = modEasing.linear(t, oy, c, d)
				local tx = ox
				scene:moveToPosition(tx, ty)
			else
				return false
			end
		end
	end
	return runProcess(1, function()
		local totalFrame = secToFrame(timeSec)
		local origin = x
		local originY = y
		local c = (toX - x)
		for i = 0,totalFrame do
			if not setPos(i, origin, originY, c, totalFrame) then
				break
			end
			yield()
		end

		if callback then
			callback()
		end
	end):update()
end

iterateNumKeyTable = function(tData, dec)
	--do return pairs(tData) end


	local sortFunc = function(numStr1, numStr2)
		local num1 = tonumber(numStr1)
		local num2 = tonumber(numStr2)
		if dec then
			return num1 > num2
		else
			return num1 < num2
		end
	end
	local allKeys = table.keys(tData)
	table.sort(allKeys, sortFunc)
	local iter = function(a)
		local data = a[1]
		local i = a[2]
		i = i + 1
		a[2] = i
		local key = allKeys[i]
		if key == nil then return nil end

		local v = data[key]
		if v ~= nil then
			return key, v
		else
			return nil
		end
	end

	return iter, {tData, 0}
end

secToTimeString = function(time)
	local hour = math.floor(time / 3600)
	local t = time % 3600
	local min = math.floor(t / 60)
	local sec = t % 3600

	local str
	local day = math.floor(hour / 24)
	if day > 0 then
		str = day .. TEXT(135)
	elseif hour > 0 then
		str = hour .. TEXT(138)
	elseif min > 1 then
		str = min .. TEXT(137)
	else
		str = sec .. TEXT(134)
	end
	return str
end

timeToStr = function(time)
	local strTime = localTime(time)
	local year, month, day = strTime.year, strTime.month, strTime.day
	local hour, minute, sec = strTime.hour, strTime.min, strTime.sec

	local str = sf("%d-%.2d-%.2d %.2d:%.2d:%.2d", year, month, day, hour, minute, sec)
	return str
end

timeToStr2 = function(time)
	local strTime = localTime(time)
	local year, month, day = strTime.year, strTime.month, strTime.day
	local str = sf("%d-%.2d-%.2d", year, month, day)
	return str
end

timeToActRankStr = function(time)
	local strTime = localTime(time)
	local year, month, day = strTime.year, strTime.month, strTime.day
	local hour, minute, sec = strTime.hour, strTime.min, strTime.sec
	hour, minute = 0, 0
	local str = sf(TEXT(158), month, day, hour, minute)
	return str
end

secToString6 = function(sec)
	sec = math.ceil(sec)
	local hour = math.floor(sec / 3600)
	local t = sec % 3600
	local min = math.floor(t / 60)

	local ret
	if hour > 0 then
		if min > 0 then
			ret = string.format(TEXT(144), hour, min)
		else
			ret = string.format(TEXT(138), hour)
		end
	elseif min > 0 then
		ret = string.format(TEXT(136), min)
	end

	return ret
end

secToString = function(sec, noSec)
	sec = math.ceil(sec)
	local hour = math.floor(sec / 3600)
	local t = sec % 3600
	local min = math.floor(t / 60)
	local sec = t % 60

	local ret
	if hour > 0 then
		if sec > 0 and not noSec then
			ret = string.format(TEXT(148), hour, min, sec)
		else
			if min > 0 then
				ret = string.format(TEXT(144), hour, min)
			else
				ret = string.format(TEXT(141), hour)
			end
		end
	elseif min > 0 then
		if sec > 0 then
			ret = string.format(TEXT(142), min, sec)
		else
			ret = string.format(TEXT(136), min)
		end
	else
		ret = string.format(TEXT(1), sec)
	end

	return ret
end

secToString2 = function(sec)
	sec = math.ceil(sec)
	local hour = math.floor(sec / 3600)
	local t = sec % 3600
	local min = math.floor(t / 60)
	local sec = t % 60

	local ret
	if hour > 0 then
		if sec > 0 then
			ret = string.format("%02d:%02d:%02d", hour, min, sec)
		else
			if min > 0 then
				ret = string.format("%02d:%02d:00", hour, min)
			else
				ret = string.format("%02d:00:00", hour)
			end
		end
	elseif min > 0 then
		if sec > 0 then
			ret = string.format("%02d:%02d", min, sec)
		else
			ret = string.format("%02d:00", min)
		end
	else
		ret = string.format("00:%02d", sec)
	end

	return ret
end

secToString3 = function(sec)
	sec = math.ceil(sec)
	local hour = math.floor(sec / 3600)
	local t = sec % 3600
	local min = math.floor(t / 60)
	local sec = t % 60

	local ret
	ret = string.format("%02d:%02d:%02d", hour, min, sec)
	return ret
end

secToString4 = function(sec)
	sec = math.ceil(sec)
	day = math.floor(sec / 24 / 3600)
	t = sec % (24 * 3600)
	strTime = secToString(t)
	local ret = strTime
	if day > 0 then
		ret = string.format(TEXT(139), day, strTime)
	end
	return ret
end

secToString5 = function(sec)
	sec = math.ceil(sec)
	day = math.floor(sec / 24 / 3600)
	t = sec % (24 * 3600)
	strTime = secToString6(t)
	local ret = strTime
	if day > 0 then
		ret = string.format(TEXT(139), day, strTime)
	end
	return ret
end

secToString7 = function(sec)
	sec = math.ceil(sec)
	day = math.floor(sec / 24 / 3600)
	t = sec % (24 * 3600)
	hour = math.ceil(t / 3600)
	local ret = ""
	if day > 0 then
		ret = string.format(TEXT("%d天%d小时"), day, hour)
	else
		ret = string.format(TEXT("%d小时"), hour)
	end
	return ret
end

secToString8 = function(sec)
	sec = math.ceil(sec)
	day = math.floor(sec / 24 / 3600)
	t = sec % (24 * 3600)
	hour = math.floor(t / 3600)
	t = t % 3600
	local min = math.floor(t / 60)
	local sec = t % 3600
	local ret = ""
	if day > 0 then
		ret = string.format(TEXT(146), day, hour)
	elseif hour > 0 then
		ret = string.format(TEXT(147), hour, min)
	elseif min > 0 then
		ret = string.format(TEXT(145), min, sec)
	else
		ret = string.format(TEXT(1), sec)
	end
	return ret
end

secToString9 = function(sec)
	sec = math.ceil(sec)
	local day = math.floor(sec / 24 / 3600)
	local t = sec % (24 * 3600)
	local hour = math.floor(t / 3600)

	local ret = ""
	if day > 0 then
		ret = string.format(TEXT(143), day, hour)
	else
		local min = math.floor(t % 3600 / 60)
		ret = string.format(TEXT("%02d:%02d"), hour, min)
	end

	return ret
end

regDragWndFocusEv = function(parent, wnd, iconPath)
	if not parent.focused then
		parent.focused = {}
		setmetatable(parent.focused, {__mode ="v"})
	end

	if not wnd.__chooseWnd then
		local w, h = wnd:getWidth(), wnd:getHeight()
		local cw, ch = w + 5, h + 5
		local c = pWindow()
		c:setSize(cw, ch)
		iconPath = iconPath or "ui:pkxuanzhong2.png"
		c:setImage(iconPath)
		c:setParent(wnd)
		c:setZ(-1000)
		c:setPosition((w - cw)/2, (h - ch)/2)
		c:show(false)
		wnd.__chooseWnd = c
	end
	wnd:addListener("ec_mouse_click", function()
		local cur = parent.focused["focus"]
		if cur and cur.__chooseWnd then
			cur.__chooseWnd:show(false)
		end

		wnd.__chooseWnd:show(true)
		parent.focused["focus"] = wnd
	end)

	parent.cancelFocus = function(parent)
		local cur = parent.focused["focus"]
		if cur and cur.__chooseWnd then
			cur.__chooseWnd:show(false)
		end
		parent.focused["focus"] = nil
	end
end

buildDragWindow = function(dragBgWnd, wnds, gap, noOverDrag)
	local id = 1
	local maxH = 0
	local dragW, dragH = 0, 0
	local x = 0
	local w1, w2 = 0, 0
	for _, wnd in ipairs(wnds) do
		local w, h = wnd:getWidth(), wnd:getHeight()
		wnd.__w = w
		wnd.__h = h
		if h > maxH then
			maxH = h
		end
		w1 = w
		if id == 1 then
			x = x + (w1 + w2) / 2
		else
			x = x + (w1 + w2) / 2 + gap
		end
		w2 = w1
		local point = pWindow()
		point:showSelf(false)
		point:setZ(-500)
		point:setSize(0, 0)
		point:setParent(dragBgWnd)
		point:setPosition(x, h/2)
		--point:setPosition((id-1) * (w + gap) + w/2, h/2)

		wnd:setParent(point)
		wnd:setPosition(-w/2, -h/2)

		id = id + 1

		dragW = dragW + w + gap
	end
	dragBgWnd.maxPage =	table.size(wnds)
	dragW = dragW - gap
	dragH = maxH
	dragBgWnd:setSize(dragW, dragH)
	local diff
	if dragW > dragBgWnd:getParent():getWidth() then
		diff = math.abs(gGameWidth - dragBgWnd:getParent():getWidth())
	else
		diff = math.abs(gGameWidth - dragW)
	end

	makeDrag(dragBgWnd, diff, noOverDrag, wnds)
end

local levelPathPointSize = {w = 16,h = 16}

buildDragWindowChangePage = function(dragBgWnd,wnds,gap,func,showPageWnd)
	local maxPage = #wnds
	local x = 0
	local dragW, dragH = 0, 0
	local maxW, maxH = 0, 0
	local w1, w2 = 0, 0
	for k, wnd in ipairs(wnds) do
		local w, h = wnd:getWidth(), wnd:getHeight()
		if maxW < w then
			maxW = w
		end
		if maxH < h then
			maxH = h
		end
		w1 = w
		x = x + (w1 + w2) / 2 + gap
		w2 = w1
		local point = pWindow()
		point:showSelf(false)
		point:setZ(-500)
		point:setSize(0,0)
		point:setParent(dragBgWnd)
		--point:setPosition((k - 1) * (w + gap) + w/2, h/2)
		point:setPosition(x, h/2)
		wnd:setParent(point)
		wnd:setPosition(-w/2,-h/2)

		dragW = dragW + w + gap
	end
	dragW = dragW - gap
	dragBgWnd.maxPage = maxPage
	local parent = dragBgWnd

	parent.maxPage = maxPage
	dragBgWnd:setSize(dragW, maxH)
	makeDragChangePage(dragBgWnd,maxW,gap,func,wnds)

	if func then
		func(1, maxPage, true)
	end
	return maxPage
end

buildDragWindowVertical = function(dragBgWnd, wnds, gap, noOverDrag, exGap)
	exGap = exGap or 0
	dragBgWnd.__wnds = {}

	dragBgWnd.__gap = gap
	dragBgWnd.removeWnds = function(self, fromPos, endPos)
		if endPos < fromPos then
			return
		end
		if not dragBgWnd.__wnds then
			return
		end
		if table.size(dragBgWnd.__wnds) < fromPos then
			return
		end
		if fromPos == 1 and table.size(dragBgWnd.__wnds) == endPos then
			return
		end

		local maxW = 0
		local subH = 0
		local subWndCnt = 0
		for pos, wnd in ipairs(dragBgWnd.__wnds) do
			if pos >= fromPos and pos <= endPos then
				subWndCnt = subWndCnt + 1
				subH = subH + wnd:getHeight() + gap + exGap
			elseif wnd:getWidth() > maxW then
				maxW = wnd:getWidth()
			end
		end

		-- 将原有的窗口向上移动
		for pos, wnd in ipairs(dragBgWnd.__wnds) do
			if wnd and pos > endPos then
				local x = wnd:getParent():getX()
				local y = wnd:getParent():getY()
				wnd:getParent():setPosition(x, y - subH)
			end
		end

		-- 删除掉原有的窗口
		for pos, wnd in ipairs(dragBgWnd.__wnds) do
			if pos >= fromPos and pos <= endPos then
				local point = wnd:getParent()
				point:setParent(nil)
				wnd:setParent(nil)
			end
		end
		for i = fromPos, endPos do
			table.remove(dragBgWnd.__wnds, fromPos)
		end

		dragBgWnd.maxPage = dragBgWnd.maxPage - subWndCnt
		dragBgWnd.maxW = maxW
		dragBgWnd.dragW = dragBgWnd.maxW + gap
		dragBgWnd.dragH = dragBgWnd.dragH - subH
		dragBgWnd:setSize(dragBgWnd.dragW, dragBgWnd.dragH)

		if dragBgWnd.posWndMinStartY then
			local diff
			if dragBgWnd.dragH > dragBgWnd:getParent():getHeight() then
				diff = math.abs(gGameHeight- dragBgWnd:getParent():getHeight())
			else
				diff = math.abs(gGameHeight - dragBgWnd.dragH)
			end
			dragBgWnd.posWndMinStartY = gGameHeight - dragBgWnd.dragH - diff
			dragBgWnd.minDiff = diff
		end

		local viewCheckData = dragBgWnd.lastInViewWndIdx
		if viewCheckData then
			if viewCheckData["maxIdx"] then
				viewCheckData["maxIdx"] = math.max(1, viewCheckData["maxIdx"] - subWndCnt)
			end
		end

		if dragBgWnd.checkWndsInView then
			dragBgWnd.checkWndsInView()
		end
	end

	dragBgWnd.insertWnds = function(self, newWnds, insertPos)
		newWnds = newWnds or {}
		if table.size(newWnds) <= 0 then
			return
		end
		local addH = 0
		for _, w in ipairs(newWnds) do
			addH = addH + w:getHeight() + gap + exGap
		end

		local beginY = 0
		insertPos = insertPos or 0
		-- 原来的向下移动
		for pos, w in ipairs(dragBgWnd.__wnds) do
			if pos > insertPos then
				local x = w:getParent():getX()
				local y = w:getParent():getY()
				w:getParent():setPosition(x, y + addH)
			else
				beginY = beginY + w:getHeight() + gap + exGap
			end
		end

		local id = 1
		local maxPage = dragBgWnd.maxPage or 0
		local maxW = dragBgWnd.maxW or 0
		local dragW = dragBgWnd.dragW or 0
		local dragH = dragBgWnd.dragH or 0
		local y = beginY
		local h1, h2 = 0, 0
		for pos, wnd in ipairs(newWnds) do
			local w, h = wnd:getWidth(), wnd:getHeight() + exGap
			wnd.__w = w
			wnd.__h = h
			if w > maxW then
				maxW = w
			end
			h1 = h
			if id ~= 1 then
				y = y + (h1 + h2) / 2 + gap
			else
				y = y + (h1 + h2) / 2
			end
			h2 = h1
			local point = pWindow()
			point:showSelf(false)
			point:setZ(-500)
			point:setSize(0, 0)
			point:setParent(dragBgWnd)
			point:setPosition(w/2, y)

			wnd:setParent(point)
			wnd:setPosition(-w/2, -h/2)

			id = id + 1
			dragH = dragH + h + gap
			wnd:show(false)
			table.insert(dragBgWnd.__wnds, insertPos + pos, wnd)
		end
		dragBgWnd.maxPage = maxPage + id - 1
		dragW = maxW + gap
		dragBgWnd:setSize(dragW, dragH)
		dragBgWnd.dragW = dragW
		dragBgWnd.dragH = dragH

		if dragBgWnd.posWndMinStartY then
			local diff
			if dragBgWnd.dragH > dragBgWnd:getParent():getHeight() then
				diff = math.abs(gGameHeight- dragBgWnd:getParent():getHeight())
			else
				diff = math.abs(gGameHeight - dragBgWnd.dragH)
			end
			dragBgWnd.posWndMinStartY = gGameHeight - dragBgWnd.dragH - diff
			dragBgWnd.minDiff = diff
		end

		local viewCheckData = dragBgWnd.lastInViewWndIdx
		if viewCheckData then
			if viewCheckData["minIdx"] then
				viewCheckData["minIdx"] = math.max(1, insertPos + id - 1)
			end
		end

		if dragBgWnd.checkWndsInView then
			dragBgWnd.checkWndsInView()
		end
	end


	dragBgWnd.isBottom = function(self)
		return self:getY() + self:getHeight() <= self:getParent():getHeight()
	end

	dragBgWnd.appendWnds = function(self, newWnds, scroll)
		if table.size(newWnds) <= 0 then
			return
		end

		local bottom = scroll and self:isBottom()

		local id = 1
		local maxW = dragBgWnd.maxW or 0
		local dragW = dragBgWnd.dragW or 0
		local dragH = dragBgWnd.dragH or 0
		local y = dragH
		local h1, h2 = 0, 0
		for _, wnd in ipairs(newWnds) do
			local w, h = wnd:getWidth(), wnd:getHeight() + exGap
			wnd.__w = w
			wnd.__h = h
			if w > maxW then
				maxW = w
			end
			h1 = h
			if id ~= 1 then
				y = y + (h1 + h2) / 2 + gap
			else
				y = y + (h1 + h2) / 2
			end
			h2 = h1
			local point = pWindow()
			point:showSelf(false)
			point:setZ(-500)
			point:setSize(0, 0)
			point:setParent(dragBgWnd)
			point:setPosition(w/2, y)

			wnd:setParent(point)
			wnd:setPosition(-w/2, -h/2)

			id = id + 1
			dragH = dragH + h + gap
			wnd:show(false)
			table.insert(dragBgWnd.__wnds, wnd)
		end
		dragBgWnd.maxPage = id - 1
		dragW = maxW + gap
		dragBgWnd:setSize(dragW, dragH)
		dragBgWnd.dragW = dragW
		dragBgWnd.dragH = dragH

		if dragBgWnd.posWndMinStartY then
			local diff
			if dragBgWnd.dragH > dragBgWnd:getParent():getHeight() then
				diff = math.abs(gGameHeight- dragBgWnd:getParent():getHeight())
			else
				diff = math.abs(gGameHeight - dragBgWnd.dragH)
			end
			dragBgWnd.posWndMinStartY = gGameHeight - dragBgWnd:getHeight() - diff
			dragBgWnd.minDiff = diff
		end

		local viewCheckData = dragBgWnd.lastInViewWndIdx
		if viewCheckData then
			if viewCheckData["maxIdx"] then
				viewCheckData["maxIdx"] = viewCheckData["maxIdx"] + table.size(newWnds)
			end
		end

		if dragBgWnd.rollToBottom and bottom then
			dragBgWnd:rollToBottom()
		elseif dragBgWnd.checkWndsInView then
			dragBgWnd.checkWndsInView()
		end
	end

	dragBgWnd:appendWnds(wnds)

	local diff
	if dragBgWnd.dragH > dragBgWnd:getParent():getHeight() then
		diff = math.abs(gGameHeight- dragBgWnd:getParent():getHeight())
	else
		diff = math.abs(gGameHeight - dragBgWnd.dragH)
	end

	makeDragVertical(dragBgWnd, diff, false, wnds)
end

buildMultiColDragWindow = function(dragBgWnd, wnds, col, gapx, gapy, pw, exGap)
	exGap = exGap or 0
	local bgWnd = nil
	local cw, ch = wnds[1]:getWidth(), wnds[1]:getHeight() + exGap
	if pw then
		local defGapX = (pw - (cw * col)) / (col + 1)
		gapx = gapx or defGapX
		gapy = gapy or 5
	else
		gapx = gapx or 5
		gapy = gapy or 5
	end
	local defW = cw * col + gapx * (col - 1)
	local bgW = pw or defW
	pw = pw or defW
	local bgH = ch
	local bgWnds = {}
	local initX = (pw - defW) / 2
	local x, y = initX, 0
	for idx, wnd in ipairs(wnds) do
		local w, h = wnd:getWidth(), wnd:getHeight()
		if (idx - 1) % col == 0 then
			bgWnd = pWindow()
			bgWnd:setColor(0)
			bgWnd:setSize(bgW, bgH)
			table.insert(bgWnds, bgWnd)
			x = initX

			bgWnd.__wnds = {}
			bgWnd.onLoadInView = function(bw)
				for _, wnd in ipairs(bw.__wnds) do
					if wnd.onLoadInView then
						callLoad(wnd)
					end
				end
			end
		else
			x = x + w + gapx
		end
		wnd:setParent(bgWnd)
		wnd:setPosition(x, y)
		table.insert(bgWnd.__wnds, wnd)
	end

	buildDragWindowVertical(dragBgWnd, bgWnds, gapy)
end

makeModelWindow = function(wnd, needApparent, autoClose, canCloseFunc)
	local w, h = wnd:getWidth(), wnd:getHeight()
	local x, y = wnd:getX(true), wnd:getY(true)
	local gw, gh = gWorld:getUIRoot():getWidth(), gWorld:getUIRoot():getHeight()
	local modelBg = pWindow()
	modelBg:setParent(wnd)
	modelBg:setSize(gw*3, gh*3)
	modelBg:setAlignX(ALIGN_CENTER)
	modelBg:setAlignY(ALIGN_MIDDLE)
	if not needApparent then
		modelBg:setColor(0xBF000000)
	else
		modelBg:setColor(0)
	end
	wnd.__modelBgWnd = modelBg
	wnd.__modelBgWnd:setZ(100)

	wnd.setBgColor = function(wnd, color)
		wnd.__modelBgWnd:setColor(color)
	end
	wnd.removeModelWindow = function(wnd)
		wnd.__modelBgWnd:setParent(nil)
		wnd.__modelBgWnd = nil
	end
	if autoClose then
		wnd.__modelBgWnd:addListener("ec_mouse_click", function(e)
			-- 是否落在wnd的范围内
			local x = e:x()
			local y = e:y()
			local diffx = (modelBg:getWidth() - w) / 2
			local diffy = (modelBg:getHeight() - h) / 2
			if x >= diffx and x <= w + diffx and y >= diffy and y <= h + diffy then
				e:bubble(true)
				return
			end
			if canCloseFunc and not canCloseFunc() then
				e:bubble(true)
				return
			end
			wnd:close()
			e:bubble(true)
		end)
	end

	wnd:setZ(-1001)

	wnd.__destroy_event = modEvent.handleEvent("DESTROY_GAME", function()
		wnd:close()
	end)
end

-- 当前时间戳，毫秒
getTime = function()
	return math.floor(getCurrentTime() / 10)
end

local serverTimeDiff = serverTimeDiff or nil

-- 秒
getServerTime = function()
	if not serverTimeDiff then
		return os.time()
	end
	local localTime = math.floor(getTime() / 1000)
	return localTime + serverTimeDiff/1000
end

getServerTimeMs = function()
	if not serverTimeDiff then
		return getTime()
	end
	return getTime() + serverTimeDiff
end

setupServerTime = function(serverTime)
	if not serverTime then
		serverTimeDiff = nil
		return
	end
	local localTime = getTime()
	serverTimeDiff = (serverTime - math.floor(localTime))
	--log("error", sf("setup servertime %d, diff=%d[ms]", serverTime, serverTimeDiff))
end

getLocalTime = function()
	local t = getServerTime()
	local info = localTime(t)
	return info
end

getServerDate = function()
	local today = localTime(getServerTime())
	local fmt = string.format("%d-%d-%d", today.year, today.month, today.day)
	return fmt, today
end

getTimeStringHuman = function(time)
	local date = localTime(time)
	local today = localTime(getServerTime())
	local fmt = string.format("%d-%d-%d %d:%d:%d", today.year, today.month, today.day, 1,0,0)
	local t = makeTime(fmt)
	local tomorrow_t = t + 24 * 3600

	if time > t then
		if time < tomorrow_t then
			return sf(TEXT(152), date["hour"], date["min"])
		elseif time - tomorrow_t < 3600 * 24 then
			return sf(TEXT(154), date["hour"], date["min"])
		elseif time - tomorrow_t < 3600 * 24 * 2 then
			return sf(TEXT(153), date["hour"], date["min"])
		else
			return TEXT(151)
		end
	elseif t - time < 3600 * 24 then -- 昨天
		return sf(TEXT(155), date["hour"], date["min"])
	elseif t - time < 3600 * 24 * 2 then
		return sf(TEXT(157), date["hour"], date["min"])
	else
		return sf(TEXT(150))
	end
	return TEXT(156)
end

leftLongDown = function(wnd, callback, stopCallback)
	wnd.__leftDownTime = nil
	wnd.__checkLeftDownHdr = nil
	local stop = function()
		if wnd.__checkLeftDownHdr then
			wnd.__checkLeftDownHdr:stop()
			wnd.__checkLeftDownHdr = nil
		end
		wnd.__leftDownTime = nil
		if stopCallback then
			stopCallback()
			wnd.__longdown_success = false
		end
	end
	wnd:addListener("ec_mouse_left_down", function(e)
		if not wnd.__leftDownTime then
			--wnd.__leftDownTime = getTime()
			wnd.__leftDownTime = app:getCurrentFrame()
			wnd.__leftDownPos = {e:ax(), e:ay()}
			wnd.__longdown_success = false
			if wnd.__checkLeftDownHdr then
				wnd.__checkLeftDownHdr:stop()
			end
			wnd.__checkLeftDownHdr = setInterval(1, function()
				if not wnd.__leftDownTime or not wnd:isShow() then
					wnd.__checkLeftDownHdr:stop()
					wnd.__checkLeftDownHdr = nil
					return
				end
				local t = app:getCurrentFrame()
				if t - wnd.__leftDownTime > 10 then
					wnd.__longdown_success = true
					if not callback() then
						wnd.__checkLeftDownHdr:stop()
						wnd.__checkLeftDownHdr = nil
						return
					end
				end
			end)
		end
		e:bubble(true)
	end)

	wnd:addListener("ec_mouse_left_up", function(e)
		stop()
		e:bubble(true)
	end)

	local canMoveStop = function(e)
		if not wnd.__leftDownPos then
			return true
		end
		local lx, ly = unpack(wnd.__leftDownPos)
		local x, y = e:ax(), e:ay()
		if math.abs(x - lx) < 10 and math.abs(y - ly) < 10 then
			return false
		end
		return true
	end

	wnd:addListener("ec_mouse_move", function(e)
		if canMoveStop(e) then
			stop()
			e:bubble(true)
		end
	end)
end

-- copy from http://blog.csdn.net/simbi/article/details/8774376
intToBytes = function(num, endian, signed)
	if num<0 and not signed then num=-num print"warning, dropping sign from number converting to unsigned" end
	local res={[1]=0, [2]=0, [3]=0, [4]=0}
	local n = math.ceil(select(2,math.frexp(num))/8) -- number of bytes to be used.
	if signed and num < 0 then
		num = num + 2^n
	end
	for k=n,1,-1 do -- 256 = 2^8 bits per char.
		local mul=2^(8*(k-1))
		res[k]=math.floor(num/mul)
		num=num-res[k]*mul
	end
	assert(num==0)
	if endian == "big" then
		local t={}
		for k=1,n do
			t[k]=res[n-k+1]
		end
		res=t
	end
	return string.char(unpack(res))
end

-- copy from http://blog.csdn.net/simbi/article/details/8774376
bytesToInt = function(str, endian, signed)
	local t={str:byte(1,-1)}
	if endian=="big" then --reverse bytes
		local tt={}
		for k=1,#t do
			tt[#t-k+1]=t[k]
		end
		t=tt
	end
	local n=0
	for k=1,#t do
		n=n+t[k]*2^((k-1)*8)
	end
	if signed then
		n = (n > 2^(#t-1) -1) and (n - 2^#t) or n -- if last bit set, negative.
	end
	return n
end

safeCallBack = function(callback, ...)
	if callback and is_function(callback) then
		return callback(...)
	end
end

UTF8StrLenChangeASCLen = function(str)
	if not str then return end
	local totalLong = 0
	local len = string.len(str)
	local id = 1
	while id <= len do
		if string.byte(string.sub(str,id,id)) > 128 then
			id = id + 2
			totalLong = totalLong + 1
		end
		totalLong = totalLong + 1
		id = id + 1
	end
	return totalLong
end

-- 给window添加显示和消失的效果
addFadeAnimation = function(window, onOpen, onClose)
	if not window.btn_close and not window.btnClose then
		log("error", "no close button named btn_close or btnClose")
		-- 没有关闭按钮
		return
	end

	local closeButton = window.btn_close or window.btnClose

	window.__oldOpen = window.open
	window.__oldClose = window.close

	window.__originOffsetX = window:getOffsetX()
	window.__originOffsetY = window:getOffsetY()
	window.__originBtnOffsetX = closeButton:getOffsetX()
	window.__originBtnOffsetY = closeButton:getOffsetY()

	if window.__modelBgWnd then
		window.__originBgAlpha = window.__modelBgWnd:getAlpha()
	end

	local inFunc = modEasing.outQuint
	local outFunc = modEasing.inBack

	window.open = function(self, ...)
		if self.__modelBgWnd then
			self.__modelBgWnd:setAlpha(0)
		end
		closeButton:show(false)
		if closeButton.setSound then
			closeButton:setSound("")
		end
		self.__oldOpen(self, ...)

		-- 原始位移
		local offx, offy = self.__originOffsetX, self.__originOffsetY
		local offbx, offby = self.__originBtnOffsetX, self.__originBtnOffsetY

		if self.openCloseHdr then
			self.openCloseHdr:stop()
			self.openCloseHdr = nil
		end
		self:enableEvent(false)
		gWorld:getUIRoot():enableEvent(false)
		gWorld:getSceneRoot():enableEvent(false)

		self.openCloseHdr = runProcess(1, function()
			local totalFrame = 10

			local fromX = -self:getWidth()
			local c = offx - fromX

			for i = 0, totalFrame do
				local nx = inFunc(i, fromX, c, totalFrame)
				self:setOffsetX(nx)
				--self:setOffsetY(offy)
				closeButton:setOffsetX(-2*(nx - offx) + offbx)
				--closeButton:setOffsetY(offby)
				if i > 1 then
					closeButton:show(true)
				end
				if self.__modelBgWnd then
					local oldAlpha = self.__originBgAlpha
					local alpha = i/totalFrame * oldAlpha
					self.__modelBgWnd:setAlpha(alpha)
				end
				yield()
			end
			self:enableEvent(true)
			gWorld:getUIRoot():enableEvent(true)
			gWorld:getSceneRoot():enableEvent(true)
			safeCallBack(onOpen)

		end):update()
	end

	window.close = function(self, ...)
		if self.__modelBgWnd then
			self.__modelBgWnd:setAlpha(0)
		end

		-- 当前位移
		local cur_offx, cur_offy = self:getOffsetX(), self:getOffsetY()
		-- 原始位移
		local offx, offy = self.__originOffsetX, self.__originOffsetY
		local offbx, offby = self.__originBtnOffsetX, self.__originBtnOffsetY

		if self.openCloseHdr then
			self.openCloseHdr:stop()
			self.openCloseHdr = nil
		end

		local args = {self, ...}

		gWorld:getUIRoot():enableEvent(false)
		gWorld:getSceneRoot():enableEvent(false)
		self.openCloseHdr = runProcess(1, function()
			local totalFrame = 10

			local fromX = cur_offx
			local c = -self:getWidth() - fromX

			for i = 0, totalFrame do
				local nx = outFunc(i, fromX, c, totalFrame)
				self:setOffsetX(nx)
				closeButton:setOffsetX(-2*(nx-offx) + offbx)
				if self.__modelBgWnd then
					local oldAlpha = self.__originBgAlpha
					local alpha = (1-i/totalFrame) * oldAlpha
					self.__modelBgWnd:setAlpha(alpha)
				end

				yield()
			end

			self.__oldClose(unpack(args))
			if self.__modelBgWnd then
				local oldAlpha = self.__originBgAlpha
				self.__modelBgWnd:setAlpha(oldAlpha)
			end
			gWorld:getUIRoot():enableEvent(true)
			gWorld:getSceneRoot():enableEvent(true)
			--self.__modelBgWnd:setParent(nil)
			safeCallBack(onClose)
			self:setOffsetX(fromX)
			closeButton:setOffsetX(offbx)
		end):update()
	end
end

-- ip字符串转整数
ipToInt = function(ipStr)
	local o1,o2,o3,o4 = ipStr:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")
	local num = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
	return num
end

local units = {
	[0]="零",
	[1]="一",
	[2]="二",
	[3]="三",
	[4]="四",
	[5]="五",
	[6]="六",
	[7]="七",
	[8]="八",
	[9]="九",
}

getUnits = function(number)
	if not number or not tonumber(number) or not units[number] then return end
	return units[number]
end

local placeHolder = {
	[10]={normal="", em=""},
	[100]={normal="十", em="十"},
	[1000]={normal="百", em="百"},
	[10000]={normal="千", em="千"},
	[100000]={normal="万", em="万"},
	[1000000]={normal="十万", em="十"},
	[10000000]={normal="百万", em="百"},
	[100000000]={normal="千万", em="千"},
	[1000000000]={normal="亿", em="亿"},
	[10000000000]={normal="十亿", em="十"},
}

arabicNum2ChineseNum = function(num)
	local place2Str = function(place, emNum)
		local divider = 10
		while math.floor(place / divider) > 0 do
			divider = divider * 10
		end
		if emNum > 0 then
			return placeHolder[divider]["em"]
		else
			return placeHolder[divider]["normal"]
		end
	end

	local unit2Str = function(unit)
		return units[unit]
	end

	local rest = num
	local minor = 0
	local ret = ""
	if num == 0 then
		ret = "零"
	elseif num < 0 then
		rest = -num
		num = -num
		minor = 1
	end

	-- 1401009之类的情况
	local display_zero = 0
	local divider = 10
	local unit = rest % divider
	local em = 1
	local place = 0
	while rest > 0 do
		place = num % divider
		if unit > 0 or display_zero > 0 then
			if unit > 0 then
				ret = place2Str(place, em) .. ret
				em = 0
			end
			-- 在此考虑大于10小于20的表现方式
			if num < 10 or num >= 20 then
				ret = unit2Str(unit) .. ret
			else
				if place < 10 or place >= 20 then
					ret = unit2Str(unit) .. ret
				end
			end
		end

		if unit > 0 then
			display_zero = 1
			em = 1
		else
			display_zero = 0
			if math.floor(place / 1000000000) == 0 or math.floor(place / 100000) == 0 or math.floor(place / 10) == 0 then
				em = 0
			else
				em = 1
			end
		end
		rest = math.floor(num / divider)
		divider = divider * 10
		unit = rest % 10
	end

	if minor > 0 then
		ret = "负" .. ret
	end
	return ret
end

consolePrint = function(msg)
	local s = string.split(msg, "\n")
	local ss = table.concat(s)
	consoleLog(ss)
end

-- 在min和max之间随机cnt个不重复的数
randomNums = function(min, max, cnt)
	if cnt > max - min + 1 then
		cnt = max - min + 1
	end

	if cnt <= 0 then
		return {}
	end

	local tmp = {}
	local ret = {}
	for i = min, max do
		table.insert(tmp, i)
	end

	local total = max - min + 1
	for i = 1, cnt do
		local idx = math.random(1, total)
		table.insert(ret, tmp[idx])
		tmp[idx], tmp[total] = tmp[total], tmp[idx]
		total = total - 1
	end

	return ret
end

isSameDay = function(t1, t2)
	if not t1 or not t2 then return false end
	local lt1 = localTime(t1)
	local lt2 = localTime(t2)
	return lt1.year == lt2.year and lt1.month == lt2.month and lt1.day == lt2.day
end

getSdkServerUrlRoot = function()
	--return "http://203.195.210.174:8001/recharge/"
	--return "http://115.29.233.158:8002/recharge/"
	return "http://203.195.210.174:8002/recharge/"
end

-- arrWnds = {
--	{wnd1, wnd2},
--	{wnd3, wnd4},
--	...
-- wnd的对齐方式为左上对齐
-- }
autoAlignTextWnds = function(arrWnds, gapx, gapy)
	gapx = gapx or 0
	gapy = gapy or 0
	local row_y = {}
	local col_x = {}
	local lastSizeY = gapy
	for row_idx, wnds in ipairs(arrWnds) do
		local lastSizeX = gapx
		local maxH = 0
		for col_idx, wnd in ipairs(wnds) do
			local w, h = wnd:getWidth(), nil
			if wnd:getText() ~= "" then
				--w = wnd:getTextControl():getWidth()
				h = wnd:getTextControl():getHeight()
			else
				--w = wnd:getWidth()
				h = wnd:getHeight()
			end
			wnd:setSize(w, h)

			local x = wnd:getX()
			local y = wnd:getY()

			local idxX = col_x[col_idx] or x
			idxX = math.max(idxX, lastSizeX)
			col_x[col_idx] = idxX
			lastSizeX = idxX + w + gapx

			local idxY = row_y[row_idx] or 0
			idxY = math.max(idxY, lastSizeY)
			row_y[row_idx] = idxY
			maxH = math.max(maxH, h)
		end
		lastSizeY = row_y[row_idx] + maxH + gapy
	end

	for row_idx, wnds in ipairs(arrWnds) do
		for col_idx, wnd in ipairs(wnds) do
			wnd:setPosition(col_x[col_idx], row_y[row_idx])
		end
	end
end

makeMaintainHintStr = function(startTime, endTime)
	return sf(TEXT(149), startTime, endTime)
end

checkBlockOnLinear = function(sx, sy, dx, dy)
	local scene = gWorld:getSceneRoot()
	if sx == dx and sy == dy then
		return nil
	end

	local checkSceneRange = function(x, y)
		local sceneX, sceneY = scene:getX(), scene:getY()
		--x = sceneX + x
		y = sceneY + y
		local sw, sh = scene:getWidth(), scene:getHeight()
		return x < sw - 100 and x > 100 and y < gGameHeight - 180 and y > 50
	end

	if sx == dx then
		for i = sy, dy, (dy-sy)/math.abs(dy-sy) do
			if scene:isPosBlock(sx, i) or
				not checkSceneRange(sx, i) then
				return {sx, i}
			end
		end
	else
		local k = (dy - sy) / (dx - sx)
		local b = sy - k*sx
		for i = sx, dx, ((dx-sx)/math.abs(dx-sx))*1 do
			local j = k*i + b
			if scene:isPosBlock(i, j) or
				not checkSceneRange(i, j) then
				return {i, j}
			end
		end
	end

	return nil
end

serverLog = function(msg)
	local modRpc = import("net/rpc.lua")
	local modLogProto = import("data/proto/log_pb.lua")
	local message = modLogProto.RecordLog()
	message.log = msg
	local payload = message:SerializeToString()
	modRpc.getServiceMgr():callRpc("RpcLogService", "log", payload, nil)
end

toReadableSize = function(size)
	if size/1024/1024 > 1 then
		return sf("%.2f", size/1024/1024) .. "M"
	elseif size/1024 > 1 then
		return sf("%.2f", size/1024) .. "K"
	else
		return tostring(size)
	end
end

getGameId = function()
	local gameId = gameconfig:getConfigStr("global", "gameid", "gjxx")
	return gameId
end

milliNumToStr = function(money)
	money = tonumber(money)
	if money < 1000000 then
		return tostring(money)
	else
		return sf(TEXT(140), money / 10000.0)
	end
end

RGB2HSV = function(r, g, b)
	local minVal = math.min(math.min(r, g), b)
	local maxVal = math.max(math.max(r, g), b)
	local delta = maxVal - minVal
	local hsv = {0, 0, 0}
	hsv[2] = delta / maxVal
	hsv[3] = maxVal
	if delta ~= 0 then
		local delR = (maxVal - r) / 6.0 / delta + 0.5
		local delG = (maxVal - g) / 6.0 / delta + 0.5
		local delB = (maxVal - b) / 6.0 / delta + 0.5
		if r == maxVal then
			hsv[1] = delB - delG
		elseif g == maxVal then
			hsv[1] = delR - delB + 0.33333333333333
		else
			hsv[1] = delG - delR + 0.66666666666667
		end
		hsv[1] = hsv[1] + 6.0
	end
	return table.unpack(hsv)
end

getCurrentVersion = function()
	local agent = puppy.pUpdateAgent:instance()
	local version = nil
	if agent then
		version = agent:getClientVersion()
	end
	return version
end

compareVersion = function(tar_ver)
	local cur_ver = getCurrentVersion()
	if cur_ver then
		local tar1, tar2, tar3
		for a, b, c in string.gmatch(tar_ver, "(%d+)%.(%d+)%.(%d+)") do
			tar1 = tonumber(a)
			tar2 = tonumber(b)
			tar3 = tonumber(c)
		end
		local cur1, cur2, cur3
		for a, b, c in string.gmatch(cur_ver, "(%d+)%.(%d+)%.(%d+)") do
			cur1 = tonumber(a)
			cur2 = tonumber(b)
			cur3 = tonumber(c)
		end
		local tar_vers = {tar1, tar2, tar3}
		local cur_vers = {cur1, cur2, cur3}
		local function checkVersion (idx)
			if idx >= 3 then
				return tar_vers[3] <= cur_vers[3]
			elseif tar_vers[idx] < cur_vers[idx] then
				return true
			else
				return checkVersion(idx + 1)
			end
		end

		return checkVersion(1)

		--[[
		if tar1 > cur1 or tar2 > cur2 or tar3 > cur3 then
			return false
		else
			return true
		end
		]]--
	else
		return true
	end
end

getChannel = function()
	return gameconfig:getConfigStr("global", "channel", "weixin")
end

getOpChannel = function()
	return gameconfig:getConfigStr("global", "op_channel", "openew")
end

local gDeviceInfo = gDeviceInfo or nil

local initDeviceInfo = function()
	if not gDeviceInfo then
		local info = puppy.sys.getDeviceInfo()
		gDeviceInfo = string.split(info, "|")
	end
end

getDeviceModel = function()
	initDeviceInfo()
	return gDeviceInfo[1]
end

getDeviceOsName = function()
	initDeviceInfo()
	return gDeviceInfo[2]
end

getDeviceOsVersion = function()
	initDeviceInfo()
	return gDeviceInfo[3]
end

isDebugVersion = function()
	return gameconfig:getConfigInt("global", "debug", 0) ~= 0
end

isAppstoreExamineVersion = function()
	if isDebugVersion() and app:getPlatform() ~= "macos" then
		return true
	end
	if app:getPlatform() ~= "ios" then
		return false
	else
		local agent = puppy.pUpdateAgent:instance()
		if agent.getVersionDistance then
			return agent:getVersionDistance() < 0;
		else
			return false
		end
	end
end

isSDKPurchase = function()
	if isAppstoreExamineVersion() then
		return false
	else
--[[	local opChannelToRet = {
			openew = true,
			ds_queyue = false,
			tj_lexian = true,
			ly_youwen = true,
			yy_doudou = true,
			xy_hanshui = true,
			rc_xianle = true,
			jz_laiba = true,
			nc_tianjiuwang = true,
		}
		local opChannel = getOpChannel()
		return opChannelToRet[opChannel]]--
		local modChannelMgr = import("logic/channels/main.lua")
		return modChannelMgr.getCurChannel():isSDKPay()
	end
end

getFsRoot = function()
	local platform = app:getPlatform()
	if platform == "android" then
		return "apk:"
	elseif platform == "ios" then
		return "bundle:"
	else
		return ""
	end
end

callTelephone = function(phoneNumber)
	if puppy.sys.callTelephone then
		phoneNumber = tostring(phoneNumber)
		if phoneNumber then
			puppy.sys.callTelephone(phoneNumber)
		end
	else
		infoMessage(TEXT("请下载最新包体获取电话功能"))
	end
end

-- @param duration 毫秒
vibrateTelephone = function(duration)
	-- TODO android某些机型会crash，待查
	do return end

	duration = duration or 1000
	if puppy.sys.vibrateTelephone then
		puppy.sys.vibrateTelephone(duration)
	end
end

local fastLoadChannel = {
	tj_lexian = true,
	rc_xianle = true,
}

isFastLoadingChannel = function()
	local opChannel = getOpChannel()
	return fastLoadChannel[opChannel] ~= nil
end

__init__ = function(module)
	loadglobally(module)
end
