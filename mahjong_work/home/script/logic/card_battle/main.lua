local modNiuniuProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")
local modBattleRpc = import("logic/card_battle/rpc.lua")
local modClubMgr = import("logic/club/main.lua")
local modClubImplProto = import("data/proto/rpc_pb2/club_impl_pb.lua")
local modUserData = import("logic/userdata.lua")

pBattleMgr = pBattleMgr or class(pSingleton)

pBattleMgr.init = function(self)
	local modNiuniuBattle = import("logic/card_battle/battles/niuniu/battle.lua")
	local modPaijiuBattle = import("logic/card_battle/battles/paijiu/battle.lua")
	self.battleCls = {
		[modNiuniuProto.NIUNIU] = modNiuniuBattle.pNiuniuBattle,
		[modNiuniuProto.PAIJIU] = modPaijiuBattle.pPaijiuBattle,
	}
	self.battle = nil
end

pBattleMgr.getCurBattle = function(self)
	return self.battle
end

pBattleMgr.createBattle = function(self, roomId, reply)
	local pokerType = reply.game_state.poker_type
	local battleCls = self.battleCls[pokerType]
	if battleCls then
		self.battle = battleCls:new(roomId, reply.create_info)
		return true
	else
		log("error", "can't find poker battle class for type", pokerType)
		return false
	end
end

pBattleMgr.enterBattle = function(self, roomId, roomHost, roomPort, callback)
	local wnd = modUtil.loadingMessage(TEXT("正在连接到房间服务器..."))
	self:initRoomNet(roomHost, roomPort, function(success)
		wnd:setParent(nil)
		if success then
			self:enterRoom(roomId, callback)
		else
			infoMessage(TEXT("连接到房间服务器失败"))
			modSessionMgr.instance():closeSession(T_SESSION_POKER)
		end
	end)
end

pBattleMgr.observeBattle = function(self, roomId, roomHost, roomPort, followee, callback)
	if self.battle then
		infoMessage(TEXT("已经在牌局中了"))
		callback(false)
		return
	end
	local wnd = modUtil.loadingMessage(TEXT("正在连接到房间服务器..."))
	self:initRoomNet(roomHost, roomPort, function(success)
		wnd:setParent(nil)
		if success then
			self:followPlayer(roomId, followee, callback)
		else
			infoMessage(TEXT("连接到房间服务器失败"))
			modSessionMgr.instance():closeSession(T_SESSION_POKER)
		end
	end)
end

pBattleMgr.reenterBattle = function(self, roomId, roomHost, roomPort, callback)
	if self.battle then
		infoMessage(TEXT("已经在牌局中了"))
		callback(false)
		return
	end
	local wnd = modUtil.loadingMessage(TEXT("正在连接到房间服务器..."))
	self:initRoomNet(roomHost, roomPort, function(success)
		wnd:setParent(nil)
		if success then
			modBattleRpc.getUserStateInRoom(roomId, function(success, reason, ret)
				if success then
					if ret.state == 1 then
						-- 打牌
						self:enterBattle(roomId, roomHost, roomPort, callback)
					elseif ret.state == 2 then
						-- 观战
						self:followPlayer(roomId, ret.ob_user_id, callback)
					else
						infoMessage(TEXT("已经不在房间了"))
						modUtil.safeCallBack(callback, false)
					end
				else
					infoMessage(reason)
					modUtil.safeCallBack(callback, false)
				end
			end)
		else
			infoMessage(TEXT("连接到房间服务器失败"))
			modSessionMgr.instance():closeSession(T_SESSION_POKER)
		end
	end)
end

pBattleMgr.initRoomNet = function(self, roomHost, roomPort, callback)
	local session = modSessionMgr.instance():newSession(T_SESSION_POKER, roomHost, roomPort)
	session:connectRemote(function(timeout, err)
		if not timeout and not err then
			callback(true)
		else
			callback(false)
		end
	end)
end

pBattleMgr.enterRoom = function(self, roomId, callback)
	modBattleRpc.enterRoom(roomId, function(success, reason, reply, isRoomCardError)
		if success then
			local bRet = true
			if self.battle then
				--self.battle:destroy()
				self.battle:reset()
			else
				bRet = self:createBattle(roomId, reply)
			end
			if bRet then
				self.battle:initFromData(reply.user_infos, reply.user_fake_infos, reply.user_ob_infos, reply.game_state)
				self.battle:startLocationDetect()
			end
			if callback then callback(bRet) end
		else
			self:cleanBattle()
			setTimeout(1, function()
				self:disconnectBattle()
			end)
			if isRoomCardError then
				local modMenuMain = import("logic/menu/main.lua")
				modMenuMain.pMenuMgr:instance():getCurMenuPanel():buyCard()
				local modShopMgr = import("logic/shop/main.lua")
				local modInvite = import("ui/menu/invite.lua")
				local modJoin = import("ui/menu/join.lua")
				if modShopMgr.pShopMgr:instance():getShopPanel(true) then
					modShopMgr.pShopMgr:instance():getShopPanel():setParent(self)
					modShopMgr.pShopMgr:instance():getShopPanel():setZ(C_BATTLE_UI_Z)
				elseif modInvite.pInviteWindow:getInstance() then
					modInvite.pInviteWindow:instance():setParent(modJoin.pMainJoin:instance())
					modInvite.pInviteWindow:instance():setZ(C_BATTLE_UI_Z)
				end
			end
			infoMessage(reason)
			modUtil.consolePrint(sf("enter room fail! %s", debug.traceback()))
			if callback then callback(false) end
		end
	end)
end

pBattleMgr.followPlayer = function(self, roomId, followee, callback)
	modBattleRpc.followPlayer(roomId, followee, function(success, reason, reply)
		if success then
			local bRet = self:createBattle(roomId, reply)
			if bRet then
				self.battle:initFromData(reply.user_infos, reply.user_fake_infos, reply.user_ob_infos, reply.game_state)
			end
			if callback then callback(bRet) end
		else
			self:cleanBattle()
			setTimeout(1, function()
				self:disconnectBattle()
			end)
			infoMessage(reason)
			if callback then callback(false) end
		end
	end)
end

pBattleMgr.prepareEnterClubGround = function(self)
	if self.battle then
		if self.__prv_battle then
			self.__prv_battle:destroy()
		end
		self.__prv_battle = self.battle
		self.battle = nil
	end
end

pBattleMgr.afterEnterClubGround = function(self)
	if self.__prv_battle then
		self.__prv_battle:destroy()
		self.__prv_battle = nil
	end
end

pBattleMgr.enterClubGround = function(self, clubId, groundId, rematch)
	self:prepareEnterClubGround()
	modClubMgr.getCurClub():clubJoinMatch(clubId, groundId, modUserData.getUID(), rematch, function(success, reply)
		if success then
			local room = reply.room
			self:enterBattle(room.id, room.host, room.port, function(success)
				self:afterEnterClubGround()
			end)
		else
			infoMessage(TEXT("加入俱乐部房间失败"))
			self:afterEnterClubGround()
		end
	end)
end

pBattleMgr.cleanBattle = function(self)
	if self.battle then
		self.battle:destroy()
		self.battle = nil
		return true
	else
		return false
	end
end

pBattleMgr.disconnectBattle = function(self)
	modSessionMgr.instance():closeSession(T_SESSION_POKER)
end

pBattleMgr.battleDestroy = function(self)
	self.preparingCancelFlag = false
	local ret = self:cleanBattle()
	self:disconnectBattle()
	return ret
end

pBattleMgr.onServerCloseRoom = function(self)
	if self.battle then
		local ret = true
		self.battle:destroy()
		self.battle = nil
		modSessionMgr.instance():closeSession(T_SESSION_POKER)
		return ret
	else
		modSessionMgr.instance():closeSession(T_SESSION_POKER)
		return false
	end
end

getCurBattle = function()
	return pBattleMgr:instance():getCurBattle()
end
