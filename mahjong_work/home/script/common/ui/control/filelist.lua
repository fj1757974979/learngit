local modUtil = import("util/util.lua")

pFileList = pFileList or class(pWindow)

pFileList.init = function(self)
	self.rootDir = nil
	self.curDir = nil
	self:load("data/ui/filelist.lua")
	self:setClipDraw(true)

	self.panel = pWindow()
	self.panel:setParent(self)
	self.panel:setColor(0x00000000)
	self.panel:addListener("ec_mouse_drag", function(e)
		self.panel:move(0, e:dy())
		local y = self.panel:getY()
		if y + self.panel:getHeight() < self:getHeight() then 
			y = - self.panel:getHeight() + self:getHeight()
		end 
		if y > 0 then y = 0 end
		self.panel:setPosition(0, y)
	end)

	-- gWorld:focus(self)
	gWorld:addHook("ec_key_up", function(e)
		local i = self.selectIndex or 1
		if e:key() == PK_DOWN then
			i = i + 1
		elseif e:key() == PK_UP then
			i = i - 1
		else
			return
		end

		if i < 1 then i = 1 end
		if i > #self.files then i = #self.files end
		
		self.selectIndex = i
		local file = self.files[self.selectIndex] 
		if io.isDir(self.rootDir .. "/" .. self.curDir .. "/" .. file) then 
			self:onDirSelect(file)
			self:onFileSelect(file, true)
		else 
			self.selectFile = self.curDir .. file
			self:onFileSelect(file, false)
		end
	end)
end

pFileList.setRootDir = function(self, rootDir)
	self.rootDir = rootDir
	self.curDir = ""
	self:update()
end

pFileList.setCurDir = function(self, dir)
	self.curDir = dir
	self:update()
end

pFileList.getCurFile = function(self)
	return self.curDir
end

pFileList.getAllFile = function(self)
	return self.files
end

pFileList.getRootDir = function(self)
	return self.rootDir
end

pFileList.onDirSelect = function(self, dir)
	if dir == "." then return end
	if dir == ".." then
		self.curDir = io.path.basename(self.curDir)
	else
		self.curDir = self.curDir .. dir .. "/"
	end
	self.selectFile = self.curDir
	self:update()
end

pFileList.setFilter = function(self, filter)
	self._filter = filter
	self:update()
end

pFileList.getSelectFile = function(self)
	return self.selectFile
end

pFileList.update = function(self, flag)
	if not self.rootDir then return end
	if not self.curDir then return end
	
	self.panel:clearChild()
	if not flag then
		self.panel:setPosition(0,0)
	end
	self.wnds = {}
	local files = io.scandir(self.rootDir.."/" .. self.curDir)
	table.insert(files, 1, "..")
	table.insert(files, 1, ".")

	local startX = self:getParam("startX")
	local startY = self:getParam("startY")
	local span = self:getParam("span")
	local w = self:getParam("w")
	local h = self:getParam("h")

	files = filter(function(file)
		if self._filter == nil or self._filter == "" then return true end

		return string.find(file, self._filter)
	end, files)

	self.files = {}
	for i,file in ipairs(files) do
		log("info", file)
		table.insert(self.files, file)
		local wnd = nil
		if io.isDir(self.rootDir .. "/" .. self.curDir .. "/" .. file) then
			wnd = pCheckButton()
			wnd:setGroup(1)
			wnd:setParent(self.panel)
			wnd:setSize(w, h)
			wnd:setColor(0x77000000)
			wnd:setPosition(startX - 10, startY )
			wnd:getTextControl():setColor(0xFF00FF00)
			wnd:getTextControl():setFontSize(14)
			wnd:setTextAlign(ALIGN_LEFT, ALIGN_MIDDLE)
			wnd:setText(file)
			wnd:getTextControl():setAlignX(ALIGN_LEFT)
			wnd:getTextControl():setFont("Heiti", 14, 0)
			wnd:addListener("ec_checked", function()
				-- self.curDir = file
				self.selectIndex = i
				self:onDirSelect(file)
				self:onFileSelect(file, true)
				--self:onMouseClick(file)
			end)
			wnd:addListener("ec_mouse_click", function()
				onMouseClickCount = onMouseClickCount or 0
				onMouseClickCount = onMouseClickCount + 1
				if onMouseClickCount >= 2 then
					self:onMouseClick(file)
				    onMouseClickCount = nil
				else
					onMouseClickCount = nil
				end
			end)
		else
			wnd = pCheckButton()
			wnd:setGroup(1)
			wnd:setParent(self.panel)
			wnd:setSize(w, h)
			wnd:setColor(0x77000000)
			wnd:setPosition(startX - 10, startY )
			wnd:setText(file)
			-- wnd:setTextAlign(ALIGN_LEFT, ALIGN_MIDDLE)
			wnd:getTextControl():setColor(0xFFFFFFFF)
			wnd:getTextControl():setAutoBreakLine(false)
			wnd:getTextControl():setFontSize(14)
			wnd:getTextControl():setAlignX(ALIGN_LEFT)
			wnd:getTextControl():setFont("Heiti", 14, 0)
			wnd:addListener("ec_checked", function()
				self.selectFile = self.curDir .. file
				self.selectIndex = i
				self:onFileSelect(file, false)
				--self:onMouseClick(file)
			end)
			wnd:addListener("ec_mouse_click",function()
				if not onMouseClickCount then
					onMouseClickCount = 0 
					onMouseClickCountLastTime = modUtil.getTime()/1000
				end
				onMouseClickCount = onMouseClickCount + 1
				local curTime = modUtil.getTime()/1000
				if curTime - onMouseClickCountLastTime > 1 then
					onMouseClickCount = nil
				end
				if onMouseClickCount and onMouseClickCount >= 2 then
					self:onMouseClick(file)
					onMouseClickCount = nil
				end
			end)  
		end
		self.wnds[wnd] = true
		startY = startY + h + span
	end

	self.panel:setSize(startX + w + startX, startY)
end
