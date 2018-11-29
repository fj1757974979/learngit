local modCardPool = import("logic/battle/pool.lua")
local modUserData = import("logic/userdata.lua")
local modCardMain = import("logic/battle/card.lua")
local modUserData = import("logic/userdata.lua")
local modEvent = import("common/event.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modUserPropCache = import("logic/userpropcache.lua")
local modPropMgr = import("common/propmgr.lua")

pPlayer = pPlayer or class(modPropMgr.propmgr)

pPlayer.init = function(self, uid, playerId, seatId)
	modPropMgr.propmgr.init(self)
	self.seatId = seatId
	self.playerId = playerId
	self.uid = uid
	self.gender = nil
	self.goldCount = nil
	self.roomCardCount = nil
	self.nickName = nil
	self.avatarUrl = nil
	self.ip = nil
	self.flags = {}
	self.inviteCode = nil
	self.realName = nil
	self.phoneNo = nil
	self.discardIndex = 0
	self.extras = nil
	self.baseScore = 0
	-- 当前可胡的牌
	self.canHuCardIds = {}
	-- 手牌
	self.handPool = modCardPool.pHandPool:new(self)
	-- 明牌
	self.showPool = modCardPool.pShowPool:new(self)
	-- 弃牌
	self.discardPool = modCardPool.pDiscardPool:new(self)
	-- 花牌
	self.flowerPool = modCardPool.pFlowerPool:new(self)
	-- 当前发给我的牌
	self.dealCard = {}
	-- 玩家分数
	self.score = nil
	self.pools = {
		[T_POOL_HAND] = self.handPool,
		[T_POOL_DISCARD] = self.discardPool,
		[T_POOL_SHOW] = self.showPool,
		[T_POOL_FLOWER] = self.flowerPool,
	}
end

pPlayer.getPlayerId = function(self)
	return self.playerId
end

pPlayer.setCurrentDealCard = function(self, cardIds)
	for _, cardId in ipairs(cardIds) do
		table.insert(self.dealCard,  modCardMain.pCardMgr:instance():newCard(cardId, self.seatId, T_CARD_HAND))
	end
end

pPlayer.setDiscardIndex = function(self, idx)
	if not idx then return end
	self.discardIndex = idx
end

pPlayer.getDiscardIndex = function(self)
	return self.discardIndex
end

pPlayer.getCurrentDealCard = function(self)
	return self.dealCard
end

pPlayer.setBaseScore = function(self, score)
	self.baseScore = score
end

pPlayer.getBaseScore = function(self)
	return self.baseScore
end

pPlayer.addCardsToPool = function(self, poolType, args)
	local pool = self.pools[poolType]
	if pool then
		pool:addCards(args)
		if poolType == T_POOL_HAND then
			pool:sort()
		end
	end
end

pPlayer.delCardsFromPool = function(self, poolType, args)
	local pool = self.pools[poolType]
	if pool then
		pool:delCards(args)
	end
end

pPlayer.setExtras = function(self, msg)
	if not msg then return end
	-- 字符串
	if string.len(msg) <= 0 then
		return
	end
	local ex = modGameProto.YunyangPlayerExtras()
	ex:ParseFromString(msg)
	self.extras = ex
end

pPlayer.getExtras = function(self)
	if not self.extras then return end
	return self.extras.hsz
end

pPlayer.clearExtras = function(self)
	self.extras = nil
end

pPlayer.cleanAllCards = function(self)
	self:clearDealCards()
	for _, pool in pairs(self.pools) do
		pool:clean()
	end
end

pPlayer.clearDealCards = function(self)
	for _, card in pairs(self.dealCard) do
		card = nil
	end
	self.dealCard = {}
end

pPlayer.getAllCardsFromPool = function(self, poolType)
	local pool = self.pools[poolType]
	if pool then
		local cards = pool:getCards()
		return cards
	else
		log("error", "getAllCardsFromPool no pool type:", poolType)
		return {}
	end
end

pPlayer.sortShowCard = function(self)
	local combs = self:getAllCardsFromPool(T_POOL_SHOW)
	local huIndex = 0
	for idx, comb in ipairs(combs) do
		if comb.t == modGameProto.HU then
			huIndex = idx
		end
	end

	slef.pools[T_POOL_SHOW]:clean()
	self.pools[T_POOL_SHOW]:addCombination(modGameProto.HU,combs[huIndex])
	table.remove(combs,huIndex)
	for _, comb in ipairs(combs) do
		self.pools[T_POOL_SHOW]:addCombination(comb.t,comb)
	end
end

pPlayer.getHasAutoPlayingFlag = function(self)
	for _, flag in pairs(self.flags) do
		if flag == modGameProto.AUTO_PLAYING then
			return true
		end
	end
	return false
end

pPlayer.isMyself = function(self)
	return self.playerId == modBattleMgr.getCurBattle().getMyPlayerId()
end

pPlayer.isRobot = function(self)
	return self.uid < 1000
end

pPlayer.isFake = function(self)
	return false
end

pPlayer.getSeat = function(self)
	return self.seatId
end

pPlayer.getUid = function(self)
	return self.uid
end


pPlayer.getHandPool = function(self)
	return self.handPool
end

pPlayer.getShowPool = function(self)

	return self.showPool
end

pPlayer.getDiscardPool = function(self)
	return self.discardPool
end

pPlayer.getFlowerPool = function(self)
	return self.flowerPool
end

pPlayer.setRealName = function(self, name)
	self.realName = name
end

pPlayer.getRealName = function(self)
	return self.realName
end

pPlayer.setPhoneNo = function(self, no)
	self.phoneNo = no
end

pPlayer.getPhoneNo = function(self)
	return self.phoneNo
end

pPlayer.setInviteCode = function(self, code)
	self.inviteCode = code
end

pPlayer.getInviteCode = function(self)
	return self.inviteCode
end

pPlayer.setCanHuCardIds = function(self, ids)
	if not ids then return end
	self:clearCanHuCardIds()
	for _, id in ipairs(ids) do
		table.insert(self.canHuCardIds, id)
	end
end

pPlayer.clearCanHuCardIds = function(self)
	self.canHuCardIds = {}
end

pPlayer.getCanHuCardIds = function(self)
	return self.canHuCardIds
end
pPlayer.destroy = function(self)
	for _, pool in pairs(self.pools) do
		pool:destroy()
	end
	self.pools = {}
	self.flags = {}
	self.handPool = nil
	self.showPool = nil
	self.flowerPool = nil
	self.discardPool = nil
	self.inviteCode = nil
	self.realName = nil
	self.phoneNo = nil
	self.gender = nil
	self.goldCount = nil
	self.score = nil
	self.roomCardCount = nil
	self:clearCanHuCardIds()
	self:clearExtras()
	self.baseScore = 0
	for _, card in pairs(self.dealCard) do
		card = nil
	end
	self.dealCard = {}

	self.nickname = nil
	self.avatarUrl = nil
	self.ip = nil
end

pPlayer.setName = function(self, name)
	if modUIUtil.utf8len(name) > 6 then
		name = modUIUtil.getMaxLenString(name, 6)
	end
	self.nickName = name
end

pPlayer.getName = function(self)
	return self.nickName
end

pPlayer.getGender = function(self)
	if not self.gender then
		self.gender = T_GENDER_UNKOW
	end
	return self.gender
end

pPlayer.setGender = function(self, gender)
	self.gender = gender
end

pPlayer.setGoldCount = function(self, count)
	self.goldCount = count
end

pPlayer.getGoldCount = function(self)
	return self.goldCount
end

pPlayer.setRoomCardCount = function(self, count)
	self.roomCardCount = count
end

pPlayer.addScore = function(self, sc)
	if not sc then return end
	self.score = self:getScore() + sc
end

pPlayer.resetScore = function(self)
	self.score = self.baseScore
end

pPlayer.getScore = function(self)
	return self.score or self.baseScore
end

pPlayer.getRoomCardCount = function(self)
	return self.roomCardCount
end
pPlayer.setAvatarUrl = function(self,avatar)
	self.avatarUrl = avatar
end

pPlayer.getAvatarUrl = function(self)
	if not self.avatarUrl or self.avatarUrl == "" then
		self.avatarUrl = modUIUtil.getDefaultImage(self.gender)
	end
	return self.avatarUrl
end

pPlayer.setPlayerCacheProp = function(self, prop)
	if not prop then return end
	if prop["userName"] then
		self:setName(prop["userName"])
	end
	if prop["gender"] then
		self:setGender(prop["gender"])
	end
	if prop["avatarUrl"] then
		self:setAvatarUrl(prop["avatarUrl"])
	end
	if prop["realName"] then
		self:setRealName(prop["realName"])
	end
	if prop["phoneNo"] then
		self:setPhoneNo(prop["phoneNo"])
	end
end

pPlayer.updateUserProps = function(self, uid, seatId)
	modBattleRpc.updateUserProps(uid,function(success,reply)
		if success then
			self.nickName = reply.nickname
			self.avatarUrl = reply.avatar_url
			self.gender = reply.gender
			self.goldCount = reply.gold_coin_count
			self.roomCardCount = reply.room_card_count
			self.ip = modUIUtil.stringToIP(reply.ip_address)
			self.inviteCode = reply.invite_code
			self.realName = reply.real_name
			self.phoneNo = reply.phone_no
			if self.avatarUrl == "" then
				self.avatarUrl = self:getAvatarUrl()
			end
			self:setUserPropCacheData("userName", self.nickName)
			self:setUserPropCacheData("avatarUrl", self.avatarUrl)
			self:setUserPropCacheData("roomCards", self.roomCardCount)
			self:setUserPropCacheData("goldCount", self.gender)
			self:setUserPropCacheData("ip", self.ip)
			self:setUserPropCacheData("inviteCode", self.inviteCode)
			self:setUserPropCacheData("realName", self.realName)
			self:setUserPropCacheData("phoneNo", self.phoneNo)
			self:setUserPropCacheData("gender", self.gender)

			self:setProp("userName", self.nickName)
			self:setProp("avatarUrl", self.avatarUrl)
			self:setProp("ip", self.ip)
			self:setProp("realName", self.realName)
			self:setProp("gender", self.gender)
			self:setProp("phoneNo", self.phoneNo)

			logv("error", "__________ ", self.nickName, self.avatarUrl)


			modEvent.fireEvent(EV_UPDATE_USER_PROP, seatId, self.nickName, self.avatarUrl, self.ip, self.playerId)
			modEvent.fireEvent(EV_UPDATE_DISSROOM_NAME, modBattleMgr.getCurBattle():getPlayerIdBySeatId(seatId), self.nickName, self.avatarUrl)
		end
	end)
end

pPlayer.setUserPropCacheData = function(self, name, value)
	modUserPropCache.getCurPropCache():setProp(self.uid, name, value)
end

pPlayer.getAllCardCount = function(self)
	local hands = self.handPool:getCards()
	local combs = self.showPool:getCards()
	local handCardsCount = table.size(hands)
	local combCount = 0
	for idx,comb in pairs(combs) do
		for _, cardId in ipairs(comb:getCards()) do
			combCount = combCount + 1
		end
		if comb.t == modGameProto.ANGANG or comb.t == modGameProto.XIAOMINGGANG or comb.t == modGameProto.DAMINGGANG then
			combCount = combCount - 1
		end
	end
	return handCardsCount + combCount
end

pPlayer.getIP = function(self)
	return self.ip
end

pPlayer.getFlags = function(self)
	return self.flags
end

pPlayer.setFlag = function(self, flag)
	self.flags[flag] = flag
	--table.insert(self.flags, flag)
end

pPlayer.clearFlags = function(self)
--	print(debug.traceback())
	self.flags = {}
end

pPlayer.clearFlagByIndex = function(self, key)	
	self.flags[key] = nil
end
