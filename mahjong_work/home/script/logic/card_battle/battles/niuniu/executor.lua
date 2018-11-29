local modExecutorMain = import("logic/card_battle/executor.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modPrepareMenu = import("ui/card_battle/prepare.lua")
local modRobBankerMenu = import("ui/card_battle/battles/niuniu/menus/rob_banker.lua")
local modBetMenu = import("ui/card_battle/battles/niuniu/menus/bet.lua")
local modViewHandMenu = import("ui/card_battle/battles/niuniu/menus/view_hand.lua")
local modChooseNiuMenu = import("ui/card_battle/battles/niuniu/menus/choose_niu.lua")
local modGameCalcPanel = import("ui/card_battle/battles/niuniu/game_over.lua")
local modNiuniuReportPanel = import("ui/card_battle/battles/niuniu/report.lua")
local modBattleRpc = import("logic/card_battle/rpc.lua")
local modBattleMain = import("logic/card_battle/main.lua")
local modSound = import("logic/sound/main.lua")
-----------------------------------------------

pTableRoundStart = pTableRoundStart or class(modExecutorMain.pTableExecutorBase)

pTableRoundStart.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modNiuniuProto.NNTablePrepareData()
	message:ParseFromString(self.data)
	self:getHost():setCurTurnNum(message.turn)
	modSound.getCurSound():playSound("sound:card_game/startgame.mp3")
	self:getHost():pausePlayer()
	self:getHost():getTableWnd():playStartEffect()
	setTimeout(s2f(1.5),function()
		self:getHost():resumePlayer()
		self:finish()
	end)
end

------------------------

pTableChooseBanker = pTableChooseBanker or class(modExecutorMain.pTableExecutorBase)

pTableChooseBanker.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modNiuniuProto.NNTableChooseBankerData()
	message:ParseFromString(self.data)
	local bankerUserId = message.user_id
	local fromUserIds = {}
	for _, userId in ipairs(message.from_user_ids) do
		table.insert(fromUserIds, userId)
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType(), bankerUserId, fromUserIds)
	if #fromUserIds > 1 then
		-- TODO 动画
		self:getHost():pausePlayer()
		runProcess(s2f(0.2), function()
			for i=1,#fromUserIds do
				self:getHost():setRandomBanker(fromUserIds[i], true)
				modSound.getCurSound():playSound("sound:card_game/randombanker.mp3")
				yield()
				self:getHost():setRandomBanker(fromUserIds[i], false)
			end
			self:getHost():setBankerUserId(bankerUserId)
			modSound.getCurSound():playSound("sound:card_game/selectbanker.mp3")
			self:finish()
			self:getHost():resumePlayer()
		end)
	else
		self:getHost():setBankerUserId(bankerUserId)
		modSound.getCurSound():playSound("sound:card_game/selectbanker.mp3")
		self:finish()
	end
end

------------------------

pTableBetDone = pTableBetDone or class(modExecutorMain.pTableExecutorBase)

pTableBetDone.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	local message = modNiuniuProto.NNTableBetDoneData()
	message:ParseFromString(self.data)
	local userIds = {}
	for _, userId in ipairs(message.user_ids) do
		table.insert(userIds, userId)
	end
	local bets = {}
	for _, bet in ipairs(message.user_bets) do
		table.insert(bets, bet)
	end
	self:getHost():setPlayerBets(userIds, bets)
	self:finish()
end

------------------------

pTableShowHand = pTableShowHand or class(modExecutorMain.pTableExecutorBase)

pTableShowHand.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	local message = modNiuniuProto.NNTableShowHandData()
	message:ParseFromString(self.data)
	local tableWnd = self:getHost():getTableWnd()
	local userIds = {}
	local niuTypes = {}
	local myIdx = nil
	for idx, userId in ipairs(message.user_ids) do
		if userId ~= self.host:getMyself():getUserId() then
			table.insert(userIds, userId)
		else
			myIdx = idx
		end
	end
	for idx, niuType in ipairs(message.niu_types) do
		if idx ~= myIdx then
			table.insert(niuTypes, niuType)
		end
	end
	tableWnd:showHands(userIds, niuTypes)
	local seconds = 0
	for _,id in ipairs(message.user_ids) do
		seconds = seconds + 1.0
	end
	setTimeout(s2f(seconds), function()
		self:finish()
	end)
end

------------------------

pTableCalc = pTableCalc or class(modExecutorMain.pTableExecutorBase)

pTableCalc.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	local message = modNiuniuProto.NNTableCalcData()
	message:ParseFromString(self.data)
	local battle = self:getHost()
	local bankerUserId = message.banker_user_id
	local param = {}
	local winFlag = false

	local selfPlayer = battle:getMyself()
	local allkill = nil
	for _, statistic in ipairs(message.data) do
		local userId = statistic.user_id
		local player = battle:getPlayer(userId)
		local info = {
			player = player,
			isZhuang = (player:getUserId() == bankerUserId),
			cardType = statistic.niu_type,
			score = statistic.score_modify,
			cardIds = statistic.card_ids,
			waterScore = statistic.water_score,
			isClub = battle:isClubRoom(),
		}
		if info.isZhuang then
			if allkill == nil then
				if info.score > 0 then
					allkill = 1
				elseif info.score < 0 then
					allkill = -1
				else
					allkill = 0
				end
			else
				if info.score > 0 and allkill == -1 then
					allkill = 0
				elseif info.score < 0 and allkill == 1 then
					allkill = 0
				end
			end
		else
			if allkill == nil then
				if info.score > 0 then
					allkill = -1
				elseif info.score < 0 then
					allkill = 1
				end
			else
				if info.score > 0 and allkill == 1 then
					allkill = 0
				elseif info.score < 0 and allkill == -1 then
					allkill = 0
				end
			end
		end

		if player:isMyself() and statistic.score_modify > 0 then
			winFlag = true
		end
		--player:modifyScore(statistic.score_modify)
		setTimeout(s2f(2), function()
			player:getTableWnd():resetNiuCards(player)
		end)
		table.insert(param, info)
	end

	if selfPlayer:getUserId() ~= bankerUserId then
		allkill = 0
	end

	self:getHost():getTableWnd():playGameOverEffect(winFlag, allkill)
	setTimeout(s2f(2), function()
		local callback = function(isClubRejoin)
			local myself = battle:getMyself()
			if myself:isBankrupt() then
				modBattleMain.pBattleMgr:instance():battleDestroy()
				infoMessage(TEXT("您的金豆不足，无法继续游戏！"))
				return
			end
			local players = battle:getAllPlayers()
			for _, player in pairs(players) do
				if player:isBankrupt() then
					player:setBankruptHint()
				end
			end
			if not battle:isLastTurn() then
				-- 完成结算状态
				local message = modNiuniuProto.NiuniuPlayerState()
				message.state_name = modNiuniuProto.ST_NN_CALC
				battle:reset()
				modBattleRpc.finishState(message, function(success)
					if success then
						self:finish()
					else
						infoMessage(TEXT("操作失败"))
					end
				end)
			else
				--[[
				if self:getHost():getRoomType() == modLobbyProto.CreatePokerRoomRequest.CLUB_SHARED then
					if isClubRejoin then
						modBattleMain.pBattleMgr:instance():prepareEnterClubGround()
					end
					local message = modNiuniuProto.NiuniuPlayerState()
					message.state_name = modNiuniuProto.ST_NN_END
					battle:reset()
					modBattleRpc.finishState(message, function(success)
						if success then
							self:finish()
							if isClubRejoin then
								local clubContext = self:getHost():getClubContext()
								modBattleMain.pBattleMgr:instance():enterClubGround(clubContext.club_id, clubContext.club_ground_id, true)
							else
								setTimeout(1, function()
									modBattleMain.pBattleMgr:instance():battleDestroy()
								end)
							end
						else
							infoMessage(TEXT("操作失败"))
						end
					end)
				else
				]]--
					self:finish()
				--end
			end
		end
		self:getHost():getTableWnd():playCalcAnimation(param, function()
			local gameCalcPanel = modGameCalcPanel.pGameOverWnd:instance()
			gameCalcPanel:setWinFlag(winFlag)
			gameCalcPanel:setPlayerInfo(param)
			--[[
			if self:getHost():getRoomType() == modLobbyProto.CreatePokerRoomRequest.CLUB_SHARED then
				gameCalcPanel:setClubFlag()
			end
			]]--
			gameCalcPanel:open(callback)
		end)
	end)
end

------------------------

pTableEnd = pTableEnd or class(modExecutorMain.pTableExecutorBase)

pTableEnd.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	local message = modNiuniuProto.NNTableEndData()
	message:ParseFromString(self.data)
	local userIds = {}
	for _, userId in ipairs(message.user_ids) do
		table.insert(userIds, userId)
	end
	local scores = {}
	for _, score in ipairs(message.win_scores) do
		table.insert(scores, score)
	end
	local waterScores = {}
	for _, score in ipairs(message.water_scores) do
		table.insert(waterScores, score)
	end
	local selfInfo = {}
	local othersInfo = {}
	local battle = self:getHost()
	for idx, userId in ipairs(userIds) do
		local player = battle:getPlayer(userId)
		if player:isMyself() then
			selfInfo["player"] = player
			selfInfo["score"] = scores[idx]
			selfInfo["waterScore"] = waterScores[idx]
		else
			local info = {
				player = player,
				score = scores[idx],
				waterScore = waterScores[idx],
			}
			table.insert(othersInfo, info)
		end
	end
	local reportPanel = modNiuniuReportPanel.pReportPanel:instance()
	reportPanel:setPlayerInfo(selfInfo, othersInfo)
	reportPanel:open(function()
		-- 完成结算状态
		local message = modNiuniuProto.NiuniuPlayerState()
		message.state_name = modNiuniuProto.ST_NN_END
		modBattleRpc.finishState(message, function(success)
			if success then
				self:finish()
				modBattleMain.pBattleMgr:instance():battleDestroy()
			else
				--infoMessage(TEXT("操作失败"))
			end
		end)
	end)
end

------------------------

pNiuniuBattleExecutorMgr = pNiuniuBattleExecutorMgr or class(modExecutorMain.pBattleExecutorMgr)

pNiuniuBattleExecutorMgr.init = function(self, battle)
	modExecutorMain.pExecutorMgr.init(self, battle)
	self.stateTypeToExecutorCls = {
		[modNiuniuProto.ST_NN_ROUND_START] = pTableRoundStart,
		[modNiuniuProto.ST_NN_CHOOSE_BANKER] = pTableChooseBanker,
		[modNiuniuProto.ST_NN_BET_DONE] = pTableBetDone,
		[modNiuniuProto.ST_NN_SHOW_HAND] = pTableShowHand,
		[modNiuniuProto.ST_NN_CALC] = pTableCalc,
		[modNiuniuProto.ST_NN_END] = pTableEnd,
	}
end

pNiuniuBattleExecutorMgr.parseExecutorInfo = function(self, stateInfo)
	local battleStateMessage = modNiuniuProto.NiuniuTableState()
	battleStateMessage:ParseFromString(stateInfo)
	log("info", battleStateMessage.state_name)
	log("info", battleStateMessage.timeout)
	log("info", battleStateMessage.rest_timeout)
	local stateName = battleStateMessage.state_name
	local executorCls = self.stateTypeToExecutorCls[stateName]
	return executorCls, battleStateMessage
end

-----------------------------------------------

pPlayerPrepare = pPlayerPrepare or class(modExecutorMain.pPlayerExecutorBase)

pPlayerPrepare.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	if self:getHost():isMyself() then
		self.menu = modPrepareMenu.pPrepareMenu:new(self)
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerPrepare.finish = function(self)
	if not self:getHost():isMyself() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		modBattleRpc.prepareDone(function(success)
			if self.menu then
				self.menu:setParent(nil)
				self.menu = nil
			end
			modExecutorMain.pPlayerExecutorBase.finish(self)
			if not success then
				infoMessage(TEXT("开始游戏失败！"))
			end
		end)
	end
end

------------------------

pPlayerDeal = pPlayerDeal or class(modExecutorMain.pPlayerExecutorBase)

pPlayerDeal.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modNiuniuProto.NNPlayerDealData()
	message:ParseFromString(self.data)
	local cardIds = {}
	for _, cardId in ipairs(message.card_ids) do
		table.insert(cardIds, cardId)
	end
	local niuType = message.niu_type
	local niuCardIds = {}
	if niuType ~= modNiuniuProto.T_NN_NONE then
		for _, cardId in ipairs(message.niu_card_ids) do
			table.insert(niuCardIds, cardId)
		end
	end
	logv("info", "======= pPlayerDeal.exec deal cards:", cardIds, niuType, niuCardIds)
	-- TODO 做效果
	self:getHost():addHandCards(cardIds)
	self:getHost():setNiuInfo(niuType, niuCardIds)
	setTimeout(s2f(1), function()
		self:finish()
	end)
end

------------------------

pPlayerGrab = pPlayerGrab or class(modExecutorMain.pPlayerExecutorBase)

pPlayerGrab.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	if self:getHost():isMyself() then
		self.menu = modRobBankerMenu.pRobBankerMenu:new(self)
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerGrab.finish = function(self, robOrNot)
	local soundName = "qiangzhuang"
	if not robOrNot then
		soundName = "buqiang"
	end
	local gender = self:getHost():getProp("gender", 1)
	local genderNum = 2
	if gender == T_GENDER_MALE then genderNum = 1 end
	modSound.getCurSound():playSound(sf("sound:card_game/%s%d.mp3", soundName, genderNum))

	if not self:getHost():isMyself() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		local stateInfo = modNiuniuProto.NNPlayerGrabingData()
		stateInfo.grabing_or_not = robOrNot
		local message = modNiuniuProto.NiuniuPlayerState()
		message.state_name = self:getType()
		message.state_data = stateInfo:SerializeToString()
		modBattleRpc.finishState(message, function(success)
			if success then
				if self.menu then
					self.menu:setParent(nil)
					self.menu = nil
				end
				modExecutorMain.pPlayerExecutorBase.finish(self)
				if not success then
					--infoMessage(TEXT("操作失败"))
				end
			else
				infoMessage(TEXT("操作失败"))
			end
		end)
	end
end

pPlayerGrab.defaultExec = function(self)
	self:finish(false)
end

------------------------

pPlayerBet = pPlayerBet or class(modExecutorMain.pPlayerExecutorBase)

pPlayerBet.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	if self:getHost():isMyself() then
		local message = modNiuniuProto.NNPlayerBettingData()
		message:ParseFromString(self.data)
		if message.is_banker then
			self:finish(1)
		else
			local opts = {}
			for _, opt in ipairs(message.rate_opts) do
				table.insert(opts, opt)
			end
			self.opts = opts
			self.menu = modBetMenu.pBetMenu:new(self, opts)
		end
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerBet.finish = function(self, bet)
	if not self:getHost():isMyself() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		local stateInfo = modNiuniuProto.NNPlayerBettingData()
		stateInfo.bet = bet
		local message = modNiuniuProto.NiuniuPlayerState()
		message.state_name = self:getType()
		message.state_data = stateInfo:SerializeToString()
		modBattleRpc.finishState(message, function(success)
			if success then
				if self.menu then
					self.menu:setParent(nil)
					self.menu = nil
				end
				modExecutorMain.pPlayerExecutorBase.finish(self)
				if not success then
					--infoMessage(TEXT("操作失败"))
				end
			else
				infoMessage(TEXT("操作失败"))
			end
		end)
	end
end

pPlayerBet.defaultExec = function(self)
	if self.opts then
		self:finish(self.opts[1])
	else
		self:finish(1)
	end
end

------------------------

pPlayerChoose = pPlayerChoose or class(modExecutorMain.pPlayerExecutorBase)

pPlayerChoose.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	local player = self:getHost()
	if player:isMyself() then
		self.menu = modChooseNiuMenu.pChooseNiuMenu:new(self)
		-- 提示牛牌
		local tableWnd = player:getTableWnd()
		tableWnd:hintNiuCards(player)
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerChoose.finish = function(self, chooseOrNot, niuCardIds)
	if chooseOrNot then
		-- 检测是否合法
		local total = 0
		for _, cardId in ipairs(niuCardIds) do
			total = total + math.min(cardId % 100, 10)
		end
		if #niuCardIds < 3
			or total == 0
			or total % 10 ~= 0 then
			infoMessage(TEXT("请选择正确的牌组成牛哦"))
			log("error", sf(TEXT("+++++++++++ 请选择正确的牌组成牛哦 [%d] [%d] [%d]"), #niuCardIds, total, total % 10))
			logv("error", niuCardIds)
			return
		end
	end
	local player = self:getHost()
	if not player:isMyself() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		local stateInfo = modNiuniuProto.NNPlayerChosingData()
		stateInfo.niu_or_not = chooseOrNot
		for _, cardId in ipairs(niuCardIds) do
			stateInfo.card_ids:append(cardId)
		end
		local message = modNiuniuProto.NiuniuPlayerState()
		message.state_name = self:getType()
		message.state_data = stateInfo:SerializeToString()
		modBattleRpc.finishState(message, function(success)
			if success then
				if self.menu then
					self.menu:setParent(nil)
					self.menu = nil
				end
				--local tableWnd = player:getTableWnd()
				--tableWnd:resetNiuCards(player)
				modExecutorMain.pPlayerExecutorBase.finish(self)
				if not success then
					--infoMessage(TEXT("操作失败"))
				end
			else
				infoMessage(TEXT("操作失败"))
			end
		end)
	end
end

pPlayerChoose.defaultExec = function(self)
	local player = self:getHost()
	local niuType = player:getNiuType()
	local niuCardIds = player:getNiuCardIds()
	self:finish(niuType > modNiuniuProto.T_NN_NONE and niuType <= modNiuniuProto.T_NN_10, niuCardIds)
end

pPlayerChoose.exit = function(self)
	local player = self:getHost()
	local tableWnd = player:getTableWnd()
	if tableWnd then
		tableWnd:resetNiuCards(player)
	end
	if self.menu then
		self.menu:setParent(nil)
		self.menu = nil
	end
end

------------------------

pPlayerViewHand = pPlayerViewHand or class(modExecutorMain.pPlayerExecutorBase)

pPlayerViewHand.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	local player = self:getHost()
	if player:isMyself() then
		local handPool = player:getHandCardPool()
		local cards = handPool:getAllCards()
		for i = 1, 4 do
			cards[i]:getCardWnd():setShowMode()
		end
		cards[5]:getCardWnd():setBackMode()
		local message = modNiuniuProto.NNPlayerViewHandData()
		message:ParseFromString(self.data)
		self.viewHandParam = message
		self.menu = modViewHandMenu.pViewHandMenu:new(self)
		--[[
		local tableWnd = player:getTableWnd()
		tableWnd:hintNiuCards(player)
		]]--
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerViewHand.getViewHandParam = function(self)
	return self.viewHandParam
end

pPlayerViewHand.cuoPai = function(self)
	local player = self:getHost()
	if player:isMyself() then
		local handCardWnd = player:getBattle():getTableWnd():getHandCardWnd(player)
		handCardWnd:setCuoPaiMode(true, function()
			self:finish()
		end)
	else
		self:finish()
	end
end

pPlayerViewHand.finish = function(self)
	local player = self:getHost()
	if not player:isMyself() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		local handCardWnd = player:getBattle():getTableWnd():getHandCardWnd(player)
		handCardWnd:setCuoPaiMode(false)
		local param = self.viewHandParam
		if param then
			local niuType = param.niu_type
			local tableWnd = self:getHost():getBattle():getTableWnd()
			tableWnd:showHands({self:getHost():getUserId()}, {niuType})
		end
		local message = modNiuniuProto.NiuniuPlayerState()
		message.state_name = self:getType()
		modBattleRpc.finishState(message, function(success)
			if success then
				if self.menu then
					self.menu:setParent(nil)
					self.menu = nil
				end
				modExecutorMain.pPlayerExecutorBase.finish(self)
			else
				infoMessage(TEXT("操作失败"))
			end
		end)
	end
end

------------------------

pPlayerCalc = pPlayerCalc or class(modExecutorMain.pPlayerExecutorBase)

------------------------

pNiuniuPlayerExecutorMgr = pNiuniuPlayerExecutorMgr or class(modExecutorMain.pExecutorMgr)

pNiuniuPlayerExecutorMgr.init = function(self, player)
	modExecutorMain.pExecutorMgr.init(self, player)
	self.stateTypeToExecutorCls = {
		[modNiuniuProto.ST_NN_DEAL] = pPlayerDeal,
		[modNiuniuProto.ST_NN_BANKER] = pPlayerGrab,
		[modNiuniuProto.ST_NN_BET] = pPlayerBet,
		[modNiuniuProto.ST_NN_VIEW_HAND] = pPlayerViewHand,
		[modNiuniuProto.ST_NN_NIUNIU] = pPlayerChoose,
		[modNiuniuProto.ST_NN_CALC] = pPlayerCalc,
	}
end

pNiuniuPlayerExecutorMgr.parseExecutorInfo = function(self, stateInfo)
	local playerStateMessage = modNiuniuProto.NiuniuPlayerState()
	playerStateMessage:ParseFromString(stateInfo)
	log("info", playerStateMessage.state_name)
	log("info", playerStateMessage.timeout)
	log("info", playerStateMessage.rest_timeout)
	local stateName = playerStateMessage.state_name
	local executorCls = self.stateTypeToExecutorCls[stateName]
	log("info", stateName, executorCls)
	return executorCls, playerStateMessage
end

pNiuniuPlayerExecutorMgr.addPrepareExecutor = function(self)
	local param = {state_name = 0, timeout = -1, rest_timeout = -1, satisfied = false}
	logv("info", "addPrepareExecutor", param)
	local executor = pPlayerPrepare:new(param, self:getHost())
	self:addExecutorObj(executor)
end
