local modMainPanel = import("ui/battle/main.lua")

pTaojiangPanel = pTaojiangPanel or class(modMainPanel.pBattlePanel)

pTaojiangPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
end

pTaojiangPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end

pTaojiangPanel.getPiaoType = function(self)
	return "dama"
end
