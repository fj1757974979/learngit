local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")

pMenu = pMenu or class(pWindow, pSingleton)

pMenu.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:setZ(C_BATTLE_UI_Z)
	self:setAlignX(ALIGN_RIGHT)
	self:setAlignY(ALIGN_BOTTOM)
	self:setOffsetX(-gGameWidth * 0.1)
	self:setOffsetY(-15)
	self:setColor(0xFFEEEE00)
	self:setImage("ui:calculate_item_bg.png")
	self:setSize(50, 100)
	self.controls = {}	
end

pMenu.open = function(self, message, wndParent)
	self.combs = message.combs
	self.versionId = message.version
	self:hasPreting()
	self:setParent(wndParent)
	self.wndParent = wndParent
	
	self.drawCombTexts = {}
	self.keyCards = {}
	-- 初始化不重复comb类型
	self:initDrawTextCombs()
	-- 描画不重复comb
	self:drawTextAndKeyCard(0.4, message.allow_pass)

end

pMenu.hasPreting = function(self)
	if not self.combs then return end
	for _, comb in ipairs(self.combs) do
		if self:isMingFlag(comb.t) then
			self:getCurGame():askCombHasMingWork(self.combs)
			break
		end
	end
end

pMenu.drawTextAndKeyCard = function(self, keyScale, isPass)
	local textWidth, textHeight = 87, 87
	local keyWidth, keyHeight = 89 * keyScale, 135 * keyScale
	local x, y = 20, 0
	local bgWidth = self:getWidth()

	-- 描画过
	if isPass then		
		local passImage = self:getImageByComb(-1)
		if not passImage or passImage == "" then
			log("error", "passimage is nil !!")
		end
		local btnPass = self:createButton(-1, x, y, passImage, textWidth, textHeight)
		self.speicalGuoEffectName = nil
		-- 特殊过
		if self:getCurGame():isSpecialGuo(self.drawCombTexts) then
			self.speicalGuoEffectName = self:getCurBattle():getBattleUI():speicalGuoWork(btnPass)
		end
		btnPass:addListener("ec_mouse_click", function() 
			self:callRpc(-1)
		end)
		x = x + btnPass:getWidth()
	end


	-- 描画comb
	for index, comb in pairs(self.drawCombTexts) do
		-- 明comb
		local isPreting = self:isMingFlag(comb.t)
		if self:isHu(comb.t) then
			textWidth, textHeight = 149, 131
		else
			textWidth, textHeight = 87, 87
		end
		-- 取触发牌
		local textImage = self:getImageByComb(comb.t, self:isSelfTrigger(comb))
		if not textImage or textImage == "" then 
			log("error", "comb image is nil!!!")
		end
		if not isPreting then
			-- 触发牌背景
			local keyBgWnd = self:createWnd(index, x, y, "ui:zhuaniao_bg.png", 0, keyHeight + 10)
			keyBgWnd:setOffsetX(-x)

			-- 描画触发牌
			local cardX = 5
			local t = self:getCombType(comb.t)
			if table.size(self.keyCards[t]) > 0 then
				for _, id in pairs(self.keyCards[t]) do
					local keyImage = "ui:card/2/show_" .. id .. ".png"
					local keyWnd = self:createWnd(index .. id, cardX, 0, keyImage, keyWidth, keyHeight)
					keyWnd:setParent(keyBgWnd)
					keyWnd:setAlignX(ALIGN_RIGHT)
					keyWnd:setAlignY(ALIGN_CENTER)
					keyWnd:setOffsetX(-cardX)
					self:magicCard(id, keyWnd, keyScale)
					--				self:diCard(id, keyWnd, keyScale)
					cardX = cardX + 5 + keyWnd:getWidth()
					keyBgWnd:setSize(keyBgWnd:getWidth() + keyWnd:getWidth() + 5, keyBgWnd:getHeight())
				end
				keyBgWnd:setSize(keyBgWnd:getWidth() + 5, keyBgWnd:getHeight())
			end
			x = x + keyBgWnd:getWidth()
		end
		-- 描画comb按钮
		local btn = self:createButton(index, x, y, textImage, textWidth, textHeight)
		btn:setOffsetX(-x)
		self:pretingBtn(isPreting, btn)
		btn:addListener("ec_mouse_click", function()
			if isPreting then
				self:pretingEvent()
			else
				self:clickReturn(comb.t)
			end
		end)
		x = x + btn:getWidth()

		bgWidth = x
	end
	-- 设置窗体背景大小
	self:setSize(bgWidth + 20, self:getHeight())
end

pMenu.pretingEvent = function(self)
	self:getCurGame():pretingEvent(self.combs, self)
end

pMenu.pretingBtn = function(self, isPreting, btn)
	if not isPreting then
		return 
	end
	self:setColor(0)
	btn:setSize(114, 106)
	btn:setOffsetX(-(gGameWidth / 2 - self:getParent():getWidth() - 35))
end

pMenu.getImageByComb = function(self, t)
logv("warn","pMenu.getImageByComb")	
	if not t then return end
	local img = modUIUtil.getImageByComb(t)
	if not img or img == "" then return end
	return img
end

pMenu.initDrawTextCombs = function(self)
	for index, comb in ipairs(self.combs) do
		if not self.drawCombTexts[self:getCombType(comb.t)] then
			-- 返回值
			self.drawCombTexts[self:getCombType(comb.t)] = comb
		end
		-- 取得所有触发牌
		self:getAllTriggerCards(comb)	
	end

	-- 排序
	local tmp = table.values(self.drawCombTexts)
	table.sort(tmp, function(c1, c2)
		return c1.t < c2.t
	end)
	self.drawCombTexts = tmp
end

pMenu.getAllTriggerCards = function(self, comb)
	local t = self:getCombType(comb.t)
	if not self.keyCards[t] then
		self.keyCards[t] = {}
	end
	-- 赋值
	for idx, id in ipairs(comb.trigger_card_ids) do
		if not self:isGang(t) and table.size(self.keyCards[t]) > 0 then
			break
		end
		if self:isInsert(t, id) then 
			table.insert(self.keyCards[t], id)
		end
	end
end

pMenu.isInsert = function(self, t, id)
	for _, i in pairs(self.keyCards[t]) do
		if i == id then
			return false
		end
	end
	return true
end

pMenu.findValue = function(self, comb)
	for index, c in ipairs(self.combs) do
		if comb == c then
			return index - 1
		end
	end
end

pMenu.findAllCombs = function(self, t)
	local combs = {}
	for index, comb in ipairs(self.combs) do
		if t == modGameProto.ANGANG then
			if self:isGang(comb.t) then
				combs[index - 1] = comb
			end
		else
			if comb.t == t then
				combs[index - 1] = comb
			end
		end
	end
	return combs
end


pMenu.addCombHasMagicOrDi = function(self, combs)	
	if not combs then return end
	-- 查询comb是否含有鬼牌或者底牌
	self.keyToHasMagicOrDi = {}
	for key, comb in pairs(combs) do
		if not self.keyToHasMagicOrDi[key] then self.keyToHasMagicOrDi[key] = {} end
		if not (comb.t == modGameProto.HU) and 
			self:isShowTipWnd(comb) then
			self:setValueToKeyList(key, comb)
		end
	end
end

pMenu.getCombMyCards = function(self, comb)
	logv("warn","getCombMyCards")
	local cards = comb.card_ids
	local tcards = comb.trigger_card_ids
	local myCards = {}
	-- 碰和杠
	if comb.t == modGameProto.MINGKE or self:isGang(comb.t) then
		return cards
	end
	-- 取出comb中自己的牌
	for _, id in ipairs(cards) do
		for _, tid in ipairs(tcards) do
			if id ~= tid then
				table.insert(myCards, id)
			end
		end
	end
	return myCards
end

pMenu.isShowTipWnd = function(self, comb)
	local myCards = self:getCombMyCards(comb)
	-- 自己的牌是否有王牌或者地牌
	for _, id in pairs(myCards) do
		if self:isMagicCard(id) 
		--	or self:isDiCard(id) 
			then
			return true
		end
	end
	return false
end

pMenu.isSelfTrigger = function(self, comb)
	if not comb.trigger_player_id then return false end
	return comb.trigger_player_id == modBattleMgr.getCurBattle():getMyPlayerId()
end

pMenu.isTriggerCardId = function(self, id, comb)
	local cards = comb.trigger_card_ids
	for _, tId in ipairs(cards) do
		if tId == id then
			return true
		end
	end
	return false
end

pMenu.setValueToKeyList = function(self, key, comb)
	local cards = comb.card_ids
	for _, cardId in ipairs(cards) do
		if self:isMagicCard(cardId) then
			self.keyToHasMagicOrDi[key]["magic"] = true
		end
		if self:isDiCard(cardId) then
			self.keyToHasMagicOrDi[key]["di"] = true
		end
	end
end

pMenu.clickReturn = function(self, t)
	-- 找出同类comb是否有多条
	local combs = self:findAllCombs(t)
	-- 建立key对应鬼牌地牌映射
	self:addCombHasMagicOrDi(combs)
	if table.size(combs) > 1 then 
		-- 展示comb选择
		self:showAllCombCards(combs)			
	else
		for key, comb in pairs(combs) do
			self:callRpc(key, comb)	
		end
	end
end

pMenu.showAllCombCards = function(self, combs, scale)
	logv("warn",pMenu.showAllCombCards)
	-- comb bg
	local distanceX, distanceY = 20, 10
	local scale = scale or 0.8
	local maxXCount = 3
	local cardWidth, cardHeight = 100 * scale, 139 * scale
	local bgWidth = distanceX
	local bgHeight = distanceY + cardHeight  
	local bgWnd = self:createWnd("comb_bg", 0, 0, "ui:battle_comb_bg.png", bgWidth, bgHeight)
	bgWnd:setOffsetY(- bgWnd:getHeight())
	bgWnd:setOffsetX(- gGameWidth * 0.1)
	bgWnd:setXSplit(true)
	bgWnd:setYSplit(true)
	bgWnd:setSplitSize(10)
	modUIUtil.makeModelWindow(bgWnd, true, true)	
	
	-- 展示牌
	local x, y = distanceX, distanceY	
	local index = 0
	for key, comb in pairs(combs) do
		index = index + 1
		-- 取comb得触发牌Id
		-- 是否为碰或者杠
		local isPengOrGang = false
		if self:isPeng(comb.t) or self:isGang(comb.t) then
			isPengOrGang = true
		end
		-- 描画牌
		-- 排序小到大
		table.sort(comb.card_ids, function(id1, id2) 
			return id1 > id2
		end)
		for idx, cardId in ipairs(comb.card_ids) do	
			local image = "ui:card/2/show_" .. cardId .. ".png"
			local wnd = self:createWnd(sf("card_%d_%d_%d", key, idx, cardId), 0, 0, image, cardWidth, cardHeight)
			wnd:setParent(bgWnd)
			wnd:setAlignY(ALIGN_BOTTOM)
			wnd:setOffsetX(-x + 5)
			wnd:setOffsetY(-y)
			self:magicCard(cardId, wnd, scale)
--			self:diCard(cardId, wnd, scale)
			wnd:addListener("ec_mouse_click", function()
				self:callRpc(key, comb)
			end)	
			x = x + wnd:getWidth() - 5
			if isPengOrGang then -- 碰和杠各画一张
				break
			else
				local isColor = false
				for _, id in pairs(self.keyCards[self:getCombType(comb.t)])do
					if cardId == id then
						isColor = true
						break
					end
				end
				if isColor then wnd:setColor(0xFFEEEE00) end
			end
		end
		x = x + distanceX
		-- 最左边加5
		if x > bgWidth then bgWidth = x - 10 + 5 end
		if y > bgHeight then bgHeight = y end
		if index % maxXCount == 0 then
			x = distanceX
			y = y + cardHeight + distanceY
		end
	end
	bgHeight = bgHeight + 10
	bgWnd:setSize(bgWidth, bgHeight)
end

pMenu.getCombType = function(self, t)
	if self:isGang(t) then
		return modGameProto.ANGANG
	end
	return t
end

pMenu.getTriggerCardId = function(self, comb)
	for _, id in ipairs(comb.card_ids) do
		return id	
	end
end

pMenu.isGang = function(self, t)
	return modBattleMgr.getCurBattle():getCurGame():isGang(t)
end

pMenu.isChi = function(self, t)
	return t == modGameProto.MINGSHUN
end

pMenu.isPeng = function(self, t)
	return t == modGameProto.MINGKE
end

pMenu.isHu = function(self, t)
	return t == modGameProto.HU
end

pMenu.getVersionId = function(self)
	return self.versionId
end

pMenu.getSpeicalGuoEffectName = function(self)
	return self.speicalGuoEffectName
end

pMenu.callRpc = function(self, idx, comb)
	self:getCurBattle():getBattleUI():combOnChoose(idx, comb, self)
end

pMenu.hasMagic = function(self, idx)
	return self.keyToHasMagicOrDi[idx]["magic"]
end

pMenu.hasDi = function(self, idx)
	return self.keyToHasMagicOrDi[idx]["di"]
end

pMenu.getKeyToMagicOrDi = function(self)
	return self.keyToHasMagicOrDi
end

pMenu.rpcChooseComb = function(self, idx)
	self:getCurGame():rpcChooseComb(idx, self.versionId)
	self:close()
end

pMenu.getChooseCombTipText = function(self, comb)
	if not comb then return end
	if not self.keyToHasMagicOrDi 
		or table.size(self.keyToHasMagicOrDi) <= 0 then return end	
	-- 有鬼牌或者地牌
	local str = ""
	local myCards = self:getCombMyCards(comb)
	-- 鬼牌
	for _, id in pairs(myCards) do
		if self:isMagicCard(id) then
			str = str .. "王牌"
			break
		end
	end
	-- 地牌
	for _, id in pairs(myCards) do
		if self:isDiCard(id) then
			str = str .. "地牌"
			break
		end
	end
	return "您选择的组合中含有" .. str .. "确定要打出吗？"
end

pMenu.close = function(self)
	self.combs = nil
	for k,v in pairs(self.controls) do
		v:setParent(nil)
	end
	self.speicalGuoEffectName = nil
	self.controls = {}
	self.wndParent = nil
	self.drawTextAndKeyCard = {}
	self.drawCombTexts = {}
	self.keyToHasMagicOrDi = {}
	pMenu:cleanInstance()
end


pMenu.createButton = function(self, name, x, y, image, width, height)
    local scale = scale
    local btnYQ = pButton():new()
    btnYQ:setName("btn_" .. name)
    btnYQ:setParent(self)
    btnYQ:setAlignX(ALIGN_RIGHT)
    btnYQ:setAlignY(ALIGN_CENTER)
    btnYQ:setPosition(x, y)
    btnYQ:setImage(image)
    btnYQ:setSize(width, height)
    btnYQ:setColor(0xFFFFFFFF)
    self[btnYQ:getName()] = btnYQ
    table.insert(self.controls, btnYQ)
    return btnYQ
end

pMenu.magicCard = function(self, cardId, w, scale)
	if not cardId or not w then
		return 
	end
	if not self:isMagicCard(cardId) then return end
	local mWnd = self:createWnd("magic_" .. w:getName())
	mWnd:setParent(w)
	mWnd:setAlignX(ALIGN_LEFT)
	mWnd:setAlignY(ALIGN_BOTTOM)
	mWnd:setOffsetX(0)
	mWnd:setOffsetY(2)
	mWnd:setImage("ui:calculate_gui.png")
	mWnd:setColor(0xFFFFFFFF)
	mWnd:setSize(81 * scale, 102 * scale)
	table.insert(self.controls, mWnd)
	return mWnd
end

pMenu.diCard = function(self, cardId, w, scale)
	if not cardId or not w then
		return 
	end
	if not self:isDiCard(cardId) then return end
	local mWnd = self:createWnd("di_" .. w:getName())
	mWnd:setParent(w)
	mWnd:setAlignX(ALIGN_LEFT)
	mWnd:setAlignY(ALIGN_BOTTOM)
	mWnd:setPosition(-1, 0)
	mWnd:setOffsetY(3)
	mWnd:setImage("ui:calculate_di.png")
	mWnd:setColor(0xFFFFFFFF)
	mWnd:setSize(81 * scale, 102 * scale)
	table.insert(self.controls, mWnd)
	return mWnd
end

pMenu.createWnd = function(self, name, x, y, image, width, height)
	local wnd = pWindow:new()
	wnd:setName("wnd_key_" .. name)
	wnd:setParent(self)
	wnd:setAlignX(ALIGN_RIGHT)
	wnd:setAlignY(ALIGN_CENTER)
	wnd:setPosition(x or 0, y or 0)
	wnd:setImage(image)
	wnd:setSize(width or 50, height or 50)
	wnd:setColor(0xFFFFFFFF)
	self[wnd:getName()] = wnd
	table.insert(self.controls, wnd)
	return wnd
end

pMenu.isMagicCard = function(self, id)
	local cards = modBattleMgr.getCurBattle():getCurGame():getMagicCard()
	if not cards then return end
	local result = false
	for _, mId in pairs(cards) do
		if id == mId then
			result = true
			break
		end
	end
	return result
end

pMenu.isDiCard = function(self, id)
	local dId = modBattleMgr.getCurBattle():getCurGame():getDiCardId()
	if not dId then return false end
	return id == dId
end

pMenu.isMingFlag = function(self, f)
	if not f then return end
	return f == modGameProto.MING 
end

pMenu.getCurBattle = function(self)
	return modBattleMgr.getCurBattle()
end

pMenu.getCurGame = function(self)
	return modBattleMgr.getCurBattle():getCurGame()
end
