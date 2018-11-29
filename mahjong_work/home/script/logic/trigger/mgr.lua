pTrigger = pTrigger or class()

pTrigger.init = function(self, id, cntLimit, callback)
	self.id = id
	self.cnt = 0
	self.cntLimit = cntLimit
	self.callback = callback
end

pTrigger.getId = function(self)
	return self.id
end

pTrigger.isOverDue = function(self)
	if self.cntLimit < 0 then
		return false
	else
		return self.cnt >= self.cntLimit
	end
end

pTrigger.active = function(self)
	if self.callback then
		self.callback()
	end
	self.cnt = self.cnt + 1
end

------------------------------------------------------------

pTriggerMgr = pTriggerMgr or class(pSingleton)

pTriggerMgr.init = function(self)
	self.triggers = {}
	self.id = 0
end

pTriggerMgr.registerTrigger = function(self, ev, cnt, callback) 
	local id = self.id + 1
	local trigger = pTrigger:new(id, cnt, callback)
	self.id = id
	if not self.triggers[ev] then
		self.triggers[ev] = {}
	end
	self.triggers[ev][trigger:getId()] = trigger
end

pTriggerMgr.trigger = function(self, ev)
	local triggers = self.triggers[ev]
	if not triggers then
		return
	end
	local overdues = {}
	for id, trigger in pairs(triggers) do
		trigger:active()
		if trigger:isOverDue() then
			table.insert(overdues, trigger:getId())
		end
	end
	for _, id in ipairs(overdues) do
		triggers[id] = nil
	end
	if table.size(triggers) <= 0 then
		self.triggers[ev] = nil
	end
end

------------------------------------------------------------

regTriggerOnce = function(ev, callback)
	pTriggerMgr:instance():registerTrigger(ev, 1, callback)
end

regTriggerWithCount = function(ev, cnt, callback)
	pTriggerMgr:instance():registerTrigger(ev, cnt, callback)
end

regTrigger = function(ev, callback)
	pTriggerMgr:instance():registerTrigger(ev, -1, callback)
end

trigger = function(ev)
	pTriggerMgr:instance():trigger(ev)
end
