import("net/macros.lua")
local modNetUtil = import("net/util.lua")

local modSession = import("net/session.lua")

local sessionTypeToCls = {
	[T_SESSION_AUTH] = modSession.pAuthSession,		-- 验证
	[T_SESSION_PROXY] = modSession.pProxySession,	-- 大厅
	[T_SESSION_BATTLE] = modSession.pBattleSession,	-- 麻将对局
	[T_SESSION_POKER] = modSession.pPokerSession,   -- 牌类对局
}

pSessionMgr = pSessionMgr or class(pSingleton)

pSessionMgr.init = function(self)
	-- type --> session
	self.sessions = {}
	self.rpcMethods = {}
end

pSessionMgr.newSession = function(self, t, ip, port)
	if self.sessions[t] then
		self:closeSession(t)
	end
	local cls = sessionTypeToCls[t]
	if cls then
		local session = cls:new(ip, port, self)
		self.sessions[t] = session
		return session
	else
		return nil
	end
end

pSessionMgr.closeSession = function(self, t)
	local session = self.sessions[t]
	if session then
		session:destroy()
		self.sessions[t] = nil
	end
end

pSessionMgr.hasSession = function(self, t)
	return self.sessions[t] ~= nil
end

pSessionMgr.hasSessionAvailable = function(self, t)
	local session = self.sessions[t]
	if not session then
		return false
	else
		return session:isSessionAvailable()
	end
end

pSessionMgr.setDeamonMode = function(self, flag)
	self.deamonMode = flag
end

pSessionMgr.onEnterBackground = function(self)		
	if not self.deamonMode then
		for t, session in pairs(self.sessions) do
			session:disconnectRemote()
		end
	end
end

pSessionMgr.onEnterForeground = function(self)	
	if not self.deamonMode then
		for t, session in pairs(self.sessions) do
			session:reconnect()
		end
	end
end

pSessionMgr.callRpc = function(self, t, msgid, body, opt, callback, noBlock)    
	local session = self.sessions[t]	
	if not session then		
		callback(false, TEXT("找不到会话连接"))
		return
	end	
	session:callToRemote(msgid, body, opt, callback, noBlock)
end

--[[
pSessionMgr.loadRpcMethods = function(self)
	import("net/rpc/battle.lua")
end
]]--

pSessionMgr.getRpcMethod = function(self, msgid)
	return self.rpcMethods[msgid]
end

pSessionMgr.regRpcMethod = function(self, msgid, method)	
	self.rpcMethods[msgid] = method
end

pSessionMgr.notifyReconnect = function(self, session, callback)
	if not self.reconnectCbs then
		self.reconnectCbs = {}
	end
	self.reconnectCbs[session] = callback
	modNetUtil.notifyReconnect(function()
		for _, cb in pairs(self.reconnectCbs) do
			cb()
		end
	end)
end

pSessionMgr.getSessionPing = function(self, t)
	if not t or not self.sessions[t] then 
		return 
	end
	return self.sessions[t]:getPing()
end

instance = function()
	return pSessionMgr:instance()
end

__init__ = function()
end
