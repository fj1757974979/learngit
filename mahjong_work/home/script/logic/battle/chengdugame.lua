local modYunyangGame = import("logic/battle/yunyanggame.lua")

pChengduGame = pChengduGame or class(modYunyangGame.pYunyangGame)

pChengduGame.init = function(self, options)
	modYunyangGame.pYunyangGame.init(self, options)
	self.changeSanZhangIds = {}
end

pChengduGame.getIsHuansanzhang = function(self)
	if not self.roomInfo then return end
	if self.roomInfo.chengdu_extras then
		return self.roomInfo.chengdu_extras.huansanzhang and self:getCurBattle():isPhaseHuanSanZhang()
	end
	return false
end

pChengduGame.getIsDingQue = function(self)
	if not self.roomInfo then return end
	-- 血战到底
	if self.roomInfo.chengdu_extras then
		return self.roomInfo.chengdu_extras.dingque and self:getCurBattle():isPhaseDingQue()
	end
	return false
end
