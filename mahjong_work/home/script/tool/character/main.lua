local modFileList = import("common/ui/control/filelist.lua")

pCharacterTool = pCharacterTool or class(pWindow, pSingleton)

pCharacterTool.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:load("tool/character/template/main.lua")

	self.dir = 3
	self.filelist = modFileList.pFileList()
	self.filelist:setParent(self.fileWnd)
	self.filelist:setRootDir("resource/character")
	self.filelist:setSize(self.fileWnd:getWidth(), self.fileWnd:getHeight())
	self.filelist.onDirSelect = function(fl, dir) end
	local names = {"attack", "stand", "walk"}
	self.filelist.onFileSelect = function(fl, file)
		log("info", file)
		self.curFile = file
		self.char:setResid(file)
		self.char:setDirIndex(self.dir)
		self.keyPoint:setPosition(0,0)
		self:initActions(names)
	end

	local char = pCharacter()
	--char:setDefaultAnimation("stand")
	char:setParent(self.pointWnd)
	char:setResid(1001, false)
	char:setDirIndex(self.dir)
	char:setAttSpeed(0.5)
	char:setRunSpeed(150)
	char:setTimeScale(0.4)


	self.keyPoint = pWindow()
	self.keyPoint:setParent(char)
	self.keyPoint:setSize(20,20)
	self.keyPoint:setKeyPoint(10,10)
	self.keyPoint:setColor(0x77ff0000)
	self.keyPoint:enableDrag(true)

	self.char = char
end

pCharacterTool.initActions = function(self, names)
	self.actionWnd:clearChild()
	self.actionButtons = {}
	for i,name in ipairs(names) do
		local button = pButton()
		button:setParent(self.actionWnd)
		button:setOffsetY((i - 1)*40)
		button:setSize(120, 30)
		button:setText(name)
		button:setColor(0x9934AA78)
		button:getTextControl():setFont("Heiti", 20, 0)
		button:getTextControl():setColor(0xFFFFFFFF)
		button:addListener("ec_mouse_click", function()
			self:playAction(name)
		end)
		table.push_back(self.actionButtons, button)
	end
end

pCharacterTool.playAction = function(self, action)
	self.char:play(action, -1)
	self.char.action = action
end

pCharacterTool.playEffect = function(self, path)
	local eff = pSprite()
	eff:setTexture(path, 0)
	eff:play(pSprite.getConfigRepeatByPath(path), true)
	eff:setParent(self.char)
	eff:setZ(eff:getConfigZ())
end

pCharacterTool.getCurFile = function(self)
	return self.filelist:getRootDir() .."/"..self.curFile
end

pCharacterTool.onSave = function(self)
	local action = self.char.action
	local dir = self.dir
	local fileName = self:getCurFile() .. "/" .. action .. "." .. dir.. ".fsi"
	local kx,ky = self.keyPoint:getX(), self.keyPoint:getY()
	local ret = puppy.pImageFile.editKeyPoint(fileName, kx, ky)
	log("info", fileName, "editKeyPoint return ", ret)

	puppy.world.pTexture.clear()
	self.filelist:onFileSelect(self.curFile)
	self:playAction(self.char.action)
end

local modUtil = import("util/util.lua")
pCharacterTool.onChoose = function(self)
	local wnd = pWindow()
	wnd:setParent(self)
	wnd.doLoad = function()
		--wnd.close()
		local scene = gWorld:getSceneRoot()
	modUtil.loadScene(scene,tonumber(wnd.editCharacterID:getText()),
		false,function()
				scene:setNormalMode()
				scene:setPosition(0,0)
				wnd:setParent(nil)
				self.loadWnd = nil
		self.characterId = tonumber(wnd.editCharacterID:getText())
				--self.filelist = modFileList.pFileList()
        			--self.filelist:setParent(self.fileWnd)
        			--self.filelist:setRootDir("td/character")
				log("info",self.characterId)
				self.char:setResid(self.characterId)
				self.keyPoint:setPosition(0,0)
                self.actionList:setRootDir("resource/armature/"..self.characterId)
	       end)
	end


	wnd.close = function()
		wnd:setParent(nil)
		self.loadWnd = nil	
	end
	 wnd:load("tool/character/template/choose.lua")
        self.loadWnd = wnd
end

showCharacterTool = function()
	pCharacterTool:instance():open()
end
