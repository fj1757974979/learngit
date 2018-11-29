local modUIUtil = import("ui/common/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modClubMgr = import("logic/club/main.lua")
local modUserData = import("logic/userdata.lua")
local modClubImplProto = import("data/proto/rpc_pb2/club_impl_pb.lua")
local modCreate = import("logic/card_battle/create.lua")

pMenuGaming = pMenuGaming or class(pWindow)

pMenuGaming.init = function(self, groundInfo, clubInfo)
	self:load("data/ui/club_desk_card.lua")
	self:setParent(gWorld:getUIRoot())
	self.groundInfo = groundInfo
	self.clubInfo = clubInfo
	self:initUI()
	self:regEvent()
end

pMenuGaming.initUI = function(self)
	self:setMJText()
end

pMenuGaming.setMJText = function(self)
	local createInfo = self.groundInfo:getRoomInfo()
--	self.wnd_member:setText(sf("%s   ", modUIUtil.getRuleStringByType(createInfo.rule_type)))
	local cost = self.groundInfo:getCostGold()
	local costStr = ""
	if cost > 0 then
		costStr = sf("小费%s金豆,", cost)
	end
	if self.groundInfo:getIsPoker() then
		self.txt_rule:setText(costStr .. modUIUtil.getPokerRuleStr(createInfo))
	else
		self.txt_rule:setText(costStr .. modUIUtil.getRuleStr(createInfo, ","))
	end
	self.txt_bet:setText("底注")
	self.txt_condition:setText("入场")
	self.wnd_bet:setText(createInfo.dibei or 1)
	self.wnd_condition:setText(self.groundInfo:getMinGold())
	if not modCreate.needRateWnd(createInfo) then
		self.txt_bet:show(false)
		self.wnd_bet:show(false)
	end
end

pMenuGaming.setGroundText = function(self, count)
	if not count then return end
	local createInfo = self.groundInfo:getRoomInfo()
	self.wnd_number:setText(sf("共%d人", count))
	if self.groundInfo:getGameType() == modLobbyProto.MAHJONG then
		self.wnd_member:setText(sf("%d人%s", createInfo.max_number_of_users, modUIUtil.getRuleStringByType(createInfo.rule_type), count))
	else
		self.wnd_member:setText(sf("%d人%s", createInfo.max_number_of_users, modUIUtil.getPokerRuleStringByType(createInfo.poker_type), count))
	end
end

pMenuGaming.regEvent = function(self)
	self:addListener("ec_mouse_click", function()
		if self:getIsCreator() then
			self:showCreatorPanel()
		else
			self:clubJoinMatch()
		end
	end)
end

pMenuGaming.getIsCreator = function(self)
	return self.groundInfo:getClubInfo():getIsCreator(self.groundInfo:getClubInfo())
end

pMenuGaming.showCreatorPanel = function(self)
	self.clubInfo:updateGroundInfoByGroundId(self.groundInfo:getGroundId(), function(groundInfo)
		local modCratorPanel = import("ui/club/creator_ground_panel.lua")
		modCratorPanel.pCreatorPanel:instance():open(self.clubInfo, groundInfo)
	end)
end

pMenuGaming.clubJoinMatch = function(self)
	local modBattleMgr = import("logic/battle/main.lua")
	modClubMgr.getCurClub():clubJoinMatch( self.clubInfo:getClubId(), self.groundInfo:getGroundId(), modUserData.getUID(), false, function(success, reply)
		if not success then
			return
		end
		local room = reply.room
		if modBattleMgr.getCurBattle() then
			modBattleMgr.getCurBattle():getBattleUI():show(true)
		else
			local modUIAllFunction = import("ui/common/uiallfunction.lua")
			modUIAllFunction.createInstanceBattleMgr(room.id, room.host, room.port, room.game_type)
		end
	end)
end



