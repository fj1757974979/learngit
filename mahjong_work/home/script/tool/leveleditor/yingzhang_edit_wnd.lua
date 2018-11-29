local modTroopConf = import("td/cultivate/config.lua")
local modUtil = import("td/util.lua")

pYingZhangEditWnd = pYingZhangEditWnd or class(pWindow)

pYingZhangEditWnd.init = function(self, parent, hostBuild)
	self:load("data/ui/yingzhang_edit_wnd.lua")
	self:setParent(parent)
	self:show(false)

	self.addBtn:addListener("ec_mouse_click", function(e)
		self:addQueueData()
	end)
	self.modifyBtn:addListener("ec_mouse_click", function(e)
		self:modifyQueueData()
	end)
	self.saveBtn:addListener("ec_mouse_click", function(e)
		local interval = self.editSec:getText()
		interval = tonumber(interval)
		local flow = self.editFlow:getText()
		flow = tonumber(flow)
		if interval and flow then
			self.troopConf["interval"] = interval
			self.troopConf["flow"] = flow
		end
		self.hostBuild:setLinkedProp("troop_conf", self.troopConf)
		infoMessage(TEXT("save success!"))

		self:refresh()
	end)
	self.recoverBtn:addListener("ec_mouse_click", function(e)
		local troopConf = self.hostBuild:getLinkedProp("troop_conf")
		self.troopConf = table.clone(troopConf)
		self:refresh()
	end)

	self.MAX_QUEUE_LEN = 7

	self.chosenWnd = nil

	self.hostBuild = hostBuild
	local troopConf = self.hostBuild:getLinkedProp("troop_conf")
	if not troopConf then
		log("error", "wrong build type!")
		return
	end

	self.troopConf = table.clone(troopConf)
end

pYingZhangEditWnd.getEditQueueData = function(self)
	local lv = self.editLevel:getText()
	lv = tonumber(lv)
	local num = self.editNum:getText()
	num = tonumber(num)
	local resid = self.editResid:getText()
	resid = tostring(resid)
	local baseHp = self.editHp:getText()
	baseHp = tonumber(baseHp)
	local baseAtt = self.editAtt:getText()
	baseAtt = tonumber(baseAtt)
	local baseArmor = self.editArmor:getText()
	baseArmor = tonumber(baseArmor)
	local attSpeed = self.editAttSpeed:getText()
	attSpeed = tonumber(attSpeed)
	local attScope = self.editAttScope:getText()
	attScope = tonumber(attScope)
	local moveSpeed = self.editMoveSpeed:getText()
	moveSpeed = tonumber(moveSpeed)
	if lv and num and resid and baseHp and
		baseArmor and baseAtt and attScope and 
		attSpeed and moveSpeed then
		return {1, lv, num, resid, {
			baseHp = baseHp,
			baseAtt = baseAtt,
			baseArmor = baseArmor,
			attSpeed = attSpeed,
			attScope = attScope,
			baseMoveSpeed = moveSpeed
		}}
	else
		return nil
	end
end

pYingZhangEditWnd.addQueueData = function(self)
	local qData = self:getEditQueueData()
	if not qData then
		infoMessage("填写不正确！")
		return
	end
	logv("info", qData)
	local new = {}
	local index = 1
	new[index] = qData
	for _, info in modUtil.iterateNumKeyTable(self.troopConf["troopQueue"]) do
		index = index + 1
		new[index] = info
	end

	self.troopConf["troopQueue"] = new

	logv("info", self.troopConf)

	self:refresh()
end

pYingZhangEditWnd.modifyQueueData = function(self)
	local wnd = self.chosenWnd
	if wnd then
		local pos = wnd.pos
		if pos then
			local qData = self:getEditQueueData()
			if not qData then
				infoMessage("填写不正确！")
				return
			end
			self.troopConf["troopQueue"][pos] = qData
			self:refresh()
		end
	end
end

pYingZhangEditWnd.open = function(self)
	self:show(true)
	self:refresh()
end

pYingZhangEditWnd.close = function(self)
	self:show(false)
end

pYingZhangEditWnd.updateQueue = function(self, data)
	local index = 1
	for pos, queueData in modUtil.iterateNumKeyTable(data) do
		logv("info", queueData)
		if index > self.MAX_QUEUE_LEN then
			return
		end

		local wnd = self["qWnd"..tostring(index)]
		if wnd then
			local t = queueData[1]
			local lv = queueData[2]
			local num = queueData[3]
			local resid = queueData[4]
			local mathprop = queueData[5]
			if lv > 6 then lv = 6 end
			--[[
			local conf = modTroopConf.getTroopConfByTypeAndLevel(t, lv)
			local name = conf["name"]
			wnd:setText(name)
			]]--

			local numWnd = self["num"..tostring(index)]
			local delBtn = self["delBtn"..tostring(index)]
			numWnd:setText(string.format("X %d", num))
			delBtn:setText("X")

			wnd.pos = pos
			wnd.t = t
			wnd.lv = lv
			wnd.num = num
			wnd.resid = resid
			wnd.mathprop = mathprop
			if not delBtn.clickHdr then
				delBtn.clickHdr = delBtn:addListener("ec_mouse_click", function(e)
					self:onDelQueue(wnd)
				end)
			end

			if not wnd.clickHdr then
				wnd.clickHdr = wnd:addListener("ec_mouse_click", function(e)
					self:onClickQueue(wnd)
				end)
			end

			wnd:show(true)
		end

		index = index + 1
	end

	for i = index, self.MAX_QUEUE_LEN do
		local wnd = self["qWnd"..tostring(i)]
		if wnd then
			wnd:show(false)
		end
	end
end

pYingZhangEditWnd.onDelQueue = function(self, wnd)
	if self.chosenWnd == wnd then
		self.chosenWnd = nil
	end
	local pos = wnd.pos
	self.troopConf["troopQueue"][pos] = nil

	self:refresh()
end

pYingZhangEditWnd.onClickQueue = function(self, wnd)
	self.chosenWnd = wnd

	local t = wnd.t
	if not t then return end

	local lv = wnd.lv
	local num = wnd.num
	local resid = wnd.resid
	local mathprop = wnd.mathprop

	local f = string.format
	self.editLevel:setText(f("%d", lv))
	self.editNum:setText(f("%d", num))
	self.editResid:setText(f("%d", resid))
	self.editHp:setText(f("%d", mathprop["baseHp"]))
	self.editAtt:setText(f("%d", mathprop["baseAtt"]))
	self.editArmor:setText(f("%d", mathprop["baseArmor"]))
	self.editAttSpeed:setText(f("%f", mathprop["attSpeed"]))
	self.editAttScope:setText(f("%d", mathprop["attScope"]))
	self.editMoveSpeed:setText(f("%d", mathprop["baseMoveSpeed"]))

	-- 预览资源
	if self.sprite then
		self.sprite:setParent(nil)
	end
	self.sprite = pSprite()
	self.sprite:setParent(self.iconWnd)
	local w, h = self.iconWnd:getWidth(), self.iconWnd:getHeight()
	self.sprite:setTexture(string.format("character:%s/stand.5.fsi", resid), 0)
	self.sprite:setPosition(w/2, h)
end

pYingZhangEditWnd.updateConfig = function(self, interval, flow)
	self.editSec:setText(tostring(interval))
	self.editFlow:setText(tostring(flow))
end

--[[
pYingZhangEditWnd.updateTroops = function(self)
	self.troopsWnd.items = {}
	if self.troopsWnd.dragBg then
		self.troopsWnd.dragBg:setParent(nil)
		self.troopsWnd.dragBg = nil
	end
	self.troopsWnd.dragBg = pWindow()
	self.troopsWnd.dragBg:setParent(self.troopsWnd)
	self.troopsWnd.dragBg:showSelf(false)
	self.troopsWnd:setClipDraw(true)

	local h = self.troopsWnd:getHeight()
	local w = h 
	local x, y = 0, 0
	local gap = 5
	local allTroopsConf = modTroopConf.getAllTroopInitInfo()
	local genItemWnd = function(t, conf)
		local wnd = pWindow()
		wnd.t = t
		wnd:setSize(w, h)
		wnd:setParent(self.troopsWnd.dragBg)
		log("info", conf["name"])
		wnd:setText(conf["name"])
		wnd:addListener("ec_mouse_click", function(e)
			-- TODO
		end)
		return wnd
	end
	local index = 1
	for t, conf in pairs(allTroopsConf) do
		local wnd = genItemWnd(t, conf)
		table.insert(self.troopsWnd.items, wnd)
		wnd:setPosition(x + (index - 1) * (w + gap), y)
		index = index + 1
	end

	local dw = w*(index - 1) + gap*(index - 2)
	local dh = self.troopsWnd:getHeight()
	self.troopsWnd.dragBg:setSize(dw, dh)
	modUtil.makeDrag(self.troopsWnd.dragBg, math.abs(gGameWidth - self.troopsWnd:getWidth()))
end
]]--

pYingZhangEditWnd.refresh = function(self)
	self:updateQueue(self.troopConf["troopQueue"])
	self:updateConfig(self.troopConf["interval"], self.troopConf["flow"])
	--self:updateTroops()
end

