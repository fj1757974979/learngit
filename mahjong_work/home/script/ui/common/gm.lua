local modUtil = import("util/util.lua")
local modPokerProto = import("data/proto/rpc_pb2/pokers/poker_pb.lua")
local modSessionMgr = import("net/mgr.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modCardBattleMgr = import("logic/card_battle/main.lua")

pGmPanel = pGmPanel or class(pWindow, pSingleton)

pGmPanel.init = function(self)
	self:load("data/ui/gm.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	modUtil.addFadeAnimation(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)
	self.btn_ok:addListener("ec_mouse_click", function()
		local userId = self.edit_user_id:getText()
		if not userId or userId == "" or not tonumber(userId) then
			infoMessage(TEXT("请输入正确的玩家ID"))
			return
		end
		local request = modLobbyProto.GetUserRoomRequest()
		request.user_id = tonumber(userId)
		request.channel_id = modUtil.getOpChannel()
		local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
		modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_USER_ROOM, request, OPT_NONE, function(success, reason, ret)
			wnd:setParent(nil)
			if success then
				local reply = modLobbyProto.GetUserRoomReply()
				reply:ParseFromString(ret)
				local code = reply.code
				if code == modLobbyProto.GetUserRoomReply.SUCCESS then
					local roomId = reply.room.id
					local roomHost = reply.room.host
					local roomPort = reply.room.port
					local gameType = reply.room.game_type
					if gameType == modLobbyProto.POKER then
						modCardBattleMgr.pBattleMgr:instance():observeBattle(roomId, roomHost, roomPort, tonumber(userId), function(success)
							if success then
								self:close()
							else
								infoMessage(TEXT("操作失败"))
							end
						end)
					end
				elseif code == modLobbyProto.GetUserRoomReply.NO_USER then
					infoMessage(TEXT("找不到该玩家"))
				elseif code == modLobbyProto.GetUserRoomReply.NO_ROOM then
					infoMessage(TEXT("玩家不在游戏中"))
				elseif code == modLobbyProto.GetUserRoomReply.NO_ROOM_INFO then
					infoMessage(TEXT("玩家牌局已不存在"))
				else
					infoMessage(TEXT("请求失败"))
				end
			else
				infoMessage(reason)
			end
		end)
	end)
end

pGmPanel.open = function(self)
	self:show(true)
end

pGmPanel.close = function(self)
	pGmPanel:cleanInstance()
end
