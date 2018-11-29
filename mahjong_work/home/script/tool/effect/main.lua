local modFileList = import("common/ui/control/filelist.lua")

pEffectTool = pEffectTool or class(pWindow, pSingleton)

pEffectTool.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:load("tool/effect/template/main.lua")

	self.package = "effect:"
	self.filelist = modFileList.pFileList()
	self.filelist:setParent(self.fileWnd)
	self.filelist:setRootDir("resource/effect")
	self.filelist:setSize(self.fileWnd:getWidth(), self.fileWnd:getHeight())
	self.filelist.onFileSelect = function(fl, file, isDir)
		local path = fl:getSelectFile()	
		pathes = string.split(path, "/")
		local resid = tonumber(pathes[table.size(pathes) - 1])
		log("info", path, resid)
		--[[
		if resid then
			local playCharMagic = function()
				self.char:setResid(resid)
				self.char.__cmp_lsn = self.char:addListener("ec_armature", function(e)
					e = class_cast(pArmatureEvent, e)
					local eventType = e:eventType()
					local eventName = e:eventName()
					if eventType == "complete" then
						setTimeout(10, function()
							if self.char.__lsn then
								self.char:removeListener(self.char.__lsn)
								self.char.__lsn = nil
							end
							if self.char.__cmp_lsn then
								self.char:removeListener(self.char.__cmp_lsn)
								self.char.__cmp_lsn = nil
							end
						end)
					end
				end)
				self.char.__lsn = self.char:addListener("ec_armature", function(e)
					e = class_cast(pArmatureEvent, e)
					local eventType = e:eventType()
					local eventName = e:eventName()
					if eventName == "on_effect" or 
						eventName == "on_effect_1" or
						eventName == "on_effect_2" or 
						eventName == "on_effect_3" or 
						eventName == "on_effect_4" then
						self.spt:setTexture(self.package..fl:getSelectFile(), 0)
						self.spt:play(self.spt:getConfigRepeat(), false)
					end
				end)
				local actionName = string.sub(file, 1, 6)
				self.char:play(actionName, 1)
			end
			playCharMagic()
		else
			log("error", self.package, fl:getSelectFile(), file)
			puppy.world.pTexture.clear()
			self.spt:setTexture(self.package..fl:getSelectFile(), 0)
		end
		]]
		log("error", self.package, fl:getSelectFile(), file)
		if not isDir then
			puppy.world.pTexture.clear()
			self.spt:setTexture(self.package..fl:getSelectFile(), 0)
		end
		self:update()
	end

	--[[
	local char = pArmatureChar()
	char:setParent(self.pointWnd)
	self.char = char
	]]--
	local cell = pWindow:new()
	cell:setImage("ui:cell01.png")
	cell:setSize(200, 200)
	cell:setParent(self.pointWnd)
	cell:setAlignX(ALIGN_CENTER)
	cell:setAlignY(ALIGN_MIDDLE)
	--cell:setKeyPoint(100, 100)
	cell:setPosition(0, 0)
	cell:enableEventSelf(false)
	self.char = cell

	self.btn_character:addListener("ec_mouse_click", function()
		local dirs = io.scandir("resource/armature")
		local id = dirs[math.random(1, #dirs - 1)]
		self.char:setResid(tonumber(id))
		self.char:playAction(self:getActionName(), -1)
	end)

	local spt = pSprite()
	spt:setParent(self.char)
	spt:setPosition(100, 100)
	spt:enableEvent(true)

	self.keyPoint = pWindow()
	self.keyPoint:setParent(spt)
	self.keyPoint:setSize(20,20)
	self.keyPoint:setKeyPoint(10,10)
	self.keyPoint:setColor(0x77ff0000)
	self.keyPoint:enableDrag(true)

	local wnd = pWindow()
	wnd:setSize(2,2)
	wnd:setKeyPoint(1,1)
	wnd:setPosition(10,10)
	wnd:setColor(0xFF00FF00)
	wnd:setParent(self.keyPoint)

	self.spt = spt
	self.spt.onLoad = function()
		self.spt:setZ(self.spt:getConfigZ())
		self:update()
		self.spt:pause(self.isPause)
	end
	self.frameWnds = {}
	self.isPause = false

	self.hookKeyDown = gWorld:addHook("ec_key_down", function(e)
		log("info", "key down", e:key())
		local frame = self.spt:getCurrentFrame()
		local totalFrame = self.spt:getFrameCount()
		local key = e:key()
		if key == 1073741904 then --left
			frame = frame - 1
			if frame < 0 then frame = frame + totalFrame end
			self.spt:setFrame(frame)
		elseif key == 1073741903 then --right
			frame = frame + 1
			if frame >= totalFrame then frame = frame - totalFrame end
			self.spt:setFrame(frame)
		elseif key == 32 then
			self.spt:pause(not self.spt:isPause())
		elseif key == 13 then
			self:onSetHit()
		end
	end)

	self.updateFrame = setInterval(1, function()
		local frame = self.spt:getCurrentFrame()
		for _,wnd in ipairs(self.frameWnds) do
			wnd:setColor(0xFF00FF00)
		end
		if self.frameWnds[frame + 1] then
			self.frameWnds[frame + 1]:setColor(0xFFFF0000)
		end

		if frame == self.spt:getHitFrame() then
			self.wndHit:show(true)
		else
			self.wndHit:show(false)
		end
	end)
end

pEffectTool.getActionName = function(self)
	if self.chk_guard:isChecked() then
		return "guard"
	elseif self.chk_run:isChecked() then
		return "run"
	elseif self.chk_magic:isChecked() then
		return "magic"
	elseif self.chk_attack:isChecked() then
		return "attack"
	else
		return "stand"
	end
end

pEffectTool.onActionChange = function(self)
	self.char:playAction(self:getActionName(), -1)
end

pEffectTool.onPlay = function(self)
	self.spt:pause(false)
	self.isPause = false
end

pEffectTool.onStop = function(self)
	self.spt:pause(true)
	self.isPause = true
end

pEffectTool.onSetHit = function(self)
	local frame = self.spt:getCurrentFrame()
	self.spt:setHitFrame(frame)
end

pEffectTool.initFrames = function(self)
	local width, height = self.wndFrames:getWidth(), self.wndFrames:getHeight()
	local numFrame = self.spt:getFrameCount()
	local w = width/numFrame - 1
	self.wndFrames:clearChild()
	self.frameWnds = {}
	for i=1,numFrame do
		local wnd = pWindow()
		wnd:setParent(self.wndFrames)
		wnd:setSize(w, height)
		wnd:setPosition((w+1) * (i - 1), 0)
		wnd:setColor(0xFF00FF00)
		self.frameWnds[i] = wnd
		wnd:addListener("ec_mouse_click", function()
			self.spt:setFrame(i - 1)
		end)
	end
end

pEffectTool.update = function(self)
	self.keyPoint:setPosition(0,0)
	self.editSpeed:setText(tostring(self.spt:getSpeed()))
	self.editZ:setText(tostring(self.spt:getZ()))
	self.editRepeat:setText(tostring(self.spt:getConfigRepeat()))
	self.editIsFoot:setText(tostring(self.spt:getConfigIsFoot()))
	self:initFrames()
end

pEffectTool.onSpeedChange = function(self)
	local speed = tonumber(self.editSpeed:getText())
	self.spt:setSpeed(speed)
	self:update()
end

pEffectTool.onZChange = function(self)
	self.spt:setZ(tonumber(self.editZ:getText()))
	self:update()
end

pEffectTool.onRepeatChange = function(self)
	local repCnt = tonumber(self.editRepeat:getText())
	if repCnt then
		self.spt:setConfigRepeat(repCnt)
	end
end

pEffectTool.onIsFootChange = function(self)
	local isFoot = tonumber(self.editIsFoot:getText())
	if isFoot then
		self.spt:setConfigIsFoot(isFoot)
	end
end

pEffectTool.chooseEffect = function(self)
	self.filelist:setRootDir("resource/effect")
	self.package = "effect:"
end

pEffectTool.chooseNewEffect = function(self)
	self.filelist:setRootDir("resource/neweffect")
	self.package = "effect:"
end

pEffectTool.chooseCharacter = function(self)
	self.filelist:setRootDir("resource/armature")
	self.package = "armature:"
end

pEffectTool.onSave = function(self)
	self.spt:setConfigZ(self.spt:getZ())
	pSprite.saveConfig()

	local fileName = self.filelist:getRootDir() .. "/" .. self.filelist:getSelectFile()
	local kx,ky = self.keyPoint:getX() + self.spt:getKX(), self.keyPoint:getY() + self.spt:getKY()
	local speed = tonumber(self.editSpeed:getText())

	local ret = puppy.pImageFile.editKeyPoint(fileName, kx, ky)
	log("info", fileName, "editKeyPoint return ", ret, kx, ky)
	ret = puppy.pImageFile.editSpeed(fileName, speed)
	log("info", fileName, "editSpeed return ", ret, speed)
	
	puppy.world.pTexture.clear()
	self.filelist:onFileSelect(self.filelist:getCurFile())
end

pEffectTool.onChoose = function(self)

end

showEffectTool = function()
	pEffectTool:instance():open()
end
