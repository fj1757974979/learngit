
local modLoginPanel = import("ui/login/login_main.lua")

local loginPanel = modLoginPanel.pLoginMainPanel

pTjlexianPanel = pTjlexianPanel or class(loginPanel)

pTjlexianPanel.init = function(self)
	loginPanel.init(self)
end

