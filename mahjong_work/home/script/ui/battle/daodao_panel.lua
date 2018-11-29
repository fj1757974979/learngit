local modMainPanel = import("ui/battle/main.lua")

pDaodaoPanel = pDaodaoPanel or class(modMainPanel.pBattlePanel)

pDaodaoPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
end

pDaodaoPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end

