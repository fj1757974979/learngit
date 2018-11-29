
pList = pList or class(pWindow)

pList.init = function(self)
	self:setClipDraw(true)

	self.content_ = pWindow()
	self.content_:setParent(self)
	self.content_:setColor(0x00000000)
	self.content_:setSize(0,0)
	self.content_:setAlignX(ALIGN_LEFT_RIGHT)
	self.content_:addListener("ec_mouse_drag", function(e)
		self.content_:move(0, e:dy())
		local y = self.content_:getY()
		if y > 0 then y = 0 end
		if y + self.content_:getHeight() < self:getHeight() then 
			y = - self.content_:getHeight() + self:getHeight()
		end
		self.content_:setPosition(0, y)
	end)

	self.itemWnds = {}
end

pList.pushBack = function(self, wnd)
	wnd:setParent(self.content_)
	wnd:setPosition(0, self.content_:getHeight())
	self.content_:setSize(self.content_:getWidth(), self.content_:getHeight() + wnd:getHeight())
	table.insert(self.itemWnds, wnd)
	return wnd
end

pList.clear = function(self)
	for _,wnd in ipairs(self.itemWnds) do
		wnd:setParent(nil)
	end
	self.itemWnds = {}
	self.content_:setSize(0,0)
end

__init__ = function()
	export("pList", pList)
end
