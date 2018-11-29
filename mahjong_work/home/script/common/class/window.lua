--import("template.lua")
local m_const = import("common/const.lua")
local m_statistics = import("common/statistics.lua")

pWindow.isDebug = function(self, flag)
	if flag then
		self:setColor(0x9900FF00)
	end
end

pWindow.toggle = function(self)
	if self:isOpen() then
		self:close()
	else
		self:open()
	end
end

pWindow.open = function(self)
	self:bringTop()
	if self:isOpen() and self:isShow() then return end
	self.isOpen_ = true
	self:show(true)
end

pWindow.isOpen = function(self)
	return self.isOpen_
end

pWindow.close = function(self)
	self.isOpen_ = false
	self:show(false)
	return
end

pWindow.setImage = function(self, path)
	self:getPictureControl():setTexturePath(path)
	-- self:getPictureControl():setAlphaTexturePath("ui:nsg_photo_alpha.png")
end

pWindow.getTexturePath = function(self)
	return self:getPictureControl():getTexturePath()
end

initWindow = function(btn, config)
	btn:setPosition(config.position[1], config.position[2])
	btn:setSize(config.size[1], config.size[2])
	btn:setImage(config.image)
end

initButton = function(btn, config)
	btn:setPosition(config.position[1], config.position[2])
	btn:setSize(config.size[1], config.size[2])
	btn:setImage(config.image)
	if config.clickDownImage then
		btn:setClickDownImage(config.clickDownImage)
	end
	if config.checkedImage then
		btn:setCheckedImage(config.checkedImage)
	end
end

initText = function(txt, config)
	txt:setPosition(config.position[1], config.position[2])
	txt:setColor(config.color)
	txt:setFontSize(config.fontSize)
end

getTextControl = getTextControl or pWindow.getTextControl
pWindow.getTextControl = function(self)
	return class_cast(pText, getTextControl(self))
end

pWindow.setText = function(self, txt)
	self:getTextControl():setText(txt)
end

pWindow.setTextAlign = function(self, alignX, alignY)
	self:getTextControl():setAlignX(alignX)
	self:getTextControl():setAlignX(alignY)
end

pWindow.setXSplit = function(self, flag)
	self:getPictureControl():setXSplit(flag)
end

pWindow.setYSplit = function(self, flag)
	self:getPictureControl():setYSplit(flag)
end

pWindow.setSplitSize = function(self, size)
	self:getPictureControl():setSplitSize(size)
end

pWindow.setTextColor = function(self, color)
	self.__txtColor = color
	self:getTextControl():setColor(color)
end

pWindow.setFont = function(self, font, size, bold)
	bold = bold or 10
	self:getTextControl():setFont(font, size, bold) 
end

oldEnable = oldEnable or pWindow.enable
pWindow.enable = function(self, flag)
	if flag == nil then flag = true end
	oldEnable(self, flag)
	if self.__txtColor then
		self:getTextControl():setColor(self.__txtColor)
	end
end

pWindow.disable = function(self)
	oldEnable(self, false)
	self.__txtColor = self.__txtColor or self:getTextControl():getColor()
	self:getTextControl():setColor(0xFF777777)
end

getWindowTable = function(self)
	local t = {}
	t.text = self:getText()
	t.textColor = self:getTextControl():getColor()
	t.autoBreakLine = self:getTextControl():isAutoBreakLine()
	t.textEdgeDistance = self:getTextControl():getEdgeDistance()
	t.textShadowColor = self:getTextControl():getShadowColor()
	t.textStrokeColor = self:getTextControl():getStrokeColor()
	t.textFontSize = self:getTextControl():getFontSize()
	t.textFontType = self:getTextControl():getFontType()
	t.textFontBold = self:getTextControl():getFontBold()
	t.textAlignX = self:getTextControl():getAlignX()
	t.textAlignY = self:getTextControl():getAlignY()
	t.splitImage = {self:getPictureControl():isXSplit(), 
			      self:getPictureControl():isYSplit(), 
			      self:getPictureControl():getSplitSize(),}
	t.rotZ = self:getRot()
	t.texturePath = self:getTexturePath()
	return t
end

pWindow.toTable = function(self)
	local t = pObject.toTable(self)
	if not t then return end
	local selfTable = getWindowTable(self)
	pWindow.emptyWindow = pWindow.emptyWindow or pWindow()
	local emptyTable = getWindowTable(pWindow.emptyWindow)
	for k,v in pairs(selfTable) do
		if emptyTable[k] ~= v then
			t[k] = v
		end
	end
	return t
end

pWindow.fromTable = function(self, conf, root)
	pObject.fromTable(self, conf, root)

	pWindow.emptyWindow = pWindow.emptyWindow or pWindow()
	local emptyTable = getWindowTable(pWindow.emptyWindow)
	for k,v in pairs(emptyTable) do
		if conf[k] == v then
			conf[k] = nil
		end
	end

	if conf.text and conf.text ~= ""then
		self:setText(conf.text)
	end
	if conf.textColor ~= nil and conf.textColor ~= 0 then
		self:getTextControl():setColor(conf.textColor)
	end
	if conf.autoBreakLine ~= nil then
		pText.setAutoBreakLine(self:getTextControl(), conf.autoBreakLine)
	end

	if conf.textEdgeDistance ~= nil then
		self:getTextControl():setEdgeDistance(conf.textEdgeDistance)
	end
	if conf.textShadowColor ~= nil then
		self:getTextControl():setShadowColor(conf.textShadowColor)
	end

	if conf.textStrokeColor ~= nil then
		self:getTextControl():setStrokeColor(conf.textStrokeColor)
	end
	if conf.textFontSize ~= nil then
		self:getTextControl():setFontSize(conf.textFontSize)
	end
	
	if conf.textFontType ~= nil then
		local txtControl = self:getTextControl()
		self:getTextControl():setFont(conf.textFontType, txtControl:getFontSize(), 0)
	end

	if conf.textFontBold ~= nil then
		self:getTextControl():setFontBold(conf.textFontBold)
	end
	
	if conf.textAlignX ~= nil then
		self:getTextControl():setAlignX(conf.textAlignX)
	end
	if conf.textAlignY ~= nil then
		self:getTextControl():setAlignY(conf.textAlignY)
	end

	if conf.texturePath ~= nil and conf.texturePath ~= "" then
		self:setImage(conf.texturePath)
	end

	if conf.splitImage then
		self:setXSplit(conf.splitImage[1])
		self:setYSplit(conf.splitImage[2])
		self:setSplitSize(conf.splitImage[3])
	end

	if conf.rotZ ~= nil then
		self:setRot(0, 0, conf.rotZ)
	end
end

pWindow.setCoverSize = function(self, coverW, coverH)
	local dx, dy = 0, 0
	if coverW then
		local w = self:getWidth()
		dx = (coverW - w) / 2
	end

	if coverH then
		local h = self:getHeight()
		dy = (coverH - h) / 2
	end

	self:setCoverBox(-dx, -dy, dx, dy)
end

pWindow.setToImgHW = function(self, callback)
	local img = self:getTexturePath()
	if img then
		local spt = pSprite:new()
		spt:setTexture(img, 0)
		self.hdr = runProcess(1, function()
			while true do
				local w, h = spt:getWidth(), spt:getHeight()
				if w > 0 and h > 0 then
					self:setSize(w, h)
					break
				end
				yield()
			end
			self.hdr = nil
			if callback then
				callback()
			end
		end)
	else
		if callback then
			callback()
		end
	end
end

-- 自动包裹内容
-- 并且对齐方式为左上对齐
-- 子节点和self的k点都必须为（0，0）(FIXME)
pWindow.wrapContent = function(self, children, borderX, borderY, fixWidth, fixHeight)
	if fixWidth and fixHeight then
		return
	end
	if table.size(children) <= 0 then
		return
	end
	borderX = borderX or 0
	borderY = borderY or 0
	local minx, miny = 1/0, 1/0
	local width = self:getWidth()
	local height = self:getHeight()
	local maxSizeX = 0
	local maxSizeY = 0
	for _, obj in pairs(children) do
		local x, y = obj:getX(), obj:getY()
		local w, h = obj:getWidth(), obj:getHeight()
		minx = math.min(minx, x)
		miny = math.min(miny, y)

		maxSizeX = math.max(maxSizeX, x + w)
		maxSizeY = math.max(maxSizeY, y + h)
	end

	local finalW = self:getWidth()
	local finalH = self:getHeight()
	if not fixWidth then
		finalW = maxSizeX + 2*borderX - minx
	end
	if not fixHeight then
		finalH = maxSizeY + 2*borderY - miny
	end
	self:setSize(finalW, finalH)
end
----------------------------------------------------

pBatchWindow.open = pWindow.open
pBatchWindow.isOpen = pWindow.isOpen 
pBatchWindow.close = pWindow.close
pBatchWindow.getTextControl = pWindow.getTextControl
pBatchWindow.setText = pWindow.setText
pBatchWindow.setTextAlign = pWindow.setTextAlign
pBatchWindow.setXSplit = function(self, flag)
end
pBatchWindow.setYSplit = function(self, flag)
end
pBatchWindow.setSplitSize = function(self, size)
end
pBatchWindow.setTextColor = pWindow.setTextColor
pBatchWindow.setFont = pWindow.setFont
pBatchWindow.enable = pWindow.enable
pBatchWindow.disable = pWindow.disable
pBatchWindow.toTable = pWindow.toTable
pBatchWindow.fromTable = pWindow.fromTable
pBatchWindow.setCoverSize = pWindow.setCoverSize
pBatchWindow.setToImgHW = pWindow.setToImgHW
----------------------------------------------------
-- 窗口的打开和关闭为栈的关系
-- 后一个窗口打开将隐藏前一个窗口；关闭则显示前一个窗口

gAllStackWnds = gAllStackWnds or {} --new_weak_table()

pStackWindow = pStackWindow or class(pWindow)

pStackWindow.open = function(self)
	pWindow.open(self)
	local count = #gAllStackWnds
	log("info", count)
	if count > 0 then
		local lastWnd = gAllStackWnds[count]
		if lastWnd == self then
			return
		end
		lastWnd:show(false)
	end
	for _, wnd in ipairs(gAllStackWnds) do
		if wnd == self then
			return
		end
	end
	table.insert(gAllStackWnds, self)
end

pStackWindow.close = function(self)
	pWindow.close(self)
	table.remove(gAllStackWnds, #gAllStackWnds)
	local count = #gAllStackWnds
	log("info", count)
	if count > 0 then
		local lastWnd = gAllStackWnds[count]
		lastWnd:show(true)
	end
end

----------------------------------------------------
__init__ = function()
	export("initButton", initButton)
	export("initText", initText)
	export("initWindow", initWindow)
	export("pStackWindow", pStackWindow)
end
