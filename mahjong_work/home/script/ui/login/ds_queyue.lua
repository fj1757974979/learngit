
local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pDsqueyuePanel = pDsqueyuePanel or class(loginPanel)

pDsqueyuePanel.init = function(self)
	loginPanel.init(self)
end
