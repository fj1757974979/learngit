local modCardMain = import("logic/battle/card.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")

------------
isMagicCard = function(id)
	local cards = modBattleMgr.getCurBattle():getCurGame():getMagicCard()
	if not cards then return end
	local result = false
	for _, mId  in pairs(cards) do
		if id == mId then
			result = true
			break
		end
	end
	return result
end
-------------
pCardPool = pCardPool or class()

pCardPool.init = function(self, player)
	self.cards = {}
	self.player = player
	self.seat = self.player:getSeat()
	self.cardMgr = modCardMain.pCardMgr:instance()
end

pCardPool.getCards = function(self)
	return self.cards
end

pCardPool.add = function(self, id, noSort,poolType)	
	log("info", sf("pCardPool.add id=%d, t=%d", id, self:getType()))	
	local card = self:newCard(id)	
	if card then
		table.insert(self.cards, card)
		if not noSort then
			self:sort()
		end
	end	
	return card
end

pCardPool.del = function(self, id)
	log("info", sf("pCardPool.del id=%d, t=%d", id, self:getType()))
	local idx = nil
	for _idx, card in ipairs(self.cards) do
		if card:getId() == id then
			idx = _idx
			break
		end
	end
	if idx then
		table.remove(self.cards, idx)
	end
end

pCardPool.sort = function(self)			
	local battle = modBattleMgr.getCurBattle()
	if not battle then return end
	if not battle:getCurGame() then return end
	local numbers = battle:getCurGame():getHuaSeFanWei()
	local rule = modBattleMgr.getCurBattle():getCurGame():getRuleType()
	local notSortMjs = {
		[modLobbyProto.CreateRoomRequest.RONGCHENG] = true,
	}
	-- 排序
	table.sort(self.cards, function(card1, card2)
		local id1 = card1:getId()
		local id2 = card2:getId()
		if not notSortMjs[rule] then
			if isMagicCard(id1) then
				id1 = id1 - 1000
			end
			if isMagicCard(id2) then
				id2 = id2 - 1000
			end
		end	

		--平和排白板
		if rule == 14 then
			local cards = modBattleMgr.getCurBattle():getCurGame():getMagicCard()	
			if cards then
				for _, mId  in pairs(cards) do
					if id1 == 33 then					
						id1 = mId					
					end
					if id2 == 33 then									
						id2 = mId					
					end
				end
			end
		end	

		-- 云阳排缺牌
		if modBattleMgr.getCurBattle():getCurGame():isYunYangMj() or modBattleMgr.getCurBattle():getCurGame():isXueZhanDaoDiMj() then
			local flags = self.player:getFlags()
			local nums = nil
			for _, f in pairs(flags) do
				if numbers[f] then
					nums = numbers[f]
					break
				end
			end
			if nums then
				if id1 >= nums[1] and id1 <= nums[2] then
					id1 = id1 + 1000
				end
				if id2 >= nums[1] and id2 <= nums[2] then
					id2 = id2 + 1000
				end
			end
		end
		return id1 < id2
	end)
end


pCardPool.newCard = function(self, id)
	log("error", "Not implemented newCard")
	return nil
end

pCardPool.refreshCards = function(self, ids)
	self.cards = {}
	for _, id in ipairs(ids) do
		local card = self:newCard(id)
		if card then
			table.insert(self.cards, card)
		end
	end
	self:sort()
end

pCardPool.addCards = function(self, args)
	local cardIds = args
	for i, cardId in ipairs(cardIds) do
		self:add(cardId, true)
	end
	self:sort()
end

pCardPool.delCards = function(self, args)
	local cardIds = args
	for _, cardId in ipairs(cardIds) do
		self:del(cardId)
	end
end

pCardPool.getType = function(self)
	return nil
end

pCardPool.clean = function(self)
	self.cards = {}
end

pCardPool.destroy = function(self)
	self:clean()
	for _, card in pairs(self.cards) do
		card:setParent(nil)
	end
	self.player = nil
	self.seat = nil
	self.cardMgr = nil
end
----------------------------------------------------------

pHandPool = pHandPool or class(pCardPool)

pHandPool.init = function(self, player)
	pCardPool.init(self, player)
	self:sort()
end


pHandPool.newCard = function(self, id)
	self:sort()
	local wnd = self.cardMgr:newCard(id, self.seat, T_CARD_HAND)
	return wnd
end

pHandPool.updateCards = function(self, args)
	local cardIdToNum = args
end

pHandPool.getType = function(self)
	return T_POOL_HAND
end

pHandPool.getCards = function(self, skipDeal)	
	logv("error",self.cards)
	if table.getn(self.player:getCurrentDealCard()) <= 0 or skipDeal then
		return self.cards
	else
		local ret = {}
		local deals = {}
		for _, card in pairs(self.player:getCurrentDealCard()) do
			table.insert(deals, card)
		end
		
		for _, card in ipairs(self.cards) do
			local dealIndex = nil
			for idx, deal in ipairs(deals) do
				if card:getId() == deal:getId() then
					dealIndex = idx
					break
				end
			end
			if dealIndex then
				table.remove(deals, dealIndex)
			else
				table.insert(ret, card)
			end
		end
		return ret
	end
end

pHandPool.discardSort = function(self, list)
	if not list then return end
	local tmps = {}
	for _, id in pairs(list) do
		table.insert(tmps, id)
	end
	local ids = {}
	for _, card in pairs(self.cards) do
		table.insert(ids, card:getId())
	end


	local idToCount = modUIUtil.getListIdToCount(tmps)
	local removeIndexs = {}
	local removeCards = {}
	for _, tid in pairs(tmps) do
		for idx, card in pairs(self.cards) do
			local id = card:getId()
			if tid == id and idToCount[tid] > 0 then
				table.insert(removeIndexs, idx)
				table.insert(removeCards, card)
				idToCount[tid] = idToCount[tid] - 1
				break
			end
		end
	end
	-- 删除并排序
	for _, idx in pairs(removeIndexs) do
		table.remove(self.cards, idx)
	end
	self:sort()
	-- 在加入没有参加排序的
	for _, card in pairs(removeCards) do
		table.insert(self.cards, card)
	end
end

pHandPool.addDealsToHands = function(self)
	-- 发牌也加入排序
	local deals = self.player:getCurrentDealCard()
	for _, card in pairs(deals) do
		table.insert(self.cards, card)
	end
end

pHandPool.delDealsInHands = function(self)
	local deals = self.player:getCurrentDealCard()
	local idxs = {}
	for _, card in pairs(deals) do
		for idx, c in pairs(self.cards) do
			if card == c then
				table.insert(idxs, idx)
				break
			end
		end
	end
	for _, idx in pairs(idxs) do
		table.remove(self.cards, idx)
	end
end

pHandPool.saveAndClearDeals = function(self)
	self.deals = self.player:getCurrentDealCard()
	self.player:clearDealCards()	
end

pHandPool.setDeals = function(self)
	if not self.deals then  log("error", "self.deals is nil ===")return end
	for _, card in pairs(self.deals) do
		table.insert(self.player:getCurrentDealCard(), card)
	end
end

pHandPool.clean = function(self)
	pCardPool.clean(self)
	self.deals = {}
end

pHandPool.destroy = function(self)
	pCardPool.destroy(self)
	self:clean()
end

----------------------------------------------------------

local calcHashId = function(cardIds)
	local cnt = 0
	for _, _ in ipairs(cardIds) do
		cnt = cnt + 1
	end
	local hashId = 0
	for _, cardId in ipairs(cardIds) do
		hashId = hashId + cardId * math.pow(100, cnt - 1) 
		cnt = cnt - 1
	end
	return hashId
end

pCombination = pCombination or class()

pCombination.init = function(self, t, cards, triggerCards, pid, id)
	logv("error", "------- ", cards)
	self.cards = cards
	self.t = t
	self.triggerCards = triggerCards
	self.triggerPid = pid
	self.id = id
	local cardIds = {}
	for _, card in ipairs(cards) do
		table.insert(cardIds, card:getId())
	end
	if self.t == modGameProto.HU then
	end
	self.cards = self:sortComb(self.cards)
--	self.hashId = calcHashId(cardIds)
end

pCombination.sortComb = function(self, args)
	local cards = {}
	local index = -1
	local rule = modBattleMgr.getCurBattle():getCurGame():getRuleType()
		table.sort(args, function(card1, card2)
			local id1 = card1:getId()
			local id2 = card2:getId()		
			if isMagicCard(id1) then
				id1 = -id1			
			end
			if isMagicCard(id2) then
				id2 = -id2				
			end

			--平和排白板
			if rule == 14 then
				local cardIds = modBattleMgr.getCurBattle():getCurGame():getMagicCard()	
				if cardIds then 
					if id1 == 33 then
						id1 = cardIds[1]						
					end
					if id2 == 33 then
						id2 = cardIds[1]						
					end
				end
			end

			return id1 < id2
		end)
	if self.t == modGameProto.MINGSHUN and self.triggerCards 
		and table.getn(self.triggerCards) > 0 then
		for idx, id in pairs(args) do
			table.insert(cards, id)
			for _, tId in ipairs(self.triggerCards) do
				if id:getId() == tId then
					index = idx
				end
			end
		end
	end
	if index ~= -1 then
		local card1 = cards[2]
		cards[2] = cards[index]
		cards[index] = card1
		return cards
	else
		return args
	end

end

pCombination.getCards = function(self)
	return self.cards
end

pCombination.getTriggerCards = function(self)
	return self.triggerCards
end

pCombination.huAndZimoSort = function(self)	
	local tmp = {}
	local tcards = {}
			
	-- 取出触发牌
	for _, card in ipairs(self.cards) do		
		table.insert(tcards, card:getId())
	end

	local tcardIdToCount = modUIUtil.getListIdToCount(tcards)		
	-- 先加普通牌	
	for _, card in pairs(self.cards) do
		for _, tCardId in ipairs(self.triggerCards) do			
			if card:getId() ~= tCardId then
				table.insert(tmp, card)				
			else				
				if tcardIdToCount[tCardId] > 1 then
					table.insert(tmp, card)
					tcardIdToCount[tCardId] = tcardIdToCount[tCardId] - 1
				end				
			end
		end
	end
	
	local findIsInList = function(card, tmpCards) 
		if not tmpCards or not card then return end
		for _, tmpCard in ipairs(tmpCards) do 
			if tmpCard == card then
				return true
			end
		end
		return false
	end	

	-- 再加触发牌
	for _, card in pairs(self.cards) do
		for _, tCardId in ipairs(self.triggerCards) do
			if card:getId() == tCardId and (not findIsInList(card, tmp))then
				table.insert(tmp, card)
			end
		end
	end
	
	self.cards = tmp
end

pCombination.getTriggerPid = function(self)
	return self.triggerPid
end

pCombination.getType = function(self)
	return self.t
end

pCombination.getHashId = function(self)
--	return self.hashId
end

pCombination.destroy = function(self)
	for _, card in pairs(self.cards) do
		card:setParent(nil)
		card = nil
	end
	self.triggerCards = nil
	self.cards = nil
--	self.hashId = nil
	self.t = nil
end

---------

pShowPool = pShowPool or class(pCardPool)

pShowPool.init = function(self, player)
	self.combinations = {}
	self.combinationsAfterHu = {}
	pCardPool.init(self, player)
end

pShowPool.addCombination = function(self, t, ids, triggerCards, pid, id)
	local comb = {}
	for _, id in ipairs(ids) do
		local card = self:add(id, true)
		if card then
			table.insert(comb, card)
		end
	end
	self.combinations[id] = pCombination:new(t, comb, triggerCards, pid, id)
--	table.insert(self.combinations, pCombination:new(t, comb, triggerCards, pid, id))
end

pShowPool.getCombinations = function(self)
	return self.combinations
end

pShowPool.newCard = function(self, id)
	return self.cardMgr:newCard(id, self.seat, T_CARD_SHOW)
end

pShowPool.addCards = function(self, combs)
	-- 添加
	for _, comb in ipairs(combs) do
		local triggerCards = comb.trigger_card_ids
		local pid = comb.trigger_player_id
		local id = comb.id + 1
		self:addCombination(comb.t, comb.card_ids, triggerCards, pid, id)
	end
end

pShowPool.delCards = function(self, ids)
	for _, id in ipairs(ids) do
		self.combinations[id + 1] = nil
	end
end

pShowPool.getType = function(self)
	return T_POOL_SHOW
end

pShowPool.getCards = function(self)
	return self.combinations
end

pShowPool.clean = function(self)
	pCardPool.clean(self)
	self.combinations = {}
end

pShowPool.destroy = function(self)
	pCardPool.destroy(self)
	for _, comb in pairs(self.combinations) do
		comb:destroy()
	end
	self.combinations = {}
	self.combinationsAfterHu = {}
end
----------------------------------------------------------
pFlowerPool = pFlowerPool or class(pCardPool)

pFlowerPool.init = function(self, player)
	pCardPool.init(self, player)
end

pFlowerPool.newCard = function(self, id)
	return self.cardMgr:newCard(id, self.seat, T_CARD_FLOWER)
end

pFlowerPool.getType = function(self)
	return T_POOL_FLOWER
end

pFlowerPool.clean = function(self)
	pCardPool.clean(self)
end

pFlowerPool.destroy = function(self)
	self:clean()
	pCardPool.destroy(self)
end

pFlowerPool.sort = function(self)
	return
end
----------------------------------------------------------
pDiscardPool = pDiscardPool or class(pCardPool)

pDiscardPool.newCard = function(self, id)
	return self.cardMgr:newCard(id, self.seat, T_CARD_DISCARD)
end

pDiscardPool.delCards = function(self, args)
	local cardIds = args
	for _, cardId in pairs(cardIds) do
		idx = nil
		for i = table.getn(self.cards), 1, -1 do
			if self.cards[i]:getId() == cardId then
				idx = i
				break
			end
		end
		if idx then
			table.remove(self.cards, idx) 
		end
	end
end

pDiscardPool.getType = function(self)
	return T_POOL_DISCARD
end

-- 弃牌不排序
pDiscardPool.sort = function(self)
	return
end



