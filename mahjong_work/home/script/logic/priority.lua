local T_DUI = 101
local T_SHUNZI = 102
local T_PENG = 103
local T_GANG = 104
local T_MAX = 105
local T_COUNT_LESS = 106
local T_CARD_ID_SUM = 107
local T_MIN = 108
local T_THREE_CARD = 109
local T_COUNT_LESS_QUE = 110
local T_SAME_COUNT = 111

local numbers = {
	[T_CARD_TONG] = {0, 8},
	[T_CARD_SUO] = {9, 17},
	[T_CARD_WAN] = {18, 26},
}

local countToType = {
	[2] = T_DUI,
	[3] = T_PENG,
	[4] = T_GANG,
}

local priorityScores = {
	[T_THREE_CARD] = 2,
	[T_DUI] = -2,
	[T_PENG] = -6,
	[T_CARD_ID_SUM] = 2,
	[T_GANG] = -8,
	[T_SHUNZI] = -2,
	[T_COUNT_LESS] = 2,
	[T_COUNT_LESS_QUE] = 2,
	[T_MAX] = 1000,
	[T_MIN] = -1000,
	[T_SAME_COUNT] = 1,
}

pPriority = pPriority or class(pSingleton)

pPriority.init = function(self)
end

pPriority.getQuePriority = function(self, ids)
	if not ids then return end
	-- 区分成三个table
	local cards = self:getCardsTypes(ids)
	-- 赋予初始权重值
	local prioritys = self:initPrioritys()
	-- 算权重
	for i = T_CARD_TONG, T_CARD_WAN do
		prioritys[i] = prioritys[i] + self:quePriority(cards[i], cards)
	end
	return self:findMaxPriority(prioritys) 
end

pPriority.getHuanPriority = function(self, ids)
	if not ids then return end
	-- 区分成三个table
	local cards = self:getCardsTypes(ids)
	-- 赋予初始权重值
	local prioritys = self:initPrioritys()
	-- 算权重
	for cardt, list in pairs(cards) do
		-- 小于三张默认不选
		if table.size(list) < 3 then
			prioritys[cardt] = prioritys[cardt] + priorityScores[T_MIN]
			-- 等于三张 若没有对子 没有顺子 默认选
		elseif table.size(list) == 3 then
			local duiCount = self:getCombCount(list, 2)
			local sum = self:getCardIdSum(list)
			if sum == 0 then
				prioritys[cardt] = prioritys[cardt] + priorityScores[T_MIN]
			elseif duiCount == 0 and sum > 3 then
				prioritys[cardt] = prioritys[cardt] + priorityScores[T_MAX]
			end
		end
	end
	-- 正常算权重
	for i = T_CARD_TONG, T_CARD_WAN do
		prioritys[i] = prioritys[i] + self:huanPriority(cards[i], cards)
	end
	-- 多个权重同样时，处理
	self:samePrioritys(prioritys, cards)
	return self:findMaxPriority(prioritys) 
end

pPriority.samePrioritys = function(self, prioritys, cards)
	if not prioritys or not cards then return end
	-- 取出最大权重
	local maxPri = nil
	for i, pri in pairs(prioritys) do
		if not maxPri or pri > maxPri then 
			maxPri = pri
		end
	end
	if not maxPri then return end
	-- 找出多个最大权重
	local samePrioritys = {}
	for i, pri in pairs(prioritys) do
		if pri == maxPri then
			table.insert(samePrioritys, i)
		end
	end
	if table.getn(samePrioritys) < 2 then return end
	-- 都没有对碰杠算牌差和
	if self:isGetSumScore() then
		for i, score in pairs(prioritys) do
			score = score + self:cardIdSum(cards[i], cards)
		end
		-- 有对碰杠选牌少的
	else
		-- 找出牌数最多的
		local minCardCount = nil
		local index = nil
		for _, idx in pairs(samePrioritys) do
			if not minCardCount or (cards[idx] and table.getn(cards[idx]) < minCardCount) then
				minCardCount = table.getn(cards[idx])
				index = idx
			end
		end
		if not index then return end
		prioritys[index] = prioritys[index] + priorityScores[T_SAME_COUNT]
	end
end

pPriority.isGetSumScore = function(self, samePrioritys, cards)
	if not samePrioritys or not cards then return end
	for _, i in pairs(samePrioritys) do
		local ids = cards[i]
		local duiScore = self:duiPriority(ids)
		local pengScore = self:sameIdPriority(ids, cards, 3)
		local gangScore = self:sameIdPriority(ids, cards, 4)
		-- 牌差和
		if duiScore ~= 0 or pengScore ~= 0 and gangScore ~= 0 then
			return false
		end
	end
	return true
end

pPriority.findMaxPriority = function(self, prioritys)
	local index = T_CARD_TONG
	local p = prioritys[index]
	for idx, ps in pairs(prioritys) do
		if ps > p then
			p = ps
			index = idx
		end
	end
	return index
end

pPriority.quePriority = function(self, ids, cards)
	-- 没有的花色默认定缺
	if not ids or table.size(ids) <= 3 then 
		if self:duiPriority(ids) < 1 then
			return priorityScores[T_MAX] * (4 - table.size(ids)) 
		end
	end
	-- 权重值
	local pscore = 0
	-- 最少手牌
	pscore = pscore + self:getCountLess(ids, cards, nil, true)
	-- 对子
	local duiScore = self:duiPriority(ids)
	pscore = pscore + duiScore 
	-- 碰
	local pengScore = self:sameIdPriority(ids, cards, 3)
	pscore = pscore + pengScore 
	-- 杠
	local gangScore = self:sameIdPriority(ids, cards, 4)
	pscore = pscore + gangScore 
	-- 牌差和
	if duiScore == 0 and pengScore == 0 and gangScore == 0 then
		pscore = pscore + self:cardIdSum(ids, cards)
	end

	return pscore
end

pPriority.huanPriority = function(self, ids, cards)
	-- 等于三
	local pscore = 0
	if table.size(ids) == 3 then pscore = pscore + priorityScores[T_THREE_CARD] end
	-- 牌数最少
	pscore = pscore + self:getCountLess(ids, cards, 3)
	-- 对子
	local duiScore = self:duiPriority(ids)
	pscore = pscore + duiScore
	-- 碰
	local pengScore = self:sameIdPriority(ids, cards, 3)
	pscore = pscore + pengScore 
	-- 杠
	local gangScore = self:sameIdPriority(ids, cards, 4)
	pscore = pscore + gangScore 
	
	return pscore
end

pPriority.sameIdPriority = function(self, ids, cards, min)
	if not min then min = 2 end
	local count = self:getCombCount(ids, min)
	return priorityScores[countToType[min]] * count
end

pPriority.getIdCountInIds = function(self, ids, min)
	if not min then min = 1 end
	local idsToCount = self:getCardIdToCount(ids)
	local idCount = 0
	for id, count in pairs(idsToCount) do
		if count >= min then
			idCount = idCount + 1
		end
	end
	return idCount
end

pPriority.getCardIdToCount = function(self, list)
	if not list then return end
	local cardCounts = {}
	for _, id in pairs(list) do
		if not cardCounts[id] then 
			cardCounts[id] = 1 
		else
			cardCounts[id] = cardCounts[id] + 1
		end
	end
	return cardCounts
end

pPriority.duiPriority = function(self, ids)
	local count = self:getCombCount(ids)
	return  priorityScores[T_DUI] * count
end

pPriority.getCombCount = function(self, ids, min)
	if not min then  min = 2 end
	local count = 0
	local duis = self:getCardIdToCount(ids)
	for id, c in pairs(duis) do
		if c == min then 
			count = count + 1
		end
	end
	return count
end

pPriority.cardIdSum = function(self, ids, cards)
	local sum = self:getCardIdSum(ids)
	for _, list in pairs(cards) do
		local csum = self:getCardIdSum(list)
		if csum > sum then
			return 0
		end
	end
	return priorityScores[T_CARD_ID_SUM]
end

pPriority.getCardIdSum = function(self, ids)
	if table.size(ids) < 2 then 
		return priorityScores[T_MAX] 
	end
	local sum = 0
	for i = table.size(ids), 1, -1 do
		if ids[i - 1] then
			sum = sum + ids[i] - ids[i - 1]
		end
	end
	return sum
end


pPriority.getCountLess = function(self, ids, cards, lessnum, isQue)
	if not lessnum then lessnum = -9999 end
	local count = table.size(ids)
	for _, list in pairs(cards) do
		if table.size(list) >= lessnum and table.size(list) < count then
			return 0
		end
	end
	if isQue then return priorityScores[T_COUNT_LESS_QUE] end
	return priorityScores[T_COUNT_LESS]
end

pPriority.initPrioritys = function(self)
	local prios = {}
	for i = T_CARD_TONG, T_CARD_WAN do
		prios[i] = 0 
	end
	return prios
end

pPriority.getCardsTypes = function(self, ids)
	if not ids then return end
	-- 排序
	table.sort(ids, function(id1, id2) 
		return id1 < id2
	end)
	-- 区分
	local cards = {}
	for i = T_CARD_TONG, T_CARD_WAN do
		local cnums = numbers[i]
		if not cards[i] then cards[i] = {} end
		for _, id in pairs(ids) do
			if id >= cnums[1] and id <= cnums[2] then
				table.insert(cards[i], id)
			end
		end
	end
	return cards
end
