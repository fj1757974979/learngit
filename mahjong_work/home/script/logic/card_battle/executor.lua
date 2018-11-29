local modUtil = import("util/util.lua")

pExecutorHost = pExecutorHost or class()

pExecutorHost.getHostType = function(self)
	log("error", "[pExecutorHost.getHostType] not implemented!")
end

---------------------------------------------------------

pExecutorBase = pExecutorBase or class()

pExecutorBase.init = function(self, stateMessage, host)
	self.t = stateMessage.state_name
	self.data = stateMessage.state_data
	self.host = host
	self.timeout = stateMessage.timeout
	self.rest_timeout = stateMessage.rest_timeout
	self.isSatisfied = stateMessage.satisfied
	self.isFinishFlag = false
end

pExecutorBase.getRealRestTime = function(self)
	if self.rest_timeout < 0 then
		return -1
	else
		return self.rest_timeout + 10
	end
end

pExecutorBase.getHost = function(self)
	return self.host
end

pExecutorBase.getType = function(self)
	return self.t
end

pExecutorBase.prepare = function(self)
	if self:getHost():getHostType() == T_EXE_HOST_PLAYER then
		local restTime = self:getRealRestTime()
		log("warn", "pExecutorBase.prepare", self:getHost():getHostName(), self:getType(), restTime)
		if restTime > 0 then
			self:getHost():setNextTimeoutTime(restTime + modUtil.getServerTime())
		else
			self:getHost():setNextTimeoutTime(0)
		end
	end
end

pExecutorBase.exec = function(self)
	self:finish()
end

pExecutorBase.postExec = function(self)
end

pExecutorBase.exit = function(self)
end

pExecutorBase.cancel = function(self)
	pExecutorBase.finish(self)
end

pExecutorBase.isTimeout = function(self)
	return false
end

pExecutorBase.tryCountDown = function(self)
	return
end

pExecutorBase.defaultExec = function(self)
	self:finish()
end

pExecutorBase.finish = function(self)
	log("info", self, self:getHost():getHostName(), "finish", self:getType())
	self.isFinishFlag = true
end

pExecutorBase.isFinish = function(self)
	return self.isFinishFlag
end

pExecutorBase.getMenuParent = function(self)
end

pExecutorBase.onServerNotifyExecutorFinish = function(self, stateData)
	pExecutorBase.finish(self)
end

-------------------------------------------------------

pTableExecutorBase = pTableExecutorBase or class(pExecutorBase)

pTableExecutorBase.prepare = function(self)
	pExecutorBase.prepare(self)
end

pTableExecutorBase.getMenuParent = function(self)
	return self.host:getMenuParent()
end

-------------------------------------------------------

pPlayerExecutorBase = pPlayerExecutorBase or class(pExecutorBase)

pPlayerExecutorBase.prepare = function(self)
	pExecutorBase.prepare(self)
	if self.host:isObserver() then
		pPlayerExecutorBase.finish(self)
	end
end

pPlayerExecutorBase.getMenuParent = function(self)
	local player = self.host
	return player:getBattle():getMenuParent()
end

pPlayerExecutorBase.tryCountDown = function(self)
	if self.timeout <= 0 then
		return
	end
	if self.host:isMyself() then
		self.host:getTableWnd():startCountDown(self.rest_timeout, function()
			self:defaultExec()
		end)
	end
end

pPlayerExecutorBase.finish = function(self)
	pExecutorBase.finish(self)
	if self.host:isMyself() then
		local battle = self.host:getBattle()
		if battle then
			local tableWnd = battle:getTableWnd()
			if tableWnd then
				tableWnd:stopCountDown()
			end
		end
	end
end

pPlayerExecutorBase.cancel = function(self)
	pExecutorBase.cancel(self)
	if self.host:isMyself() then
		self.host:getTableWnd():stopCountDown()
	end
end
-------------------------------------------------------

pExecutorMgr = pExecutorMgr or class()

pExecutorMgr.init = function(self, host)
	self.exeQueue = {}
	self.curExecutor = nil
	self.host = host
end

pExecutorMgr.getHost = function(self)
	return self.host
end

pExecutorMgr.addExecutor = function(self, stateInfo)
	local executor = self:newExecutor(stateInfo, self.host)
	if executor then
		self:addExecutorObj(executor)
	end
end

pExecutorMgr.addExecutorObj = function(self, executor)
	log("info", self:getHost():getHostName(), "addExecutorObj ", executor:getType())
	table.insert(self.exeQueue, executor)
end

pExecutorMgr.addPrepareExecutor = function(self)
	log("error", "[pExecutorMgr.addPrepareExecutor] not implemented!")
end

pExecutorMgr.parseExecutorInfo = function(self, stateInfo)
	log("error", "[pExecutorMgr.parseExecutorInfo] not implemented!")
end

pExecutorMgr.newExecutor = function(self, stateInfo, host)
	local cls, stateMessage = self:parseExecutorInfo(stateInfo)
	if stateMessage and host:getHostType() == T_EXE_HOST_PLAYER then
		if stateMessage.satisfied then
			return nil
		end
	end
	if cls then
		return cls:new(stateMessage, host)
	else
		if stateMessage.state_name and stateMessage.state_name > 0 then
			return pExecutorBase:new(stateMessage, host)
		else
			return nil
		end
	end
end

pExecutorMgr.pause = function(self)
	if self._hdr then
		self._hdr:pause(true)
	end
end

pExecutorMgr.resume = function(self)
	if self._hdr then
		self._hdr:pause(false)
	end
end

pExecutorMgr.checkOnce = function(self, t)
	if self.curExecutor then
		if not self.curExecutor:isFinish() then
			--log("info", self:getHost():getHostName(), "not finish", self.curExecutor:getType())
			return
		elseif self.exeQueue[1] then
			self.curExecutor:exit()
			self.curExecutor = nil
		end
	end
	if t and self.exeQueue[1] and self.exeQueue[1]:getType() ~= t then
		return
	end
	self.curExecutor = self.exeQueue[1]
	if self.curExecutor then
		table.remove(self.exeQueue, 1)
		--try { function()
			log("info", self:getHost():getHostName(), "********* executor type", self.curExecutor:getType())
			self.curExecutor:tryCountDown()
			self.curExecutor:prepare()
			self.curExecutor:exec()
			self.curExecutor:postExec()
		--end} catch { function()
		---	log("error", "execute fail")
		--end} finally { function()
		--end}
	else
		--log("info", self:getHost():getHostName(), "no executor")
	end
end

pExecutorMgr.run = function(self)
end

pExecutorMgr.prepareCancel = function(self)
	if self.curExecutor then
		self.curExecutor:cancel()
	end
	self:reset()
end

pExecutorMgr.onServerNotifyExecutorFinish = function(self, stateMessage)
	if self.curExecutor then
		local stateName = stateMessage.state_name
		if self.curExecutor:getType() == stateName then
			self.curExecutor:onServerNotifyExecutorFinish(stateMessage.state_data)
		end
	end
end

pExecutorMgr.reset = function(self)
	if self.curExecutor then
		self.curExecutor:cancel()
		self.curExecutor = nil
	end
	self.exeQueue = {}
end

pExecutorMgr.destroy = function(self)
	self:reset()
	if self._hdr then
		self._hdr:stop()
		self._hdr = nil
	end
	self.host = nil
end

--------------------------------------------------------

pBattleExecutorMgr = pBattleExecutorMgr or class(pExecutorMgr)

pBattleExecutorMgr.run = function(self)
	if not self._hdr then
		self._hdr = setInterval(1, function()
			self:checkOnce()
			if self.host:getHostType() == T_EXE_HOST_BATTLE then
				if not self.__pause_player_flag then
					local players = self.host:getAllPlayers()
					for _, player in pairs(players) do
						local exeMgr = player:getExecutorMgr()
						if exeMgr then
							if self.curExecutor then
								exeMgr:checkOnce(self.curExecutor:getType())
							else
								exeMgr:checkOnce()
							end
						end
					end
				end
			end
		end)
	end
end

pBattleExecutorMgr.pausePlayer = function(self)
	self.__pause_player_flag = true
end

pBattleExecutorMgr.resumePlayer = function(self)
	self.__pause_player_flag = false
end
