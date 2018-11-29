local modMainPanel = import("ui/battle/main.lua")

pJiningPanel = pJiningPanel or class(modMainPanel.pBattlePanel)

pJiningPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
end

pJiningPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end

pJiningPanel.getIsCircle = function(self)
	return true
end

pJiningPanel.changeRuleText = function(self, roomInfo, rs)
	rs["number_of_game_times"] = {
		[1] = "1圈",
		[4] = "4圈",
		[8] = "8圈",
		[12] = "12圈",
	}
end
