local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pOpenewPanel = pOpenewPanel or class(loginPanel)

pOpenewPanel.init = function(self)
	loginPanel.init(self)
end
