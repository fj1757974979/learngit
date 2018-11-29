local modMsg = import("common/ui/msgbox.lua")
local modBuilding = import("building.lua")
local modLevelData = import("td/leveldata.lua")

pLevelEditor = pLevelEditor or class(pWindow, pSingleton)

pLevelEditor.init = function(self)
	self:setParent(gWorld:getUIRoot())

	local scene = gWorld:getSceneRoot()
	local pathPoints = {}

	local createPointWnd = function(i)
		local wnd = pWindow()
		wnd:setSize(30,30)
		wnd:setParent(scene)
		wnd:setColor(0x77ff0000)
		wnd:setText(string.format("%d", i))
		wnd:setPosition(-scene:getX() + gGameWidth/2, -scene:getY() + gGameHeight/2)
		wnd:addListener("ec_mouse_drag", function(e)
			wnd:setPosition(wnd:getX() + e:dx(), wnd:getY() + e:dy())
		end)
		pathPoints[i] = wnd
		return wnd
	end

	self.btnLoad = pButton()
	self.btnLoad:setParent(self)
	self.btnLoad:setPosition(0, 100)
	self.btnLoad:setSize(150, 40)
	self.btnLoad:setText("加载路径")
	self.btnLoad:setColor(0x7700ff00)
	self.btnLoad:addListener("ec_mouse_left_up", function()
		local dataPath = string.format("data/map/%04d/path.lua", scene:getResid())
		local pathData = _import(dataPath) or {data = {}}
		for i, pointWnd in ipairs(pathPoints) do
			pointWnd:setParent(nil)
		end
		pathPoints = {}
		for i, pos in ipairs(pathData.data) do
			local wnd = createPointWnd(i)
			wnd:setPosition(pos[1], pos[2])
		end
	end)

	self.btnSave = pButton()
	self.btnSave:setParent(self)
	self.btnSave:setPosition(0, 150)
	self.btnSave:setSize(150, 40)
	self.btnSave:setText("保存路径")
	self.btnSave:setColor(0x7700ff00)
	self.btnSave:addListener("ec_mouse_left_up", function()
		local points = {}
		for i, pointWnd in ipairs(pathPoints) do
			points[i] = {pointWnd:getX(), pointWnd:getY()}
		end
		table.save(points, string.format("home/script/data/map/%04d/path.lua", scene:getResid()))
		modMsg.showMessage("保存成功!")
	end)

	self.btnAddPoint = pButton()
	self.btnAddPoint:setParent(self)
	self.btnAddPoint:setPosition(0, 200)
	self.btnAddPoint:setSize(150, 40)
	self.btnAddPoint:setText("添加路点")
	self.btnAddPoint:setColor(0x7700ff00)

	self.btnAddPoint:addListener("ec_mouse_left_up", function()
		createPointWnd(#pathPoints + 1)
	end)

	self.btnLoadLevel = pButton()
	self.btnLoadLevel:setParent(self)
	self.btnLoadLevel:setPosition(0, 250)
	self.btnLoadLevel:setSize(150,40)
	self.btnLoadLevel:setColor(0x7700ff00)
	self.btnLoadLevel:setText("加载关卡")
	self.btnLoadLevel:addListener("ec_mouse_left_up", function()
		local scene = gWorld:getSceneRoot()
		if scene.buildings then
			for i,b in ipairs(scene.buildings) do
				b:setParent(nil)
			end
		end
		scene.buildings = {}
		local levelData = _import(modLevelData.getLevelLoadPath(1))
		if levelData then
			for i,info in ipairs(levelData.data.buildings) do
				local spt = pSprite()
				spt:setParent(scene)
				spt:setPosition(info.pos[1], info.pos[2])
				spt:setTexture(info.texture, 0)
				spt:setKeyPoint(info.keyPoint[1], info.keyPoint[2])
				spt:enableEvent(true)
				spt.isEnemy = info.isEnemy
				if info.isEnemy then
					spt:setHSVAdd(0.5, 0.0, 0.0)
				end
				table.insert(scene.buildings, spt)

				local wnd = pWindow()
				wnd:setParent(spt)
				wnd:setSize(50,50)
				spt.wnd = wnd
				spt.wnd:addListener("ec_mouse_drag", function(e)
					spt:setPosition(spt:getX() + e:dx(), spt:getY() + e:dy())
				end)
			end
		end
	end)

	self.btnSaveLevel = pButton()
	self.btnSaveLevel:setParent(self)
	self.btnSaveLevel:setPosition(0, 300)
	self.btnSaveLevel:setSize(150, 40)
	self.btnSaveLevel:setColor(0x7700ff00)
	self.btnSaveLevel:setText("保存关卡")
	self.btnSaveLevel:addListener("ec_mouse_left_up", function()
		local scene = gWorld:getSceneRoot()
		local buildings = scene.buildings
		local saveTable = {}
		saveTable.buildings = {}
		for i, b in ipairs(buildings) do
			local info = {}
			info.pos = {b:getX(), b:getY()}
			info.keyPoint = {b:getKX(), b:getKY()}
			info.texture = b:getTexturePath()
			info.isEnemy = b.isEnemy
			saveTable.buildings[i] = info
		end
		table.save(saveTable, modLevelData.getLevelSavePath(1))
		modMsg.showMessage("保存成功!")
	end)

	self.btnAddBuilding = pButton()
	self.btnAddBuilding:setParent(self)
	self.btnAddBuilding:setPosition(0,350)
	self.btnAddBuilding:setSize(150, 40)
	self.btnAddBuilding:setText("添加建筑")
	self.btnAddBuilding:setColor(0x7700ff00)
	self.btnAddBuilding:addListener("ec_mouse_left_up", function()
		modBuilding.showAddBuildingPanel()
	end)

	--[[
	self.tilePanel = pWindow()
	self.tilePanel:setParent(self)
	self.tilePanel:setColor(0x7700ff00)
	self.tilePanel:enableDrag(true)
	
	self.tile = puppy.world.pTileMap()
	self.tile:setParent(self.tilePanel)
	self.tile:setTileSize(6,3)
	self.tile:loadTileSet(0, "map:tileset1/1.png")
	self.tile:loadTileSet(1, "map:tileset1/2.png")
	
	local w,h = self.tile:getTileWidth(), self.tile:getTileHeight()

	self.tilePanel:setSize(w * 3, h * 3 * 2)
	self.tilePanel:setPosition(gGameWidth - w * 3, 200)
	self.tile:setPosition(w/2, h/2 * 3)
	local x,y = 0,0

	self.selectTile = nil
	self.editTile = nil
	self.tiles = {}
	self.mapTiles = {}
	for i=0,2 do
		for j=0,2 do
			local tile = self.tile:getTile(i*3 + j)
			local w,h = tile:getWidth(), tile:getHeight()
			tile:setTileID(getTileID(0, i*3 + j))
			tile:setPosition(x + w/2 * (i+j), y + h/2 * (i-j))
			tile:addListener("ec_mouse_left_up", function()
				if self.selectTile then
					self.selectTile:setColor(0xFFFFFFFF)
				end
				tile:setColor(0xFFFF0000)
				self.selectTile = tile
				if self.editTile then
					self.editTile:setTileID(self.selectTile:getTileID())
				end
			end)
			table.insert(self.tiles, tile)

			local tile = self.tile:getTile(i*3 + j + 9)
			local w,h = tile:getWidth(), tile:getHeight()
			tile:setTileID(getTileID(1, i*3 + j))
			tile:setPosition(x + w/2 * (i+j) , y + h/2 * (i-j) + h * 3)
			tile:addListener("ec_mouse_left_up", function()
				if self.selectTile then
					self.selectTile:setColor(0xFFFFFFFF)
				end
				tile:setColor(0xFFFF0000)
				self.selectTile = tile
				if self.editTile then
					self.editTile:setTileID(self.selectTile:getTileID())
				end
			end)
			table.insert(self.tiles, tile)
		end
	end
	--]]
end

pLevelEditor.open = function(self)
	pWindow.open(self)
	self:showSelf(false)
	local scene = gWorld:getSceneRoot()
	scene:loadCfg(1001, true)
	scene:setNormalMode()

	--[[
	local tilemap = puppy.world.pTileMap()
	tilemap:setParent(scene)
	tilemap:enableDrag(true)
	tilemap:setTileSize(20,10)
	tilemap:loadTileSet(0, "map:tileset1/1.png")
	tilemap:loadTileSet(1, "map:tileset1/2.png")
	tilemap:addListener("ec_mouse_left_up", function(e)
		if self.editTile then
			self.editTile:setColor(0xFFFFFFFF)
		end
		local tile = tilemap:getCoveredTile(e:ax(), e:ay())
		if tile then tile:setColor(0xFFFF0000) end
		self.editTile = tile
	end)

	self.editMap = tilemap
	--]]
	self.onSceneMove = scene:addListener("ec_mouse_drag", function(e)
		scene:setPosition(scene:getX() + e:dx(), scene:getY() + e:dy())
	end)
end

pLevelEditor.close = function(self)
	pWindow.close(self)

	local scene = gWorld:getSceneRoot()
	if self.onSceneMove then
		scene:removeListener(self.onSceneMove)
		self.onSceneMove = nil
	end
end

showLevelEditor = function()
	pLevelEditor:instance():open()
end

hideLevelEditor = function()
	pLevelEditor:instance():close()
end
