local modSessionMgr = import("net/mgr.lua")
local modPokerProto = import("data/proto/rpc_pb2/pokers/poker_pb.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modPokerBattleMain = import("logic/card_battle/main.lua")

local register = function()
	modSessionMgr.instance():regRpcMethod(modPokerProto.NOTIFY_USER_ENTER_STATE, function(payload)
		local notify = modPokerProto.UserEnterStateNotify()
		notify:ParseFromString(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			log("info", "NOTIFY_USER_ENTER_STATE")
			battle:playerEnterState(notify.user_id, notify.state_info)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.NOTIFY_TABLE_ENTER_STATE, function(payload)
		local notify = modPokerProto.TableEnterStateNotify()
		notify:ParseFromString(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			log("info", "NOTIFY_TABLE_ENTER_STATE")
			battle:enterState(notify.state_info)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.ADD_POKER_USER, function(payload)
		local notify = modPokerProto.AddPokerUserNotify()
		notify:ParseFromString(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			battle:addPlayer(notify.user_id, notify.player_id, notify.is_fake, notify.is_ready, notify.score)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.DEL_POKER_USER, function(payload)
		local notify = modPokerProto.DelPokerUserNotify()
		notify:ParseFromString(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			battle:delPlayer(notify.user_id)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.ADD_POKER_OBSERVER, function(payload)
		local notify = modPokerProto.AddPokerObserverNotify()
		notify:ParseFromString(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			battle:addObserver(notify.user_id, notify.ob_user_id)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.DEL_POKER_OBSERVER, function(payload)
		local notify = modPokerProto.DelPokerObserverNotify()
		notify:ParseFromString(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			battle:delObserver(notify.user_id)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.POKER_USER_ONLINE, function(payload)
		local notify = modPokerProto.PokerUserOnlineNotify()
		notify:ParseFromString(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			log("info", "POKER_USER_ONLINE", notify.user_id)
			battle:playerOnline(notify.user_id)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.POKER_USER_OFFLINE, function(payload)
		local notify = modPokerProto.PokerUserOfflineNotify()
		notify:ParseFromString(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			log("info", "POKER_USER_OFFLINE", notify.user_id)
			battle:playerOffline(notify.user_id)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.POKER_ASK_CLOSE_ROOM, function(payload)
		print("============ ask poker close room ===============")
		local message = modRoomProto.AskCloseRoomRequest()
		message:ParseFromString(payload)
		local modDismissList = import("ui/battle/dismisslist.lua")
		modDismissList.pDisMissList:instance():open(message.user_id, T_POKER_ROOM)
		modDismissList.pDisMissList:instance():setReLoad(true)
		modDismissList.pDisMissList:instance():setTimeOut(message.timeout)
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.POKER_ANSWER_CLOSE_ROOM, function(payload)
		print("============ answer poker close room ===============")
		local modEvent = import("common/event.lua")
		local message = modRoomProto.AnswerCloseRoomRequest()
		message:ParseFromString(payload)
		modEvent.fireEvent(EV_UPDATE_DISSROOM_RESULT, message)
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.CLOSE_POKER_ROOM, function(payload)
		if modPokerBattleMain.pBattleMgr:instance():onServerCloseRoom() then
			infoMessage(TEXT("房间已关闭"))
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.POKER_CANCEL_CLOSE_ROOM, function(payload)
		print("============ cancel poker close room ===============")
		local modDismissList = import("ui/battle/dismisslist.lua")
		if modDismissList.pDisMissList:getInstance() then
			modDismissList.pDisMissList:instance():close()
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.POKER_APPLY_CLOSE_ROOM, function(payload)
		print("============ apply poker close room ===============")
		local message = modRoomProto.ApplyCloseRoomRequest()
		message:ParseFromString(payload)
		local modDismissList = import("ui/battle/dismisslist.lua")
		if modDismissList.pDisMissList:getInstance() then
			modDismissList.pDisMissList:instance():close()
		end
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			battle:prepareCancel()
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.NOTIFY_POKER_USER_READY, function(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			local message = modPokerProto.PokerUserReadyNotify()
			message:ParseFromString(payload)
			battle:playerReady(message.user_id, message.is_ready)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.NOTIFY_START_POKER_GAME, function(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			local message = modPokerProto.StartPokerGameNotify()
			message:ParseFromString(payload)
			battle:setStartFlag(message.is_started)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.NOTIFY_USER_FINISH_STATE, function(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			local message = modPokerProto.UserFinishStateNotify()
			message:ParseFromString(payload)
			battle:onNotifyPlayerFinishState(message.user_id, message.state_info)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.NOTIFY_USER_BANKRUPT, function(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			local message = modPokerProto.UserBankruptNotify()
			message:ParseFromString(payload)
			battle:onNotifyPlayerBankrupt(message.user_id)
		end
	end)

	modSessionMgr.instance():regRpcMethod(modPokerProto.GM_NOTIFY_CARD_CHANGE, function(payload)
		local battle = modPokerBattleMain.getCurBattle()
		if battle then
			local message = modPokerProto.GmCardChangeNotify()
			message:ParseFromString(payload)
			battle:onNotifyCardChange(message)
		end
	end)
end

__init__ = function()
	register()
end

