pButton.init = function(self)
	self:setSound("")
--	do return end
	self._left_down = self:addListener("ec_mouse_left_down", function(e)
		if e then
			e:bubble(true)
		end
		if not self.__mute_sound then
			local modSound = import("logic/sound/main.lua")
			modSound.getCurSound():playSound("sound:click1.mp3", false)
		end
		if self.__isScale then
			return
		end
		-- 缩小
		if self.__eff_bounce_back_hdr then
			self.__eff_bounce_back_hdr:stop()
			self.__eff_bounce_back_hdr = nil
		end
		self.__eff_scalex = self.__eff_scalex or self:getSX()
		self.__eff_scaley = self.__eff_scaley or self:getSY()
		local scalex = 0.85 * self.__eff_scalex
		local scaley = 0.85 * self.__eff_scaley
		self:setScale(scalex, scaley)
		local w, h = self:getWidth(), self:getHeight()
		local addOffx = w*(1 - scalex) / 2
		local addOffy = h*(1 - scaley) / 2
		self.__eff_offx = self.__eff_offx or self:getOffsetX() 
		self.__eff_offy = self.__eff_offy or self:getOffsetY()
		local alignx = self:getAlignX()
		if alignx == ALIGN_LEFT then
			self:setOffsetX(self.__eff_offx + addOffx)
		elseif alignx == ALIGN_RIGHT then
			self:setOffsetX(self.__eff_offx - addOffx)
		end
		local aligny = self:getAlignY()
		if aligny == ALIGN_TOP then
			self:setOffsetY(self.__eff_offy + addOffy)
		elseif aligny == ALIGN_BOTTOM then
			self:setOffsetY(self.__eff_offy - addOffy)
		end
	end)
	self._left_up = self:addListener("ec_mouse_left_up", function(e)
		if e then
			e:bubble(true)
		end
		if self.__isScale then
			return
		end
		-- 反弹
		if self.__eff_bounce_back_hdr then
			self.__eff_bounce_back_hdr:stop()
		end
		local modEasing = import("common/easing.lua")
		self.__eff_bounce_back_hdr = runProcess(1, function()
			local fsx = self:getSX()
			local fsy = self:getSY()
			local tsx = self.__eff_scalex
			local tsy = self.__eff_scaley
			local foffx = self:getOffsetX()
			local foffy = self:getOffsetY()
			local toffx = self.__eff_offx
			local toffy = self.__eff_offy
			local t = 10
			for i = 1, t do
				if not fsx or not tsx or not t then
					break
				end
				local sx = modEasing.outElastic(i, fsx, tsx - fsx, t)
				local sy = modEasing.outElastic(i, fsy, tsy - fsy, t)
				self:setScale(sx, sy)
				local offx = modEasing.outElastic(i, foffx, toffx - foffx, t)
				local offy = modEasing.outElastic(i, foffy, toffy - foffy, t)
				self:setOffsetX(offx)
				self:setOffsetY(offy)
				yield()
			end
			self.__eff_bounce_back_hdr = nil
		end)
	end)
end

pButton.toTable = function(self)
	local t = pWindow.toTable(self)
	if not t then return end
	t.clickDownImage = self:getClickDownImage()
	t.sound = self:getSound()
	t.bindWithParent = self._bind
	t.disableImage = self:getDisableImage()
	return t
end

pButton.unbindWithParent = function(self)
	local p = self:getParent()
	if self._bind and p then
		p:removeListener(self._onMouseUp)
		p:removeListener(self._onMouseDown)
	end
	self._bind = false
end

pButton.bindWithParent = function(self)
	self:unbindWithParent()
	self._bind = true
	local p = self:getParent()
	if not p then return end
	p.__text = self
	self:enableEvent(false)
	self._normalImage = pWindow.getTexturePath(self)
	self._clickDownImage = self:getClickDownImage()
	self._onMouseDown = p:addListener("ec_mouse_left_down", function()
		self:setImage(self._clickDownImage)
	end)
	self._onMouseUp = p:addListener("ec_mouse_left_up", function()
		self:setImage(self._normalImage)
	end)
	self.getTexturePath = function(self)
		return self._normalImage
	end
end

pButton.isBindWithParent = function(self)
	return self._bind
end

pButton.fromTable = function(self, conf, root)
	pWindow.fromTable(self, conf, root)
	if conf.clickDownImage then
		self:setClickDownImage(conf.clickDownImage)
	end

	if conf.disableImage and self.setDisableImage then
		self:setDisableImage(conf.disableImage)
	end

	local name = self:getName()
	if conf.sound then
		self:setSound(conf.sound)
	end

	if conf.bindWithParent then
		self:bindWithParent()
	end
end

pButton.setXSplit = function(self, flag)
	self:getPictureControl():setXSplit(flag)
	self:getClickDownPictureControl():setXSplit(flag)
	if self.getDisablePictureControl then
		self:getDisablePictureControl():setXSplit(flag)
	end
end

pButton.setYSplit = function(self, flag)
	self:getPictureControl():setYSplit(flag)
	self:getClickDownPictureControl():setYSplit(flag)
	if self.getDisablePictureControl then
		self:getDisablePictureControl():setYSplit(flag)
	end
end

pButton.setSplitSize = function(self, size)
	self:getPictureControl():setSplitSize(size)
	self:getClickDownPictureControl():setSplitSize(size)
	if self.getDisablePictureControl then
		self:getDisablePictureControl():setSplitSize(size)
	end
end

pButton.enable = function(self, flag)
	if flag == nil then flag = true end
	pWindow.enable(self, flag)
	self:getTextControl():enable(flag)
	self:enableEvent(flag)
	if self.__text then
		self.__text:enable(flag)
		self.__text:enableEvent(false)
	end
end

pButton.disable = function(self)
	self:enable(false)
end

pButton.muteSound = function(self, flag)
	self.__mute_sound = flag
end

pButton.isScale = function(self, iss)
	self.__isScale = iss
end
