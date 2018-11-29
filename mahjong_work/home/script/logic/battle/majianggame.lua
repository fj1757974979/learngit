--- 麻将
-- 管理游戏规则及玩法
local modBattleMgr = import("logic/battle/main.lua")
local modSessionMgr = import("net/mgr.lua")
local modUserPropCache = import("logic/userpropcache.lua")
local modUtil = import("util/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUserData = import("logic/userdata.lua")
local modPlayer = import("logic/battle/player.lua")
local modEvent = import("common/event.lua")
local modBattleUI = import("ui/battle/main.lua")
local modUIFunctionManager = import("ui/common/uifunctionmanager.lua")
local modVoiceDefault = import("data/info/info_voices_default.lua")
local modSound = import("logic/sound/main.lua")
local modRuleMain = import("ui/menu/rule.lua")
local modChatMgr = import("logic/chat/mgr.lua")
local modMenuMain = import("ui/menu/main.lua")
local modChannelMgr = import("logic/channels/main.lua")

local setMenuBtnValues = { "zhengdong", "fangyan", "click", "big"}

pMajiangGame = pMajiangGame or class()

pMajiangGame.init = function(self, options)
	-- 当前局数
	self.currentRound = 0
	-- 总局数
	self.totalRound = 0
	-- 默认解散时间
	self.timeOut = 60
	-- 剩余牌数
	self.undealCardCount = nil
	-- 当前麻将类型
	self.currMJType = nil
	-- 最大手牌
	self.maxCardCount = nil
	-- 连庄次数
	self.bankerZhuangCount = nil
	-- 设置面板配置
	self.btnValues = {}
	-- 鬼牌
	self.magicCardIds = {}
	-- 当前可选牌属性
	self.curChooseWndProps = {}
	-- 当前打的牌
	self.discardBeforePorto = {}
	-- 建议打牌
	self.suggestions = {}
	-- 是否可以预听
	self.isPreting = false
	-- 麻将类型
	self.ruleType = nil
	-- gameState
	self.gameState = options[K_ROOM_STATE]
	-- 设置房间属性	
	self:setRoomParam(options)	
end

--------------------- get set ----------------------
pMajiangGame.getIsPreting = function(self)
	return self.isPreting
end

pMajiangGame.setIsPreting = function(self, isTrue)
	self.isPreting = isTrue
end

pMajiangGame.getPlayers = function(self)
	return self:getCurBattle():getAllPlayers()
end

pMajiangGame.clearAllPlayerDiscardIndex = function(self)
	for _, player in pairs(self:getPlayers()) do
		player:setDiscardIndex(0)
	end
end

pMajiangGame.chooseCardsWork = function(self, istrue)
	self.battleUI:updateCardIsShow(-1, true)
	self.battleUI:notSelectCardSetTingColorWork()
	return
end

pMajiangGame.isSpecialGuo = function(self, drawCombTexts)
	return
end

pMajiangGame.isGang = function(self, t)
	return t == modGameProto.ANGANG or t == modGameProto.XIAOMINGGANG or t == modGameProto.DAMINGGANG
end

pMajiangGame.setCardIdToCurDiscard = function(self, id)
	if not self.discardBeforePorto then self.discardBeforePorto = {} end
	table.insert(self.discardBeforePorto, id)
end

pMajiangGame.getDiscardBeforPorto = function(self)
	return self.discardBeforePorto or {}
end

pMajiangGame.clearDiscardBeforPorto = function(self)
	self.discardBeforePorto = {}
end

pMajiangGame.askCombHasMingWork = function(self, combs)
	return
end

pMajiangGame.clearAllPlayersHuCardIds = function(self)
	if not self:getPlayers() then return end
	for _, player in pairs(self:getPlayers()) do
		player:clearCanHuCardIds()
	end
end

pMajiangGame.getBattleUI = function(self)
	return self.battleUI
end

pMajiangGame.setCurrMJTpe = function(self, t)
	self.currMJType = t
end

pMajiangGame.getIsCanDiscardCard = function(self, id)
	local isCan = false
	if not self.canDiscardCardIds or not id then
		return
	end
	for _, did in pairs(self.canDiscardCardIds) do
		if did == id then isCan = true end
	end
	return (self.canDiscardCardFlag and isCan)
end

pMajiangGame.getCanDiscardCardIds = function(self)
	return self.canDiscardCardIds or {}
end

pMajiangGame.setDiCardIndex = function(self, index)
	self.diCardIndex = index
end

pMajiangGame.getDiCardIndex = function(self)
	return self.diCardIndex
end

pMajiangGame.setDiCardId = function(self, id)
	self.diCardId = id
end

pMajiangGame.getDiCardId = function(self)
	return self.diCardId
end

pMajiangGame.getCurrMJType = function(self)
	return self.currMJType
end

pMajiangGame.getRoomType = function(self)
	return self.roomType
end


pMajiangGame.setCurRound = function(self,cur)
	self.currentRound = cur
end

pMajiangGame.setTotRound = function(self,tot)
	self.totalRound = tot
end

pMajiangGame.getRuleType = function(self)
	return self.ruleType
end

pMajiangGame.getCurRound = function(self)
	return self.currentRound
end

pMajiangGame.getTotRound = function(self)
	return self.totalRound
end
--可加判断去除金替
pMajiangGame.setMagicCard = function(self,cardIds)	
	--根据类型判断是不是平和麻将，是平和麻将就做特殊处理
	if self.ruleType == 14 then
		if(#cardIds > 1) then	
			cardIds = {cardIds[1]}
		end
	end	
	if not cardIds then return end
	self.magicCardIds = {}
	for _, id in ipairs(cardIds) do
		if self:isInsertMagic(id) then
			table.insert(self.magicCardIds, id)
		end
	end
end

pMajiangGame.getMagicCard = function(self)
	return self.magicCardIds
end

pMajiangGame.getCurPlayer = function(self)
	return self:getCurBattle():getPlayerByPlayerId(self:getCurBattle():getMyPlayerId())
end

pMajiangGame.updateUndealtCard = function(self,count)
	if self.battleUI then
		self.battleUI:updateUndealtCard(count)
	end
end


pMajiangGame.setMaxCardCount = function(self, c)
	self.maxCardCount = c
end

pMajiangGame.getMaxCardCount = function(self)
--	if self:isTaoJiang() and self.maxCardCount ~= 15 then
--		self.maxCardCount = 15
--	end
	return self.maxCardCount
end

pMajiangGame.getHuaSeFanWei = function(self, f)
	local numbers = {
		[modGameProto.YUNYANG_QUE_TONG] = {0, 8},
		[modGameProto.YUNYANG_QUE_SUO] = {9, 17},
		[modGameProto.YUNYANG_QUE_WAN] = {18, 26},
	}

	if not f then
		return numbers
	end
	return numbers[f] or {}
end

pMajiangGame.isDongShan = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.DONGSHAN
end

pMajiangGame.isPingHe = function ( self )
	return self.ruleType == modLobbyProto.CreateRoomRequest.PINGHE
end

pMajiangGame.isDongShanQueYue = function(self)
	return modUtil.getOpChannel() == "ds_queyue"
end

pMajiangGame.isPingHeMJ = function ( self )
	return modUtil.getOpChannel() == "qs_pinghe"   --标注
end

pMajiangGame.isZhaoAnQueYue = function(self)
	return modUtil.getOpChannel() == "za_queyue"
end

pMajiangGame.isTaoJiangLexian = function(self)
	return modUtil.getOpChannel() == "tj_lexian"
end

pMajiangGame.isYunYangDouDou = function(self)
	return modUtil.getOpChannel() == "yy_doudou"
end

pMajiangGame.isTianJinMJ = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.TIANJIN
end

pMajiangGame.isZhaoAn = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.ZHAOAN
end

pMajiangGame.isHongZhong = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.HONGZHONG
end

pMajiangGame.isYunYangMj = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.YUNYANG
end

pMajiangGame.isXueZhanDaoDiMj = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.CHENGDU
end

pMajiangGame.isKawuxingMJ = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.XIANGYANG
end

pMajiangGame.isZhuanZhuanMJ = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.ZHUANZHUAN
end

pMajiangGame.isTaoJiangMJ = function(self)
	return self.ruleType == modLobbyProto.CreateRoomRequest.TAOJIANG
end

pMajiangGame.getDealCount = function(self)
--	if self:isTaoJiang() then
--		return 2
--	else
		return 1
--	end
end

pMajiangGame.getBankerZhuangCount = function(self)
	return self.bankerZhuangCount
end

pMajiangGame.isKoupaimode = function(self)
	return self.roomInfo.conceal_discarded_cards
end

pMajiangGame.isClubRoom = function(self)
	return self.roomInfo.room_type == modLobbyProto.CreateRoomRequest.CLUB_SHARED
end
------------------ get set over -------------------
-- ^^^^^^^^^^^^^^^ 非基类 ^^^^^^^^^

-- ^^^^^^^^^^^^^^^ over  ^^^^^^^^^^^
pMajiangGame.pretingEvent = function(self, combs)
	return
end

pMajiangGame.askCheckGameOver = function(self)
	self:clearAllPlayersHuCardIds()
	self:clearCanDiscardCardIds()
	self.battleUI:clearSelectTipWnd()
	self:clearAllPlayerExtras()
	self.battleUI:clearPlayerExtrasWnds()
	return
end

------------------ 回复协议 ------------
pMajiangGame.rpcChooseComb = function(self, idx, versionId)
	if not idx then return end
	modBattleRpc.chooseCombIdx(idx, versionId, function(success, reply)
		if success then
			self:getCurBattle():getBattleUI():clearCombMenu()
		end
	end)
end

pMajiangGame.rpcChooseAngang = function (self,agidx,plid)
	logv("warn","pMajiangGame.rpcChooseAngang",agidx,plid)
	if not plid then return end
	modBattleRpc.chooseAnGangIdx(agidx,plid,function ( success,reply )
		if success then
			logv("warn","抢杠成功")
		else
			logv("warn","请选择正确的玩家和暗杠")
		end
	end)
end

pMajiangGame.isInsertMagic = function(self, id)
	for _, mId in pairs(self.magicCardIds) do
		if id == mId then
			return false
		end
	end
	return true
end

pMajiangGame.setChooseWndProp = function(self, message)
	if not message then return end
	local prop = {}
	if message.card_pool_type then
		prop["pooltype"] = message.card_pool_type
	end
	if message.card_ids then
		if not prop["ids"] then prop["ids"] = {} end
		for _, id in ipairs(message.card_ids) do
			table.insert(prop["ids"], id)
		end
	end
	if message.number_of_cards then
		prop["count"] = message.number_of_cards
	end
	if message.player_id then
		prop["pid"] = message.player_id
		self.curChooseWndProps[message.player_id] = prop
	end
end

pMajiangGame.getChooseWndProp = function(self, pid, name)
	if not pid or not name then return end
	if not self.curChooseWndProps or not self.curChooseWndProps[pid] then
		return
	end
	return self.curChooseWndProps[pid][name]
end

pMajiangGame.clearChooseWndProps = function(self)
	self.curChooseWndProps = {}
end

pMajiangGame.getSelfHasTing = function(self)
	local modUIUtil = import("ui/common/util.lua")
	return modUIUtil.getIsTing(self:getCurPlayer())
end

pMajiangGame.setRoomParam = function(self, param)
	self.param = param
	self:setMagicCard(param[K_ROOM_STATE].options.magic_card_ids)		
	self.roomInfo = param[K_ROOM_INFO]	
	log("info","--------------magicCard---------------",self.magicCardIds)
	self:setCurrMJTpe(self.roomInfo.rule_type)
	self.ruleType = self.roomInfo.rule_type
	self.roomType = self.roomInfo.room_type
	self.maxCardCount = self.gameState.options.max_number_of_cards_per_player
end

pMajiangGame.initBattleUI = function(self)
	if self.battleUI then
		self.battleUI:destroy()
	end
	-- 麻将UI	
	self.battleUI = self:getNewBattleUI():new()	
	self.battleUI:videoBattle()
	-- 设置房间属性
	self:setBattleInfo()
end

pMajiangGame.setBattleInfo = function(self)
	local curTurnPlayer = self:getCurBattle():getCurTurnPlayer()
	local players = self:getCurBattle():getAllPlayers()
	self.battleUI:initFromData(self.seatToUid, players, curTurnPlayer, self.param)
	self.battleUI:setRoomInfo(self.roomInfo)
end

pMajiangGame.getNewBattleUI = function(self)
	logv("info","pMajiangGame.getNewBattleUI")
	if not self.ruleType then return end
	local crr = modLobbyProto.CreateRoomRequest
	local zhuanzhuangame = import("ui/battle/zhuanzhuan_panel.lua")
	local hongzhonggame = import("ui/battle/hongzhong_panel.lua")
	local daodaogame = import("ui/battle/daodao_panel.lua")
	local taojianggame = import("ui/battle/taojiang_panel.lua")
	local dongshangame = import("ui/battle/dongshan_panel.lua")
	local zhaoangame = import("ui/battle/zhaoan_panel.lua")
	local maominggame = import("ui/battle/maoming_panel.lua")
	local tianjingame = import("ui/battle/tianjin_panel.lua")
	local yunyanggame = import("ui/battle/yunyang_panel.lua")
	local xiangyanggame = import("ui/battle/xiangyang_panel.lua")
	local baihegame = import("ui/battle/baihe_panel.lua")
	local rongchenggame = import("ui/battle/rongcheng_panel.lua")
	local chengdugame = import("ui/battle/chengdu_panel.lua")
	local jininggame = import("ui/battle/jining_panel.lua")
	local pinghegame = import("ui/battle/pinghe_panel.lua")		
	local mjts = {
		[crr.ZHUANZHUAN] = zhuanzhuangame.pZhuanzhuanPanel,
		[crr.HONGZHONG] = hongzhonggame.pHongzhongPanel,
		[crr.DAODAO] = daodaogame.pDaodaoPanel,
		[crr.TAOJIANG] = taojianggame.pTaojiangPanel,
		[crr.DONGSHAN] = dongshangame.pDongshanPanel,		
		[crr.ZHAOAN]= zhaoangame.pZhaoanPanel,
		[crr.MAOMING] = maominggame.pMaomingPanel,
		[crr.TIANJIN] = tianjingame.pTianjinPanel,
		[crr.YUNYANG] = yunyanggame.pYunyangPanel,
		[crr.XIANGYANG] = xiangyanggame.pXiangyangPanel,
		[crr.RONGCHENG] = rongchenggame.pRongchengPanel,
		[crr.CHENGDU] = chengdugame.pChengduPanel,
		[crr.XIANGYANG_BAIHE] = baihegame.pBaihePanel,		
		[crr.JINING] = jininggame.pJiningPanel,	
		[crr.PINGHE] = pinghegame.pPinghePanel,
	}
	return mjts[self.ruleType]
end

pMajiangGame.getCurBattle = function(self)
	return modBattleMgr.getCurBattle()
end

pMajiangGame.getPlayerHasMingComb = function(self, p)
	local player = self:getCurPlayer()
	if p then
		player = p
	end
	local combs = player:getAllCardsFromPool(T_POOL_SHOW)
	for _, comb in pairs(combs) do
		if comb.t == modGameProto.MING then
			return true
		end
	end
	return false
end

pMajiangGame.getCurSubTimeCount = function(self)
	if not self.gameState then return 0 end
	return self.gameState.sub_time_count or 0
end

pMajiangGame.leaveRoomCleanPlayerInfo = function(self,uid)
	local seatId = self.uidToSeat[uid]
	if seatId then
		self.uidToSeat[uid] = nil
	else
		return
	end
	self.seatToUid[seatId] = nil
	local players = self:getPlayers()
	local player = players[seatId]
	if player then
		players[seatId] = nil
		self.playerCnt = math.max(0, self.playerCnt - 1)
		if player:isRobot() then
			self.robotCnt = math.max(0, self.robotCnt - 1)
		end
	end
	return players
end

pMajiangGame.setDiscardMark = function(self, markId, player)
	self.battleUI:setCurrDiscardCard(markId, player:getSeat())
end

pMajiangGame.getSuggestions = function(self)
	return self.suggestions
end

pMajiangGame.delBeforeCard = function(self)
	local discardBeforePorto = self:getDiscardBeforPorto()
	local player = self:getCurPlayer()
	local cards = player:getDiscardPool():getCards()
	for _, id in pairs(discardBeforePorto) do
		local removeIds = {}
		for i = table.size(cards) , 0, -1 do
			if cards[i] and cards[i]:getId() == id then
				table.insert(removeIds, i)
				break
			end
		end
		for _, delIndex in pairs(removeIds) do
			table.remove(cards, delIndex)
		end
	end
end

pMajiangGame.clearCanDiscardCardIds = function(self)
	if self.canDiscardCardIds then
		self.canDiscardCardIds = {}
	end
end

pMajiangGame.setCanDiscardCardIds = function(self, ids)
	self.canDiscardCardIds = ids
end

pMajiangGame.canDiscardCard = function(self)
	return self.canDiscardCardFlag
end

pMajiangGame.setCanDiscardCardFlag = function(self, flag)
	self.canDiscardCardFlag = flag
	if not flag then
		self.suggestions = {}
		self.isPreting = flag
		self:clearCanDiscardCardIds()
	end
end

pMajiangGame.getBankerId = function(self)
	return self.gameState.banker_id
end

pMajiangGame.hasPlayerInList = function(self, player, list)
	if not player or not list then return end
	for _, p in pairs(list) do
		if p == player then
			return true
		end
	end
	return false
end

pMajiangGame.start = function(self, message)	
	modSound.getCurSound():playSound("sound:gamestart.mp3")

	if message then
		local gameState = message.initial_state
		self.gameState = gameState
	end
	self:updateStartPlayerFlags(self.gameState.player_states)
	self:setMagicCard(self.gameState.options.magic_card_ids)
	self:getCurBattle():setIsCalculate(self.gameState.is_over)
	self:setDiCardIndex(self.gameState.options.special_card_position)
	self:setDiCardId(self.gameState.options.special_card_id)
	self:setCurRound(self.gameState.time_count + 1)
	self:getCurBattle():setIsGaming(true)
	self:getCurBattle():setIsCalculate(self.gameState.is_over)
	self:setMaxCardCount(self.gameState.options.max_number_of_cards_per_player)
	self.battleUI:calcPos()
	self.battleUI:showPiaoWnd(false)
	self.battleUI:showReturnBtn(false)
	if self.battleUI:isSelfShow() == false then
		self.battleUI:show(true)
	end
	self.battleUI:setRoomInfo(self.roomInfo)
	self.battleUI:showYaoQing(false)
	self.battleUI:showTime()
	if self:getCurBattle():getIsCalculate() then
		self.battleUI:initIconPos()
	else
		if self:getCurBattle():getIsGaming() then
			self.battleUI:resetIconPos()
		end
	end
	self.battleUI:clearOkReady()
	self.battleUI:clearWndByName("wnd_role_%d_score")
	self.battleUI:clearWndByName("wnd_role_%d_name")
	local isAll = function() return
		self:isTaoJiangMJ() and
		self:isHongZhong() and
		self:isZhaoAn()
	end
	self.battleUI:clearWndByName("wnd_piao_%d", isAll())
	self.battleUI:clearOwnerMark()
	self.battleUI:updatePiaoText(self:getPlayers())
	self.battleUI:hostMark(self.gameState.banker_id, self.roomInfo.max_number_of_users)
	self:getCurBattle():seatConvertToDir(self.gameState.east_player_id)
	self.battleUI:initDir()
	self.battleUI:showUser(self.playerOnlineInfo)
	self.battleUI:updatePlayerScores()
	self.bankerZhuangCount = self.gameState.banker_remaining_count
	-- 画玩家手牌
	self.battleUI:updatePlayerCards(self:getPlayers())
	-- 游戏阶段和flag
	self:gamePhaseFunction(self.gameState.phase)
	-- 画鬼牌和地牌
	self:showMagicAndDi()
	-- 更新离地张数
	self.battleUI:updateUndealtCard(self.gameState.undealt_card_count)
	-- 保留张数
	self.battleUI:updateReservedCard(self.gameState.reserved_card_count)
	-- 更新剩余张数位置
	self.battleUI:updateUndealtCardPos()
	-- 重登检查是否在小结算
	self.battleUI:gameOverClear()
	-- 检查是否有ok标志
	self:checkOkFlag()
	-- 检查三人游戏东南西北上移
	self.battleUI:setTimePos()
	-- 检查是否有漏胡
	self.battleUI:checkLouFlag()
	-- 检查是否有重连的个人信息展示地图
	self.battleUI:checkPlayerInfo()
	-- 清除需要清除的界面
	self:startClearWnds()
	-- 如果还有人在小结算
--	self:waitStartGame()
	-- 停掉uifunciton
	self:clearUIFunctionMgr()
	-- 清除打过的牌
	self:clearDiscardBeforPorto()
	-- 是否有取消听牌
--	self.battleUI:showCancelMingpai()
	-- 是否可胡牌
	-- 是否有显示宝牌鬼牌
	self.battleUI:updateMagicAndDiCards()
	-- 是否显示@离线按钮
	self.battleUI:updateBtnTell()
	-- 是否显示@全体离线
	self.battleUI:updateIsShowBtnTellAll()
	-- 更新听牌wnd
	self.battleUI:updateTingWnds()
	-- 胡牌提示
	self.battleUI:updateWinnerCardsWnds()
	-- 玩家附加信息
	self.battleUI:showPlayerExtrasWnds(modBattleMgr.getCurBattle():getCurPlayer())
	-- 是否托管
	self.battleUI:updateAllPlayersAtuoPlayingFlag()
	-- 子类start
	self:personalStart()
end

pMajiangGame.updateStartPlayerFlags = function(self, playerStates)
	if not playerStates then return end
	-- flag
	for playerId, playState in ipairs(playerStates) do
		local player = modBattleMgr.getCurBattle():getPlayerByPlayerId(playerId - 1)
		player:clearFlags()
		for _, flag in ipairs(playState.flags) do
			player:setFlag(flag)
		end

	end
end

pMajiangGame.personalStart = function(self)
	return
end

pMajiangGame.waitStartGame = function(self)
	if not self:getCurBattle():getIsCalculate() then return end
	self.battleUI:initIconPos()
end

pMajiangGame.startClearWnds = function(self)
	self.battleUI:startClear()
end

pMajiangGame.hasDiscardCard = function(self, player)
	if not player then return end
	local cards = player:getAllCardsFromPool(T_POOL_DISCARD)
	return table.getn(cards) > 0
end

pMajiangGame.getAllPlayerHasDiscard = function(self)
	local isHas = true
	for _, player in pairs(self:getPlayers()) do
		if not self:hasDiscardCard(player) then
			isHas = false
			break
		end
	end
	return isHas
end

pMajiangGame.checkOkFlag = function(self)
	for _, player in pairs(self:getPlayers()) do
		local flags = player:getFlags()
		for _, flag in pairs(flags) do
			if flag == modGameProto.GAME_OVER_CHECKED then
				self.battleUI:gameOverShowOk(player:getSeat(), true)
			end
		end
	end
end

pMajiangGame.showMagicAndDi = function(self)
	-- 鬼牌
	self:showMagic()
	-- 地牌
	self:showDi()
end

pMajiangGame.showMagic = function(self)
	local x, y = 0, 0
	local cards = self:getMagicCard()
	if table.size(cards) > 0 then
		local bgWnd = self.battleUI:showCard("magic", x, y, cards, 0.8, true)
		self.battleUI:setMagicCardPos(bgWnd)
		if self:getIsSetSpecialPosToDicardPos(cards) then
			self.battleUI:setDiCardPos(bgWnd)
		end
	end
end

pMajiangGame.getIsSetSpecialPosToDicardPos = function(self, cards)
	if not cards then return end
	return table.size(cards) > 1
end

pMajiangGame.showDi = function(self)
	local x, y = 0, 0
	if self:isShowDiCard() then
		local diCards = {self:getDiCardId()}
		if table.size(diCards) > 0 then
			local diBg = self.battleUI:showCard("di", x, y, diCards, 0.8, nil, true)
			self.battleUI:setDiCardPos(diBg)
		end
	end
end

pMajiangGame.isShowDiCard = function(self)
	local mjs = {
		[modLobbyProto.CreateRoomRequest.TAOJIANG] = true,
		[modLobbyProto.CreateRoomRequest.RONGCHENG] = true,
	}
	return mjs[self:getCurrMJType()]
end

pMajiangGame.isRongChengMJ = function(self)
	return self:getCurrMJType() == modLobbyProto.CreateRoomRequest.RONGCHENG
end

pMajiangGame.destroy = function(self)
	self.magicCardIds = {}
	self.suggestions = {}
	if self.battleUI then
		self.battleUI:destroy()
		self.battleUI:setParent(nil)
		self.battleUI = nil
	else
		modBattleUI.pBattlePanel:instance():destroy()
	end
	self.discardBeforePorto = {}
	self.isDiscarded = false
	self:clearCanDiscardCardIds()
	self.videoLocations = nil
	self.maxCardCount = nil
	self.roomType = nil
	self.currentRound = 0
	self.currMJType = nil
	self.undealCardCount = nil
	self.totalRound = 0
	self.ruleType = nil
	self.diCardId = nil
	self.diCardIndex = nil
	self.bankerZhuangCount = nil
	self.btnValues = nil
	self.currMJType = nil
	self.isPreting = false
	self:clearUIFunctionMgr()
	modChatMgr.pChatMgr:instance():setBattle(nil)
end

pMajiangGame.clearUIFunctionMgr = function(self)
	if modUIFunctionManager.pUIFunctionManager:getInstance() then
		modUIFunctionManager.pUIFunctionManager:instance():destroy()
	end
end

pMajiangGame.setMagicCardFunction = function(self, message)
	if not message then return end
	self:setMagicCard(message.magic_card_ids)
	self:setDiCardId(message.special_card_id)
	self.battleUI:updateMagicAndDiCards()
	self.battleUI:updateAllPlayerCards()
end

pMajiangGame.isShowPhaseWnd = function(self)
	-- 游戏阶段
	local isPhase = self:getIsShowPhaseWnd()
	if not isPhase then return end
	-- 已经选过就不显示
	local player = self:getCurPlayer()
	if not player then return end
	local flags = player:getFlags()
	if not flags then return end
	for _, f in pairs(flags) do
		if self:isPiaoCase(f) then
			return false
		end
	end
	return true
end

pMajiangGame.getIsShowPhaseWnd = function(self)
	return self:getCurBattle():isPhasePiao()
end

pMajiangGame.getIsShowPhaseBG = function(self)
	return
end

pMajiangGame.isPiaoCase = function(self, f)
	return f == modGameProto.PIAO_A or f == modGameProto.PIAO_B or
	f == modGameProto.PIAO_C or f == modGameProto.PIAO_D or f ==
	modGameProto.PIAO_E
end

-- ********************* 接口实现 **********************

pMajiangGame.afterSetParseGame = function(self)
	return
end

pMajiangGame.afterSetGamePhase = function(self, phase)
	-- TODO ?????
	if self.battleUI then
	end
end

pMajiangGame.askChooseCardToDiscard = function(self, message)
	if not message then return end
	local ids = {}
	if message then
		ids = message.card_ids
		self.suggestions = message.suggestions
		self.isPreting = message.pre_ting
	end
	self:setCanDiscardCardFlag(true)
	self.canDiscardCardIds = {}
	-- 建议打牌
	if self.battleUI then
		self.battleUI:suggMark()
		if self.isPreting then
			self:pretingWork()
		end
	end
	if not ids then return end
	for _, id in ipairs(ids) do
		table.insert(self.canDiscardCardIds, id)
	end
	-- 有打牌列表 压暗其他牌
	if table.getn(self.canDiscardCardIds) <= 0 then return end
	if self.battleUI then
		self.battleUI:notInDiscardListSetTingColor()
	end
end

pMajiangGame.pretingWork = function(self)
	return
end

pMajiangGame.askChoosePlayerFlag = function(self, message)
	if not message then return end

	local battle = modBattleMgr.getCurBattle()
	local player = self:getCurBattle():getCurPlayer()
	local flags = {}
	for _, f in ipairs(message.player_flags) do
		table.insert(flags, f)
	end
	-- UITODO
	-- self.battleUI:askChoosePlayerFlag
	-- 请求玩家选择
	if table.getn(flags) > 0 then
		self.battleUI:askFlagShowPiaoWnds(flags, message)
	end
end

pMajiangGame.addFlagWork = function(self, flag, player)
	return
end

pMajiangGame.addClearFlagWork = function ( self,flag,player )
	return
end

pMajiangGame.updatePlayerFlags = function(self, message)
	logv("warn","pMajiangGame.updatePlayerFlags")
	logv("warn",message)
	if not message then return end
	-- logic
	-- ui TODO
	local battle = self:getCurBattle()
	local player = battle:getPlayerByPlayerId(message.player_id)
	local gender = player:getGender()
	-- 增
	for _, flag in ipairs(message.set_player_flags) do
		logv("warn",flag)
		if player then
			-- 设置player的flag
			player:setFlag(flag)
			-- 更新player flag标志
			self.battleUI:setPiaoText(player:getSeat(), flag)
			-- 听牌标志动画
			if flag == modGameProto.TING then
				self.battleUI:updateTingCardColor(player:getSeat())
				modSound.getCurSound():playCombSound(modGameProto.TING, gender)
				self.battleUI:showCombEffect(modGameProto.TING, player:getSeat())
				if player:getSeat() == 0 then
					self.battleUI:updateMagicAndDiCards()
				end
			-- 准备ok手势
			elseif flag == modGameProto.GAME_OVER_CHECKED then
				self.battleUI:gameOverShowOk(player:getSeat(), true)
			end
			-- 添加flag处理
			self:addFlagWork(flag, player)
		end
	end

	-- 删
	for _, flag in ipairs(message.cleared_player_flags) do
		logv("warn",message.cleared_player_flags)
		logv("warn",flag)
		if player then
			logv("warn",flag)
			self:addClearFlagWork(flag,player)
			player:clearFlagByIndex(flag)
			if flag == modGameProto.GAME_OVER_CHECKED then
				self.battleUI:gameOverShowOk(player:getSeat(), false)
			end
		end
	end

	-- 更新漏胡等特殊标志
	self:updateSpeicalFlag(player)
end


pMajiangGame.updateSpeicalFlag = function(self, player)
	-- 漏胡展示
	self.battleUI:updateLouFlagWnds(player)
	-- 更新听标志
	self.battleUI:updateTingWnds()
	-- 更新托管标志
	self:autoPlayingUpdate(player)
end

pMajiangGame.autoPlayingUpdate = function(self, player)
	self.battleUI:updatePlayerAutoPlayingFlag(player)
	if not player or player:getSeat() ~= T_SEAT_MINE then
		return
	end
	self:autoPlayingClearState(player)
end

pMajiangGame.autoPlayingClearState = function(self, player)
	return
end

pMajiangGame.startGame = function(self, message)
	-- clear player info and set magic infos TODO
	local battle = self:getCurBattle()
	battle:stop()
	self:clearAllPlayerDiscardIndex()
	self:clearAllPlayersHuCardIds()
	self:clearCanDiscardCardIds()
	battle:clearAllPlayerFlags()
	self:clearAllPlayerExtras()
	self:start(message)
	self.battleUI:clearPlayerExtrasWnds()
--	self:updateScoreByStartGame(message)
end

pMajiangGame.updateScoreByStartGame = function(self, message)
	if not message then return end
	local states = message.initial_state.player_states
	for pid, state in ipairs(states) do
		self:getCurBattle():updateScoreByPid(pid - 1, state)
	end
	self.battleUI:updatePlayerScores()
end

pMajiangGame.clearAllPlayerExtras = function(self)
	for _, player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
		player:clearExtras()
	end
end

pMajiangGame.updatePlayerScore = function(self, message)
	if not message then return end
	local fplayer = self:getCurBattle():getPlayerByPlayerId(message.from_player_id)
	local tplayer = self:getCurBattle():getPlayerByPlayerId(message.to_player_id)
	local score = message.score_delta
	fplayer:addScore(-score)
	tplayer:addScore(score)
	self.battleUI:updatePlayerScores()
end

pMajiangGame.updateCardPoolUpdate = function(self, message)		
	if not message then return end
	-- 更新牌池 TODO
	local battle = self:getCurBattle()
	local poolType = message.t
	local playerId = message.player_id
	local seatId = battle:getSeatByPlayerId(playerId)
	local player = battle:getPlayerByPlayerId(playerId)
	local gender = player:getGender()
	local isAddDiscardCard = false
	local addDiscardCards = {}
	-- 先删
	if poolType == modGameProto.HELD_CARD_POOL then
		player:clearDealCards()
	end
	for _, set in ipairs(message.del_set or {}) do
		local pools = {
			[modGameProto.HELD_CARD_POOL] = T_POOL_HAND,
			[modGameProto.DISCARDED_CARD_POOL] = T_POOL_DISCARD,
			[modGameProto.BONUS_CARD_POOL] = T_POOL_FLOWER,
		}
		player:delCardsFromPool(pools[poolType], set.card_ids)
		-- 预出牌被别人打comb
		if poolType == modGameProto.DISCARDED_CARD_POOL then
			if player:getPlayerId() == battle:getMyPlayerId() then
				self.battleUI:clearDiscardBeforCard()
			end
		end
	end
	-- 再加
	for _, set in ipairs(message.add_set or {}) do
		-- 手牌
		if poolType == modGameProto.HELD_CARD_POOL then
			player:addCardsToPool(poolType, set.card_ids)
			local dealCards = {}
			for _, id in ipairs(set.card_ids) do
				if set.t == 1 then
					table.insert(dealCards, id)
				end
			end
			if table.size(dealCards) > 0 then
				player:setCurrentDealCard(dealCards)
			end
		end

		-- 弃牌
		if poolType == modGameProto.DISCARDED_CARD_POOL then
			isAddDiscardCard = true
			player:addCardsToPool(T_POOL_DISCARD, set.card_ids)
			for _, id in ipairs(set.card_ids) do
				table.insert(addDiscardCards, id)
			end
		end

		-- 花牌
		if poolType == modGameProto.BONUS_CARD_POOL then
			modSound.getCurSound():playSound("sound:down.mp3")
			if self:isPlayFlowerCardSound() then
				modSound.getCurSound():playCombSound(nil, gender, nil, true)
			end
			local cards = {}
			for _, id in ipairs(set.card_ids) do
				table.insert(cards, id)
			end
			if table.getn(set.card_ids) > 0 then
				player:addCardsToPool(T_POOL_FLOWER, set.card_ids)
			end
		end
	end
	-- 是否更新弃牌
	if not isAddDiscardCard then
		modEvent.fireEvent(EV_CARD_POOL_UPDATE, seatId, poolType)
	else
		if playerId ~= battle:getMyPlayerId() then
			self.battleUI:discardFunction(addDiscardCards, player)
			self.battleUI:setDiscardSetDiscardMark( addDiscardCards, player)
			modEvent.fireEvent(EV_CARD_POOL_UPDATE, seatId, poolType)
		else
			local cards = self:getDiscardBeforPorto()
			if table.size(cards) <= 0 then
				self.battleUI:discardFunction(addDiscardCards, player)
				self.battleUI:setDiscardSetDiscardMark( addDiscardCards, player)
				modEvent.fireEvent(EV_CARD_POOL_UPDATE, seatId, poolType)
			end
			self:clearDiscardBeforPorto()
		end
	end
end

pMajiangGame.isPlayFlowerCardSound = function(self)
	return true
end

pMajiangGame.updateShowCombsUpdate = function(self, message)
	if not message then return end
	-- 更新明牌牌池
	local battle = self:getCurBattle()
	local playerId = message.player_id
	local seatId = battle:getSeatByPlayerId(playerId)
	local player = battle:getPlayerByPlayerId(playerId)
	local gender = player:getGender()
	local currSet = nil
	-- 删除
	if table.getn(message.removed_comb_ids) > 0 then
		player:delCardsFromPool(T_POOL_SHOW, message.removed_comb_ids)
	end
	-- 增加
	local zimo = false
	if table.getn(message.added_combs) > 0 then
		-- 如果没有触发牌
		for idx, comb in ipairs(message.added_combs) do
			if table.getn(comb.trigger_card_ids) == 0 then
				local tId = nil
				for _, id in ipairs(comb.card_ids) do
					tId = id
				end
				comb.trigger_card_ids:append(tId)
			end
		end
		-- 添加comb
		player:addCardsToPool(T_POOL_SHOW, message.added_combs)

		-- 胡牌comb
		local addComb = nil
		for _, comb in ipairs(message.added_combs) do
			addComb = comb
		end
		if addComb.t == modGameProto.HU then
			--player:sortShowCard()
			local triggerPid = addComb.trigger_player_id
			if triggerPid and triggerPid == playerId and
				(not self:isTianJinMJ()) then
				zimo = true
			end
			modSound.getCurSound():playSound("sound:hubg.mp3")
		end
		currSet = addComb
	end
	if currSet then
		modSound.getCurSound():playCombSound(currSet.t, gender, zimo)
		self.battleUI:showCombEffect(currSet.t, seatId, zimo)
	end
	modEvent.fireEvent(EV_CARD_POOL_UPDATE, seatId, T_POOL_SHOW)
end

pMajiangGame.showGamePhaseWnd = function(self, phase)
	if self:isShowPhaseWnd(phase) then
		local modGamePhase = import("ui/battle/gamephase.lua")
		local isNotBg = false
		if  self.battleUI:isShowPhaseBlackBG() then
			isNotBg = true
		end
		modGamePhase.pGamePhase:instance():open(self.battleUI:getCombParentWnd(), phase, isNotBg)
	end
end

pMajiangGame.phaseWork = function(self, gamePhase)
	if not gamePhase then return end
	local battle = self:getCurBattle()
	battle:setGamePhase(gamePhase)
	local phase = gamePhase
	-- 子类 UI TODO
	local modGamePhase = import("ui/battle/gamephase.lua")
	if modGamePhase.pGamePhase:getInstance() then
		modGamePhase.pGamePhase:instance():close()
	end
end

pMajiangGame.afterPhaseWork = function(self, phase)
	-- 是否显示黑底
	self:showGamePhaseWnd(phase)
	if self.battleUI then
		self.battleUI:showPhaseInfoMessage(phase)
		self.battleUI:setPhaseInitPiaoWnds()
	end
end

pMajiangGame.normalPhaseWork = function(self, gamePhase)
	return
end

pMajiangGame.gamePhaseFunction = function(self, gamePhase)
	if not gamePhase then return end
	self:phaseWork(gamePhase)
	if self:getCurBattle():isPhaseNormal() then
--		self:normalPhaseWork(gamePhase)
		return
	end
	self:afterPhaseWork(gamePhase)
end

pMajiangGame.askChooseCards = function(self, message)
	-- 子类 TODO
	local battle = self:getCurBattle()
	self:setChooseWndProp(message)
	self.battleUI:clearChooseWnds()
	self:chooseCardsWork(true)
end

pMajiangGame.askChooseAngangIds = function ( self,message )
	local battle = self:getCurBattle()
	self.battleUI:dealAngangData(message)
end

pMajiangGame.updateWinnerCards = function(self, message)
	if not message then return end
	local battle = modBattleMgr.getCurBattle()
	local pid = message.player_id
	local cards = message.winning_card_ids
	local player = battle:getPlayerByPlayerId(pid)
	player:setCanHuCardIds(cards)
	self.battleUI:updateWinnerCardsWnds()
end

pMajiangGame.updateMagicCards = function(self, message)
	if not message then return end
	self:setMagicCardFunction(message)
end

pMajiangGame.updatePlayerExtras = function(self, message, player)
	if not message or not player then return end
	self.battleUI:showPlayerExtrasWnds(player)
end

-- ********************* 接口over **********************


