
local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pTestPanel = pTestPanel or class(loginPanel)

pTestPanel.init = function(self)
	loginPanel.init(self)
end

