pCheckButton.toTable = function(self)
	local t = pButton.toTable(self)
	if not t then return end
	t.group = self:getGroup()
	t.checkedImage = self:getCheckedImage()
	t.bindWithParent = self._bind
	return t
end

pCheckButton.fromTable = function(self, conf, root)
	pButton.fromTable(self, conf, root)
	if conf.group then
		self:setGroup(conf.group)
	end

	if conf.checkedImage then
		self:setCheckedImage(conf.checkedImage)
	end

	if conf.bindWithParent then
		self:bindWithParent()
	end
end

pCheckButton.unbindWithParent = function(self)
	local p = self:getParent()
	if self._bind and p then
		p:removeListener(self._onMouseUp)
		p:removeListener(self._onMouseDown)
		p:removeListener(self._onCheck)
		p.__text = nil
	end
	self._bind = false
end

pCheckButton.isBindWithParent = function(self)
	return self._bind
end

pCheckButton.bindWithParent = function(self)
	self._bind = true
	local p = self:getParent()
	if not p then return end

	p.__text = self
	self:enableEvent(false)
	self._normalImage = pWindow.getTexturePath(self)
	self._clickDownImage = self:getClickDownImage()
	self._checkImage = self:getCheckedImage()
	self._onMouseDown = p:addListener("ec_mouse_left_down", function(e)
		self:setImage(self._clickDownImage)
		--log("info", "left down")
		e:bubble(true)
	end)
	self._onMouseUp = p:addListener("ec_mouse_left_up", function(e)
		if p:isChecked() then
			self:setImage(self._checkImage)
			--log("error", "check image ", self._checkImage, debug.traceback())
		else
			self:setImage(self._normalImage)
			--log("error", "normal image ", self._normalImage, debug.traceback())
		end
		-- self:setImage(self._normalImage)
		--log("info", "left up")
		e:bubble(true)
	end)
	self._onCheck = p:addListener("ec_select_change", function()
		--self._normalImage = pWindow.getTexturePath(self)
		self._clickDownImage = self:getClickDownImage()
		self._checkImage = self:getCheckedImage()
		if p:isChecked() then
			self:setImage(self._checkImage)
			--log("error", "check image ", self._checkImage, debug.traceback())
		else
			self:setImage(self._normalImage)
			--log("error", "normal image ", self._normalImage, debug.traceback())
		end
		--log("info", "select change")
	end)

	self.getTexturePath = function(self)
		return self._normalImage
	end
end

pCheckButton.setNormalImage = function(self, img)
	self._normalImage = img
end

pCheckButton.setXSplit = function(self, flag)
	self:getPictureControl():setXSplit(flag)
	self:getClickDownPictureControl():setXSplit(flag)
	self:getCheckedPictureControl():setXSplit(flag)
end

pCheckButton.setYSplit = function(self, flag)
	self:getPictureControl():setYSplit(flag)
	self:getClickDownPictureControl():setYSplit(flag)
	self:getCheckedPictureControl():setYSplit(flag)
end

pCheckButton.setSplitSize = function(self, size)
	self:getPictureControl():setSplitSize(size)
	self:getClickDownPictureControl():setSplitSize(size)
	self:getCheckedPictureControl():setSplitSize(size)
end
