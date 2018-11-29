local modMainPanel = import("ui/battle/main.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")

pTianjinPanel = pTianjinPanel or class(modMainPanel.pBattlePanel)

pTianjinPanel.init = function(self)
	modMainPanel.pBattlePanel.init(self)	
end

pTianjinPanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end

pTianjinPanel.chuaiPhaseHideLaSelect = function(self)
	for i = 0, 3 do
		local wnd = self[sf("wnd_piao_%d", i)]
		if wnd and self:isChuaiPhaseHideLaSelect(i) then
			wnd:show(false)
		end
	end
end

pTianjinPanel.isChuaiPhaseHideLaSelect = function(self, seatId)
	if not seatId then return end
	if not modBattleMgr.getCurBattle():getCurGame():isTianJinMJ() then return end
	if not modBattleMgr.getCurBattle():isPhaseChuai() then return end
	local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
	if not player then return end
	local flags = player:getFlags()
	for _, flag in pairs(flags) do
		if flag == modGameProto.PIAO_A or flag == modGameProto.PIAO_C then
			return true
		end
	end
	return false
end

pTianjinPanel.laChuaiHide = function(self, seatId, isShow)
	local show = false
	if isShow then show = isShow end
	local wnd = self[sf("wnd_piao_%d", seatId)]
	if wnd then
		wnd:show(show)
	end
end

pTianjinPanel.updateLaChuaiFlagWnds = function(self)
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	if not players then return end
	for _, player in pairs(players) do
		local wnd = self[sf("wnd_piao_%d", player:getSeat())]
		if not wnd then break end
		local f = modBattleMgr.getCurBattle():getCurGame():hasLaChuaiFlag(player)
		if f then
			wnd:show(true)
		end
	end

end

pTianjinPanel.initLaChuaiWndText = function(self)
	local hostId = modBattleMgr.getCurBattle():getCurGame():getBankerId()
	local hostSeat = modBattleMgr.getCurBattle():getSeatMap()[hostId]
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		if modBattleMgr.getCurBattle():isPhaseLa() then
			if i ~= hostSeat then
				local fv = modBattleMgr.getCurBattle():getCurGame():isSelectedLaChuaiFlag(modBattleMgr.getCurBattle():getAllPlayers()[i])
				if not fv then
					fv = "la"
				end
				self:setPiaoText(i,fv)
			else
				local wnd = self[sf("wnd_piao_%d", i)]
				if wnd then 
					wnd:setColor(0) 
				end
			end
		elseif modBattleMgr.getCurBattle():isPhaseChuai() then
			self:updateLaChuaiFlagWnds()
			if i == hostSeat then
				self:setPiaoText(i, "chuai")
			end
		end
	end
end

pTianjinPanel.getIsCircle = function(self)
	return true
end

pTianjinPanel.changeRuleText = function(self, roomInfo, rs)
	rs["number_of_game_times"] = {
		[1] = "1圈",
		[4] = "4圈",
		[8] = "8圈",
		[12] = "12圈",
	}
end

pTianjinPanel.getPiaoType = function(self)
	if modBattleMgr.getCurBattle():isPhaseLa() then
		return "la"
	elseif modBattleMgr.getCurBattle():isPhaseChuai() then
		return "chuai"
	end
end

pTianjinPanel.setPhaseInitPiaoWnds = function(self)
	if modBattleMgr.getCurBattle():isPhaseLa() or modBattleMgr.getCurBattle():isPhaseChuai() then
		self:initLaChuaiWndText()
	elseif modBattleMgr.getCurBattle():isNormalDiscardPhase()then
		self:updateLaChuaiFlagWnds()
	end
	modMainPanel.pBattlePanel.normalDiscardPhase(self)
end

pTianjinPanel.askFlagShowPiaoWnds = function(self, flags, message)
	if not flags or not message then return end
	modMainPanel.pBattlePanel.askFlagShowPiaoWnds(self, flags, message)
	-- 天津麻将踹阶段隐藏选拉中
	self:chuaiPhaseHideLaSelect()
end
