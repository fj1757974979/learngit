
local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pQspinghePanel = pQspinghePanel or class(loginPanel)

pQspinghePanel.init = function(self)
	loginPanel.init(self)
end
