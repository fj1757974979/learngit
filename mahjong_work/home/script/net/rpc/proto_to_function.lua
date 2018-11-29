local modBattleMgr = import("logic/battle/main.lua")
local modClubProto = import("data/proto/rpc_pb2/club_pb.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")
local modSessionMgr = import("net/mgr.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modEvent = import("common/event.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modCalculate = import("ui/battle/calculate.lua")
local modFunctionManager = import("ui/common/uifunctionmanager.lua")
local modMainZhuaNiao = import("ui/battle/zhuaniao.lua")
local modEndCalculate = import("ui/battle/endcalculate.lua")
local modDisMissList = import("ui/battle/dismisslist.lua")
local modFlagMenu = import("ui/battle/flags.lua")
local modSound = import("logic/sound/main.lua")
local modUserPropCache = import("logic/userpropcache.lua")
local modUtil = import("util/util.lua")
local modChatProto = import("data/proto/rpc_pb2/chat_pb.lua")

local disRoomTime = 60

-- 关闭房间  CLOSE_ROOM
closeRoom = function(payload)
	modSessionMgr.instance():closeSession(T_SESSION_BATTLE)
	local message = modRoomProto.CloseRoomRequest()
	message:ParseFromString(payload)
	modBattleMgr.getCurBattle():closeRoom(message)
end

-- 取消关闭房间 CANCEL_CLOSE_ROOM
cancelCloseRoom = function(payload)
	local message = modRoomProto.CancelCloseRoomRequest()
	message:ParseFromString(payload)
	modBattleMgr.getCurBattle():cancelCloseRoom(message)
end

-- 回复关闭房间
answerCloseRoom = function(payload)
	local message = modRoomProto.AnswerCloseRoomRequest()
	message:ParseFromString(payload)
	modBattleMgr.getCurBattle():answerCloseRoom(message)
end

-- 请求关闭房间
askCloseRoom = function(payload)
	local message = modRoomProto.AskCloseRoomRequest()
	message:ParseFromString(payload)
	modBattleMgr.getCurBattle():askCloseRoom(message)
end

-- 确认关闭房间
applyCloseRoom = function(payload)
	local message = modRoomProto.ApplyCloseRoomRequest()
	message:ParseFromString(payload)
	modBattleMgr.getCurBattle():applyCloseRoom(message)
end

setPropCacheData = function(self, name, value)
	local modUserData = import("logic/userdata.lua")
	modUserPropCache.getCurPropCache():setProp(modUserData.getUID(), name, value)
end

-- 更新玩家属性
updateUserProps = function(payload)
	local message = modLobbyProto.UpdateUserPropsRequest()
	message:ParseFromString(payload)
	local modUserData = import("logic/userdata.lua")
	-- 更新房卡
	if message:HasField("room_card_count_delta") then
		local diff = message.room_card_count_delta
		modUserData.instance():modifyProp("roomCards", diff)
		setPropCacheData("roomCards", diff)
		if diff < 0 then
			puppy.sys.onConsumeJade("roomcard", math.abs(diff), math.abs(diff))
		elseif diff > 0 then
--			infoMessage("获得" .. "#cm" .. diff .. "#n" .. "钻石")
		end
	end
	-- 更新金币
	if message:HasField("gold_coin_count_delta") then
		local goldDiff = message.gold_coin_count_delta
		modUserData.instance():modifyProp("goldCount", goldDiff)
		setPropCacheData("goldCount", goldDiff)
		if goldDiff < 0 then
		else
--			infoMessage("获得" .. "#cm" .. goldDiff .. "#n" .. "金币")
		end
	end
	-- 绑定认证码
	if message:HasField("invite_code") then
		modUserData.setProp("inviteCode", message.invite_code)
		setPropCacheData("inviteCode", message.invite_code)
		if not modUtil.isAppstoreExamineVersion() then
			local modMenuMain = import("logic/menu/main.lua")
			modMenuMain.pMenuMgr:instance():getCurMenuPanel():isShowInvite()
		end
	end
	-- 更新名字
	if message:HasField("real_name") then
		modUserData.setProp("realName", message.real_name)
		setPropCacheData("realName", message.real_name)
		if not modUtil.isAppstoreExamineVersion() then
			local modMenuMain = import("logic/menu/main.lua")
			modMenuMain.pMenuMgr:instance():getCurMenuPanel():isShowAuth()
		end
	end
	-- 更新电话号码
	if message:HasField("phone_no") then
		modUserData.setProp("phoneNo", message.phone_no)
		setPropCacheData("phoneNo", message.phone_no)
	end
end

-- 推送公告
postNotices = function(payload)
	local messageFormRequest = modLobbyProto.PostNoticesRequest()
	messageFormRequest:ParseFromString(payload)
	local modMenuMain = import("logic/menu/main.lua")
	modMenuMain.pMenuMgr:instance():getCurMenuPanel():setNotic(messageFormRequest.notices)
end

-- 添加玩家
addUser = function(payload)
	local message = modRoomProto.AddUserRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	modBattleMain.getCurBattle():addUser(message)
end

-- 移除玩家
removeUser = function(payload)
	local message = modRoomProto.RemoveUserRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	modBattleMain.getCurBattle():removeUser(message)
end

-- 上线下线
updateOnline = function(payload)
	local message = modRoomProto.UpdateOnlineRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	modBattleMain.getCurBattle():updateOnline(message)
end

-- 请求玩家出牌
askChooseCardToDiscard = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.AskChooseCardToDiscardRequest()
	message:ParseFromString(payload)
	battle:askChooseCardToDiscard(message)
	log("info", "-------aks_choose_card_to_discard-------")
end

hasCanDiscardFlag = function(flags)
	if not flags then return end
	local modUIUtil = import("ui/common/util.lua")
	for _, flag in ipairs(flags) do
		if modUIUtil.getIsCanDiscardComb(flag) then
			return true
		end
	end
	return false
end

-- 请求玩家选择标识
askChoosePlayerFlag = function(payload)
	local message = modGameProto.AskChoosePlayerFlagRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	logv("info", "ask_choose_player_flag ============")
	battle:askChoosePlayerFlag(message)
end

-- 更新玩家标识
updatePlayerFlags = function(payload)
	local message = modGameProto.UpdatePlayerFlagsRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	log("warn", "-------------------------update player flag ------------")
	battle:updatePlayerFlags(message)
end

-- 开始游戏
startGame = function(payload)
	local message = modGameProto.StartGameRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	battle:startGame(message)
end

--请求玩家选择comb
askChooseCombination = function(payload)	
	local message = modGameProto.AskChooseCombinationRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	-- 加入combs
	battle:askChooseCombination(message)
end

--请求玩家选择暗杠
askChooseAngang = function (payload)	
	local message = modGameProto.AskChooseAngangRequest()
	message:ParseFromString(payload)			
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	battle:askChooseAngang(message)
end

-- 下家
nextTurn = function(payload)
	local message = modGameProto.NextTurnRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	battle:nextTurn(message)
end

-- 小结算
askCheckGameOver = function(payload)
	local message = modGameProto.AskCheckGameOverRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	battle:askCheckGameOver(message)
end

-- 更新玩家分数
updatePlayerScore = function(payload)
	local message = modGameProto.UpdatePlayerScoreRequest()
	message:ParseFromString(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	battle:updatePlayerScore(message)
	log("info","update_player_score","FromPlayer:",message.from_player_id,"ToPlayer:",message.to_player_id,"score:",message.score_delta)
end

-- 更新剩余牌数
updateUndealtCardCount = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.UpdateUndealtCardCountRequest()
	message:ParseFromString(payload)
	battle:updateUndealtCardCount(message)
end

updateReservedCardCount = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.UpdateReservedCardCountRequest()
	message:ParseFromString(payload)
	battle:getBattleUI():updateReservedCard(message.reserved_card_count)
end

showClosureReport = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modRoomProto.ShowClosureReportRequest()
	message:ParseFromString(payload)

	battle:getBattleUI():clearDiscardMark()
	modFunctionManager.pUIFunctionManager:instance():startFunction(function()
		if modCalculate.pCalculatePanel:getInstance() then
			modCalculate.pCalculatePanel:instance():close()
		end
		modEndCalculate.pEndCalculate:instance():open(message)
	end)
end

rollDices = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.RollDicesRequest()
	message:ParseFromString(payload)
	battle:rollDices(message)
end

sendMessage = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local gameVoiceName = nil
	if not battle then
		local modCardbattleMgr = import("logic/card_battle/main.lua")
		battle = modCardbattleMgr.getCurBattle()
		if not battle then
			return
		end
		gameVoiceName = battle:getGameVoiceName()
	end
	local message = modChatProto.SendChatMessageRequest()
	message:ParseFromString(payload)
	battle:getBattleUI():showSendMessage(message, gameVoiceName)
end

-- 更新牌池(除combs， 明牌)
updateCardPoolUpdate = function(payload)

	log("info", "UPDATE_CARD_POOL===============")
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.UpdateCardPool()
	message:ParseFromString(payload)
	battle:updateCardPoolUpdate(message)
end

-- 更新明牌(combs)
updateShowCombsUpdate = function(payload)
	logv("warn","updateShowCombsUpdate")
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.UpdateShowedCombinationsRequest()
	message:ParseFromString(payload)
	battle:updateShowCombsUpdate(message)
end

-- 延迟关闭解散房间界面
dismissRoomClose = function()
	modFunctionManager.pUIFunctionManager:instance():startFunction(function()
		if modDisMissList.pDisMissList:getInstance() then
			modDisMissList.pDisMissList:instance():isShowOkAndNo(false)
			modDisMissList.pDisMissList:instance():timeOut(disRoomTime,nil,function()
				if modDisMissList.pDisMissList:getInstance() then
					modDisMissList.pDisMissList:instance():close()
				end
			end)
		end
	end)
end

dismissRoomAndStopFunction = function()
	modFunctionManager.pUIFunctionManager:instance():startPriorFunction(function()
		if modDisMissList.pDisMissList:getInstance() then
			modDisMissList.pDisMissList:instance():isShowOkAndNo(false)
			modDisMissList.pDisMissList:instance():timeOut(disRoomTime, nil, function()
				if modDisMissList.pDisMissList:getInstance() then
					modDisMissList.pDisMissList:instance():close()
				end
				modFunctionManager.pUIFunctionManager:instance():stopPriorFunction()
			end)
		end
	end)
end

showGamePhaseWnd = function(battle, phase)
	if battle:isShowPhaseWnd() then
		local modGamePhase = import("ui/battle/gamephase.lua")
		local isNotBg = false
		if battle:isYunYangMj() or battle:isXueZhanDaoDiMj() then
			isNotBg = true
		end
		modGamePhase.pGamePhase:instance():open(battle:getBattleUI():getCombParentWnd(), phase, isNotBg)
	end
end

gamePhase = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.EnterGamePhaseRequest()
	message:ParseFromString(payload)
	battle:gamePhaseFunction(message.game_phase)
end

askChooseCards = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.AskChooseCardsRequest()
	message:ParseFromString(payload)
	battle:askChooseCards(message)
end

robAnganResult = function ( payload )	
	local modMenuMain = import("logic/battle/main.lua")
	local battle = modMenuMain.getCurBattle()
	local message = modGameProto.RobAngangResultRequest()
	message:ParseFromString(payload)
	logv("warn",message.card_id)
	logv("warn",message.is_hu)	
	logv("warn",message)
	battle:askChooseAngangIds(message)
end

updateWinnerCards = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.UpdateWinningCardsRequest()
	message:ParseFromString(payload)
	battle:updateWinnerCards(message)
end

updateMagicCards = function(payload)
	local modUIUtil = import("ui/common/util.lua")
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.UpdateMagicCardsRequest()
	message:ParseFromString(payload)
	battle:updateMagicCards(message)
end

updateDiscardIndex = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.UpdateSpecialDiscardingPositionRequest()
	message:ParseFromString(payload)
	battle:updateDiscardIndex(message)
end

updatePlayerExtras = function(payload)
	local modBattleMain = import("logic/battle/main.lua")
	local battle = modBattleMain.getCurBattle()
	local message = modGameProto.UpdatePlayerExtrasRequest()
	message:ParseFromString(payload)
	battle:updatePlayerExtras(message)
end

notifyNewMail = function(payload)
	local message = modMailProto.NotifyNewMailRequest()
	message:ParseFromString(payload)
	local lastMailId = message.latest_mail_id
	modEvent.fireEvent(EV_PROCESS_MAIL, true)
	modEvent.fireEvent(EV_NEW_MAIL, lastMailId)
end

updateClubMember = function(payload)
	local message = modClubProto.UpdateClubMemberRequest()
	message:ParseFromString(payload)
--[[	local modMainDesk = import("ui/club/main_desk.lua")
	if modMainDesk.pMainDesk:getInstance() then
		modMainDesk.pMainDesk:instance():refreshMemberInfo(message)
	end]]--
	local modClubMgr = import("logic/club/main.lua")
	modClubMgr.getCurClub():refreshClubSelfMemberInfo(message)
end

local protoFunctions = {
	[modRoomProto.CLOSE_ROOM] = closeRoom,
	[modRoomProto.CANCEL_CLOSE_ROOM] = cancelCloseRoom,
	[modRoomProto.ANSWER_CLOSE_ROOM] = answerCloseRoom,
	[modRoomProto.ASK_CLOSE_ROOM] = askCloseRoom,
	[modRoomProto.APPLY_CLOSE_ROOM] = applyCloseRoom,
	[modLobbyProto.UPDATE_USER_PROPS] = updateUserProps,
	[modLobbyProto.POST_NOTICES] = postNotices,
	[modRoomProto.ADD_USER] = addUser,
	[modRoomProto.REMOVE_USER] = removeUser,
	[modRoomProto.UPDATE_ONLINE] = updateOnline,
	[modGameProto.UPDATE_CARD_POOL] = updateCardPoolUpdate,
	[modGameProto.UPDATE_SHOWED_COMBINATIONS] = updateShowCombsUpdate,
	[modGameProto.ASK_CHOOSE_CARD_TO_DISCARD] = askChooseCardToDiscard,
	[modGameProto.ASK_CHOOSE_PLAYER_FLAG] = askChoosePlayerFlag,
	[modGameProto.UPDATE_PLAYER_FLAGS] = updatePlayerFlags,
	[modGameProto.START_GAME] = startGame,
	[modGameProto.ASK_CHOOSE_COMBINATION] = askChooseCombination,
	[modGameProto.ASK_CHOOSE_ANGANG] = askChooseAngang,
	[modGameProto.NEXT_TURN] = nextTurn,
	[modGameProto.ASK_CHECK_GAME_OVER] = askCheckGameOver,
	[modGameProto.UPDATE_PLAYER_SCORE] = updatePlayerScore,
	[modGameProto.UPDATE_UNDEALT_CARD_COUNT] = updateUndealtCardCount,
	[modRoomProto.SHOW_CLOSURE_REPORT] = showClosureReport,
	[modGameProto.ROLL_DICES] = rollDices,
	[modChatProto.SEND_CHAT_MESSAGE] = sendMessage,
	[modGameProto.ENTER_GAME_PHASE] = gamePhase,
	[modGameProto.ASK_CHOOSE_CARDS] = askChooseCards,
	[modGameProto.ROB_ANGANG_RESULT] = robAnganResult,
	[modGameProto.UPDATE_WINNING_CARDS] = updateWinnerCards,
	[modGameProto.UPDATE_MAGIC_CARDS] = updateMagicCards,
	[modGameProto.UPDATE_RESERVED_CARD_COUNT] = updateReservedCardCount,
	[modGameProto.UPDATE_SPECIAL_DISCARDING_POSITION] = updateDiscardIndex,
	[modGameProto.UPDATE_PLAYER_EXTRAS] = updatePlayerExtras,
	[modMailProto.NOTIFY_NEW_MAIL] = notifyNewMail,
	[modClubProto.UPDATE_CLUB_MEMBER] = updateClubMember,
}

getProtoFunction = function(proto)
	return protoFunctions[proto]
end

