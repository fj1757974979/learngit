local modSocket = import("net/socket.lua")
local modUtil = import("util/util.lua")
local modNetUtil = import("net/util.lua")
local modCommonProto = import("data/proto/rpc_pb2/common_pb.lua")
local modLoginProto = import("data/proto/rpc_pb2/login_pb.lua")

local errToMsg = {
	[ST_NO_CONNECT] = TEXT("网络连接断开"),
	[ST_ERROR] = TEXT("请求错误"),
	[ST_DUPLICATE] = TEXT("重复的请求"),
}

local bandRedoMsgid = {
	[modCommonProto.PING] = true,
}

pSession = pSession or class()

pSession.init = function(self, ip, port, mgr)
	self.socket = modSocket.pSocket:new(self)
	self.ip = ip
	self.port = port
	self.buffer = nil
	self.identity = 0
	self.asyncRpcTask = {}
	self.blockedRpcTask = {}
	self.mgr = mgr
	self.timeout = modUtil.s2f(5)
	self.ping = nil
end

pSession.getType = function(self)
	return nil
end

pSession.genIdentity = function(self)	
	self.identity = self.identity + 1
	return self.identity
end

pSession.launchTimeoutChecker = function(self)
	if self.__timeout_checker then
		self.__timeout_checker:stop()
	end
	self.__timeout_checker = setInterval(10, function()
		if not self:isSessionAvailable() or self.__reconnecting then
			return
		end
		local identities = table.keys(self.asyncRpcTask)
		for _, identity in ipairs(identities) do
			local info = self.asyncRpcTask[identity]
			local frame = info.frame
			if app:getCurrentFrame() - frame >= self.timeout then
				local msgid = info.msgid
				if not bandRedoMsgid[msgid] then
					-- 重发
					local message = Request()
					message.sequence_number = identity
					message.method_id = msgid
					message.arguments = info.payload
					message.options = info.opt
					self:_sendMsg(T_REQUEST, message)
				else
					-- 清除
					self.asyncRpcTask[identity] = nil
				end
			end
		end
	end)
end

pSession.startHeartBeat = function(self)
	if self.__heartbeat_hdr then
		self.__heartbeat_hdr:stop()
	end
	self.__heartbeat_hdr = setInterval(modUtil.s2f(2), function()
		if self.__destroyed then
			return "release"
		end
		local time = modUtil.getServerTimeMs()
		self:callToRemote(modCommonProto.PING, nil, OPT_NONE, function(isSuccess, reason, ret)
			if isSuccess then
				local message = modCommonProto.PingReply()
				message:ParseFromString(ret)
				--log("info", "ping ret", message.timestamp)
				modUtil.setupServerTime(message.timestamp)
				local ctime = modUtil.getServerTimeMs()
				self.ping = ctime - time
			else
				self.ping = nil
				log("error", "ping error:", reason)
			end
		end)
	end)
end

pSession.getPing = function(self)
	return self.ping
end

pSession.isSessionAvailable = function(self)
	if self.socket then
		return self.socket:isAvailable()
	else
		return false
	end
end

pSession.callConnectCb = function(self, timeout, err)
	if self.__connect_cb then
		self.__connect_cb(timeout, err)
		self.__connect_cb = nil
	end
end

pSession.connectRemote = function(self, callback, retryCnt)
	if self.__destroyed then
		return
	end
	if self.socket:isAvailable() then
		callback(false, false)
		return
	end

	if callback then
		self.__connect_cb = callback
	end
	self.connectRetryCnt = retryCnt or 0
	self.socket:connectRemote(self.ip, self.port, function(timeout, err)
		if (timeout or err) and
			self.connectRetryCnt < C_NET_CONNECT_RETRY_MAX_CNT then
			setTimeout(1, function()
				--modUtil.consolePrint(sf("connect remote %s[%d] failed, retry [%d]", self.ip, self.port, self.connectRetryCnt))
				self:connectRemote(callback, self.connectRetryCnt + 1)
			end)
		else
			--modUtil.consolePrint(sf("[session] connect remote done [%s:%d]", self.ip, self.port))
			self:callConnectCb(timeout, err)
		end
	end)
end

pSession._sendMsg = function(self, t, message)	
	local data = message:SerializeToString()
	local dataLen = string.len(data)
	local content = {}
	for i = 1, dataLen do
		local t = string.byte(data, i)
		table.insert(content, t)
	end

	local sendData = map(string.char, content, ipairs)
	self.buffer = puppy.pBuffer:new()
	self.buffer:initFromString(table.concat(sendData), dataLen)
	return self.socket:sendBuffer(self.buffer, dataLen, t)
end

pSession.callToRemote = function(self, msgid, body, opt, callback, noBlock)	
	local identity = self:genIdentity()	
	--modUtil.consolePrint(sf("[session] callToRemote %d [%d][%s:%d]", msgid, identity, self.ip, self.port))
	local addBlockedCache = function()
		--modUtil.consolePrint(sf("[session] add %d to blocked cache [%s:%d]", msgid, self.ip, self.port))
		self.blockedRpcTask[identity] = {
			msgid = msgid,
			body = body,
			opt = opt,
			callback = callback,
		}
	end		
	if (not self:isSessionAvailable() or
		self.__reconnecting) and
		not noBlock then
		--callback(false, errToMsg[ST_NO_CONNECT])
		if not bandRedoMsgid[msgid] then
			addBlockedCache()
			if not self.__reconnecting and
				not app:isInBackground() then
				self:reconnect()
			end
			return
		end
	end
	
	local message = Request()
	
	message.sequence_number = identity
	
	message.method_id = msgid	
	if body then		
		message.arguments = body:SerializeToString()
	else		
		message.arguments = ""
	end	
	message.options = opt	
	if opt ~= OPT_NO_REPLY and callback then
		self.asyncRpcTask[identity] = {
			identity = identity,
			callback = callback,
			payload = message.arguments,
			frame = app:getCurrentFrame(),
			msgid = msgid,
			time = modUtil.getTime(),
			body = body,
			opt = opt
		}		
		modUtil.consolePrint(sf("[session] add %d to async rpc cache [%s:%d]", msgid, self.ip, self.port))
	end

	--log("info", sf("callToRemote, msgid = %d, identity = %d done", msgid, identity))	
	self:_sendMsg(T_REQUEST, message)
end

pSession.replyFromRemote = function(self, payload)
	local message = Reply()
	message:ParseFromString(payload)
	local identity = message.sequence_number
	local taskEntry = self.asyncRpcTask[identity]
	if not taskEntry then
		log("error", sf("late reply for request %d", identity))
		return
	end
	self.asyncRpcTask[identity] = nil
	local callback = taskEntry.callback
	local status = message.status
	if status ~= ST_OK then		
		callback(false, errToMsg[status])
	else		
		callback(true, "", message.result)
	end
end

pSession.callFromRemote = function(self, payload)
	local message = Request()
	message:ParseFromString(payload)
	local identity = message.sequence_number
	local msgid = message.method_id
	local opt = message.options
	local method = self.mgr:getRpcMethod(msgid)
	if not method then
		log("error", sf("pSession.callFromRemote can't find method for msgid = %d", msgid))
		return
	end
	if opt == Request.NO_REPLY then
		method(message.arguments)
	else
		local reply = Reply()
		reply.sequence_number = identity
		if not method then
			reply.status = ST_ERROR
		else
			reply.status = ST_OK
			reply.arguments = method(message.arguments):SerializeToString()
		end
		self:_sendMsg(T_REPLY, reply)
	end
	log("info", sf("callFromRemote, msgid = %d, identity = %d", msgid, identity))
end

pSession._redoAllTask = function(self)
	modUtil.consolePrint(sf("[session] redo all task [%s:%d]", self.ip, self.port))
	local asyncIds = table.keys(self.asyncRpcTask)
	for _, identity in ipairs(asyncIds) do
		local info = self.asyncRpcTask[identity]
		local msgid = info.msgid
		if not bandRedoMsgid[msgid] then
			local body = info.body
			local opt = info.opt
			local callback = info.callback
			modUtil.consolePrint(sf("[session] redo async task: %d", msgid))
			self:callToRemote(msgid, body, opt, callback)
		end
		self.asyncRpcTask[identity] = nil
	end
	local ids = table.keys(self.blockedRpcTask)
	for _, identity in ipairs(ids) do
		local task = self.blockedRpcTask[identity]
		local msgid = task.msgid
		if not bandRedoMsgid[msgid] then
			local body = task.body
			local opt = task.opt
			local callback = task.callback
			modUtil.consolePrint(sf("[session] redo blocked task: %d", msgid))
			self:callToRemote(msgid, body, opt, callback)
		end
		self.blockedRpcTask[identity] = nil
	end
end

pSession._errorAllTask = function(self)
	for identity, info in pairs(self.asyncRpcTask) do
		local callback = info.callback
		if callback then
			callback(false, errToMsg[ST_NO_CONNECT])
		end
	end
	self.asyncRpcTask = {}
end

pSession.networkError = function(self, code, msg)
	log("info", "networkError: destroyed ", self, self.__destroyed)
	modUtil.consolePrint(sf("networkError: destroyed: %s %s [%s:%d]", self.__destroyed, debug.traceback(), self.ip, self.port))
	if not self.__destroyed and not self.__reconnecting then
		-- 所有请求作出错处理
		-- 太粗暴...
		--self:_errorAllTask()
		setTimeout(1, function()
			-- 重连服务器
			self:reconnect()
		end)
	end
end

pSession.reconnect = function(self)
	logv("warn","pSession.reconnect")
	if self.__destroyed then
		return
	end
	if self.__reconnecting then
		return
	end
	self.__reconnecting = true
	modUtil.consolePrint(sf("reconnect: destroyed: %s %s [%s:%d]", self.__destroyed, debug.traceback(), self.ip, self.port))
	self:_errorAllTask()
	self:connectRemote(function(timeout, err)
		if self.__destroyed then
			return
		end
		if timeout or err then
			self.__reconnecting = false
			log("error", "reconnect fail, timeout=%s, err=%s")
			modUtil.consolePrint(sf("[session] reconnect fail... [%s:%d]", self.ip, self.port))
			-- hint
			self.mgr:notifyReconnect(self, function()
				setTimeout(10, function()
					self:reconnect()
				end)
			end)
		else
			self:onReconnectDone(function(timeout, err)
				if self.__destroyed then
					return
				end
				self.__reconnecting = false
				if timeout or err then
					log("error", sf("reconnect done func fail, timeout=%s, err=%s"
									, timeout
									, err))
					modUtil.consolePrint(sf("[session] reconnect after do fail... [%s:%d]", self.ip, self.port))
					self:reconnect()
				else
					modUtil.consolePrint(sf("[session] reconnect ok! [%s:%d]", self.ip, self.port))
					self:_redoAllTask()
					self:startHeartBeat()
					self:launchTimeoutChecker()
					local modEvent = import("common/event.lua")
					modEvent.fireEvent(EV_RECONNECT_DONE)
				end
			end)
		end
	end)
end

pSession.onReconnectDone = function(self, callback)
	-- to be implemented
end

pSession.networkTimeout = function(self, code, msg)
	-- 网络超时，底层socket很长一段时间没有读写，作出错处理效果更好
	self:networkError()
end

pSession.networkAvailable = function(self)
	if not self.__reconnecting then
		self:startHeartBeat()
		self:launchTimeoutChecker()
	end
end

pSession.isConnected = function(self)
	return self.socket:isConnected()
end

pSession.disconnectRemote = function(self)
	if self.__timeout_checker then
		self.__timeout_checker:stop()
		self.__timeout_checker = nil
	end
	if self.__heartbeat_hdr then
		self.__heartbeat_hdr:stop()
		self.__heartbeat_hdr = nil
	end
	self:_errorAllTask()
	self.buffer = nil
	modUtil.consolePrint(sf("disconnectRemote: destroyed: %s %s [%s:%d]", self.__destroyed, debug.traceback(), self.ip, self.port))
	self.socket:close()
end

pSession.destroy = function(self)
	log("warn", "session destroy!", self)
	self.__destroyed = true
	self:disconnectRemote()
	self.socket = nil
	self.asyncRpcTask = {}
	self.blockedRpcTask = {}
	self.mgr = nil
	self.ping = nil
end

----------------------------------------------------------

pAuthSession = pAuthSession or class(pSession)

pAuthSession.init = function(self, ip, port, mgr)
	pSession.init(self, ip, port, mgr)
	self.socket:setTimeoutLimit(C_NET_TIMEOUT_MAX_LIMIT)
end

pAuthSession.networkTimeout = function(self, code, msg)
	-- 与验证服的会话忽略网络超时
	-- do nothing
end

pAuthSession.networkAvailable = function(self)
	pSession.networkAvailable(self)
end

pAuthSession.getType = function(self)
	return T_SESSION_AUTH
end
----------------------------------------------------------

pProxySession = pProxySession or class(pSession)

pProxySession.init = function(self, ip, port, mgr)
	pSession.init(self, ip, port, mgr)
	self.socket:setTimeoutLimit(C_NET_TIMEOUT_LIMIT)
end

pProxySession.onReconnectDone = function(self, callback)
	local modLoginMgr = import("logic/login/main.lua")
	modLoginMgr.pLoginMgr:instance():relogin(function(success, reason)
		if success then
			infoMessage(TEXT("重连成功"))
		end
		callback(false, not success)
	end)
end

pProxySession.networkAvailable = function(self)
	pSession.networkAvailable(self)
end

pProxySession.getType = function(self)
	return T_SESSION_PROXY
end

----------------------------------------------------------

pBattleSession = pBattleSession or class(pSession)

pBattleSession.init = function(self, ip, port, mgr)
	pSession.init(self, ip, port, mgr)
	self.socket:setTimeoutLimit(C_NET_TIMEOUT_LIMIT)
end

pBattleSession.getCurBattle = function(self)
	local modBattleMain = import("logic/battle/main.lua")
	return modBattleMain.getCurBattle()
end

pBattleSession.enterBattleRoom = function(self, roomId, callback)
	local modBattleMain = import("logic/battle/main.lua")
	modBattleMain.pBattleMgr:instance():enterRoom(roomId, callback, true)
end

pBattleSession.onReconnectDone = function(self, callback)
	local battle = self:getCurBattle()
	if battle then
		local roomId = battle:getRoomId()
		if roomId then
			self:enterBattleRoom(roomId, function(success)
				callback(false, false)
			end)
		else
			callback(false, false)
		end
	else
		callback(false, false)
	end
end

pBattleSession.networkAvailable = function(self)
	pSession.networkAvailable(self)
end

pBattleSession.getType = function(self)
	return T_SESSION_BATTLE
end

----------------------------------------------------------

pPokerSession = pPokerSession or class(pBattleSession)

pPokerSession.init = function(self, ip, port, mgr)
	pBattleSession.init(self, ip, port, mgr)
end

pPokerSession.getCurBattle = function(self)
	local modBattleMain = import("logic/card_battle/main.lua")
	return modBattleMain.getCurBattle()
end

pPokerSession.enterBattleRoom = function(self, roomId, callback)
	local modBattleMain = import("logic/card_battle/main.lua")
	local battle = self:getCurBattle()
	local followeeUid = battle:getFolloweeUid()
	if followeeUid then
		modBattleMain.pBattleMgr:instance():followPlayer(roomId, followeeUid, callback)
	else
		modBattleMain.pBattleMgr:instance():enterRoom(roomId, callback)
	end
end
