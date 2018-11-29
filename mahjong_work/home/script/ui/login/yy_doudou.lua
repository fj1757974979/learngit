
local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pYydoudouPanel = pYydoudouPanel or class(loginPanel)

pYydoudouPanel.init = function(self)
	loginPanel.init(self)
end
