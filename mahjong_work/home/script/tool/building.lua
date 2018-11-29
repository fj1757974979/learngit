-- local modLevelData = import("td/leveldata.lua")
local modMsg = import("common/ui/msgbox.lua")
local modFileList = import("common/ui/control/filelist.lua")

pBuildingEditor = pBuildingEditor or class(pWindow, pSingleton)

pBuildingEditor.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:load("tool/template/building.lua")


	self.sprite = pSprite()
	self.sprite:setParent(self.wndOri)
	self.sprite:setName("mainPart")
	self.sprite:enableEvent(true)
	self.sprite.setKeyPoint = function(spt, kx, ky)
		--self.sprite.kx = kx
		--self.sprite.ky = ky
		--self.wndKeyPoint:setPosition(kx, ky)
		pSprite.setKeyPoint(self.sprite, kx, ky)
	end
	self.sprite.setHeadPoint = function(spt, hx, hy)
		pSprite.setHeadPoint(spt, hx, hy)
		self.wndHeadPoint:setPosition(hx, hy)
	end
	--self.sprite.getKX = function(spt) return self.sprite.kx or 0 end
	--self.sprite.getKY = function(spt) return self.sprite.ky or 0 end

	self.wndOri:setRenderLayer(2)
	self.wndKeyPointShow:setRenderLayer(1)
	self.sprites = {}
	self.sprites[self.sprite:getName()] = self.sprite
	self.selectedSprite = self.sprite

	self.wndKeyPoint:setParent(self.sprite)
	self.wndKeyPoint:needSave(false)

	self.wndHeadPoint:setParent(self.selectedSprite)
	self.wndHeadPoint:setName(nil)
	
	self.filelist = modFileList.pFileList()
	self.filelist:setParent(self.wndFile)
	self.filelist:setRootDir("home/script/data/building")
	self.filelist:setSize(self.wndFile:getWidth(), self.wndFile:getHeight())
	self.filelist:setPosition(0,0)
	self.filelist.onFileSelect = function(fl, file)
		self.editSavePath:setText("data/building/"..file)
		self:loadBuilding("data/building/"..file)
	end
end

pBuildingEditor.onKeypointChange = function(self, control, event)
	self.selectedSprite:setKeyPoint(tonumber(self.editKX:getText()) or 0, tonumber(self.editKY:getText()) or 0)
end

pBuildingEditor.onHeadPointChange = function(self, control, event)
	self.selectedSprite:setHeadPoint(tonumber(self.editHeadX:getText()) or 0, tonumber(self.editHeadY:getText()) or 0)
end

pBuildingEditor.onKeypointDrag = function(self, control, event)
	self.selectedSprite:setKeyPoint(self.wndKeyPoint:getX(), self.wndKeyPoint:getY())
	self:updateProp()
end

pBuildingEditor.onLayerChange = function(self)
	self.selectedSprite:setRenderLayer(tonumber(self.editLayer:getText()))
	self:updateProp()
end

pBuildingEditor.onHeadPointDrag = function(self, control, event)
	self.selectedSprite:setHeadPoint(self.wndHeadPoint:getX(), self.wndHeadPoint:getY())
	self:updateProp()
end

pBuildingEditor.onTexturePathChange = function(self, control, event)
	self.selectedSprite:setTexture(self.editPath:getText(), 0)
	self:updateProp()
end

local checkPath = function(self)
	local path = self.editSavePath:getText()
	if not path or path == "" then 
		modMsg.showMessage("path name error!")
		return nil
	end
	return path
end

pBuildingEditor.onLoad = function(self, control, event)
	local path = checkPath(self)
	if not path then return end
	self:loadBuilding(path)
end

pBuildingEditor.loadBuilding = function(self, path)
	self.sprite:clearChild()
	self.sprite:load(path)

	self.sprites = {}
	self.sprites[self.sprite:getName()] = self.sprite
	for _,child in ipairs(self.sprite:children()) do
		child:enableEvent(true)
		child.isEnableEvent = function() return false end
		if isA(child, pSprite) then
			self.sprites[child:getName()] = child
		end
	end

	self:updateProp()
end

pBuildingEditor.onSave = function(self, control, event)
	local path = checkPath(self)
	if not path then return end
	local conf = self.sprite:toTable()
	logv("info", conf)
	table.save(conf, "home/script/" .. path)
	modMsg.showMessage(string.format("%s save success", path))
end

pBuildingEditor.onScaleChange = function(self)
	local sx,sy = tonumber(self.editSX:getText()), tonumber(self.editSY:getSY())
	self.selectedSprite:setScale(sx, sy)
end

pBuildingEditor.updateProp = function(self)
	local kx, ky = self.selectedSprite:getKX(), self.selectedSprite:getKY()
	self.wndKeyPoint:setPosition(kx,ky)
	self.wndKeyPoint:setParent(self.selectedSprite)
	self.wndHeadPoint:setParent(self.selectedSprite)
	self.editPath:setText(self.selectedSprite:getTexturePath())
	self.editKX:setText(kx)
	self.editKY:setText(ky)

	local sx, sy = self.selectedSprite:getSX(), self.selectedSprite:getSY()
	self.editSX:setText(string.format("%.2f", sx))
	self.editSY:setText(string.format("%.2f", sy))

	self.editName:setText(self.selectedSprite:getName())

	self.editHeadX:setText(self.selectedSprite:getHeadX())
	self.editHeadY:setText(self.selectedSprite:getHeadY())

	self.editLayer:setText(tostring(self.selectedSprite:getSelfRenderLayer()))

	self:updateChildren()
end

pBuildingEditor.selectSprite = function(self, name)
	self.selectedSprite = self.sprites[name]
	self:updateProp()
end

pBuildingEditor.updateChildren = function(self)
	self.wndChild:clearChild()
	local x,y = 0, 0
	local w,h = 100, 40
	local xl, yl = 10, 10
	for name, spt in pairs(self.sprites) do
		local btn = pButton()
		btn:setPosition(x, y)
		btn:setSize(w, h)
		btn:setText(name)
		btn:setParent(self.wndChild)
		btn:addListener("ec_mouse_click", function()
			self:selectSprite(name)
		end)
		x = x + w + xl
		if x + w > self.wndChild:getWidth() then
			x = 0
			y = y + h + yl
		end
	end
end

pBuildingEditor.getNewName = function(self)
	for i=1,1000 do
		if not self.sprites["part"..i] then
			return "part"..i
		end
	end
	return "part"..0
end

pBuildingEditor.onAdd = function(self)
	local spt = pSprite()
	spt:setParent(self.sprite)
	spt:setName(self:getNewName())
	spt:enableEvent(true)
	self.sprites[spt:getName()] = spt
	self.selectedSprite = spt
	self:updateProp()	
end

pBuildingEditor.onDelete = function(self)
	if self.selectedSprite ~= self.sprite then
		local name = self.selectedSprite:getName()
		self.selectedSprite:setParent(nil)
		self.sprites[name] = nil
		self.selectedSprite = self.sprite
		self:updateProp()
	end
end

showAddBuildingPanel = function()
	pBuildingPanel:instance():open()
end

showBuildingEditor = function()
	pBuildingEditor:instance():open()
end

__init__ = function()
	pBuildingEditor:updateObject()
end
