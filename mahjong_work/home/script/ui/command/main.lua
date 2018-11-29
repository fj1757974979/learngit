local modUserData = import("logic/userdata.lua")
local modUtil = import("util/util.lua")
local modCommands = import("logic/command/main.lua")

pCommandPanel = pCommandPanel or class(pWindow, pSingleton)

pCommandPanel.init = function(self)
	self:load("data/ui/command.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self, false, true)

	self.cmd = modCommands.pCommands:instance()
	self.originCommandString = self.input:getText()
	self:initUI()
	self:regEvent()
	self:setZ(-100001)
end

pCommandPanel.initUI = function(self)
end

pCommandPanel.regEvent = function(self)
	self.input:addListener("ec_mouse_click", function()
		self.input:setText("")
	end)

	self.confirm:addListener("ec_mouse_click", function()
		self:onDo()
	end)
end

pCommandPanel.onDo = function(self)
	local command = self.input:getText()
	if not command then
		return
	end
	if command == self.originCommandString then
		return
	end

	self.cmd:commandsEntry(command)
	self.input:setText("")
end

pCommandPanel.open = function(self)
	self:show(true)
end

pCommandPanel.close = function(self)
	pCommandPanel:cleanInstance()
end


