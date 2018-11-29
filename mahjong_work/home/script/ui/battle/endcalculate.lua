local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modEasing = import("common/easing.lua")
local modUserData = import("logic/userdata.lua")
local modFunctionManager = import("ui/common/uifunctionmanager.lua")
local modUserData = import("logic/userdata.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modEndPlayerInfo = import("ui/battle/endplayerinfo.lua")
local modDisMissList = import("ui/battle/dismisslist.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modEndPlayerWindow = import("ui/battle/endplayerwindow.lua")
local modTrigger = import("logic/trigger/mgr.lua")

local pcToChinese = {
	[1]="一",
	[2]="二",
	[3]="三",
	[4]="四",
}
local hasChannelRes = {
	tj_lexian = true,
	ds_queyue = true,
	test = true,
	jz_laiba = true,
	yy_doudou = true,
	ly_youwen = true,
	nc_tianjiuwang = true,
	za_queyue = true,
	qs_pinghe = true,
}

getChannelRes = function(name)
	local opChannel = modUtil.getOpChannel()
	if hasChannelRes[opChannel] then
		return "ui:channel_res/" .. modUtil.getOpChannel() .. "/" .. name
	else
		local path = "ui:" .. name
		if app:getIOServer():fileExist(path) then
			return path
		else
			return nil
		end
	end
end
pEndCalculate = pEndCalculate or class(pWindow, pSingleton)

pEndCalculate.init = function(self)
	self:load("data/ui/totalcalculate.lua")
	self:setRenderLayer(C_BATTLE_UI_RL)
    self:setParent(gWorld:getUIRoot())
    self:setZ(C_BATTLE_UI_Z )
	self.controls = {}
	self.btn_share:addListener("ec_mouse_click", function()
		if self.btn_share.__wait_exec_flag then
			return
		end
		if self.btn_share.__wait_exec_hdr then
			self.btn_share.__wait_exec_hdr:stop()
		end
		self.btn_share.__wait_exec_flag = true
		modTrigger.regTriggerOnce(EV_AFTER_DRAW, function()
			if self.btn_share.__wait_exec_hdr then
				self.btn_share.__wait_exec_hdr:stop()
				self.btn_share.__wait_exec_hdr = nil
			end
			self.btn_share.__wait_exec_flag = false
			puppy.sys.shareWeChatWithScreenCapture(2)
		end)
		self.btn_share.__wait_exec_hdr = setTimeout(10, function()
			if self.btn_share.__wait_exec_flag then
				puppy.sys.shareWeChatWithScreenCapture(2)
				self.btn_share.__wait_exec_hdr = nil
				self.btn_share.__wait_exec_flag = false
			end
		end)
	end)
	self.btn_back:addListener("ec_mouse_click", function()
		self:close()
	end)
	self.wnd_bg:addListener("ec_mouse_click", function()
		if self.curChosenWnd then
			self.curChosenWnd:showPlayerInfoWnd(false)
			self.curChosenWnd = nil
			return
		end
	end)
	modUIUtil.setClosePos(self.btn_back)
	self:initWindows()
	modUIUtil.adjustSize(self, gGameWidth, gGameHeight)
end

pEndCalculate.initWindows = function(self)
	self.wnd_rcode:setOffsetX(-self.wnd_rcode:getWidth() / 3)
	self.wnd_rcode:setOffsetY(-self.wnd_rcode:getHeight() / 5)
end


pEndCalculate.open = function(self, message, isVideo, playerUids, roomInfo, time, roomId)
	local playerCount = table.getn(message.player_total_statistics)
	local winners = message.dayingjias
	local paoshous = message.zuijiapaoshous
	local playerStatistics = {}
	local index = 1
	local playerIds = {}
	local currentPid = nil
	local allPlayers = nil
	local gameStr = nil
	local ruleStr = nil
	local time = time
	local roomId = roomId
	local ownerUid = nil
	local roomTypeStr = nil
	if not isVideo then
		if not modBattleMgr.getCurBattle() then return end
		currentPid = modBattleMgr.getCurBattle():getMyPlayerId()
		allPlayers = modBattleMgr.getCurBattle():getAllPlayersByPid()
		ruleStr = modBattleMgr.getCurBattle():getBattleUI():getRuleStr()
		gameStr = modBattleMgr.getCurBattle():getBattleUI():getGameName()
		roomId = modBattleMgr.getCurBattle():getBattleUI():getRoomId()
		time = os.date("%Y.%m.%d   %H:%M:%S", os.time())
		ownerUid = modBattleMgr.getCurBattle():getOwnerId()
		roomTypeStr = modBattleMgr.getCurBattle():getBattleUI():getRoomType()
	else
		if not roomInfo then return end
		ruleStr = modUIUtil.getRuleStr(roomInfo)
		gameStr = modUIUtil.getRuleStringByType(roomInfo.rule_type)
		time = os.date("%Y.%m.%d   %H:%M:%S", time)
		ownerUid = roomInfo.owner_user_id
		roomTypeStr = modUIUtil.getRoomTypeStr(roomInfo.room_type)
	end
	-- 设置文字说明
	local pcStr = pcToChinese[playerCount] .. "人"
	local roomStr = sf( "房间号：%06d", roomId)
	self.wnd_game_name:setText(roomStr .. " " .. pcStr .. gameStr .. " " .. roomTypeStr)
	self.wnd_text_3:setText(ruleStr)
	self.wnd_time:setText(time)

	-- 设置rcode
	self.wnd_rcode:setImage(getChannelRes("rcode.png"))

	for pid, s in ipairs(message.player_total_statistics) do
		if not currentPid then
			currentPid = pid - 1
		end
		if pid - 1 == currentPid then
			playerStatistics[0] = s
			playerIds[0] = pid - 1
		else
			playerStatistics[index] = s
			playerIds[index] = pid - 1
			index = index + 1
		end
	end

	local x, y = 0, 0
	local stateCount = table.size(playerStatistics)
	local pidToSeat = nil
	if not isVideo then
		pidToSeat = modBattleMgr.getCurBattle():getSeatMap()
		logv("warn", pidToSeat)
	end
	self.wnd_infos:load(sf("data/ui/endcalculate_%d.lua", stateCount))
	for idx, statistic in pairs(playerStatistics) do
		local userId = nil
		if playerUids then
			userId =  playerUids[playerIds[idx]]
		end
		local wnd = modEndPlayerWindow.pEndPlayer:new(statistic, idx, playerIds[idx], userId, allPlayers, winners, paoshous, isVideo, ownerUid, playerCount, self)
		local pwnd = nil
		if not isVideo then
			pwnd = self.wnd_infos[sf("wnd_%d", pidToSeat[playerIds[idx]])]
		else
			pwnd = self.wnd_infos[sf("wnd_%d", idx)]
		end
		wnd:setParent(pwnd)

		table.insert(self.controls, wnd)
	end
end


pEndCalculate.onChoosePlayerWindow = function(self, wnd)
	if self.curChosenWnd then
		self.curChosenWnd:showPlayerInfoWnd(false)
		if self.curChosenWnd == wnd then
			self.curChosenWnd = nil
			return
		end
	end
	self.curChosenWnd = wnd
	self.curChosenWnd:showPlayerInfoWnd(true)
end



pEndCalculate.close = function(self)
	if self.controls then
		for _, wnd in pairs(self.controls) do
			wnd:setParent(nil)
		end
	end
	if self.controls then
		for _, wnd in pairs(self.controls) do
			wnd:destroy()
		end
		self.controls = nil
	end
	self.showInfoWnd = nil
	modFunctionManager.pUIFunctionManager:instance():stopFunction()
	pEndCalculate:cleanInstance()
end

