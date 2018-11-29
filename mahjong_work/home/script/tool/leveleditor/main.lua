local modBattleField = import("td/cultivate/battlefield.lua")
local modUtil = import("td/util.lua")
local modBuildConf = import("td/cultivate/config.lua")
local modDefense = import("td/cultivate/defense.lua")
local modSavePanel = import("tool/leveleditor/savepanel.lua")
local modLoadPanel = import("tool/leveleditor/loadpanel.lua")
local modGndMgr = import("td/cultivate/ground_mgr.lua")
local modLoader = import("td/fight/loader.lua")
local modEditable = import("editable.lua")
local modTroopEditPanel = import("troop_edit_wnd.lua")
local modMenu = import("tool/menu.lua")
local modMsg = import("common/ui/msgbox.lua")

local modPrepareCell = import("td/fight/prepare/cell.lua")
local modCellMgr = import("cell_mgr.lua")

import("td/net/rpc/rpc_msg.lua")

local sceneId = 1002

local defLevelData = {
	buildings={},
	config={
		sceneid=1002,
		bornPoint={gGameWidth *2/5, gGameHeight/3}
	},
	troops={}
}

local defTroopData = {
	type=10101,
	lv=1,
	resid=30001,
	ai="",
	mathprop={
		baseHp = 100,
		baseAtt = 1,
		baseArmor = 2,
		attScope = 50,
		baseAttSpeed = 1,
		baseMoveSpeed = 75
	},
	config={
		x=0,y=0
	},
}

pLevelEditor = pLevelEditor or class(pWindow, pSingleton)

pLevelEditor.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:setSize(gGameWidth, gGameHeight)
	self:showSelf(false)
	self:setPosition(0,0)

	self.scene = gWorld:getSceneRoot()
	self.scene:setNormalMode()
	modUtil.makeSceneDrag(self.scene)
	self.scene.enableOutBound = true
	modUtil.loadScene(self.scene, sceneId, false, function(scene, aspect)
		if aspect == "block" then
			self.scene = scene
			local x, y = scene:getX(), scene:getY()
			local newX, newY = x - gGameWidth, y - gGameHeight
			scene:setPosition(newX, newY)
			self:onSceneLoadDone()
		end
	end)
end

pLevelEditor.initDS = function(self)
	self.mgr = modBattleField.pBattleFieldMgr:new()
	self.mgr.gndMgr = modGndMgr.pGroundMgr:new(self.scene)
	self.loader = modLoader.pFightLoader:new(self.scene)
	self.allTroopsObjs = {}
	if self.troopEditWnd then
		self.troopEditWnd:setParent(nil)
	end
	self.troopEditWnd = modTroopEditPanel.pTroopEditWnd:new(gWorld:getUIRoot(), self)
	self.levelData = table.clone(defLevelData)

	self:initFormation()
end

pLevelEditor.getFightFormationPos = function(self)
	-- TODO
	return {1536, 350}
end

pLevelEditor.getFightScene = function(self)
	return self.scene
end

pLevelEditor.genBornPointWnd = function(self)
	if not self.bornPointWnd then
		self.bornPointWnd = pWindow()
		self.bornPointWnd:setColor(0xffff0000)
		self.bornPointWnd:setSize(50, 50)
		self.bornPointWnd:setParent(self.scene)
		self.bornPointWnd:enableDrag(true)
		self.bornPointWnd:setZ(-500)
	end
	return self.bornPointWnd
end

pLevelEditor.onSceneLoadDone = function(self)
	self:initDS()

	self.scene:addListener("ec_mouse_click", function(e)
		-- self.mgr:resetChosenBuildObj()
	end)

	self.path = "data/level/C01L01.lua"

	self:initBuildList()

	self:initMenu()

	self:initConf()
end

pLevelEditor.getSelectTroops = function(self)
	return table.keys(self.selectTroops or {})
end

pLevelEditor.eventTroop = function(self, troop)
	troop:addListener("ec_mouse_click", function(event)
		self.selectTroops = self.selectTroops or {}

		if event and bit.band(event:ck_status(), puppy.ecks_ctrl) ~= 0 then
		else
			for t,_ in pairs(self.selectTroops) do
				t:select(false)
			end
			self.selectTroops = {}
			self.troopEditWnd:open(troop)
		end

		self.selectTroops[troop] = true
		troop:select(true)

	end)
	troop:addListener("ec_mouse_drag", function(event)
		for _,t in ipairs(self:getSelectTroops()) do
			t:move(event:dx(), event:dy())
		end
	end)
end

pLevelEditor.onDeleteBuilding = function(self, buildObj)
	local index = buildObj.__index
	table.remove(self.levelData["buildings"], index)
end

pLevelEditor.loadLevel = function(self, data)
	-- ¼ÓÔØ½¨Öþ
	self.loader:loadLevelBuildingsFromData(data["buildings"], function(buildType, buildData)
		local build = modDefense.loadBuilding(buildType, buildData, self.mgr, true)
		build:setEditMode(self)
		--modEditable.enableEdit(build)
		return build
	end)
	-- ¼ÓÔØ²¿¶Ó
	--local allTroopsObjs = self.loader:loadLevelTroopsFromData(self.levelData["troops"])
	for _, d in pairs(data["troops"]) do
		if not d.config.editFlg then
			self:addOneTroop(d)
		end
	end
	-- ¼ÓÔØ³ö±øµã
	local bornPoint = data["config"]["bornPoint"]
	if bornPoint then
		local wnd = self:genBornPointWnd()	
		wnd:setPosition(bornPoint[1], bornPoint[2])
	end
	-- ÉèÖÃ³¡¾°id
	local sceneId = data["config"]["sceneid"]
	if sceneId then
		self.conf.editSceneid:setText(string.format("%d", sceneId))
	end
	-- ¼ÓÔØbossÐÅÏ¢
	local bossName = data["config"]["bossName"]
	self.conf.editName:setText(bossName)
	local bossPhoto = data["config"]["bossPhoto"]
	self.conf.editPhoto:setText(bossPhoto)
	local bossLevel = data["config"]["bossLevel"]
	self.conf.editLevel:setText(tostring(bossLevel))
	-- ¼ÓÔØ²¼Õó
	local formation = data["formation"]
	if formation then
		self.cellMgr:importCells(formation)
	end
	-- ²¼ÕóÎ»ÖÃ
	local formationPos = data["formationPos"]
	if formationPos then
		self.cellMgr:adjustFormationPos(formationPos[1], formationPos[2])
	end
end

pLevelEditor.initFormation = function(self)
	if self.cellMgr then
		self.cellMgr:clean()
	end
	self.cellMgr = modCellMgr.pCellMgr:new(self)
	self.cellMgr:importCells({})
end

pLevelEditor.initBuildList = function(self)
	self.buildList = pWindow()
	self.buildList:setParent(self)
	self.buildList:load("tool/leveleditor/template/building_list.lua")

	local allBuildData = modBuildConf.getAllBuildInitInfo()
	local index = 1
	for t, data in pairs(allBuildData) do
		if modDefense.isDefenseBuildType(t) then
			local wnd = self.buildList["bWnd"..tostring(index)]
			local x, y = wnd:getX(), wnd:getY()
			local w, h = wnd:getWidth(), wnd:getHeight()
			local templateId = data["templateId"]
			wnd:load(templateId)
			wnd:clearChild()
			wnd:setPosition(x, y)
			wnd:setSize(w, h)
			wnd.buildType = t
			wnd:addListener("ec_mouse_click", function(e)
				self:onClickBuildList(e, wnd)
			end)
			index = index + 1
		end
	end

	for i=index,10 do
		local wnd = self.buildList["bWnd"..tostring(i)]
		wnd:setParent(nil)
		self.buildList["bWnd"..tostring(i)] = nil
	end
end

pLevelEditor.initMenu = function(self)
	self.menu = pWindow()
	self.menu:setParent(self)
	local loadLevel = function(path)
		self.path = path
		local levelData = _import(path)
		if not levelData then
			infoMessage(TEXT("加载关卡出错!"))
			return 
		end

		for k, v in pairs(levelData.data) do
			self.levelData[k] = v
		end
		--modUtil.loadScene(self.scene, self.levelData["config"]["sceneid"] or sceneId, false, function(scene, aspect)
		local sceneId = 1000 + math.random(2,3)
		modUtil.loadScene(self.scene, sceneId, false, function(scene, aspect)
			if aspect == "block" then
				--logv("info", self.levelData)
				self.bornPointWnd = nil
				self:initFormation()
				self:loadLevel(self.levelData)
			end
		end)
	end

	self.menu.getPath = function(_)
		local type = self.menu.editType:getText()
		local c = tonumber(self.menu.editChapter:getText()) or 0
		local l = tonumber(self.menu.editLevel:getText()) or 0
		local w = tonumber(self.menu.editWave:getText()) or 0
		return string.format("data/level/%s%02dL%02dW%02d.lua", type, c, l,  w)
	end

	self.menu.onLoad2 = function(menu, btn, event)
		self:initDS()
		loadLevel(self.menu:getPath())
	end

	self.menu.onLoad = function(menu, btn, event)
		self:initDS()
		-- ¼ÓÔØ¹Ø¿¨
		modLoadPanel.showLoadPanel(self.path, loadLevel)
	end

	self.menu.onSave2 = function(menu, btn, event)
		self:updateLevelData()
		table.save(self.levelData, "home/script/" .. self.menu:getPath())
		modMsg.showMessage(string.format("%s保存成功", self.menu:getPath()))
	end

	self.menu.onSave = function(menu, btn, event)
		self:updateLevelData()
		modSavePanel.showSavePanel(self.levelData, self.path)
	end
	self.menu.onNew = function(menu, btn, event)
		-- ÐÂ½¨¹Ø¿¨
		self:initDS()
		self.levelData = table.clone(defLevelData)
		modUtil.loadScene(self.scene, 1002, false, function(scene, aspect)
			if aspect == "block" then
			end
		end)
		self.bornPointWnd = nil
	end
	self.menu.onClose = function(menu, btn, event)
		-- ¹Ø±Õ
		self:initDS()
		self:close()
		self.bornPointWnd = nil
		self.levelData = table.clone(defLevelData)
	end
	self.menu:load("tool/leveleditor/template/menu.lua")
end

pLevelEditor.updateLevelData = function(self)
	-- ±£´æ¹Ø¿¨
	local sceneId = self.conf.editSceneid:getText()
	sceneId = tonumber(sceneId)
	if sceneId then
		self.levelData["config"]["sceneid"] = sceneId
	end
	if self.bornPointWnd then
		local x, y = self.bornPointWnd:getX(), self.bornPointWnd:getY()
		self.levelData["config"]["bornPoint"] = {x, y}
	end
	local troopsData = {}
	for obj, _ in pairs(self.allTroopsObjs) do
		obj.data.config.x = obj:getX()
		obj.data.config.y = obj:getY()
		table.insert(troopsData, obj.data)
	end

	if self.cellMgr then
		local formation = self.cellMgr:exportCells()
		self.levelData.formation = formation 
		local x, y = self.cellMgr:getFormationPos()
		if x and y then
			self.levelData.formationPos = {x, y}
		end
	end

	self.levelData.troops = troopsData
end

pLevelEditor.initConf = function(self)
	self.conf = pWindow()
	self.conf:setParent(self)
	self.conf.defResId = "20011"
	self.conf.onAddTroop = function(menu, btn, event)
		-- Ôö¼Ó±ø
		local pos = modUtil.getCurScreenCenterPoint()
		local data
		if self.copyData then
			data = table.clone(self.copyData)
		else
			data = table.clone(defTroopData)
		end
		data.config.x = pos[1]
		data.config.y = pos[2]
		self:addOneTroop(data)
	end
	self.conf.onSetBornPoint = function(menu, btn, event)
		-- ÉèÖÃ³öÉúµã
		self:genBornPointWnd()
		local x, y = unpack(modUtil.getCurScreenCenterPoint())	
		self.bornPointWnd:setPosition(x, y)
	end
	self.conf.onLoadScene = function(menu, btn, event)
		-- ÉèÖÃ¹Ø¿¨³¡¾°
		local sceneId = self.conf.editSceneid:getText()
		sceneId = tonumber(sceneId)
		if not sceneId then 
			return
		end
		modUtil.loadScene(self.scene, sceneId, false, nil)
		self.bornPointWnd = nil
	end
	self.conf.setBossName = function(menu, editor, event)
		local name = editor:getText()
		self.levelData["config"]["bossName"] = name
	end
	self.conf.setBossPhoto = function(menu, editor, event)
		local photo = editor:getText()
		self.levelData["config"]["bossPhoto"] = photo
	end
	self.conf.setBossLevel = function(menu, editor, event)
		local level = editor:getText()
		level = tonumber(level)
		self.levelData["config"]["bossLevel"] = level
	end
	self.conf:load("tool/leveleditor/template/config.lua")
end

pLevelEditor.addOneTroop = function(self, data)
	local troop = self.loader:loadOneTroopFromData(data)
	troop.data = data
	local config = data.config
	local x, y = config.x, config.y
	troop:setPosition(x, y)
	troop:setID(modUtil.newPlayerID())
	--troop:enableDrag(troop)
	self:eventTroop(troop)
	self.scene:addPlayer(troop)
	self.allTroopsObjs[troop] = true
end

local currentFakeBuildObj = nil

pLevelEditor.onClickBuildList = function(self, e, wnd)
	if currentFakeBuildObj then
		e:bubble(true)
		return
	end

	self.mgr:resetChosenBuildObj()

	local buildType = wnd.buildType
	local buildInitData = self.mgr:getNewBuildingData(buildType, 1)
	buildInitData.buildType = buildType
	buildInitData.level = 1
	-- ÆÁÄ»ÖÐÐÄµã
	local pos0 = modUtil.getCurScreenCenterPoint()
	local pos = self.mgr:getGndMgr():findCellPoint(pos0)
	buildInitData.x = pos[1]
	buildInitData.y = pos[2]

	currentFakeBuildObj = modDefense.pFakeBuild:new(buildInitData, self.mgr)

	currentFakeBuildObj:regParentMoveOk(function()
		local pos = currentFakeBuildObj:getCurPosition()
		currentFakeBuildObj:destroy()
		currentFakeBuildObj = nil
		buildInitData.x = pos[1]
		buildInitData.y = pos[2]
		--self.mgr:createNewBuilding(buildData)
		self.loader:loadOneBuildingFromData(buildType, buildInitData, function(t, data)
			local obj = modDefense.loadBuilding(buildType, buildInitData, self.mgr, true)
			obj.sprite:setParent(self.scene)
			obj:setEditMode(self)
			--modEditable.enableEdit(obj)
			return obj
		end)

		table.insert(self.levelData["buildings"], buildInitData)
	end)
	currentFakeBuildObj:regParentMoveCancel(function()
		currentFakeBuildObj:destroy()
		currentFakeBuildObj = nil
	end)
	currentFakeBuildObj:setState(BUILDING_STATE_DOWN)
	currentFakeBuildObj.sprite:setZ(-100)
end

pLevelEditor.open = function(self)
	self:showChild(true)
end

pLevelEditor.close = function(self)
	self:showChild(false)
	modMenu.showMenu()
end

showLevelEditor = function()
	pLevelEditor:instance():open()
end

hideLevelEditor = function()
	pLevelEditor:instance():close()
end
