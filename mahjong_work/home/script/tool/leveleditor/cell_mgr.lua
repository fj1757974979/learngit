local modCastle = import("td/cultivate/castle.lua")
local modEasing = import("common/easing.lua")
local modCellMgr = import("td/fight/prepare/cell_mgr.lua")
local modPrepareCell = import("td/fight/prepare/cell.lua")
local modCellMenu = import("td/fight/prepare/cell_menu.lua")
local modTroopsMgr = import("td/cultivate/troops_mgr.lua")
local modTroop = import("td/cultivate/troop.lua")
local modCultivateConf = import("td/cultivate/config.lua")
local modUtil = import("td/util.lua")
local modCellTroopWnd = import("cell_troop_wnd.lua")
local modCellGeneralWnd = import("cell_general_wnd.lua")

pTroopsMgr = pTroopsMgr or class(modTroopsMgr.pTroopsMgr)

pTroopsMgr.loadAllTroops = function(self)
	self.allTroops = {}
	local allTroopConf = modCultivateConf.getAllTroopInitInfo()
	for t, conf in pairs(allTroopConf) do
		if modTroop.isValidTroopType(t) then
			local data = self:getNewTroopData(t, 1)
			data.troopType = t
			local obj = modTroop.newTroop(t, data)
			self.allTroops[t] = obj
			obj:modifyTroopCount(999)
		end
	end
end
------------------------------------------------------------

pCell = pCell or class(modPrepareCell.pPrepareCell)

pCell.init = function(self, w, h, x, y, parent, troopsMgr, cellMgr, cellIndex)
	self.offset = -w/4
	modPrepareCell.pPrepareCell.init(self, w, h, x, y, parent, troopsMgr, cellMgr, cellIndex)
	self.generalPosition = {20 - cellMgr:getCellXDiff()/3, h/2}
	-- 默认的功能菜单大小
	self.funcWndSize = {150, 150}
	self.functionWnds = {}
	self.keyToFuncWnd = {}

	self:genDefaultFuncWnds()
end

pCell.isEmptyCell = function(self)
	return false
end

pCell.destroy = function(self)
	for _, funcWnd in pairs(self.functionWnds) do
		funcWnd:setParent(nil)
	end
	self.functionWnds = {}
	modPrepareCell.pPrepareCell.destroy(self)
end

pCell.createFuncWnd = function(self, img, msg, w, h)
	local wnd = pButton()
	wnd:setSize(w, h)
	wnd:setImage(img)
	wnd:setClickDownImage(img)
	wnd:setKeyPoint(w/2,h/2)
	wnd.process = runProcess(2, function()
		local skip = math.random(20)
		for i=0,skip do
			yield()
		end

		while true do
			for i = 1.02, 0.98, -0.003 do
				wnd:setScale(i, 2 - i)
				yield()				
			end
			for i = 1.02, 0.98, -0.003 do
				wnd:setScale(2-i, i)
				yield()
			end
		end
	end)
	wnd.process:release()

	wnd.muteTaskId = {}
	wnd.canShow = function()
		return true
	end

	return wnd
end

pCell.genDefaultFuncWnds = function(self)
	local wnd = self:createFuncWnd("ui:buff9.png", "调兵", self.funcWndSize[1], self.funcWndSize[2])
	wnd:addListener("ec_mouse_click", function()
		self:onClickLayoutTroop()
	end)
	table.insert(self.functionWnds, wnd)
	self.keyToFuncWnd["diaobing"] = wnd

	wnd = self:createFuncWnd("ui:buff10.png", "遣将", self.funcWndSize[1], self.funcWndSize[2])
	wnd:addListener("ec_mouse_click", function()
		self:onClickLayoutGeneral()
	end)
	table.insert(self.functionWnds, wnd)
	self.keyToFuncWnd["qianjiang"] = wnd
end

pCell.onClickLayoutTroop = function(self)
	self:hideMenu()
	modCellMenu.getCellMenu():open(self)
end

pCell.onClickLayoutGeneral = function(self)
	self:hideMenu()
	modGeneralPrepareMenu.open(self)	
end

pCell.onCloseMenu = function(self)
	if self.cellMgr:getChosenCell() == self then
		self:setState(PREPARE_CELL_STATE_CHOSEN)
	end
end

pCell.getPosition = function(self)
	local x, y = self:getX(), self:getY()

	local parent = self:getParent()
	local px, py = parent:getX(), parent:getY()

	return x + px, y + py
end

pCell.showMenu = function(self)
	if self:isHeroCell() then
		return
	end

	local allWnds = self.functionWnds
	local cnt = table.size(allWnds)
	if cnt <= 0 then
		return 
	end
	local w = self.funcWndSize[1]
	local h = self.funcWndSize[2]
	local kx = w/2
	local ky = h/2
	local gap = 5
	local totalW = cnt*w + (cnt-1)*gap
	local startX = (gGameWidth - totalW) / 2 + kx
	local startY = gGameHeight - (h - ky) - 20
	local ox, oy = startX, startY
	local parent = gWorld:getUIRoot()
	local startFadeInProcess = function(wndObj, finalX, finalY, duration, isLast)
		wndObj:setPosition(finalX, gGameHeight)
		local x = wndObj:getX() 
		local y = wndObj:getY()
		local c = y - finalY
		local t = 1
		local origin = y
		local finalAlpha = 255
		local startAlpha = 0
		local alphaDelta = (finalAlpha - startAlpha) / duration
		local a = startAlpha 
		wndObj.fadeInProcess = setInterval(1, function()
			if y <= finalY or t > duration then
				y = finalY
				a = finalAlpha
				if wndObj.fadeInProcess then
					wndObj.fadeInProcess:stop()
					wndObj.fadeInProcess = nil
				end
			else
				y = modEasing.outQuad(t, origin, c, duration)
				y = 2 * gGameHeight - y
				t = t + 1
				a = a + alphaDelta
			end
			wndObj:setPosition(x, y)
			wndObj:setAlpha(a)
		end)
	end
	local du = 5
	local idx = 1
	for _, wnd in ipairs(allWnds) do
		if wnd.fadeInProcess then
			wnd.fadeInProcess:stop()
		end
		if wnd.fadeOutProcess then
			wnd.fadeOutProcess:stop()
		end
		local x, y = startX, startY
		wnd:setParent(parent)
		wnd:show(true)
		startX = startX + w + gap
		if idx == cnt then
			startFadeInProcess(wnd, x, y, du, true)
		else
			startFadeInProcess(wnd, x, y, du, false)
		end
		du = du + 2
		idx = idx + 1
	end
end

pCell.hideMenu = function(self)
	if self:isHeroCell() then
		return
	end

	local allWnds = self.functionWnds
	local cnt = table.size(allWnds)
	if cnt <= 0 then
		return 
	end
	local startFadeOutProcess = function(wndObj, finalX, finalY, duration)
		local x = wndObj:getX() 
		local y = wndObj:getY()
		local c = finalY - y
		local t = 1
		local origin = y
		local finalAlpha = 0
		local startAlpha = 255 
		local alphaDelta = math.abs(finalAlpha - startAlpha) / duration
		local a = startAlpha 
		wndObj.fadeOutProcess = setInterval(1, function()
			if y >= finalY or t > duration then
				if wndObj.fadeOutProcess then
					wndObj.fadeOutProcess:stop()
					wndObj.fadeOutProcess = nil
				end
				wndObj:show(false)
			else
				y = modEasing.outQuad(t, origin, c, duration)
				wndObj:setPosition(x, y)
				wndObj:setAlpha(a)
				t = t + 1
				a = a - alphaDelta
			end
		end)
	end
	local du = 3
	for _, wnd in ipairs(allWnds) do
		if wnd.fadeInProcess then
			wnd.fadeInProcess:stop()
		end
		if wnd.fadeOutProcess then
			wnd.fadeOutProcess:stop()
		end
		startFadeOutProcess(wnd, wnd:getX(), gGameHeight, du)
		du = du + 2
	end
end
pCell.layoutTroopsFromData = function(self, data, num)
	local size = self:getSize()
	if num > size then
		log("error", "get num big than ", size)
		num = size
	end

	self:cleanTroops()
	if num <= 0 then
		self.troopData = nil
		return
	end

	self.troopData = data
	for i=1,num do
		local pos = self.positions[i]
		local troop = self.loader:loadOneTroopFromData(data)
		troop:setParent(self)
		troop:setPosition(pos[1], pos[2])
		table.insert(self.troops, troop)
	end

	if self.general then
		self.general.cellTroops = self.troops
	end
end

--[[
--pCell.layoutHeroFromData = function(self, data)
	self:cleanTroops()
	if self.general then
		self.general:setParent(nil)
		self.general = nil
	end
	if self.hero then
		self.hero:setParent(nil)
		self.hero = nil
	end
	self.heroData = data
	local hero = self.loader:loadHeroFromData(data)
	local pos = self.positions[5]
	hero:setParent(self)
	hero:setPosition(pos[1], pos[2])

	self.hero = hero
end
]]--

pCell.layoutGeneralFromData = function(self, gtype, data)
	if self.general then
		self.general:setParent(nil)
		self.general = nil
	end
	if not gtype then 
		self.generalType = nil
		self.generalData = nil
		return 
	end
	local general = self.loader:loadGeneralFromData(gtype, data)
	if general then
		self.generalData = data
		local x = self.generalPosition[1]
		local y = self.generalPosition[2]
		general:setParent(self)
		general:setPosition(x, y)
		self.general = general
		self.generalType = gtype
		self.general.cellTroops = self.troops
		-- 小兵欢呼
		if self.troops then
			for _, troop in pairs(self.troops) do
				troop:playAction("victory", 2, false)
			end
		end
	else
		infoMessage("info", string.format("武将类型错误：%s", gtype))
	end
end

pCell.getTroopsData = function(self)
	return self.troopData
end

pCell.getGeneralData = function(self)
	return self.generalData
end

pCell.getHeroData = function(self)
	return self.heroData
end

pCell.onClickLayoutTroop = function(self)
	self:hideMenu()
	modCellTroopWnd.open(self)
end

pCell.onClickLayoutGeneral = function(self)
	self:hideMenu()
	modCellGeneralWnd.open(self)
end

pCell.dumpTroopsToScene = function(self, scene, editFlg)
	local troops = modPrepareCell.pPrepareCell.dumpTroopsToScene(self, scene, editFlg)
	local data = self:getTroopsData()
	for t, _ in pairs(troops) do
		t.data = table.clone(data)
	end

	return troops
end

pCell.dumpGeneralToScene = function(self, scene, editFlg) 
	local general = modPrepareCell.pPrepareCell.dumpGeneralToScene(self, scene, editFlg)
	if general then
		local data = self:getGeneralData()
		general.data = table.clone(data)
	end

	return general
end

pCell.dumpHeroToScene = function(self, scene, editFlg) 
	local hero = modPrepareCell.pPrepareCell.dumpHeroToScene(self, scene, editFlg)
	if hero then
		local data = self:getHeroData()
		hero.data = table.clone(data)
	end

	return hero
end

------------------------------------------------------------

pCellMgr = pCellMgr or class(modCellMgr.pPrepareCellMgr)

pCellMgr.init = function(self, editor)
	self.cellGapW = -35
	self.cellGapH = 10 
	self.cells = {}
	--self.cellGap = 10
	self.cellW = 300
	self.cellH = 140

	self.cellXDiff = 40

	self.scenePos = editor:getFightFormationPos()
	self.formationArea = {3*self.cellW + 2*self.cellGapW, 3*self.cellH + 2*self.cellGapH}

	self.formationPos = {self.scenePos[1] - self.formationArea[1]/2,
						self.scenePos[2] - self.formationArea[2]/2}

	local troopsMgr = pTroopsMgr:new()
	troopsMgr:loadAllTroops()
	self.troopsMgr = troopsMgr
	self.fightMgr = editor

	local parent = editor:getFightScene()
	local initCells = function(x, y, pos, z)
		local cell = pCell:new(self.cellW, self.cellH, x, y, self.formationAreaWnd, self.troopsMgr, self, pos)
		self.cells[pos] = cell
		cell.pos = pos

		cell:setZOrder(z)
		return cell
	end
	local initAllCells = function()
		self.formationAreaWnd = pWindow()
		self.formationAreaWnd:setColor(0x5500ff00)
		self.formationAreaWnd:setParent(parent)
		self.formationAreaWnd:setPosition(self.formationPos[1], self.formationPos[2])
		self.formationAreaWnd:setSize(self.formationArea[1], self.formationArea[2])
		self.formationAreaWnd:show(true)

		self.formationAreaWnd:enableDrag(true)

		local w = self.cellW
		local h = self.cellH
		local sw = w + self.cellGapW
		local sh = h + self.cellGapH
		--local x = self.formationPos[1]
		--local y = self.formationPos[2]
		local x = 0
		local y = 0

		--[[
		--	1	2	3
		--	4	5	6  --->
		--	7	8	9
		--]]

		initCells(x, y, 1, -1)
		initCells(x+sw, y, 2, -4)
		initCells(x+2*sw, y, 3, -7)

		x = x + self.cellXDiff
		initCells(x, y+sh, 4, -2)
		initCells(x+sw, y+sh, 5, -5)
		initCells(x+2*sw, y+sh, 6, -8)

		x = x + self.cellXDiff
		initCells(x, y+2*sh, 7, -3)
		initCells(x+sw, y+2*sh, 8, -6)
		initCells(x+2*sw, y+2*sh, 9, -9)
	end

	initAllCells()

	self:initTroopsCnt()
end

pCellMgr.adjustFormationPos = function(self, x, y)
	self.formationAreaWnd:setPosition(x, y)
end

pCellMgr.getFormationPos = function(self)
	if self.formationAreaWnd then
		local x, y = self.formationAreaWnd:getX(), self.formationAreaWnd:getY()
		return x, y
	end
	return nil
end

pCellMgr.initTroopsCnt = function(self)
	self.troopsCnt = {}
	for troopType, troopObj in self.troopsMgr:troopsObjs() do
		self.troopsCnt[troopType] = 999
	end
end

pCellMgr.getTotalUnitLimit = function(self)
	return 999999
end

pCellMgr.onModifyUnit = function(self, unit)
	return
end

pCellMgr.getMaxGeneralCnt = function(self)
	return 9
end

--[[
--	@param data : 
--	{
--		[1]={ct="troop", c_data={}, num=xxx, gt="type", g_data={}},
--		[2]={ct="hero", h_data={}},
--		[3]={ct="troop", c_data={}, num=xxx},
--		....
--		[9]={...},
--	}
--]]
pCellMgr.importCells = function(self, data)
	for k, info in modUtil.iterateNumKeyTable(data) do
		local pos = tonumber(k)
		if pos then
			local t = info["ct"]
			if t == "hero" then
				--self.cells[pos]:layoutHeroFromData(info["h_data"])
				--self.heroCell = self.cells[pos]
			elseif t == "troop" then
				-- local troopNum = info["num"]
				-- self.cells[pos]:layoutTroopsFromData(info["t_data"], troopNum)
			end

			local gt = info["gt"]
			if gt then
				self.cells[pos]:layoutGeneralFromData(gt, info["g_data"])
			end
		end
	end

	modCellMenu.genCellMenu(self.troopsCnt)
end

pCellMgr.exportCells = function(self)
	local data = {}
	for pos, cell in pairs(self.cells) do
		data[pos] = {}
		if cell:isHeroCell() then
			-- 英雄格子
			data[pos]["ct"] = "hero"
			data[pos]["h_data"] = cell:getHeroData()
		elseif cell:isTroopCell() then
			-- 部队格子
			data[pos]["ct"] = "troop"
			local num = cell:getTroopNum()
			data[pos]["num"] = num
			data[pos]["t_data"] = cell:getTroopsData()
		end

		local gt = cell:getGeneralType()
		if gt then
			data[pos]["gt"] = gt
			data[pos]["g_data"] = cell:getGeneralData()
		end
	end
	logv("info", data)
	return data
end

