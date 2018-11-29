local modMainPanel = import("ui/battle/main.lua")

pZhaoanPanel = pZhaoanPanel or class(modMainPanel.pBattlePanel)

pZhaoanPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
end

pZhaoanPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end

pZhaoanPanel.getIsHideAnGang = function(self)
	return true
end

pZhaoanPanel.getPiaoType = function(self)
	return "chatai"
end
