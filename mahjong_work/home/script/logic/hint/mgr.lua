--[[
--	红点管理模块
--	产生可能引起红点的一方设置红点检测的标记
--	需要展示红点的一方来此查询对应的标记
--	并检测之
--]]

local modEvent = import("common/event.lua")
local modHintSaveMgr = import("logic/hint/save.lua")

pHintMgr = pHintMgr or class(pSingleton)

pHintMgr.init = function(self)
	self.listenerList = self.listenerList or {}
	setmetatable(self.listenerList, {__mode = "v"})
	self.callbackList = self.callbackList or {}
	self.eventList = self.eventList or {}
	self.id = 0
	self.evId = 0
end

pHintMgr.fireHint = function(self, hintName, noSave)
	--log("info", "[pHintMgr.fireHint] ", hintName)
	self.eventList[hintName] = true
	--logv("info", self.eventList)
	self:executeHint(hintName, true)
	for name, allIds in pairs(self.callbackList) do
		if name ~= hintName then
			if self:isPrefix(name, hintName) then
				for id, _ in pairs(allIds) do
					local callback = self.listenerList[id]
					if callback then
						callback(name, true)
					end
				end
			end
		end
	end
	if not noSave then
		modHintSaveMgr.pHintSaveMgr:instance():addHint(hintName)
	end
end

pHintMgr.withDrawHint = function(self, hintName)
	--log("info", "withdraw hint", hintName)
	self.eventList[hintName] = nil
	self:executeHint(hintName, false)
	local allNames = table.keys(self.callbackList)
	--logv("info", allNames)
	for _, name in ipairs(allNames) do
		--if self.eventList[name] and self:isPrefix(name, hintName) then
		if self:isPrefix(name, hintName, 1) then
			-- 如果name是hintName的前缀，则检查name是否还剩余第一级子提示
			-- 若没有则撤销该提示
			for _name, _ in pairs(self.eventList) do
				if self:isPrefix(name, _name) then
					--log("error", name, _name)
					modEvent.fireEvent("REDO_PREFIX_HINT", name)
					return
				end
			end
			self:withDrawHint(name)
			--log("info", "parent: ", "withdraw hint", name)
		end
	end
	modHintSaveMgr.pHintSaveMgr:instance():delHint(hintName)
end

pHintMgr.hasHint = function(self, hintName)
	for _name, _ in pairs(self.eventList) do
		if self:isRelatedWith(_name, hintName) then
			return true
		end
	end
	return false
end

-- src是否是dst的前缀
pHintMgr.isPrefix = function(self, src, dst, depth)
	if src == dst then
		return false
	end
	if not depth then
		return string.find(dst, src) == 1
	else
		local sz = string.len(dst)
		return string.sub(dst, 1, sz - depth) == src
	end
end

pHintMgr.isRelatedWith = function(self, src, dst)
	--log("error", src, dst)
	local ret = (src == dst or string.find(dst, src) == 1)
	--log("error", ret)
	return ret
end

-- 是否有子提示
pHintMgr.hasBePrefixed = function(self, hintName)
	for name, _ in pairs(self.eventList) do
		if self:isPrefix(hintName, name) then
			return true
		end
	end
	return false
end

-- 是否有父提示
pHintMgr.hasPrefix = function(self, hintName)
	for name, _ in pairs(self.eventList) do
		if self:isPrefix(name, hintName) then
			return true
		end
	end
	return false
end

pHintMgr.updateHints = function(self, hintNames, callback)
	if not callback then
		--log("error", "[pHintMgr.updateHints] no callback given")
		return
	end
	for _, hintName in ipairs(hintNames) do
		for name, _ in pairs(self.eventList) do
			if name == hintName or self:isPrefix(hintName, name) then
				if not callback(hintName, true) then
					return
				end
				--self:executeHint(hintName, true)
			end
		end
	end
end

pHintMgr.executeHint = function(self, hintName, flag)
	--log("info", "[pHintMgr.executeHint]", hintName, flag)
	--logv("info", self.callbackList)
	--logv("info", self.listenerList)
	local ids = self.callbackList[hintName] or {}
	for id, _ in pairs(ids) do
		local callback = self.listenerList[id]
		--log("info", callback)
		if callback then
			callback(hintName, flag)
		end
	end
	--[[
	for name, allIds in pairs(self.callbackList) do
		if name == hintName or self:isPrefix(name, hintName) then
			for id, _ in pairs(allIds) do
				log("info", id)
				local callback = self.listenerList[id]
				logv("info", callback)
				if callback then
					callback(name, flag)
				end
			end
		end
	end
	]]--
end

pHintMgr.handleHints = function(self, hintNames, callback)
	--logv("info", "[pHintMgr.handleHints]:",  hintNames)
	--logv("info", "[pHintMgr.handleHints] has event:", self.eventList)
	self.id = self.id + 1
	self.listenerList[self.id] = callback
	for _, hintName in ipairs(hintNames) do
		self.callbackList[hintName] = self.callbackList[hintName] or {}
		self.callbackList[hintName][self.id] = true
		if self:hasBePrefixed(hintName) or 
			self.eventList[hintName] then
			-- 若有子提示或提示
			if callback then
				--log("info", "callback for ", hintName)
				callback(hintName, true)
			end
		end
	end
	return callback
end

pHintMgr.unhandleHints = function(self, func)
	local id = nil
	for _id, callback in pairs(self.listenerList) do
		if func == callback then
			id = _id
			break
		end
	end
	if not id then
		return 
	end
	self.listenerList[id] = nil
	for hintName, cbList in pairs(self.callbackList) do
		cbList[id] = nil
	end
end

initAllHints = function(self)
end
