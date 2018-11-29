local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pLyyouwenPanel = pLyyouwenPanel or class(loginPanel)

pLyyouwenPanel.init = function(self)
	loginPanel.init(self)
end

