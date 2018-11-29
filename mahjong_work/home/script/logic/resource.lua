pResourceMgr = pResourceMgr or class(pSingleton)

pResourceMgr.init = function(self)
	self.resource = {}
	self.bindList = {}
end

pResourceMgr.setResourceAmount = function(self, t, v)
	log("info", "setResourceAmount:", t, v)
	local old = self.resource[t]
	self.resource[t] = v
	self:callBindList(t, old or 0, v)
	if t == T_RES_LEVEL then
		if old and v > old then
			-- 升级
			puppy.sys.onRoleLevelUp(old, v)
			local modGuideMgr = import("logic/guide/mgr.lua")
			modGuideMgr.pGuideMgr:instance():onRoleLevelUp(old, v)
		end
	end
end

pResourceMgr.getResourceAmount = function(self, t)
	return self.resource[t] or 0
end

pResourceMgr.addResourceAmount = function(self, t, v)
	if v <= 0 then
		return
	end
	self:setResourceAmount(t, self:getResourceAmount(t) + v)
end

pResourceMgr.subResourceAmount = function(self, t, v)
	if v <= 0 then
		return
	end
	self:setResourceAmount(t, math.max(0, self:getResourceAmount(t) - v))
end

pResourceMgr.callBindList = function(self, t, prev, cur)
	if self.bindList[t] then
		for func, _ in pairs(self.bindList[t]) do
			func(prev, cur)
		end
	end
end

pResourceMgr.bind = function(self, t, func)
	if not t or not func then
		return 
	end
	self.bindList[t] = self.bindList[t] or new_weak_table()
	self.bindList[t][func] = true
	local v = self:getResourceAmount(t)
	func(v, v)
	return func
end

pResourceMgr.unbind = function(self, t, func)
	if self.bindList[t] then
		self.bindList[t][func] = nil
	end
end

bind = function(t, func)
	return pResourceMgr:instance():bind(t, func)
end

unbind = function(t, func)
	return pResourceMgr:instance():unbind(t, func)
end

hasGold = function(val)
	return pResourceMgr:instance():getResourceAmount(T_RES_GOLD) >= val
end

getEnergyDiff = function(val)
	local energy = pResourceMgr:instance():getResourceAmount(T_RES_ENERGY)
	return val - energy
end
