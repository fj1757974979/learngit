
pMenuWndBase = pMenuWndBase or class(pWindow)

pMenuWndBase.init = function(self, executor)
	self.executor = executor
	self:load(self:getTemplate())
	self:setParent(self:getMenuParent())
	self:enableEventSelf(false)
	self:initUI()
	self:regEvent()
	self:adjustUI()
end

pMenuWndBase.getMenuParent = function(self)
	return self.executor:getMenuParent()
end

pMenuWndBase.initUI = function(self)
end

pMenuWndBase.adjustUI = function(self)
end

pMenuWndBase.regEvent = function(self)
end

pMenuWndBase.getExecutor = function(self)
	return self.executor
end

pMenuWndBase.getTemplate = function(self)
	log("error", "[pMenuWndBase.getTemplate] not implemented!", debug.traceback())
end
