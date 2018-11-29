
local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pZaqueyuePanel = pZaqueyuePanel or class(loginPanel)

pZaqueyuePanel.init = function(self)
	loginPanel.init(self)
end
