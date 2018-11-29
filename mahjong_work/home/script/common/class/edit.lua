
pEdit.on_over_input_limit = function(self,text,input_limit)
	m_message_box.new_message(self:getWorld().ui, TEXT("输入内容已达到最大长度！"))
end

pEdit.setPasswordMode = function(self, flag)
	self:getTextControl():setPasswordMode(flag)
end

pEdit.set_max_input_number = function(self, max_number)
	self._max_input_number = tonumber(max_number) or 0
	self:set_number_mode(true)
	if not self._has_set_max_number then
		local check_func = function()
			local input_number = tonumber(self:get_text()) or 0
			if input_number > self._max_input_number then
				self:set_text(self._max_input_number)
			end
		end
		
		self._has_set_max_number = true
		self:add_listener("ec_text_change", function(e) e:bubble(false) check_func() end)
	end
end

pEdit.set_confirm_func = function(self, func)
	self:addListener("ec_unfocus",function(e)
		func(self,self:getText())
	end)
	
	self:addListener("ec_key_down",function(e)
		if e:key()==VK_RETURN then
			func(self,self:getText())
		end
	end)
end

pEdit.set_max_input_str_len = function(self, max_len)
	if app:getPlatform() == "macos" then
		local getChNum = function(text)
			local len = string.len(text)
			local chNum = 0

			for idx = 1, len do
				if string.byte(string.sub(text, idx, idx)) > 128 then
					chNum = chNum + 1
				end
			end
			return chNum
		end

		local getStrLen = function(text)
			local len = string.len(text)
			local chNum = getChNum(text)

			return len - math.floor((chNum / 3)) * 2
		end

		local getStrByLen = function(text, len)
			local id = 0
			local num = 0
			local l = 0
			for i = 1, string.len(text) do
				if string.byte(string.sub(text, i, i)) > 128 then
					l = l + 1
					id = id + 1
					if id == 3 then
						id = 0
						num = num + 1
					end
				else
					l = l + 1
					num = num + 1
				end
				if num >= len then break end
			end
			return string.sub(text, 1, l)
		end

		local checkEditText = function(wnd, text)
			local num = max_len
			if text and getStrLen(text) > num then
				infoMessage(TEXT("输入内容已达到最大长度"))

				local chNum = getChNum(text)
				local realText = getStrByLen(text, num)
				wnd:setText(realText)
			end
		end

		self:addListener("ec_key_down", function(e)
			local text = self:getText()
			checkEditText(self, text)
		end)
	else
		if self.setMaxTxtLen then
			self:setMaxTxtLen(max_len)
		end
	end
end

pEdit.fromTable = function(self, conf, root)
	pWindow.fromTable(self, conf, root)
	if conf.checkedImage ~= nil then
		self:getFocusPicture():setTexturePath(conf.checkedImage)
	end
end

pEdit.toTable = function(self)
	local t = pWindow.toTable(self)
	if not t then return end
	t.checkedImage = self:getFocusPicture():getTexturePath()
	return t
end

pEdit.getFocusImage = function(self)
	return self:getFocusPicture():getTexturePath()
end

pEdit.setCheckedImage = function(self, img)
	self:getFocusPicture():setTexturePath(img)
end

pEdit.setXSplit = function(self, flag)
	self:getPictureControl():setXSplit(flag)
	self:getFocusPicture():setXSplit(flag)
end

pEdit.setYSplit = function(self, flag)
	self:getPictureControl():setYSplit(flag)
	self:getFocusPicture():setYSplit(flag)
end

pEdit.setSplitSize = function(self, size)
	self:getPictureControl():setSplitSize(size)
	self:getFocusPicture():setSplitSize(size)
end

pEdit.setupKeyboardOffset = function(self, panel)
	local modEasing = import("common/easing.lua")
	local platform = puppy.world.app.instance():getPlatform()
	local distance = self:getY(true) + self:getHeight() + 5 - gGameHeight 

	if platform == "ios" then
		if self.__focus_lsn then
			self:removeListener(self.__focus_lsn)
		end

		local originOffset = 0
		if panel then originOffset = panel:getOffsetY() end
		local setOffset = function(y)
			if panel then
				panel:setOffsetY(y + originOffset)
			else
				gWorld:getUIRoot():setPosition(0, y)
				gWorld:getSceneRoot():setPosition(0, y)
			end
		end

		local onFocus = function()
			local curDistance = self:getY(true) + self:getHeight() + 5 - gGameHeight 
			local keyboardHeight = gWidget:get_keyboard_height()
			local desty = -keyboardHeight - curDistance

			if desty > 0 then return end

			runProcess(1, function()
				for i=0,1,0.1 do
					local y = modEasing.outQuad(i,0,desty, 1)
					setOffset(y)
					yield()
				end

				local keyboardHeight = gWidget:get_keyboard_height()
				local desty = -keyboardHeight - curDistance
				setOffset(desty)

			end)
		end
		self.__focus_lsn = self:addListener("ec_focus", function()
			onFocus()
		end)

		self.__refocus_lsn = self:addListener("ec_refocus", function()
			onFocus()
		end)
		if self.__unfocus_lsn then
			self:removeListener(self.__unfocus_lsn)
		end
		self.__unfocus_lsn = self:addListener("ec_unfocus", function()
			local keyboardHeight = gWidget:get_keyboard_height()
			local desty = -keyboardHeight - distance
			if desty > 0 then 
				setOffset(0)
				return 
			end

			runProcess(1, function()
				for i=1,0,-0.1 do
					local y = modEasing.outQuad(i,0,desty, 1)
					setOffset(y)
					yield()
				end
				setOffset(0)
			end)
		end)
	end
end
