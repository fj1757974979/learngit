local modMajiangGame = import("logic/battle/majianggame.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
pPingheGame = pPingheGame or class(modMajiangGame.pMajiangGame)

pPingheGame.addFlagWork = function(self, flag, player)
	if not flag or not player then return end
	if self:isJinFlag(flag) then			
		self.battleUI:updateJinFlagWnds(flag,player)
	end	
end

pPingheGame.isJinFlag = function ( self,f )
	if self:isYouJinFlag(f) or self:isShuangYouFlag(f) or self:isSiYouFlag(f) or self:isBaYouFlag(f) or self:isHuFlag(f) or self:isRobAngangFlag(f) then
		return f
	end
	return nil
end

pPingheGame.addClearFlagWork = function (self,flag,player )
	if not flag or not player then return end
	if self:isJinFlag(flag) then
		self.battleUI:hideJinFlagWnds(flag,player)
	end
end

pPingheGame.isYouJinFlag = function ( self, f )
	if f then
		return f == modGameProto.PINGHE_YOUJIN
	end

	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _,f in pairs(flags) do
		if f == modGameProto.PINGHE_YOUJIN then 
			return true
		end
	end
	return false
end

pPingheGame.isShuangYouFlag = function ( self, f )
	if f then
		return f == modGameProto.PINGHE_SHUANGYOU
	end

	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _,f in pairs(flags) do
		if f == modGameProto.PINGHE_SHUANGYOU then 
			return true
		end
	end
	return false
end

pPingheGame.isSiYouFlag = function ( self, f )
	if f then
		return f == modGameProto.PINGHE_SIYOU
	end

	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _,f in pairs(flags) do
		if f == modGameProto.PINGHE_SIYOU then 
			return true
		end
	end
	return false
end

pPingheGame.isBaYouFlag = function ( self, f )
	if f then
		return f == modGameProto.PINGHE_BAYOU
	end

	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _,f in pairs(flags) do
		if f == modGameProto.PINGHE_BAYOU then 
			return true
		end
	end
	return false
end

pPingheGame.isHuFlag = function ( self, f )
	if f then
		return f == modGameProto.PINGHE_HU
	end

	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _,f in pairs(flags) do
		if f == modGameProto.PINGHE_HU then 
			return true
		end
	end
	return false
end

pPingheGame.isRobAngangFlag = function ( self, f )
	if f then
		return f == modGameProto.PINGHE_ROBANGANG
	end

	local player = self:getCurBattle():getMyPlayer()
	local flags = player:getFlags()
	for _,f in pairs(flags) do
		if f == modGameProto.PINGHE_ROBANGANG then 
			return true
		end
	end
	return false
end

pPingheGame.getSelfHasJin = function ( self,p )
	local player = self:getCurBattle():getMyPlayer()
	if p then player = p end 
	local flags = player:getFlags()
	for _,f in pairs(flags) do
		if self:isJinFlag(f) then
			return f
		end
	end
	return
end

pPingheGame.getMagicCard = function(self)
	return {self.magicCardIds[1]}
end
