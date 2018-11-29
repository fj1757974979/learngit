local modMainCreate = import("ui/menu/create.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modPokerBattleMgr = import("logic/card_battle/main.lua")
local modUIUtil = import("ui/common/util.lua")

local deskSize = {363, 249}

getDeskSize = function()
	return deskSize[1], deskSize[2]
end

----------------------------------------------------------

pDeskCreateWnd = pDeskCreateWnd or class(pWindow)

pDeskCreateWnd.init = function(self, host)
	self:load("data/ui/group_desk_card_new.lua")
	self.host = host
	self:initUI()
	self:regEvent()
end

pDeskCreateWnd.initUI = function(self)
	self.txt_new:setText(TEXT("新建牌局"))
end

pDeskCreateWnd.regEvent = function(self)
	self.btn_desk:addListener("ec_mouse_click", function()
		if modMainCreate.pMainCreate:getInstance() then
			modMainCreate.pMainCreate:instance():show(true)
		else
			modMainCreate.pMainCreate:instance():open()
		end
		modMainCreate.pMainCreate:instance():setGrpId(self.host:getGroup():getGrpId())
	end)
end

----------------------------------------------------------

pDeskWnd = pDeskWnd or class(pWindow)

pDeskWnd.init = function(self, desk, host)
	self:load("data/ui/group_desk_card.lua")
	self.desk = desk
	self.host = host
	self:initUI()
	self:regEvent()
end

pDeskWnd.initUI = function(self)
	local gameType = self.desk:getGameType()
	local creationInfo = self.desk:getCreateParam(gameType)
	local maxUsers = creationInfo.max_number_of_users
	self.desk:bind("gameCount", function(gameCount)
		if gameCount == 0 then
			self.title:setText(sf(TEXT("%d人房【未开始】"), maxUsers))
		else
			self.title:setText(sf(TEXT("%d人房【第%d局】"), maxUsers, gameCount))
		end
	end)
	local rule = ""
	if gameType == T_MAHJONG_ROOM then
		rule = modUIUtil.getRuleStr(creationInfo, ",")
	else
		rule = modUIUtil.getPokerRuleStr(creationInfo)
	end
	local roomType = creationInfo.room_type
	local typeStr = ""
	if roomType == 0 then
		typeStr = TEXT("普通房间")
	elseif roomType == 1 then
		typeStr = TEXT("代开房间")
	elseif roomType == 2 then
		typeStr = TEXT("AA房间")
	end
	self.txt_rule:setText(typeStr .. " " .. rule)
end

pDeskWnd.regEvent = function(self)
	self.__desk_hdr = self.desk:bind("players", function(players)
		local all = table.values(players)
		table.sort(all, function(p1, p2)
			return p1:getId() < p2:getId()
		end)
		for i = 1, 4 do
			local nameWnd = self[sf("wnd_name_%d", i)]
			nameWnd:setText("")
			local imageWnd = self[sf("wnd_image_%d", i)]
			imageWnd:setColor(0)
		end
		for _, player in ipairs(all) do
			idx = player:getId() + 1
			player.__idx = idx
			player:bind("name", function(name)
				local nameWnd = self[sf("wnd_name_%d", player.__idx)]
				nameWnd:setText(name)
			end)
			player:bind("avatarurl", function(url)
				if url == "" then
					url = "ui:image_default_female.png"
				end
				local imageWnd = self[sf("wnd_image_%d", player.__idx)]
				imageWnd:setColor(0xffffffff)
				imageWnd:setImage(url)
			end)
		end
	end)

	self.btn_desk:addListener("ec_mouse_click", function()
		local roomId = self.desk:getRoomId()
		modBattleRpc.lookupRoom(roomId, function(success, reason, roomId, roomHost, roomPort, gameType)
			if success then
				if gameType == T_MAHJONG_ROOM then
					modBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort, function(success)
					end)
				elseif gameType == T_POKER_ROOM then
					modPokerBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort, function(success)
					end)
				end
			else
				infoMessage(reason)
			end
		end)
	end)
end

pDeskWnd.destroy = function(self)
end
