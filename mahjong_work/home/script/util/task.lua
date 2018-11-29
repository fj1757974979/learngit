-- 养成任务管理模块
local modUtil = import("util/util.lua")

----------------------------------------
local modPropMgr = import("common/propmgr.lua")

pTasklet = pTasklet or class(modPropMgr.propmgr)

pTasklet.init = function(self, time, taskType, callback)
	self.data = {}
	self.data.interval = time
	self.data.taskType = taskType
	self.data.callback = callback
	--self.data.lastTime = getTimeStamp()
	self.data.lastTime = getTime()

	--[[
	local mt = {}
	mt.__mode = "kv"
	setmetatable(self.data, mt)
	]]--
end

pTasklet.update = function(self, time, taskType, callback)
	self.data.interval = time
	self.data.taskType = taskType
	self.data.callback = callback
end

pTasklet.pend = function(self)
	self.pendFlg = true
end

pTasklet.resume = function(self)
	self.pendFlg = false
end

pTaskMgr = pTaskMgr or class(pSingleton)

-- 超时任务
local T_TASK_TIMEOUT = 1
local T_SCENE_TASK_TIMEOUT = 11
-- 循环任务
local T_TASK_INTERVAL = 2
local T_SCENE_TASK_INTERVAL = 22

local taskToSceneTaskType = {
	[T_TASK_TIMEOUT] = T_SCENE_TASK_TIMEOUT,
	[T_TASK_INTERVAL] = T_SCENE_TASK_INTERVAL,
}

pTaskMgr.init = function(self)
	self.taskList = new_weak_table()
	self.sceneTaskList = new_weak_table()
	self.taskId = 1
	self.timestamp = getTime()
	self.elapseUnit = 1 / getFrameRate()

	--self.mgrProcess = setInterval(secToFrame(1), function()
	self.mgrProcess = setInterval(30, function()
		self:checkList(self.taskList)
	end)

	self.mgrSceneProcess = setSceneIntervalPersist(1, function()
		local elapse = math.ceil(self.elapseUnit * 1000)
		self.timestamp = self.timestamp + elapse
		self:checkList(self.sceneTaskList)
	end)
end

pTaskMgr.getSceneTimeStamp = function(self)
	return self.timestamp
end

pTaskMgr.genTaskId = function(self)
	self.taskId = self.taskId + 1
	return self.taskId
end

pTaskMgr.addSceneTask = function(self, time, taskType, callback)
	taskType = taskToSceneTaskType[taskType]

	local tasklet = pTasklet:new(time, taskType, callback)
	tasklet.data.lastTime = self.timestamp
	local taskId = self:genTaskId()
	self.sceneTaskList[taskId] = tasklet

	log("info", sf("add scene task: %d, type: %d", taskId, taskType))
	log("info", time, self.timestamp)
	return taskId, tasklet
end

pTaskMgr.addTask = function(self, time, taskType, callback)
	local tasklet = pTasklet:new(time, taskType, callback)
	local taskId = self:genTaskId()
	self.taskList[taskId] = tasklet

	log("info", sf("add task: %d, type: %d", taskId, taskType))
	log("info", time, getTime())
	return taskId, tasklet
end

pTaskMgr.delTask = function(self, taskId)
	if self.taskList[taskId] then
		logv("info", "del task: ", taskId)
		self.taskList[taskId] = nil
	end

	if self.sceneTaskList[taskId] then
		log("info", "del scene task: ", taskId)
		self.sceneTaskList[taskId] = nil
	end
end

pTaskMgr.updateTask = function(self, taskId, time, taskType, callback)
	if self.taskList[taskId] then
		self.taskList[taskId]:update(time, taskType, callback)
	end

	if self.sceneTaskList[taskId] then
		self.taskList[taskId]:update(time, taskType, callback)
	end
end

pTaskMgr.pendTask = function(self, taskId)
	if self.taskList[taskId] then
		logv("info", "pend task: ", taskId)
		self.taskList[taskId]:pend()
	end

	if self.sceneTaskList[taskId] then
		log("info", "pend task: ", taskId)
		self.taskList[taskId]:pend()
	end
end

pTaskMgr.isActiveTask = function(self, taskId)
	local tasklet = self.taskList[taskId]
	if not tasklet then
		tasklet = self.sceneTaskList[taskId]
		if not tasklet then
			return false
		end
	end
	return not tasklet.pendFlg
end

pTaskMgr.resumeTask = function(self, taskId)
	if self.taskList[taskId] then
		logv("info", "resume task: ", taskId)
		self.taskList[taskId]:resume()
	end

	if self.sceneTaskList[taskId] then
		log("info", "resume scene task: ", taskId)
		self.sceneTaskList[taskId]:resume()
	end
end

pTaskMgr.checkList = function(self, taskList)
	--local curTime = getTimeStamp()
	local curTime = getTime()
	for taskId, tasklet in pairs(taskList) do
		local taskType = tasklet.data.taskType
		local time = tasklet.data.interval
		local lastTime = tasklet.data.lastTime
		local pend = tasklet.pendFlg
		if not pend then
			if taskType == T_TASK_TIMEOUT then
				--log("error", time, curTime)
				-- 超时任务
				if time <= curTime then
					local ret = tasklet.data.callback()
					self:delTask(taskId)
				end
			elseif taskType == T_SCENE_TASK_TIMEOUT then
				local _curTime = self.timestamp
				-- 超时任务
				if time <= _curTime then
					local ret = tasklet.data.callback()
					self:delTask(taskId)
				end
			elseif taskType == T_TASK_INTERVAL then
				-- 循环任务
				if lastTime + time <= curTime then
					if not tasklet.data.callback() then
						self:delTask(taskId)
					else
						tasklet.data.lastTime = curTime
					end
				end
			elseif taskType == T_SCENE_TASK_INTERVAL then
				-- 循环任务
				local _curTime = self.timestamp
				if lastTime + time <= _curTime then
					if not tasklet.data.callback(_curTime) then
						self:delTask(taskId)
					else
						tasklet.data.lastTime = _curTime 
					end
				end
			end
		end
	end
end

pTaskMgr.cleanAllTask = function(self)
	for taskId, tasklet in pairs(self.taskList) do
		self:delTask(taskId)
	end

	for taskId, tasklet in pairs(self.sceneTaskList) do
		self:delTask(taskId)
	end
end

----------------------------------------
addTask = function(taskData)
	return pTaskMgr:instance():addTask(taskData.time, taskData.taskType, taskData.callback)
end

delTask = function(taskId)
	pTaskMgr:instance():delTask(taskId)
end

updateTask = function(taskId, taskData)
	return pTaskMgr:instance():updateTask(taskId, taskData.time, taskData.taskType, taskData.callback)
end

cleanAllTask = function()
	pTaskMgr:instance():cleanAllTask()
end

pendTask = function(taskId)
	pTaskMgr:instance():pendTask(taskId)
end

resumeTask = function(taskId)
	pTaskMgr:instance():resumeTask(taskId)
end

isActiveTask = function(taskId)
	return pTaskMgr:instance():isActiveTask(taskId)
end

----------------------------------------
getStrTaskKey = function(key)
	key = key or ""
	local taskIdStr = string.format("%s_id", key)
	local taskletStr = string.format("%slet", key)
	local countDownIdStr = string.format("%s_count_down_id", key)
	local countDownletStr = string.format("%s_count_down_let", key)
	return taskIdStr, taskletStr, countDownIdStr, countDownletStr
end

clearTask = function(tasks, key)
	if not table.isEmpty(tasks or {}) and key and key ~= "" then
		local taskIdStr, taskletStr, countDownIdStr, countDownletStr = getStrTaskKey(key)

		if tasks[ taskIdStr ] then
			delTask(tasks[ taskIdStr ])
			tasks[ taskletStr ] = nil
		end

		if tasks[ countDownIdStr ] then
			delTask(tasks[ countDownIdStr ])
			tasks[ countDownletStr ] = nil
		end
	end
end

startCountDown = function(rest, countDownCb)
	local last = modUtil.getTime()
	local callback = function()
		modUtil.safeCallBack(countDownCb, rest/1000)
		local cur = modUtil.getTime()
		rest = rest - (cur - last)
		last = cur

		if rest < 0 then
			return false
		else
			return true
		end
	end

	return pTaskMgr:instance():addTask(1, T_TASK_INTERVAL, callback)
end

startNormalCountDown = function(key, endTime, countDownCb, timeOutCB)
	local taskIdStr, taskletStr, countDownIdStr, countDownletStr = getStrTaskKey(key)
	local tasks = {}
	
	local curTime = modUtil.getTime()
	if endTime <= 0 then
		modUtil.safeCallBack(timeOutCB)
	else
		tasks[ taskIdStr ], tasks[ taskletStr ] = pTaskMgr:instance():addTask(endTime * 1000 + curTime, T_TASK_TIMEOUT, timeOutCB)
		tasks[ countDownIdStr ], tasks[ countDownletStr ] = startCountDown(endTime * 1000, countDownCb)
	end

	return tasks
end

----------------------------------------
__init__ = function()
	export("T_TASK_TIMEOUT", T_TASK_TIMEOUT)
	export("T_SCENE_TASK_TIMEOUT", T_SCENE_TASK_TIMEOUT)
	export("T_TASK_INTERVAL", T_TASK_INTERVAL)
	export("T_SCENE_TASK_INTERVAL", T_SCENE_TASK_INTERVAL)
end

