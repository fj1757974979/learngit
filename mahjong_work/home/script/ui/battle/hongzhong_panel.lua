local modMainPanel = import("ui/battle/main.lua")

pHongzhongPanel = pHongzhongPanel or class(modMainPanel.pBattlePanel)

pHongzhongPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
end

pHongzhongPanel.getPiaoType = function(self)
	return "piaofen"
end

pHongzhongPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end
