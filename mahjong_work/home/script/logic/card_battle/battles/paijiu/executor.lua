local modExecutorMain = import("logic/card_battle/executor.lua")
local modPaijiuProto = import("data/proto/rpc_pb2/pokers/paijiu_pb.lua")
local modSound = import("logic/sound/main.lua")
local modBattleRpc = import("logic/card_battle/rpc.lua")
local modBattleMain = import("logic/card_battle/main.lua")
local modNiuniuReportPanel = import("ui/card_battle/battles/niuniu/report.lua")
local modPrepareMenu = import("ui/card_battle/prepare.lua")
local modRobBankerMenu = import("ui/card_battle/battles/paijiu/menus/rob_banker.lua")
local modRollDiceMenu = import("ui/card_battle/battles/paijiu/menus/roll_dice.lua")
local modAntesMenu = import("ui/card_battle/battles/paijiu/menus/antes.lua")
local modContBankerMenu = import("ui/card_battle/battles/paijiu/menus/cont_banker.lua")
local modShuffleMenu = import("ui/card_battle/battles/paijiu/menus/shuffle.lua")
local modViewHandMenu = import("ui/card_battle/battles/paijiu/menus/view_hand.lua")
local modUserData = import("logic/userdata.lua")

-------------------------------------------------------

pPaijiuTableExecutorBase = pPaijiuTableExecutorBase or class(modExecutorMain.pTableExecutorBase)

pPaijiuTableExecutorBase.init = function(self, stateMessage, host)
	modExecutorMain.pTableExecutorBase.init(self, stateMessage, host)
	self.cardInfos = stateMessage.card_infos
end

pPaijiuTableExecutorBase.prepare = function(self)
	self:getHost():updateTableCards(self.cardInfos)
	modExecutorMain.pTableExecutorBase.prepare(self)
end

-------------------------------------------------------

pTableRoundStart = pTableRoundStart or class(pPaijiuTableExecutorBase)

pTableRoundStart.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJTableRoundStartData()
	message:ParseFromString(self.data)
	self:getHost():setCurTurnNum(message.turn)
	local userIds = {}
	for _, userId in ipairs(message.user_ids) do
		table.insert(userIds, userId)
	end
	for idx, score in ipairs(message.user_scores) do
		local userId = userIds[idx]
		local player = self:getHost():getPlayer(userId)
		player:setScore(score)
	end
	if message.banker_user_id ~= 0 then
		self:getHost():setBankerUserId(message.banker_user_id)
	end
	modSound.getCurSound():playSound("sound:card_game/startgame.mp3")
	self:getHost():pausePlayer()
	self:getHost():getTableWnd():playStartEffect()
	setTimeout(s2f(1.5),function()
		self:getHost():resumePlayer()
		self:finish()
	end)
end

------------------------

pTableChooseRow = pTableChooseRow or class(pPaijiuTableExecutorBase)

pTableChooseRow.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJTableChooseRowData()
	message:ParseFromString(self.data)
	local curIdx = message.row_idx
	local fromIdxs = message.from_idxs
	local tableWnd = self:getHost():getTableWnd()
	self:getHost():pausePlayer()
	tableWnd:playChooseRowAnimation(curIdx, fromIdxs, function()
		self:getHost():resumePlayer()
		self:finish()
	end)
end

------------------------

pTableDeal = pTableDeal or class(pPaijiuTableExecutorBase)

pTableDeal.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJTableDealData()
	message:ParseFromString(self.data)
	self:getHost():getTableWnd():showCurIdxCards()
	runProcess(s2f(0.5), function()
		for _, dealInfo in ipairs(message.deal_card_infos) do
			local userId = dealInfo.user_id
			local player = self:getHost():getPlayer(userId)
			if player then
				local cardIds = {}
				for _, cardId in ipairs(dealInfo.card_ids) do
					table.insert(cardIds, cardId)
				end
				player:addHandCards(cardIds)
				yield()
			end
		end
		yield()
		self:finish()
	end)
end

------------------------

pTableGrabBanker = pTableGrabBanker or class(pPaijiuTableExecutorBase)

------------------------

pTableChooseBanker = pTableChooseBanker or class(pPaijiuTableExecutorBase)

pTableChooseBanker.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJTableChooseBankerData()
	message:ParseFromString(self.data)
	local bankerUserId = message.user_id
	local fromUserIds = {}
	for _, userId in ipairs(message.from_user_ids) do
		table.insert(fromUserIds, userId)
	end
	local initBankerScore = message.init_banker_score
	if #fromUserIds > 1 then
		-- TODO 动画
		self:getHost():pausePlayer()
		runProcess(s2f(0.2), function()
			for i=1, #fromUserIds do
				self:getHost():setRandomBanker(fromUserIds[i], true)
				modSound.getCurSound():playSound("sound:card_game/randombanker.mp3")
				yield()
				self:getHost():setRandomBanker(fromUserIds[i], false)
			end

			for i=1, #fromUserIds do
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
		self:finish()
	end
end

------------------------

pTableRollDice = pTableRollDice or class(pPaijiuTableExecutorBase)

------------------------

pTableRollDiceDone = pTableRollDiceDone or class(pPaijiuTableExecutorBase)

pTableRollDiceDone.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJTableRollDiceDoneData()
	message:ParseFromString(self.data)

	self:getHost():getTableWnd():playRollDiceEffect(message.dice1, message.dice2)
	log("info", "-------------roll dice done")

	-- TODO
	setTimeout(s2f(1), function()
		self:finish()
	end)
end

------------------------

pTableAntes = pTableAntes or class(pPaijiuTableExecutorBase)

------------------------

pTableAntesDone = pTableAntesDone or class(pPaijiuTableExecutorBase)

pTableAntesDone.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJTableAntesDoneData()
	message:ParseFromString(self.data)
	local userIds = {}
	for _, userId in ipairs(message.user_ids) do
		table.insert(userIds, userId)
	end
	local bets = {}
	for _, bet in ipairs(message.user_antes) do
		table.insert(bets, bet)
	end
	local bets2 = {}
	for _, bet in ipairs(message.user_antes2) do
		table.insert(bets2, bet)
	end
	self:getHost():setPlayerBets(userIds, bets, bets2)
	self:finish()
end

------------------------

pTableShuffle = pTableShuffle or class(pPaijiuTableExecutorBase)

------------------------

pTableContBanker = pTableContBanker or class(pPaijiuTableExecutorBase)

------------------------

pTableViewHand = pTableViewHand or class(pPaijiuTableExecutorBase)

pTableViewHand.exec = function(self)
	if self:isFinish() then
		return
	end
	if self:getHost():getMyself():isObserver() then
		self:finish()
		return
	end
	local message = modPaijiuProto.PJTableViewHandData()
	message:ParseFromString(self.data)
	for _, info in ipairs(message.hands) do
		local userId = info.user_id
		local player = self:getHost():getPlayer(userId)
		if player:isMyself() then
			self.viewHandResult = {
				userId = userId,
				pjType = info.pj_type,
			}
			player:setPjType(info.pj_type)
			break
		end
	end
	self.menu = modViewHandMenu.pViewHandMenu:new(self)

	local tbwin = self:getHost():getTableWnd()
	local handcard = tbwin:getHandCardWnd(self:getHost():getMyself())
	self.menu:setHandCardWnd(handcard)
end

pTableViewHand.tryCountDown = function(self)
	self:getHost():getTableWnd():startCountDown(15, function()
		self:finish()
	end)
end

pTableViewHand.finish = function(self)
	if self:getHost():getMyself():isObserver() then
		pPaijiuTableExecutorBase.finish(self)
		return
	end

	local tbwin = self:getHost():getTableWnd()
	tbwin:stopCountDown()
	local handcard = tbwin:getHandCardWnd(self:getHost():getMyself())
	handcard:endCuoPai()

	local message = modPaijiuProto.PaijiuPlayerState()
	message.state_name = self:getType()
	modBattleRpc.finishState(message, function(success)
		if success then
			if self.menu then
				self.menu:setParent(nil)
				self.menu = nil
			end

			if self.viewHandResult then
				local userIds = {self.viewHandResult.userId}
				local pjTypes = {self:getHost():getMyself():getPjType()}
				local tableWnd = self:getHost():getTableWnd()
				if tableWnd then
					tableWnd:showHands(userIds, pjTypes, function()
						pPaijiuTableExecutorBase.finish(self)
					end)
				end
			end
		else
			infoMessage(TEXT("操作失败"))
		end
	end)
end

------------------------

pTableShowHand = pTableShowHand or class(pPaijiuTableExecutorBase)

pTableShowHand.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJTableShowHandData()
	message:ParseFromString(self.data)
	local tableWnd = self:getHost():getTableWnd()
	local userIds = {}
	local pjTypes = {}
	for _, hand in ipairs(message.hands) do
		if hand.user_id ~= modUserData.getUID() then
			table.insert(userIds, hand.user_id)
			table.insert(pjTypes, hand.pj_type)
		end
	end
	tableWnd:showHands(userIds, pjTypes, function()
		self:finish()
	end)
end

------------------------

pTableCalc = pTableCalc or class(pPaijiuTableExecutorBase)

pTableCalc.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJTableCalcData()
	message:ParseFromString(self.data)
	local calcStatistic = {}
	local isWin = false
	for _, info in ipairs(message.calc_infos) do
		local userId = info.user_id
		if userId == self:getHost():getMyself():getUserId() then
			if info.score_modify > 0 then isWin = true end
		end

		calcStatistic[userId] = {
			pjType = info.pj_type,
			scoreModify = info.score_modify
		}
	end
	-- 庄家和闲家们的输赢关系
	local winLoseInfos = {}


	for _, info in ipairs(message.win_lose_infos) do
		local userId = info.user_id
		winLoseInfos[userId] = {
			score = info.score,
			relate = info.relate, -- 1,赢, 2,输, 3,平
		}
	end

	local allkill = 0
	if self:getHost():getMyself():getUserId() == self:getHost():getBankerUserId() then
		local allwin = true
		for _, info in ipairs(message.win_lose_infos) do
			if info.relate == 2 then
				allwin = false
			end
		end
		local alllose = true
		for _, info in ipairs(message.win_lose_infos) do
			if info.relate == 1 then
				alllose = false
			end
		end

		if allwin then allkill = 1 end
		if alllose then allkill = -1 end
	end

	local tableWnd = self:getHost():getTableWnd()
	tableWnd:playGameOverEffect(isWin, allkill)
	tableWnd:playCalcAnimation(calcStatistic, winLoseInfos, function()
		local battle = self:getHost()
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
		if not self:getHost():isLastTurn() then
			if not self:getHost():getMyself():isObserver() then
				local message = modPaijiuProto.PaijiuPlayerState()
				message.state_name = modPaijiuProto.ST_PJ_CALC
				self:getHost():reset()
				modBattleRpc.finishState(message, function(success)
					if success then
						self:finish()
					else
						infoMessage(TEXT("操作失败"))
					end
				end)
			else
				self:getHost():reset()
			end
		else
			self:finish()
		end
	end)
end

------------------------

pTableEnd = pTableEnd or class(pPaijiuTableExecutorBase)

pTableEnd.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	local message = modPaijiuProto.PJTableEndData()
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
	local followeeUid = -1
	if self:getHost():getMyself():isObserver() then
		followeeUid = self:getHost():getMyself():getFollowee():getUserId()
	end
	for idx, userId in ipairs(userIds) do
		local player = battle:getPlayer(userId)
		if player:isMyself() or userId == followeeUid then
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
		if not self:getHost():getMyself():isObserver() then
			-- 完成结算状态
			local message = modPaijiuProto.PaijiuPlayerState()
			message.state_name = modPaijiuProto.ST_PJ_END
			modBattleRpc.finishState(message, function(success)
				if success then
					self:finish()
					modBattleMain.pBattleMgr:instance():battleDestroy()
				else
					--infoMessage(TEXT("操作失败"))
				end
			end)
		else
			modBattleRpc.observerLeaveRoom(function(success, reason)
				if success then
					self:finish()
					modBattleMain.pBattleMgr:instance():battleDestroy()
				else
					infoMessage(reason)
				end
			end)
		end
	end)
end

------------------------

pPaijiuBattleExecutorMgr = pPaijiuBattleExecutorMgr or class(modExecutorMain.pBattleExecutorMgr)

pPaijiuBattleExecutorMgr.init = function(self, player)
	modExecutorMain.pExecutorMgr.init(self, player)
	self.stateTypeToExecutorCls = {
		[modPaijiuProto.ST_PJ_ROUND_START] = pTableRoundStart,
		[modPaijiuProto.ST_PJ_CHOOSE_ROW] = pTableChooseRow,
		[modPaijiuProto.ST_PJ_DEAL] = pTableDeal,
		[modPaijiuProto.ST_PJ_GRAB_BANKER] = pTableGrabBanker,
		[modPaijiuProto.ST_PJ_CHOOSE_BANKER] = pTableChooseBanker,
		[modPaijiuProto.ST_PJ_ROLL_DICE] = pTableRollDice,
		[modPaijiuProto.ST_PJ_ROLL_DICE_DONE] = pTableRollDiceDone,
		[modPaijiuProto.ST_PJ_ANTES] = pTableAntes,
		[modPaijiuProto.ST_PJ_ANTES_DONE] = pTableAntesDone,
		[modPaijiuProto.ST_PJ_VIEW_HAND] = pTableViewHand,
		[modPaijiuProto.ST_PJ_SHOW_HAND] = pTableShowHand,
		[modPaijiuProto.ST_PJ_CALC] = pTableCalc,
		[modPaijiuProto.ST_PJ_CONT_BANKER] = pTableContBanker,
		[modPaijiuProto.ST_PJ_SHUFFLE] = pTableShuffle,
		[modPaijiuProto.ST_PJ_END] = pTableEnd,
	}
end

pPaijiuBattleExecutorMgr.parseExecutorInfo = function(self, stateInfo)
	local battleStateMessage = modPaijiuProto.PaijiuTableState()
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

pPlayerGrab = pPlayerGrab or class(modExecutorMain.pPlayerExecutorBase)

pPlayerGrab.exec = function(self)
	if self:isFinish() then
		return
	end
	if self:getHost():isMyself() then
		local message = modPaijiuProto.PJPlayerGrabBankerData()
		message:ParseFromString(self.data)
		self.maxGrabRate = message.max_grab_rate
		self.menu = modRobBankerMenu.pRobBankerMenu:new(self)
	else
		if self:getHost():getBattle():isKzwf() then
			modExecutorMain.pPlayerExecutorBase.finish(self)
		end
	end
end

pPlayerGrab.getMaxGrabRate = function(self)
	return self.maxGrabRate
end

pPlayerGrab.finish = function(self, grabRate)
	local soundName = "qiangzhuang"
	if grabRate == 0 then
		soundName = "buqiang"
	end
	local gender = self:getHost():getProp("gender", 1)
	local genderNum = 2
	if gender == T_GENDER_MALE then genderNum = 1 end
	modSound.getCurSound():playSound(sf("sound:card_game/%s%d.mp3", soundName, genderNum))
	if not self:getHost():isMyself() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		local stateInfo = modPaijiuProto.PJPlayerGrabBankerData()
		if grabRate == 0 then
			stateInfo.grabing_or_not = false
			self:getHost():getBattle():getTableWnd():setHintText(self:getHost():getUserId(), TEXT("不抢"))
		else
			stateInfo.grabing_or_not = true
			self:getHost():getBattle():getTableWnd():setHintText(self:getHost():getUserId(), sf(TEXT("抢x%d"), grabRate))
		end
		stateInfo.grab_rate = grabRate
		local message = modPaijiuProto.PaijiuPlayerState()
		message.state_name = self:getType()
		message.state_data = stateInfo:SerializeToString()
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

pPlayerGrab.defaultExec = function(self)
	self:finish(0)
end

pPlayerGrab.onServerNotifyExecutorFinish = function(self, stateData)
	local battle = self:getHost():getBattle()
	if not battle:isKzwf() then
		local stateInfo = modPaijiuProto.PJPlayerGrabBankerData()
		stateInfo:ParseFromString(stateData)
		local grabingOrNot = stateInfo.grabing_or_not
		local grabRate = stateInfo.grab_rate
		if grabingOrNot then
			battle:getTableWnd():setHintText(self:getHost():getUserId(), sf(TEXT("抢x%d"), grabRate))
		else
			battle:getTableWnd():setHintText(self:getHost():getUserId(), TEXT("不抢"))
		end
	end
	modExecutorMain.pPlayerExecutorBase.onServerNotifyExecutorFinish(self, stateData)
end

------------------------

pPlayerRollDice = pPlayerRollDice or class(modExecutorMain.pPlayerExecutorBase)

pPlayerRollDice.exec = function(self)
	if self:isFinish() then
		return
	end
	local message = modPaijiuProto.PJPlayerRollDiceData()
	message:ParseFromString(self.data)
	local bankerUserId = message.banker_user_id
	log("info", self, self:getHost():getHostName(), "exec", self:getType(), "bankerUserId:", bankerUserId)
	if self:getHost():isMyself() and self:getHost():getUserId() == bankerUserId then
		self.menu = modRollDiceMenu.pRollDiceMenu:new(self)
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerRollDice.finish = function(self)
	if not self:getHost():isMyself() or not self:getHost():isBanker() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		local message = modPaijiuProto.PaijiuPlayerState()
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

pPlayerAntes = pPlayerAntes or class(modExecutorMain.pPlayerExecutorBase)

pPlayerAntes.exec = function(self)
	if self:isFinish() then
		return
	end
	log("info", self, self:getHost():getHostName(), "exec", self:getType())
	self:getHost():getBattle():getTableWnd():setHintText(self:getHost():getUserId(), "")
	if self:getHost():isMyself() and not self:getHost():isBanker() then
		local message = modPaijiuProto.PJPlayerAntesData()
		message:ParseFromString(self.data)
		self.antesParam = message
		self.menu = modAntesMenu.pAntesMenu:new(self)
	elseif self:getHost():isBanker() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerAntes.getAntesParam = function(self)
	return self.antesParam
end

pPlayerAntes.finish = function(self, antes, isTui)
	if not self:getHost():isMyself() or self:getHost():isBanker() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		local battle = self:getHost():getBattle()
		local stateInfo = modPaijiuProto.PJPlayerAntesData()
		if battle:isKzwf() then
			stateInfo.antes_score1 = antes[1]
			stateInfo.antes_score2 = antes[2]
		else
			if isTui then
				stateInfo.tui_score = antes
			else
				stateInfo.antes = antes
			end
		end
		local message = modPaijiuProto.PaijiuPlayerState()
		message.state_name = self:getType()
		message.state_data = stateInfo:SerializeToString()
		modBattleRpc.finishState(message, function(success)
			if success then
				if self.menu then
					self.menu:setParent(nil)
					self.menu = nil
				end
				modExecutorMain.pPlayerExecutorBase.finish(self)
				if battle:isKzwf() then
					self:getHost():setBet(antes[1])
					self:getHost():setBet2(antes[2])
				else
					self:getHost():setBet(antes)
				end
			else
				infoMessage(TEXT("操作失败"))
			end
		end)
	end
end

pPlayerAntes.defaultExec = function(self)
	if self.antesParam then
		if self:getHost():getBattle():isKzwf() then
			self:finish({self.antesParam.min_antes, 0}, false)
		else
			self:finish(self.antesParam.min_antes, false)
		end
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerAntes.onServerNotifyExecutorFinish = function(self, stateData)
	local stateInfo = modPaijiuProto.PJPlayerAntesData()
	stateInfo:ParseFromString(stateData)
	local battle = self:getHost():getBattle()
	if battle:isKzwf() then
		self:getHost():setBet(stateInfo.antes_score1)
		self:getHost():setBet2(stateInfo.antes_score2)
	else
		if stateInfo.tui_score > 0 then
			self:getHost():setBet(stateInfo.tui_score)
		else
			self:getHost():setBet(stateInfo.antes)
		end
	end
	modExecutorMain.pPlayerExecutorBase.onServerNotifyExecutorFinish(self, stateData)
end

------------------------

pPlayerContBanker = pPlayerContBanker or class(modExecutorMain.pPlayerExecutorBase)

pPlayerContBanker.exec = function(self)
	if self:isFinish() then
		return
	end
	if self:getHost():isMyself() and self:getHost():isBanker() then
		local message = modPaijiuProto.PJPlayerContBankerData()
		message:ParseFromString(self.data)
		self.contBankerScores = {}
		for _, score in ipairs(message.cont_banker_scores) do
			table.insert(self.contBankerScores, score)
		end
		self.menu = modContBankerMenu.pContBankerMenu:new(self)
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerContBanker.getContBankerScores = function(self)
	return self.contBankerScores
end

pPlayerContBanker.finish = function(self, contBankerScore)
	if not self:getHost():isMyself() or not self:getHost():isBanker() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		if self.__is_finishing then
			return
		end
		self.__is_finishing = true
		local stateInfo = modPaijiuProto.PJPlayerContBankerData()
		stateInfo.cont_banker_score = contBankerScore
		local message = modPaijiuProto.PaijiuPlayerState()
		message.state_name = self:getType()
		message.state_data = stateInfo:SerializeToString()
		modBattleRpc.finishState(message, function(success, finishSuccess)
			self.__is_finishing = false
			if success then
				if finishSuccess then
					if self.menu then
						self.menu:destroy()
						self.menu = nil
					end
					modExecutorMain.pPlayerExecutorBase.finish(self)
				else
					if contBankerScore > 0 then
						infoMessage(TEXT(sf("您的积分不够续%d分的庄啦！", contBankerScore)))
					else
						infoMessage(TEXT("操作失败"))
					end
				end
			else
				infoMessage(TEXT("操作失败"))
			end
		end)
	end
end

pPlayerContBanker.defaultExec = function(self)
	self:finish(0)
end

------------------------

pPlayerShuffle = pPlayerShuffle or class(modExecutorMain.pPlayerExecutorBase)

pPlayerShuffle.exec = function(self)
	if self:isFinish() then
		return
	end
	if self:getHost():isMyself() and self:getHost():isBanker() then
		local message = modPaijiuProto.PJPlayerShuffleData()
		message:ParseFromString(self.data)
		local opts = {}
		for _, opt in ipairs(message.opts) do
			opts[opt] = true
		end
		self.opts = opts
		self.menu = modShuffleMenu.pShuffleMenu:new(self)
	else
		modExecutorMain.pPlayerExecutorBase.finish(self)
	end
end

pPlayerShuffle.getOpts = function(self)
	return self.opts
end

pPlayerShuffle.finish = function(self, opt)
	if not self:getHost():isMyself() or not self:getHost():isBanker() then
		modExecutorMain.pPlayerExecutorBase.finish(self)
	else
		local stateInfo = modPaijiuProto.PJPlayerShuffleData()
		stateInfo.shuffle_opt = opt
		local message = modPaijiuProto.PaijiuPlayerState()
		message.state_name = self:getType()
		message.state_data = stateInfo:SerializeToString()
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

pPlayerShuffle.defaultExec = function(self)
	self:finish(2)
end

------------------------

pPaijiuPlayerExecutorMgr = pPaijiuPlayerExecutorMgr or class(modExecutorMain.pExecutorMgr)

pPaijiuPlayerExecutorMgr.init = function(self, player)
	modExecutorMain.pExecutorMgr.init(self, player)
	self.stateTypeToExecutorCls = {
		[modPaijiuProto.ST_PJ_GRAB_BANKER] = pPlayerGrab,
		[modPaijiuProto.ST_PJ_ROLL_DICE] = pPlayerRollDice,
		[modPaijiuProto.ST_PJ_ANTES] = pPlayerAntes,
		[modPaijiuProto.ST_PJ_CONT_BANKER] = pPlayerContBanker,
		[modPaijiuProto.ST_PJ_SHUFFLE] = pPlayerShuffle,
	}
end

pPaijiuPlayerExecutorMgr.parseExecutorInfo = function(self, stateInfo)
	local playerStateMessage = modPaijiuProto.PaijiuPlayerState()
	playerStateMessage:ParseFromString(stateInfo)
	log("info", playerStateMessage.state_name)
	log("info", playerStateMessage.timeout)
	log("info", playerStateMessage.rest_timeout)
	local stateName = playerStateMessage.state_name
	local executorCls = self.stateTypeToExecutorCls[stateName]
	log("info", stateName, executorCls)
	return executorCls, playerStateMessage
end

pPaijiuPlayerExecutorMgr.addPrepareExecutor = function(self)
	local param = {state_name = 0, timeout = -1, rest_timeout = -1, satisfied = false}
	logv("info", "addPrepareExecutor", param)
	local executor = pPlayerPrepare:new(param, self:getHost())
	self:addExecutorObj(executor)
end
