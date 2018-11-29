local modUIUtil = import("ui/common/util.lua")

pAuthSuccess = pAuthSuccess or class(pWindow, pSingleton)

pAuthSuccess.init = function(self)
	self:load("data/ui/authsuccess.lua")
	self:setParent(gWorld:getUIRoot())
	modUIUtil.makeModelWindow(self, false, true)
end

pAuthSuccess.close = function(self)
	pAuthSuccess:cleanInstance()
end
