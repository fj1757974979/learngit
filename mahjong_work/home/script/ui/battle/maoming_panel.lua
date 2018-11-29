local modMainPanel = import("ui/battle/main.lua")

pMaomingPanel = pMaomingPanel or class(modMainPanel.pBattlePanel)

pMaomingPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
end

pMaomingPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end
