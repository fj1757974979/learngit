local modMajiangGame = import("logic/battle/majianggame.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")

pTianjinGame = pTianjinGame or class(modMajiangGame.pMajiangGame)

pTianjinGame.init = function(self, options)
	modMajiangGame.pMajiangGame.init(self, options)
end

pTianjinGame.isKoupaimode = function(self)
	if not self.roomInfo then return end
	return self.roomInfo.conceal_discarded_cards	
end

pTianjinGame.destroy = function(self)
	modMajiangGame.pMajiangGame.destroy(self)
end

pTianjinGame.hasLaChuaiFlag = function(self, player)
	if not player then return end
	local flags = player:getFlags()
	for _, f in pairs(flags) do
		if self:isLaFlag(f) or self:isChuaiFlag(f) then
			return f
		end
	end
	return false
end

pTianjinGame.isSelectedLaChuaiFlag = function(self, player)
	if not player then return end
	local flags = player:getFlags()
	for _, f in pairs(flags) do
		if self:isLaFlag(f) or self:isChuaiFlag(f) 
			or f == modGameProto.PIAO_A 
			or f == modGameProto.PIAO_C
			then
			return f
		end
	end
	return false
end

pTianjinGame.isLaFlag = function(self, f)
	if not f then return end
	return f == modGameProto.PIAO_B
end

pTianjinGame.isChuaiFlag = function(self, f)
	if not f then return end
	return f == modGameProto.PIAO_D
end

pTianjinGame.getIsShowPhaseWnd = function(self)
	return self:getCurBattle():isPhaseLa() or self:getCurBattle():isPhaseChuai()
end

pTianjinGame.addFlagWork = function(self, flag, player)
	if not flag or not player then return end
	if self:getCurBattle():isPhaseLa() or self:getCurBattle():isPhaseChuai() then
		if flag == modGameProto.PIAO_A or flag == modGameProto.PIAO_C then
			self.battleUI:laChuaiHide(player:getSeat())
		elseif flag == modGameProto.PIAO_B or flag == modGameProto.PIAO_D then
			self.battleUI:setPiaoText(player:getSeat(), flag)
		end
	end
end
