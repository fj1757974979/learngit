local modPropMgr = import("common/propmgr.lua")
local modEvent = import("common/event.lua")

pMathProperty = pMathProperty or class(modPropMgr.propmgr)

pMathProperty.calculate = function(self)
	self:full()
end

pMathProperty.init = function(self, data)
	modPropMgr.propmgr.init(self)

	self.eventSource = modEvent.EventSource:new()

	--[[
	-- event
	self.__hpChange = modPropMgr.propmgr.bind(self, ATTR_CUR_HP, function(curHP, oldHP)
		self.eventSource:fireEvent("addHP", curHP - oldHP)
	end)
	]]--

	if data then
		for k, v in pairs(data) do
			self:setProp(k, v)
		end
	end
end

pMathProperty.full = function(self)
	self:setProp(ATTR_CUR_HP, self:getProp(ATTR_HP))
end

pMathProperty.modifyHP = function(self, modVal)
	local cur = self:getProp(ATTR_CUR_HP)
	local max = self:getProp(ATTR_HP)
	local val = cur + modVal
	if val < 0 then
		val = 0
	end
	if val > max then
		val = max
	end

	self:setProp(ATTR_CUR_HP, val)
end

pMathProperty.initProperty = function(self, config)
	for k,v in pairs(config) do
		self:setProp(k, v)
	end

	--self:calculate()
	self:full()
end

__update__ = function()

end

__init__ = function()
end

