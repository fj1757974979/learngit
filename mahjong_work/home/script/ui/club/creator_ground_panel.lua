local modClubMgr = import("logic/club/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modWndList = import("ui/common/list.lua")
local modUIUtil = import("ui/common/util.lua")
local modUserData = import("logic/userdata.lua")
local modEvent = import("common/event.lua")
local modChannelMgr = import("logic/channels/main.lua")
local modUtil = import("util/util.lua")

pCreatorPanel = pCreatorPanel or class(pWindow, pSingleton)

pCreatorPanel.init = function(self)
	self:load("data/ui/club_enter_info.lua")
	self:setParent(gWorld:getUIRoot())
	self:regEvent()
	self.contorls = {}
	modUIUtil.makeModelWindow(self, false, true)
end

pCreatorPanel.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)

	self.btn_ground_close:addListener("ec_mouse_click", function()
		self:destroyGround()	
	end)

	self.btn_join:addListener("ec_mouse_click", function() 
		self:clubJoinMatch()	
	end)
	
end

pCreatorPanel.clubJoinMatch = function(self)
	local modBattleMgr = import("logic/battle/main.lua")
	modClubMgr.getCurClub():clubJoinMatch( self.clubInfo:getClubId(), self.groundInfo:getGroundId(), modUserData.getUID(), false, function(success, reply)
		if not success then return end
		local room = reply.room
		if modBattleMgr.getCurBattle() then
			modBattleMgr.getCurBattle():getBattleUI():show(true)
		else
			local modUIAllFunction = import("ui/common/uiallfunction.lua")
			modUIAllFunction.createInstanceBattleMgr(room.id, room.host, room.port, self.groundInfo:getGameTypeToMacros())
			self:close()
		end
	end)
end

pCreatorPanel.getGroundPlayers = function(self)
	modClubMgr.getCurClub():getGroundPlayers(self.clubInfo:getClubId(), self.groundInfo:getGroundId(), function(reply)
		local uids = reply.player_user_ids
		self.groundInfo:getPlayerInfos(function(playerInfos) 
			local props = playerInfos 
			local uidToNames = {}
			for _, prop in pairs(props) do
				uidToNames[prop.user_id] = prop.nickname
			end
			self.clubInfo:getMemberInfos(function(memberInfos)
				self:showPlayers(uidToNames, memberInfos)
			end)
		end)
	end)
end

pCreatorPanel.showPlayers = function(self, uidToNames, memberInfos)
	if table.size(uidToNames) <= 0 then
		self.wnd_list:setText("此牌局目前没有玩家")
		return
	else
		self.wnd_list:setText("")
	end
	-- 先清除
	self:refreshClear()
	if not uidToNames or table.size(uidToNames) <= 0 then return end
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	local y = 5
	for uid, name in pairs(uidToNames) do
		local gold = memberInfos[uid]:getGold()
		local wnd = self:newPlayerInfoWnd(name, uid, gold, y)
		y = y + 80
	end
	self.dragWnd:setSize(self.wnd_list:getWidth(),y + 100)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self.wnd_list)
end

pCreatorPanel.newPlayerInfoWnd = function(self, name, uid, gold, y)
	if not name or not uid or  not y then return end
	local wnd = pWindow:new()
	wnd:load("data/ui/club_enter_info_card.lua")
	wnd:setParent(self.dragWnd)
	wnd.txt_name:setText(name)
	wnd.txt_id:setText(uid)
	wnd:setPosition(0, y)
	wnd.txt_coin:setText(gold or "")
	table.insert(self.contorls, wnd)
	return wnd
end

pCreatorPanel.findGoldByUid = function(self, uid)
	if not uid or not self.memberInfos then return end
	for _, info in ipairs(self.memberInfos) do
		if uid == info.user_id then
			return info.gold_coin_count
		end
	end
	return nil
end

pCreatorPanel.refreshGrounds = function(self)
	local modMainDesk = import("ui/club/main_desk.lua")
	if modMainDesk.pMainDesk:getInstance() then
		modMainDesk.pMainDesk:instance():refreshGrounds()
	end
end

pCreatorPanel.destroyGround = function(self)
	modClubMgr.getCurClub():destroyGround(self.clubInfo.id, self.groundInfo.id, function(reply)
		infoMessage("关闭牌局成功")
		self:refreshGrounds()
		self:close()
	end)
end

pCreatorPanel.open = function(self, clubInfo, groundInfo)
	self.clubInfo = clubInfo
	self.groundInfo = groundInfo
	self.createInfo = self.groundInfo:getRoomInfo()
	self:initUI()
	self:getGroundPlayers()
end


pCreatorPanel.initUI = function(self)
	self.wnd_time:setText("创建于：" .. os.date("%m-%d %H:%M", self.groundInfo:getDate()))
	self.txt_cost:setText("总消耗：")
	self.wnd_diamond:setText(self.groundInfo:getTotalCost())
	self.txt_cost2:setText("剩    余：")
	self.wnd_diamond2:setText(modUserData.getRoomCardCount())
	local channel = modUtil.getOpChannel()
	if channel == "nc_tianjiuwang" then
		self.txt_tips1:setText("*每场对局消耗管理员6个房卡")
		if self.groundInfo:getTotalCost() > 0 then
			self.txt_tips3:setText(sf("已对局%d场", self.groundInfo:getTotalCost() / 6))
		else
			self.txt_tips3:setText("暂未开局")
		end
		self.room_card1:setImage("ui:channel_res/nc_tianjiuwang/main_room_card.png")
		self.room_card2:setImage("ui:channel_res/nc_tianjiuwang/main_room_card.png")
		self.room_card1:setToImgHW()
		self.room_card1:setScale(0.8,0.8)
		self.room_card2:setToImgHW()
		self.room_card2:setScale(0.8,0.8)
	else
		self.txt_tips1:setText("*每场对局消耗管理员4个钻石")
		if self.groundInfo:getTotalCost() > 0 then
			self.txt_tips3:setText(sf("已对局%d场", self.groundInfo:getTotalCost() / 2))
		else
			self.txt_tips3:setText("暂未开局")
		end
	end
	if modUserData.getRoomCardCount() - self.groundInfo:getTotalCost() <= 50 then
		self.txt_tips2:setText("*即将消耗完，记得及时补充哦！")
		self.wnd_diamond2:getTextControl():setColor(0xFFFF4500)
	else
		self.txt_tips2:setText("")
	end
	self:setMJText()
end

pCreatorPanel.setMJText = function(self)
	if not self.createInfo then return end
	if self.groundInfo:getGameType() == modLobbyProto.MAHJONG then
		self.wnd_name:setText(sf("%d人%s", self.createInfo.max_number_of_users, modUIUtil.getRuleStringByType(self.createInfo.rule_type), count))
	else
		self.wnd_name:setText(sf("%d人%s", self.createInfo.max_number_of_users, modUIUtil.getPokerRuleStringByType(self.createInfo.poker_type), count))
	end
	if self.groundInfo:getIsPoker() then
		self.wnd_rule:setText(modUIUtil.getPokerRuleStr(self.createInfo))
	else
		self.wnd_rule:setText(modUIUtil.getRuleStr(self.createInfo, ","))
	end

end

pCreatorPanel.close = function(self)
	self:refreshClear()
	pCreatorPanel:cleanInstance()
end

pCreatorPanel.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(100, 100)
	pWnd:setParent(self.wnd_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pCreatorPanel.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pCreatorPanel.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end

pCreatorPanel.clearInfoControls = function(self)
	if not self.contorls then return end
	for _, wnd in pairs(self.contorls) do
		wnd:setParent(nil)
	end
	self.contorls = {}
end

pCreatorPanel.refreshClear = function(self)
	self:clearInfoControls()
	self:clearDragWnd()
	self:clearWindowList()
end
