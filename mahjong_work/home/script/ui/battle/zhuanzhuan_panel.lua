local modMainPanel = import("ui/battle/main.lua")

pZhuanzhuanPanel = pZhuanzhuanPanel or class(modMainPanel.pBattlePanel)

pZhuanzhuanPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
end

pZhuanzhuanPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end
