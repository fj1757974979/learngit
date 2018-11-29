local modMenu = import("tool/menu.lua")
local modUtil = import("td/util.lua")

pSpritePropPanel = pSpritePropPanel or class(pWindow)

pSpritePropPanel.init = function(self)
	self:load("tool/sceneeditor/template/prop.lua")
	self.editor = nil
end

pSpritePropPanel.update = function(self, spt)
	if spt.__is_anchor then
		self.editBuildType:setText(spt.buildType or "")
		self.editBuildIndex:setText(tonumber(spt.buildIndex) or 1)
	else
		self.editImagePath:setText(spt:getTexturePath())
	end
end

pSpritePropPanel.onImageChange = function(self, edit, event)
	if not self.editor.selectSpt then return end

	self.editor.selectSpt:setTexture(edit:getText(), 0)
end

pSpritePropPanel.onBuildTypeChange = function(self, edit, event)
	if not self.editor.selectAnchor then return end

	local buildType = edit:getText()
	self.editor.selectAnchor.buildType = buildType
end

pSpritePropPanel.onBuildIndexChange = function(self, edit, event)
	if not slf.editor.selectAnchor then return end

	local buildIndex = edit:getText()
	buildIndex = tonumber(buildIndex)
	if buildIndex then
		self.editor.selectAnchor.buildIndex = buildIndex
	end
end

pSceneEditor = pSceneEditor or class(pWindow, pSingleton)

pSceneEditor.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:load("tool/sceneeditor/template/mainpanel.lua")
	
	self.propPanel = pSpritePropPanel()
	self.propPanel:setParent(self)
	self.propPanel.editor = self
	self.selectSpt = nil

	self.allPosAnchor = {}
	self.allWalkPos = {}
end

pSceneEditor.select = function(self, spt)
	if spt.__is_anchor then
		self.selectAnchor = spt
	else
		self.selectSpt  = spt
	end
	self.propPanel:update(spt)
end

pSceneEditor.onLoad = function(self)
	local wnd = pWindow()
	wnd:setParent(self)
	wnd.doLoad = function()
		local scene = gWorld:getSceneRoot()
		modUtil.loadScene(scene, tonumber(wnd.editSceneID:getText()), false, function()
			scene:setNormalMode()
			scene:setPosition(0,0)
			wnd:setParent(nil)
			self.loadWnd = nil
			self.sceneId = tonumber(wnd.editSceneID:getText())
			self:cleanAllPosAnchor()
			local posConf = import(string.format("data/scene/%4d_building_pos.lua", self.sceneId))
			if posConf then
				local data = posConf.data
				for _, info in pairs(data) do
					local x, y, buildType = info[1], info[2], info[3]
					local spt = self:addPosAnchor(x, y)
					spt.buildType = buildType
					self:select(spt)
				end
			end

			posConf = import(string.format("home/script/data/scene/%4d_walk_pos.lua", self.sceneId))
			if posConf then
				local data = posConf.data
				for _, info in pairs(data) do
					local x, y = info[1], info[2]
					self:addWalkPos(x, y)
				end
			end
		end)
		--scene:loadCfg(tonumber(wnd.editSceneID:getText()), true)
	end

	wnd.close = function()
		wnd:setParent(nil)
		self.loadWnd = nil
	end
	wnd:load("tool/sceneeditor/template/load.lua")
	self.loadWnd = wnd
end

pSceneEditor.getNewName = function(self)
	local scene = gWorld:getSceneRoot()
	for i=1,1000 do
		if not scene["spt"..i] then
			return "spt"..i
		end
	end
	return "spt"..0
end

pSceneEditor.onSave = function(self)
	local wnd = pWindow()
	wnd:setParent(self)
	wnd.doSave = function()
		local scene = gWorld:getSceneRoot()
		local data = scene:toTable()
		local sceneid = tonumber(wnd.editSceneID:getText())
		table.save(data, string.format("home/script/data/scene/%4d.lua", sceneid))
		wnd:setParent(nil)
		self.saveWnd = nil
	end

	wnd.close = function()
		wnd:setParent(nil)
		self.saveWnd = nil
	end
	wnd:load("tool/sceneeditor/template/save.lua")
	self.saveWnd = wnd
end

pSceneEditor.onSaveBuildingPos = function(self)
	local data = {}
	local tmp = {}
	for _, spt in ipairs(self.allPosAnchor) do
		local buildType = spt.buildType
		if buildType and buildType ~= "" then
			if not tmp[buildType] then
				tmp[buildType] = 0
			end
			tmp[buildType] = tmp[buildType] + 1
			local indx = tmp[buildType]
			local x, y = spt:getX(), spt:getY()
			table.insert(data, {x, y, buildType, indx})
		end
	end

	if table.size(data) > 0 then
		local sceneid = self.sceneId
		table.save(data, string.format("home/script/data/scene/%4d_building_pos.lua", sceneid))
		infoMessage("保存建筑点成功！")
	else
		infoMessage("还没有添加任何有效的建筑点！")
	end

	local walkData = {}
	for _, spt in ipairs(self.allWalkPos) do
		local x, y = spt:getX(), spt:getY()
		table.insert(walkData, {x, y})
	end
	if table.size(walkData) > 0 then
		local sceneid = self.sceneId
		table.save(walkData, string.format("home/script/data/scene/%4d_walk_pos.lua", sceneid))
	end
end

pSceneEditor.cleanAllPosAnchor = function(self)
	for _, spt in ipairs(self.allPosAnchor) do
		spt:setParent(nil)
	end

	self.allPosAnchor = {}
end

pSceneEditor.addPosAnchor = function(self, x, y)
	local scene = gWorld:getSceneRoot()
	local spt = pSprite()
	spt:setTexture("ui:xingxing.png", 0)
	spt:setParent(scene)

	spt:setPosition(x, y)
	spt:enableDrag(true)
	spt:enableEvent(true)
	spt.__is_anchor = true
	spt:addListener("ec_mouse_click", function(e)
		self:select(spt)
	end)
	self:select(spt)

	table.insert(self.allPosAnchor, spt)

	return spt
end

pSceneEditor.onAddPosAnchor = function(self)
	local scene = gWorld:getSceneRoot()
	local center = scene:getViewCenter()
	self:addPosAnchor(center:x(), center:y())
end

pSceneEditor.addWalkPos = function(self, x,y)
	local scene = gWorld:getSceneRoot()
	local spt = pSprite()
	spt:setTexture("ui:chongzhi.png", 0)
	spt:setParent(scene)

	spt:setPosition(x, y)
	spt:enableDrag(true)
	spt:enableEvent(true)
	table.insert(self.allWalkPos, spt)
	return spt
end

pSceneEditor.onAddWalkPos = function(self)
	local scene = gWorld:getSceneRoot()
	local center = scene:getViewCenter()
	self:addWalkPos(center:x(), center:y())
end

pSceneEditor.onAddSprite = function(self)
	local scene = gWorld:getSceneRoot()
	local spt = pSprite()
	spt:setTexture("effect:1008.fsi", 0)
	spt:setParent(scene)
	spt:setName(self:getNewName())
	scene[spt:getName()] = spt
	
	local center = scene:getViewCenter()
	spt:setPosition(center:x(), center:y())
	spt:enableDrag(true)
	spt:enableEvent(true)
	self:select(spt)
end

pSceneEditor.show = pSceneEditor.showChild

pSceneEditor.close = function(self)
	pWindow.close(self)
	modMenu.showMenu()
end

showSceneEditor = function()
	pSceneEditor:instance():open()
end

hideSceneEditor = function()
	pSceneEditor:instance():close()
end
