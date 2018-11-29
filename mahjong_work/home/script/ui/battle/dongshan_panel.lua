local modMainPanel = import("ui/battle/main.lua")

pDongshanPanel = pDongshanPanel or class(modMainPanel.pBattlePanel)

pDongshanPanel.init = function(self)
	logv("warn","pDongshanPanel.init")
	modMainPanel.pBattlePanel.init(self)	
end

pDongshanPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end

pDongshanPanel.initCardSizes = function(self)
	self.handSizes = {
		[T_SEAT_MINE] = {100, 139},
		[T_SEAT_RIGHT] = {36 * 1.8, 72 * 1.8},
		[T_SEAT_OPP] = {100, 139},
		[T_SEAT_LEFT] = {36 * 1.8, 72 * 1.8},
	}
	self.showSizes = {
		[T_SEAT_MINE] = {100 * 0.90, 139 * 0.90},
		[T_SEAT_RIGHT] = {134 * 0.7, 104 * 0.7},
		[T_SEAT_OPP] = {100 * 0.9, 139 * 0.9},
		[T_SEAT_LEFT] = {134 * 0.7, 104 * 0.7},
	}
	self.DiscardSizes = {
		[T_SEAT_MINE] = {100 * 0.55, 139 * 0.55},
		[T_SEAT_RIGHT] = {134 * 0.43, 104 * 0.43},
		[T_SEAT_OPP] = {100 * 0.5, 139 * 0.5},
		[T_SEAT_LEFT] = {134 * 0.43, 104 * 0.43},
	}
end

pDongshanPanel.hasFlowerCards = function(self)
	return modBattleMgr.getCurBattle():getCurGame():isDongShan()
end

pDongshanPanel.getMaxWidthCount = function(self)
	return 4	
end

pDongshanPanel.getMaxHeightCount = function(self)
	return 3
end

pDongshanPanel.getIsHideAnGang = function(self)
	return true
end
