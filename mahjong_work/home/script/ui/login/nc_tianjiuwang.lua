
local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pNctianjiuwangPanel = pNctianjiuwangPanel or class(loginPanel)

pNctianjiuwangPanel.init = function(self)
	loginPanel.init(self)
end
