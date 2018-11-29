local modVoice = import("ui/battle/voice.lua")
local modVideoPlayer = import("ui/menu/videoplayer.lua")
local modPlayerInfo = import("logic/menu/player_info_mgr.lua")
local modCommonCue = import("ui/common/common_cue.lua")
local modEvent = import("common/event.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modEasing = import("common/easing.lua")
local modCombWnd = import("ui/battle/comb.lua")
local modAnGangWnd = import("ui/battle/qiangangang.lua")
local modCalcPanel = import("ui/battle/calculate.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modMainZhuaNiao = import("ui/battle/zhuaniao.lua")
local modFunctionManager = import("ui/common/uifunctionmanager.lua")
local modEndCalculate = import("ui/battle/endcalculate.lua")
local modUserData = import("logic/userdata.lua")
local modDisMissList = import("ui/battle/dismisslist.lua")
local modSound = import("logic/sound/main.lua")
local modSet = import("ui/menu/set.lua")
local modFlagMenu = import("ui/battle/flags.lua")
local modCreate = import("ui/menu/create.lua")
local modVideoMain = import("ui/menu/video.lua")
local modVideoInfo = import("ui/menu/video_info.lua")
local modSessionMgr = import("net/mgr.lua")
local modClipBoardMgr = import("logic/clipboard/mgr.lua")

local modUtil = import("util/util.lua")
local modUserPropCache = import("logic/userpropcache.lua")

local modChatMain = import("logic/chat/mgr.lua")
local modChatUtil = import("logic/chat/util.lua")
local modSuggMenu = import("ui/battle/suggestionmenu.lua")
local modChannelMgr = import("logic/channels/main.lua")
local modStopAutoPlayingWnd = import("ui/battle/stop_auto_playing.lua")
local modMingGuo = import("ui/battle/mingguo.lua")

local GAP_RATE = 1/3
local VERTICAL_DIFF_RATE = 0.4
--local HAND_CNT = 13
local MAX_DISCARD_CNT_PER_LINE = 10
local tingColor = 0xFFC4C4C4

pBattlePanel = pBattlePanel or class(pWindow)

pBattlePanel.init = function(self)
	self:load("data/ui/battle.lua")
	self:setParent(gWorld:getUIRoot())
	self.isResetState = true
	-- 未开始战斗头像位置
	self.iconPos = {}
	-- 初始化UI
	self:initUI()
	-- 解散玩家信息
	self.disRoomInfoList = {}
	-- 时间
	self.wnd_time:show(false)
	-- 当前放大的牌
	self.controls = {}
	-- 座位对应东南西北
	self.seatToDir = {}
	-- showcard 特殊牌
	self.showCardControls = {}
	-- 地牌控件集合
	self.diCardControls = {}
	-- 多张牌展示
	self.gangCardControls = {}
	-- 漏胡控件
	self.louControls = {}
	-- 建议控件
	self.suggControls = {}
	-- 胡牌窗口
	self.huCardWnds = {}
	-- 颜色不变窗口
	self.isNotChangeColorWnds = {}
	-- 当前地牌
	self.currentDiCardWnd = nil
	-- 注册事件
	self:regEvent()
	-- {
	--	seatId = {
	--	 T_CARD_HAND = {
	--	  wnds = {wnd1, wnd2, ...},
	--	 }
	--	 T_CARD_SHOW = {
	--	  wnds = {},
	--	 }
	--	 T_CARD_DISCARD = {
	--	  wnds = {},
	--	 }
	--	 dealCard = wnd,
	--	}
	-- }
	-- 所有牌的信息
	self.cardInfo = {}
	-- 同时最大选择牌数
--	self.maxChooseCardCount = 3
	-- 是否显示桌子水印
	self:showTableLogo()
	-- 弃牌浮标
	self.discardMarkId = nil
	-- 自己座位
	self.mySeatId = modBattleMgr.getCurBattle():getMySeatId()
	-- 测试按钮 换
	self.btn_change:show(false)
	self.btn_change:setZ(C_BATTLE_UI_Z)
	self.btn_change:setParent(self.wnd_hand_0)
	-- 换和明
	self.btn_change_san:show(false)
	-- 换三张本局换牌信息
	self.wnd_huan_rule:show(false)
	-- 过
	self.btn_guo:show(false)
	-- 刷新信号
	self:refreshSign()
	--
	self.curChooseWnds = {}
	self.btn_test_time_out:show(false)
	if modUtil.isDebugVersion() then
		self.btn_test_time_out:show(true)
	end
	-- 托管
	self.autoPlayingWnds = {}
	-- 隐藏俱乐部界面
	modEvent.fireEvent(EV_BATTLE_BEGIN)
end

pBattlePanel.refreshSign = function(self)
	local modUIUtil = import("ui/common/util.lua")
	modUIUtil.timeOutDo(modUtil.s2f(5), nil, function()
		local ping = modSessionMgr.instance():getSessionPing(T_SESSION_BATTLE)
		local imgt = 3
		if not ping then
			imgt = 3
		elseif ping <= 100 then
			imgt = 1
		elseif ping <= 300 then
			imgt = 2
		else
			imgt = 3
		end
		self.wnd_sign:setImage(sf("ui:battle_sign_%d.png", imgt))
		self:refreshSign()
	end)
end

pBattlePanel.huCombOnleAddTrigger = function(self)
	return false
end

pBattlePanel.setWndFromCache = function(self)
	if not modUserPropCache.pUserPropCache:getInstance() then
		return
	end

	local seatToUid = modBattleMgr.getCurBattle():getSeatToUid()
	if not seatToUid then return end
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local prop = modUserPropCache.getCurPropCache():getProp(seatToUid[i])
		if prop then
			local imgWnd = self[sf("wnd_role_%d", i)]
			local nameWnd = self[sf("wnd_role_%d_name", i)]
			if imgWnd and prop["avatarUrl"] then
				imgWnd:setColor(0xFFFFFFFF)
				imgWnd:setImage(prop["avatarUrl"])
			end
			if nameWnd and prop["userName"] then
				nameWnd:setText(prop["userName"])
			end
		end
	end
end

pBattlePanel.clearEndcalculate = function(self)
	if modEndCalculate.pEndCalculate:getInstance() then
		modEndCalculate.pEndCalculate:instance():close()
	end
end

pBattlePanel.askCloseRoomWork = function(self, message)
	if not message then return end
	modDisMissList.pDisMissList:instance():open(message.user_id, T_MAHJONG_ROOM)
	modDisMissList.pDisMissList:instance():setReLoad(true)
	modDisMissList.pDisMissList:instance():setTimeOut(message.timeout)
end

pBattlePanel.showTableLogo = function(self)
	local logos = {
		["ds_queyue"] = "ui:channel_res/ds_queyue/battle_logo.png",
		["tj_lexian"] = "ui:channel_res/tj_lexian/battle_logo.png",
		["rc_xianle"] = "ui:channel_res/rc_xianle/battle_logo.png",
		["test"] = "ui:channel_res/test/battle_logo_ph.png",
		["qs_pinghe"] = "ui:channel_res/qs_pinghe/battle_logo_ph.png",
	}
	local channel = modUtil.getOpChannel()
	if logos[channel] then
		self.wnd_logo:setColor(0xFFFFFFFF)
		self.wnd_logo:setImage(logos[channel])
	else
		self.wnd_logo:setColor(0)
	end
	if channel == "rc_xianle" or channel == "qs_pinghe" or modUtil.isDebugVersion() then
		self.wnd_logo:setSize(351, 88)
		--if channel == "rc_xianle" or modUtil.isDebugVersion() then
			self.wnd_logo:setOffsetY(-170)
		--end
	end
end

pBattlePanel.videoBattle = function(self)
	if not modBattleMgr.getCurBattle():getIsVideoState() then
		return
	end
	self.btn_return:show(false)
	self.btn_share:show(false)
	self.btn_copy_room_info:show(false)
	self.btn_voices:show(false)
	self.btn_speak:show(false)
end

pBattlePanel.rotaImage = function(self, wnd, angel)
	local wnd = wnd
	wnd:setKeyPoint(wnd:getWidth() / 2, wnd:getHeight() / 2)
	wnd:setRot(0, 0, angel)
end

pBattlePanel.showTime = function(self)
	self.wnd_time:show(true)
end

pBattlePanel.getIsShowBtnTellAll = function(self)
	if not modBattleMgr.getCurBattle():getIsGaming() then
		return false
	end
	if self:getCurGame():getAllPlayerHasDiscard() then
		return false
	end
	if table.size(modBattleMgr.getCurBattle():getAllPlayers()) < 3 then
		return false
	end
	return not self:getAllPlayerIsOnline()
end

pBattlePanel.updateIsShowBtnTellAll = function(self)	
	self.btn_tell_all:show(self:getIsShowBtnTellAll())
end

pBattlePanel.updateTingWnds = function(self, isInit)
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local wnd = self[sf("wnd_role_%d_ting", i)]
		if isInit then
			wnd:show(false)
		else
			local modUIUtil = import("ui/common/util.lua")
			wnd:show(modUIUtil.getIsTing(players[i]))
		end
	end
end

pBattlePanel.offlineStatus = function(self,seatId)
	if self[sf("wnd_role_%d_ok",seatId)] then
		self[sf("wnd_role_%d_ok",seatId)]:show(false)
	end
	if self["wnd_off_line" .. seatId] then
		self["wnd_off_line" .. seatId]:setParent(nil)
	end
	if self[sf("btn_role_%d_tell", seatId)] then
		if modBattleMgr.getCurBattle():getIsGaming() then
			self[sf("btn_role_%d_tell", seatId)]:show(true)
		end
	end
	local wnd = pWindow:new()
	wnd:setName("wnd_off_line" .. seatId)
	local parentWnd = self[sf("wnd_role_%d_front",seatId)]
	if parentWnd then
		wnd:setParent(parentWnd)
	end
	wnd:setColor(0xFFFFFFFF)
	wnd:setImage("ui:battle_off_line.png")
	wnd:setZ(-1)
--	wnd:setRenderLayer(C_BATTLE_UI_RL)
	wnd:setSize(77, 58)
	wnd:setPosition(parentWnd:getWidth() - wnd:getWidth() * 0.9, parentWnd:getHeight() - wnd:getHeight() * 0.9)
	self[wnd:getName()] = wnd
	return wnd
end

pBattlePanel.clearPlayerExtrasWnds = function(self)
	return
end

pBattlePanel.showPlayerExtrasWnds = function(self)
	return
end

pBattlePanel.setCurrDiscardCard = function(self, cardId, seatId)
	self.discardMarkId = cardId
	self.curDiscardSeatId = seatId
end

pBattlePanel.setDiscardId = function(self,cardId)
	self.discardMarkId = cardId
end

pBattlePanel.isShowPhaseTipWnd = function(self)
	return
end

pBattlePanel.showExtras = function(self, player)
	if not player then return end
end

pBattlePanel.speicalGuoWork = function(self, btn)
	return
end

pBattlePanel.normalDiscardPhase = function(self)
	if modBattleMgr.getCurBattle():isNormalDiscardPhase() then
		self.wnd_huan_rule:show(false)
	end
end

pBattlePanel.setPhaseInitPiaoWnds = function(self)
	if modBattleMgr.getCurBattle():isPhasePiao() then
		self:initPiaoWndText(true)
		self:updatePlayerPiaoWnds()
	end
	-- 正常游戏阶段
	if modBattleMgr.getCurBattle():isNormalDiscardPhase() then
		self:normalDiscardPhase()
		self:showPiaoWnd(true)
	end
end

pBattlePanel.showPhaseTipWnd = function(self, phase)
	return
end

pBattlePanel.showPhaseInfoMessage = function(self, phase)
	local showPhases = {
		[modGameProto.EnterGamePhaseRequest.PIAO] = "飘分",
		[modGameProto.EnterGamePhaseRequest.TIANJIN_LA] = "拉" ,
		[modGameProto.EnterGamePhaseRequest.TIANJIN_CHUAI] = "踹",
		[modGameProto.EnterGamePhaseRequest.YUNYANG_HUANSANZHANG] = "换三张",
		[modGameProto.EnterGamePhaseRequest.YUNYANG_DINQUE] = "定缺",
		[modGameProto.EnterGamePhaseRequest.YUNYANG_HOUSI] = "后四",
		[modGameProto.EnterGamePhaseRequest.YUNYANG_QIANSI] = "前四"
	,
		[modGameProto.EnterGamePhaseRequest.NORMAL] = "正常打牌",
		[modGameProto.EnterGamePhaseRequest.RONGCHENG_JIEBAO] = "揭宝",
		[modGameProto.EnterGamePhaseRequest.RONGCHENG_HAIDILAO] = "海底",
	}
	-- 展示游戏阶段文字(后四)
	self:showPhaseTipWnd(phase)

	-- log
	if showPhases[phase] then
		log("warn", "setGamePhase:", phase, "进入" .. showPhases[phase] .. "阶段")
	end
end

pBattlePanel.newTipWnd = function(self, name, text, x, y, width, height, time)
	local modUIUtil = import("ui/common/util.lua")
	local wnd = pWindow():new()
	wnd:load("data/ui/texttip.lua")
	wnd:setParent(self.wnd_table)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setAlignY(ALIGN_MIDDLE)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setName("battle_tip_" .. name)
	if width and height then
		wnd:setSize(width, height)
	end
	if x then wnd:setOffsetX(x) end
	if y then wnd:setOffsetY(y)	end
	if text then wnd:setText(text)	end
	local fream = modUtil.s2f(3)
	modUIUtil.timeOutDo(time or fream, nil, function()
		if wnd then
			wnd:setParent(nil)
		end
	end)
	return wnd
end

pBattlePanel.isShowPhaseBlackBG = function(self)
	return
end

pBattlePanel.addUserStatus = function(self, userId, playerId)
	if userId and playerId then
		local seatId = modBattleMgr.getCurBattle():getUidToSeat()[userId]
		local player = modBattleMgr.getCurBattle():getPlayerByPlayerId(playerId)
		if self["wnd_off_line" .. seatId] then
			self["wnd_off_line" .. seatId]:setParent(nil)
		end
		if self[sf("wnd_role_%d_ok",seatId)] then
			self[sf("wnd_role_%d_ok",seatId)]:show(true)
		end
		if self[sf("wnd_role_%d_bg",seatId)] then
			self[sf("wnd_role_%d_bg",seatId)]:setColor(0xFFFFFFF)
		end
		if self[sf("wnd_role_%d",seatId)] then
			self[sf("wnd_role_%d",seatId)]:setColor(0xFFFFFFFF)
			self[sf("wnd_role_%d",seatId)]:show(true)
			self[sf("wnd_role_%d",seatId)]:setImage(player:getAvatarUrl())
		end

		if self[sf("wnd_role_%d_name",seatId)] then
			self[sf("wnd_role_%d_name",seatId)]:show(true)
			self[sf("wnd_role_%d_name",seatId)]:setText(player:getName())
		end
		if self[sf("wnd_role_%d_score",seatId)] then
			self[sf("wnd_role_%d_score",seatId)]:show(true)
		end
		if 	self[sf("btn_role_%d_plus", seatId)] then
			self[sf("btn_role_%d_plus", seatId)]:show(false)
		end
		if self[sf("btn_role_%d_tell", seatId)] then
			self[sf("btn_role_%d_tell", seatId)]:show(false)
		end
	end
end

pBattlePanel.onlineStatus = function(self, userId)
	if userId then
		local seatId = modBattleMgr.getCurBattle():getUidToSeat()[userId]
		if self["wnd_off_line" .. seatId] then
			self["wnd_off_line" .. seatId]:setParent(nil)
		end
		if self[sf("wnd_role_%d_ok",seatId)] then
			self[sf("wnd_role_%d_ok",seatId)]:show(true)
		end
		if self[sf("wnd_role_%d_bg",seatId)] then
			self[sf("wnd_role_%d_bg",seatId)]:setColor(0xFFFFFFFF)
			self[sf("wnd_role_%d_bg",seatId)]:show(true)
		end
		if self[sf("btn_role_%d_tell", seatId)] then
			self[sf("btn_role_%d_tell", seatId)]:show(false)
		end
	end
end

pBattlePanel.removeUserStatus = function(self, uid)
	if uid then
		local seatId = modBattleMgr.getCurBattle():getUidToSeat()[uid]
		if self[sf("wnd_role_%d",seatId)] then
			self[sf("wnd_role_%d",seatId)]:setImage("")
			self[sf("wnd_role_%d",seatId)]:setColor(0)
		end
		if self[sf("wnd_role_%d_ok",seatId)] then
			self[sf("wnd_role_%d_ok",seatId)]:show(false)
		end
		if self[sf("wnd_role_%d_name",seatId)] then
			self[sf("wnd_role_%d_name",seatId)]:setText("")
		end
		if self[sf("wnd_role_%d_score",seatId)] then
			self[sf("wnd_role_%d_score",seatId)]:show(false)
		end
		if self["wnd_off_line" .. seatId] then
			self["wnd_off_line" .. seatId]:setParent(nil)
		end
		if self[sf("btn_role_%d_tell", seatId)] then
			self[sf("btn_role_%d_tell", seatId)]:show(false)
		end
		if not modBattleMgr.getCurBattle():getIsGaming() then
			if self[sf("wnd_role_%d_bg", seatId)] then
				self[sf("wnd_role_%d_bg", seatId)]:setColor(0)
			end
			if self[sf("btn_role_%d_plus", seatId)] then
				self[sf("btn_role_%d_plus", seatId)]:show(true)
			end
		end
	end
end

pBattlePanel.offlineIcon = function(self, uid)
	local seatId = modBattleMgr.getCurBattle():getUidToSeat()[uid]
	if seatId then
		self:offlineStatus(seatId)
	end
--	self:updateIsShowBtnTellAll()
end

pBattlePanel.askFlagShowPiaoWnds = function(self, flags, message)
	logv("warn",pBattlePanel.askFlagShowPiaoWnds)
	logv("warn",flags,message)
	if not flags or not message then return end
	-- 描画flag选项
	local wndParent = self:getCombParentWnd()
	local modGamePhase = import("ui/battle/gamephase.lua")
	if modGamePhase.pGamePhase:getInstance() then
		wndParent = modGamePhase.pGamePhase:instance()
	end
	local modFlagMenu = import("ui/battle/flags.lua")
	modFlagMenu.pFlagMenu:instance():open(flags, wndParent, message.allow_pass)
	-- 显示全部飘wnd
	self:showPiaoWnd(true)
end

pBattlePanel.changeCard = function(self)
	local modChangeCardMenu = import("ui/battle/testchangecard.lua")
	if self.testWnds then
		self.testWnds:close()
		self.testWnds = nil
		return
	end
	self.testWnds = modChangeCardMenu.pChangeCard:new(self)
end

pBattlePanel.clearTestWnds = function(self)
	if self.testWnds then
		self.testWnds:setParent(nil)
		self.testWnds = nil
		return
	end
end

pBattlePanel.updateBatteryLevel = function(self, level)
	if not self.__fill_origin_w then
		self.__fill_origin_w = self.wnd_battery_fill:getWidth()
	end
	local fillWidth = level / 100.0 * self.__fill_origin_w
	self.wnd_battery_fill:setSize(fillWidth, self.wnd_battery_fill:getHeight())
	self.__battery_level = level
	if not self.__battery_status or
		self.__battery_status ~= puppy.world.pApp.ST_BATTERY_CHARGING then
		self.wnd_battery:setText(sf("%d", level))
		if level > 20 then
			self.wnd_battery:setImage("ui:battery_bottom_normal.png")
			self.wnd_battery_fill:setImage("ui:battery_normal.png")
		else
			self.wnd_battery:setImage("ui:battery_bottom_low.png")
			self.wnd_battery_fill:setImage("ui:battery_low.png")
		end
	else
		self.wnd_battery:setText("")
		self.wnd_battery:setImage("ui:battery_bottom_normal.png")
		self.wnd_battery_fill:setImage("ui:battery_normal.png")
	end
end

pBattlePanel.updateBatteryStatus = function(self, status)
	self.__battery_status = status
	if puppy.world.pApp.ST_BATTERY_FULL then
		if status == puppy.world.pApp.ST_BATTERY_CHARGING then
			if not self.__charging_flag_wnd then
				local wnd = pWindow:new()
				wnd:setImage("ui:battery_charging_flag.png")
				wnd:setSize(50, 50)
				wnd:setParent(self.wnd_battery)
				wnd:setZ(-2)
				wnd:setAlignX(ALIGN_CENTER)
				wnd:setAlignY(ALIGN_MIDDLE)
				self.__charging_flag_wnd = wnd
			end
		else
			if self.__charging_flag_wnd then
				self.__charging_flag_wnd:setParent(nil)
				self.__charging_flag_wnd = nil
			end
		end
		if self.__battery_level then
			self:updateBatteryLevel(self.__battery_level)
		end
	else
		modUtil.consolePrint(sf("updateBatteryStatus no const defined!"))
	end
end

pBattlePanel.regEvent = function(self)
	if app:getPlatform() == "macos" then
		-- 测试重连
		self.btn_test_time_out:addListener("ec_mouse_click", function()
			local modSessionMgr = import("net/mgr.lua")
			modSessionMgr.pSessionMgr:instance():onEnterBackground()
			local modEvent = import("common/event.lua")
			modEvent.fireEvent(EV_BACK_GROUND)
			app.__is_background = true
			setTimeout(s2f(5), function()
				app.__is_background = false
				local modSessionMgr = import("net/mgr.lua")
				modSessionMgr.pSessionMgr:instance():onEnterForeground()
			end)
		end)
	end

	self.__battery_level_changed_hdr = modEvent.handleEvent(EV_BATTERY_LEVEL_CHANGED, function(level)
		self:updateBatteryLevel(level)
	end)

	self.__battery_status_changed_hdr = modEvent.handleEvent(EV_BATTERY_STATUS_CHANGED, function(status)
		self:updateBatteryStatus(status)
	end)

	self.__add_user_hdr = modEvent.handleEvent(EV_ADD_USER, function(seatId, players)
		self.players = players
		self[sf("wnd_role_%d_bg", seatId)]:show(true)
		self:showScore()
		self:showPlayerBg()
		self:showNickName()
		self:updatePlusBySeatId(seatId, false)
		self:updatePlayerScores()
	end)


	self.btn_change:addListener("ec_mouse_click", function()
		self:changeCard()
	end)

	self.__card_pool_update_hdr = modEvent.handleEvent(EV_CARD_POOL_UPDATE, function(seatId, poolType)		
		log("info", sf("evhandler: UPDATE_CARD_POOL seat=%d, pooltype=%d", seatId, poolType))
		local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
		if poolType == T_POOL_DISCARD then
			self:updatePlayerDiscardCards(player)
		else
			self:updatePlayerFrontCards(player)
		end
		self:updateIsShowBtnTellAll()
		self:updateAllHuWndsCountText()
	end)

	self.__choose_combs_hdr = modEvent.handleEvent(EV_CHOOSE_COMBS, function(message)
		if modCombWnd.pMenu:getInstance() then
			modCombWnd.pMenu:instance():close()
		end
		if table.getn(message.combs) > 0 then
			modCombWnd.pMenu:instance():open(message, self.wnd_comb_parent)
		end
	end)

	self.__choose_angangs_hdr = modEvent.handleEvent(EV_CHOOSE_ANGANGS,function ( message )
		if modAnGangWnd.pAnGang:getInstance() then
			modAnGangWnd.pAnGang:instance():close()
		end
		if table.getn(message.player_to_angang) > 0 then
			modAnGangWnd.pAnGang:instance():open(message,self.wnd_comb_parent)
		end
	end)

	self.__next_turn_hdr = modEvent.handleEvent(EV_NEXT_TURN, function(seatId)
		self:setCurTurnSeat(seatId)
--		self:clearDiscardMark()
--		self.discardMarkId = nil
	end)

	self.__update_user_prop = modEvent.handleEvent(EV_UPDATE_USER_PROP,function(seatId, name, avatarUrl)
		local modUIUtil = import("ui/common/util.lua")
		self:setAvatarUrl(seatId,avatarUrl)
		if self[sf("wnd_role_%d_name",seatId)] then
			if modUIUtil.utf8len(name) > 6 then
				name = modUIUtil.getMaxLenString(name, 6)
			end
			self[sf("wnd_role_%d_name",seatId)]:setText(name)
			self[sf("wnd_role_%d_name",seatId)]:show(true)
		end
--		if self:checkPlayerProps() then
		self:checkSameIP()
--		end

	end)

	self.wnd_table:addListener("ec_mouse_click",function() -- ????
		if not modBattleMgr.getCurBattle():getIsGaming() then return end
		-- 摧毁听牌建议
		self:clearSuggestionMenu()
		-- 调牌时不响应
		if self.testWnds and self.curChooseWnds and #self.curChooseWnds > 0 and modUtil.isDebugVersion() then
			self:clearTestWnds()
			return
		end

		local wnds = self:getMineHandCard()
		if wnds then
			for _, wnd in pairs(wnds) do
				wnd:resetWork()
				self:resetTestChangeWnd()
				self:setMineHandCard(nil)
			end
		end
		-- 点击桌面颜色处理
		self:tableClickSetColor()
	end)

	self.__game_calc_hdr = modEvent.handleEvent(EV_GAME_CALC, function(message)
		-- 删掉发牌
		for i = T_SEAT_MINE, T_SEAT_LEFT do
			if self.cardInfo[seatId] and
				self.cardInfo[seatId][T_CARD_HAND] and
				self.cardInfo[seatId][T_CARD_HAND]["dealCard"] then
				for _, wnd in pairs(self.cardInfo[seatId][T_CARD_HAND]["dealCard"]) do
					wnd:setParent(nil)
				end
				self.cardInfo[seatId][T_CARD_HAND]["dealCard"] = {}
			end
		end
		self:calculateClear()
		log("info", "handle EV_GAME_CALC")
	end)


	for i = 0,3 do
		self[sf("wnd_role_%d_bg", i)]:addListener("ec_mouse_click",function()
			local uid = modBattleMgr.getCurBattle():getSeatToUid()[i]
			if uid then
				modPlayerInfo.newMgr(uid, T_MAHJONG_ROOM)
			end
		end)

		self[sf("btn_role_%d_plus", i)]:addListener("ec_mouse_click", function()
			local roomType = self:getCurGame():getRoomType()
			if not roomType or roomType == modLobbyProto.CreateRoomRequest.MATCH then
				return
			end
			self:shareToWeixin()
		end)
	end
	self.btn_share:addListener("ec_mouse_click",function()
		self:shareToWeixin()
	end)

	self.btn_copy_room_info:addListener("ec_mouse_click", function()
		self:shareToWeixin(true)
	end)

	self.btn_menu:addListener("ec_mouse_click", function()
		self:showMenu()
	end)

	self.btn_return:addListener("ec_mouse_click",function() self:show(false)  end)

	self.btn_voices:addListener("ec_mouse_click", function()
		if modVoice.pVoice:getInstance() then
			modVoice.pVoice:getInstance():show(true)
			if modChannelMgr.getCurChannel():getIsResetFangYan() then
				modVoice.pVoice:getInstance():defaultValue()
			end
		else
			modVoice.pVoice:instance():open(self.wnd_table)
		end
	end)

	modChatUtil.initSpeakBtn(self, self.btn_speak)

	self.btn_tell_all:addListener("ec_mouse_click", function()
		if self:getAllPlayerIsOnline() then
			return
		end
		local players = modBattleMgr.getCurBattle():getAllPlayers()
		local playerOnlineInfos = modBattleMgr.getCurBattle():getPlayerOnlineInfos()
		if not players then return end
		local roomId = sf("%06d", modBattleMgr.getCurBattle():getRoomId())
		local text = "房号【" .. roomId .. "】开牌啦，快进入游戏吧！"
		local name = ""
		for idx, player in pairs(players) do
			if not playerOnlineInfos[player:getUid()] then
				name = name .. "@" .. player:getName() .. " "
			end
		end
		if puppy.sys.shareWeChatText then
			puppy.sys.shareWeChatText(2, TEXT(name .. text))
		end
		log("info", TEXT(name .. text))
	end)
end

pBattlePanel.clearSuggestionMenu = function(self)
	if modSuggMenu.pSuggestionMenu:getInstance() then
		modSuggMenu.pSuggestionMenu:instance():close()
	end
end

pBattlePanel.getAllPlayerIsOnline = function(self)
	local playerOnlineInfos = modBattleMgr.getCurBattle():getPlayerOnlineInfos()
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	for _, player in pairs(players) do
		local uid = player:getUid()
		if not playerOnlineInfos[uid] then
			return false
		end
	end
	return true
end

pBattlePanel.calculateClear = function(self)
	self:closeSet()
	self:clearFlagWnd()
	self:clearControls()
	self:updateTingWnds()
	self:clearLouControls()
	self:stopTimeoutSound()
	self:clearDiscardMark()
	self:clearWinnerCardWnds()
	self:clearDiCardControls()
	self:clearSuggestionMenu()
	self:clearShowCardControls()
	self:clearGangCardControls()
	self:updateIsShowBtnTellAll()
	self:clearAutoPlayingWnds()
	self:clearAutoPlayingBG()
	self.btn_change:show(false)
	self.btn_change_san:show(false)
end

pBattlePanel.autoPlayingClear = function(self)
	self:clearFlagWnd()
	self.btn_change:show(false)
	self.btn_guo:show(false)
	self.btn_change_san:show(false)
	self:clearCombMenu()
	self:clearChooseWnds()
end

pBattlePanel.startClear = function(self)
	self:clearCombMenu()
	self:clearFlagWnd()
	self:clearCalculate()
	self:clearSelectTipWnd()
	self:clearSuggestionMenu()
	self:clearWinnerCardWnds()
	self:clearEndcalculate()
	self:clearAutoPlayingBG()
	self:clearAutoPlayingWnds()
end

pBattlePanel.tableClickSetColor = function(self)
	self:updatePlayerTingColor()
	self:notSelectCardSetTingColorWork()
end

pBattlePanel.updatePlayerTingColor = function(self)
	-- 清除所有压暗牌
	self:updateCardIsShow(-1, true)
	-- 压暗所有听牌
	self:updateAllPlayersTingCard()
	-- 不能打的牌压暗
	self:notInDiscardListSetTingColor()
end

-- 清除combUI
pBattlePanel.clearCombMenu = function(self)
	if modCombWnd.pMenu:getInstance() then
		modCombWnd.pMenu:instance():close()
	end
end

--清楚angangUI
pBattlePanel.clearAngangMenu = function ( self )
	if modAnGangWnd.pAnGang:getInstance() then
		modAnGangWnd.pAnGang:instance():close()
	end
end

pBattlePanel.dealAngangData = function ( self, btn, message )
	if modAnGangWnd.pAnGang:getInstance() then
		modAnGangWnd.pAnGang:instance():dealAngangData(btn, message)
	end
end

pBattlePanel.checkPlayerProps = function(self)
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	for _, p in pairs(players) do
		if not p:getName() or not p:getIP() then
			return false
		end
	end
	return true
end

pBattlePanel.checkSameIP = function(self)
	if table.size(modBattleMgr.getCurBattle():getAllPlayers()) < 2 then return end
	local sameIPPlayers = modBattleMgr.getCurBattle():sameIp()[1]
	local noipPlayers = modBattleMgr.getCurBattle():sameIp()[2]
	if table.size(sameIPPlayers) == 0 and table.size(noipPlayers) == 0 then
		return
	end
	local noIPStr = "请注意玩家"
	local strs = {}
	for index, plist in pairs(sameIPPlayers) do
		local sameIPStr = "请注意玩家"
		for idx, p in pairs(plist) do
			sameIPStr = sameIPStr .. "#cr" .. p:getName() .. "#n"
			if idx ~= table.size(plist) then
				sameIPStr = sameIPStr .. "、"
			end
		end
		sameIPStr = sameIPStr .. "IP相同"
		table.insert(strs, sameIPStr)
	end
--	for idx, p in pairs(noipPlayers) do
--		noIPStr = noIPStr .. p:getName() .. "、"
--	end
--	noIPStr = noIPStr .. "无法获取IP"
--	table.insert(strs, noIPStr)
	self:showSameIPWnd(strs)
end

pBattlePanel.showSameIPWnd = function(self, strs)
	if self["tip_wnd"] then
		self["tip_wnd"]:setParent(nil)
	end
	local modUIUtil = import("ui/common/util.lua")
	local wnd = pWindow():new()
	wnd:load("data/ui/texttip.lua")
	wnd:setParent(self.wnd_table)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setPosition(0, 100)
	local slen = 0
	for _, str in pairs(strs) do
		if modUIUtil.utf8len(str) > slen then
			slen = modUIUtil.utf8len(str)
		end
		wnd:setText(wnd:getText() or "" .. str .. "\n")
	end
	wnd:setSize(slen * 21, table.size(strs) * 50)
	self["tip_wnd"] = wnd
	modUIUtil.timeOutDo(modUtil.s2f(5), nil, function()
		if wnd then
			wnd:setParent(nil)
		end
	end)
end


pBattlePanel.clearSelectTipWnd = function(self)
	if self["select_tip"] then
		self["select_tip"]:setParent(nil)
	end
end

pBattlePanel.updateAllPlayerCards = function(self)
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	for _, player in pairs(players) do
		self:updatePlayerFrontCards(player)
		self:updatePlayerDiscardCards(player)
	end
end

pBattlePanel.findCardIsInList = function(self, card, ids)
	if not card or not ids then return end
	for _, id in pairs(ids) do
		if  card == id or card:getCardId() == id then
			return true
		end
	end
	return false
end


pBattlePanel.getIsCircle = function(self)
	return
end

pBattlePanel.shareToWeixin = function(self, justPaste)
	local modChannel = import("logic/channels/main.lua")
	local titleStr = self:getGameName()
	local roomId = sf("%06d", self.param[K_ROOM_ID])
	local downLoadLink = modChannel.getCurChannel():getShareRoomUrl(roomId)
	local nowCount = table.size(modBattleMgr.getCurBattle():getAllPlayers())
	local waitCount = self.playerCount - nowCount
	local totRound = self.param[K_ROOM_INFO].number_of_game_times
	nowCount = self:numberToChinese(nowCount)
	waitCount = self:numberToChinese(waitCount)
	local waitStr = nowCount .. "缺" .. waitCount
	-- 标题
	titleStr = titleStr .. "【" .. roomId .. "】" .. waitStr
	-- 内容
	local roundStr = "局 "
	if self:getIsCircle() then
		roundStr = "圈 "
	end
	local ruleStr = totRound .. roundStr .. self.roomTypeStr .. "," .. self:getRuleStr()
	-- 等你来
	local welcomeStr = "("
	local nameIndex = 0
	for idx, player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
		nameIndex = nameIndex + 1
		welcomeStr = welcomeStr .. player:getName()
		if nameIndex ~= table.size(modBattleMgr.getCurBattle():getAllPlayers()) then
			welcomeStr = welcomeStr .. "、"
		end
	end
	welcomeStr = welcomeStr .. "等你来)"
	log("info", titleStr, ruleStr,  welcomeStr, downLoadLink)
	if justPaste then
		modClipBoardMgr.pClipBoardMgr:instance():setClipBoardText(titleStr .. "\n" .. ruleStr .. welcomeStr .. TEXT("（复制此消息打开游戏可直接进入房间哦）"), TEXT("复制成功！"))
	else
		puppy.sys.shareWeChat(2, TEXT(titleStr), TEXT(ruleStr .. welcomeStr), downLoadLink)
	end
end

pBattlePanel.getAudioInputWndRX = function(self)
	return 2 * self.btn_speak:getWidth()
end

pBattlePanel.clearFlagWnd = function(self)
	if modFlagMenu.pFlagMenu:getInstance() then
		modFlagMenu.pFlagMenu:instance():close()
	end
end

pBattlePanel.numberToChinese = function(self,s)
	local str = ""
	if s == 1 then
		str = "一"
	elseif s == 2 then
		str = "二"
	elseif s == 3 then
		str = "三"
	elseif s == 4 then
		str = "四"
	elseif s == 0 then
		str = "零"
	end
	if str ~= "" then
		return str
	end
end

pBattlePanel.getPiaoType = function(self)
	return
end

pBattlePanel.zhuanNiaoFunction = function(self,message)
	modFunctionManager.pUIFunctionManager:instance():startFunction(function()
		modMainZhuaNiao.pMainZhuaNiao:instance():open(message)
	end)
end

pBattlePanel.calculateFunction = function(self,message)
	modFunctionManager.pUIFunctionManager:instance():startFunction(function()
		if modPlayerInfo.pPlayerInfoMgr:getInstance() then
			modPlayerInfo.pPlayerInfoMgr:instance():destroy()
		end
		local str = "房间号:" .. self.roomIdStr  .. " " .. self.roomTypeStr .. " " .. self.gameTypeStr .. " " .. self.ruleStr
		modCalcPanel.pCalculatePanel:instance():open(message, str)
	end)
end


pBattlePanel.initFromData = function(self, seatToUid, players, curTurnPlayer, param)
	self.param = param
	-- logv("warn","param",param)
	self.handCnt = self:getCurGame():getMaxCardCount()
	self:clearShowCardControls()
	-- 弃牌张数增加
	self.playerCount = self.param[K_ROOM_INFO].max_number_of_users
	if  self.playerCount == 2 then
		MAX_DISCARD_CNT_PER_LINE = 15
	else
		MAX_DISCARD_CNT_PER_LINE = 10
	end
	self:calcPos()
	-- 设置房间号
	self.wnd_roomid:setText(sf(TEXT("房号:%06d"), self.param[K_ROOM_ID]))
		self.roomIdStr = self.param[K_ROOM_ID]
--	self.wnd_roomid:getTextControl():setColor(0xFFBFEFFF)--0xFFFFE7BA
	if self.param[K_ROOM_INFO].room_type == modLobbyProto.CreateRoomRequest.MATCH then
		self.wnd_roomid:setText("")
		self.wnd_roomid:show(false)
	end
	-- 显示积分
	self:showScore()
--	self:showNickName()
	self:showPlayerBg()
	-- 更新座位
	self:updateSeat()
	self:updateSeatBeforStart("wnd_role_%d_bg")
	self:updateSeatBeforStart("wnd_role_%d_name")
	-- 画ok
	self:showOkReady()
	-- 代开不画房主
	if self.param[K_ROOM_INFO].room_type ~= modLobbyProto.CreateRoomRequest.SHARED then
		self:ownerMark()
	end

	-- 三人麻将东南西北上移
	self:setTimePos()

	-- 存在当前玩家
	if curTurnPlayer then
		self:setCurTurnSeat(curTurnPlayer:getSeat())
		local hands = curTurnPlayer:getAllCardsFromPool(T_POOL_HAND, curTurnPlayer:getSeat())
		local deals  = curTurnPlayer:getCurrentDealCard()
		local combs = curTurnPlayer:getAllCardsFromPool(T_POOL_SHOW)
		local isLastPlayer = false
		for _, player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
			if self:getCardsIsMax(player) then
				isLastPlayer = true
			end
		end
		if isLastPlayer then
			self.lastPid = curTurnPlayer:getPlayerId() - 1
			if self.lastPid < 0 then
				self.lastPid = table.size(modBattleMgr.getCurBattle():getAllPlayers()) - 1
			end
		else
			self.lastPid = curTurnPlayer:getPlayerId()
		end
		local discards = modBattleMgr.getCurBattle():getAllPlayers()[modBattleMgr.getCurBattle():getSeatMap()[self.lastPid]]:getAllCardsFromPool(T_POOL_DISCARD)
		if table.getn(discards) > 0 then
			self.discardMarkId = discards[table.getn(discards)]:getId()
			self.curDiscardSeatId = modBattleMgr.getCurBattle():getSeatMap()[self.lastPid]
		end
	end
	-- 展示玩家
	self:showUser(modBattleMgr.getCurBattle():getPlayerOnlineInfos())
	-- 展示加号
	self:showPlus()
	-- 查看是否有flag和底
	self:gamePhaseWnd()
	-- 取cache数据
	self:setWndFromCache()
	-- 更新@离线
	self:updateIsShowBtnTellAll()
	-- 更新玩家听牌
	self:updateTingWnds()
end


pBattlePanel.gamePhaseWnd = function(self)
	local phase = modBattleMgr.getCurBattle():getGamePhase()
	if not phase then
		log("error", "game_phase is nil")
		return
	end
	if phase == modGameProto.EnterGamePhaseRequest.NORMAL then
		return
	end
	local modGamePhase = import("ui/battle/gamephase.lua")
	if modGamePhase.pGamePhase:getInstance() then
		modGamePhase.pGamePhase:instance():close()
	end
	if self:getCurGame():isShowPhaseWnd() then
		local isNotBg = self:getCurGame():getIsShowPhaseBG()
		modGamePhase.pGamePhase:instance():open(modBattleMgr.getCurBattle():getBattleUI():getCombParentWnd(), phase, isNotBg)
	end
end


pBattlePanel.setTimePos = function(self)
	-- 东南西西北3人麻将上移
--	if self.param[K_ROOM_INFO].max_number_of_users == 3 then
--		self.wnd_time:setOffsetY(-self.wnd_time:getHeight() )
--	end
	self.wnd_undealt_card:setOffsetY(self.wnd_time:getOffsetY() - self.wnd_undealt_card:getHeight() * 2)
	self.wnd_reserved_card:setOffsetY(self.wnd_undealt_card:getOffsetY())
end

pBattlePanel.getCardsIsMax = function(self, player)
	local hands = player:getAllCardsFromPool(T_POOL_HAND)
	local deals  = player:getCurrentDealCard()
	local combs = player:getAllCardsFromPool(T_POOL_SHOW)
	local count = #hands + self:getCombCardCount(combs) + #deals
	return count >= self:getCurGame():getMaxCardCount()
end

pBattlePanel.clearPhaseWnd = function(self)
	local modGamePhase = import("ui/battle/gamephase.lua")
	if not modGamePhase.pGamePhase:getInstance() then return end
	local phase = modBattleMgr.getCurBattle():getGamePhase()
	modGamePhase.pGamePhase:instance():close()
end

pBattlePanel.setMagicCardPos = function(self, card)
	if card then
		card:setPosition(self.wnd_table:getWidth() * 0.92, self.wnd_table:getHeight() * 0.06)
	end
end

pBattlePanel.updatePlayerCards = function(self, players)
	-- 更新牌
	for _, player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
		self:updatePlayerFrontCards(player)
		self:updatePlayerDiscardCards(player)
	end
end

pBattlePanel.setDiCardPos = function(self, card)
	if card then
		card:setParent(self.wnd_table)
		card:setAlignX(ALIGN_CENTER)
		card:setAlignY(ALIGN_CENTER)
		card:setOffsetX( self.wnd_time:getWidth())
		card:setOffsetY(self.wnd_time:getOffsetY() - 10)
		table.insert(self.diCardControls, card)

		local dId = self:getCurGame():getDiCardId()
		if not dId or dId < 0 or self:getCurGame():isRongChengMJ() then
			return
		end
		-- 描画离地
		local bg = pWindow:new()
		bg:setName("bg_" .. card:getName())
		bg:setParent(card)
		bg:setSize(150, 50)
		bg:setImage("ui:calculate_item_bg.png")
		bg:setColor(0xFFFFFFFF)
		bg:setAlignX(ALIGN_CENTER)
		bg:setAlignY(ALIGN_BOTTOM)
		bg:setOffsetY(bg:getHeight() - 5)
		self[bg:getName()] = bg
		table.insert(self.showCardControls, bg)
		table.insert(self.diCardControls, bg)

		local wnd = pWindow:new()
		wnd:setName("di_text" .. card:getName())
		wnd:setParent(bg)
		wnd:setSize(50, 30)
		wnd:setText("离地0张")
		wnd:setAlignX(ALIGN_CENTER)
		wnd:setAlignY(ALIGN_CENTER)
		wnd:setColor(0)
		wnd:getTextControl():setAutoBreakLine(false)
		wnd:getTextControl():setColor(0xFFFFFFFF)
		self[wnd:getName()] = wnd
		self.currDiCard = wnd
		table.insert(self.showCardControls, wnd)
		table.insert(self.diCardControls, wnd)
	end
end

pBattlePanel.clearDiCardControls = function(self)
	for _, wnd in pairs(self.diCardControls) do
		wnd:setParent(nil)
	end
	self.diCardControls = {}
end

pBattlePanel.clearGangCardControls = function(self)
	local modUIUtil = import("ui/common/util.lua")
	for _, card in pairs(self.gangCardControls) do
--		card:setParent(nil)
		modUIUtil.fadeOut(card, 2)
	end
	self.gangCardControls = {}
end

pBattlePanel.setGangDealCardPos = function(self, card, seatId)
	if card and seatId then
		local pWnd = self[sf("wnd_hand_%d", seatId)]
		if seatId == T_SEAT_MINE then
			if pWnd then
				card:setParent(pWnd)
				card:setAlignX(ALIGN_LEFT)
				card:setAlignY(ALIGN_TOP)
				card:setPosition((self.wnd_table:getWidth() - card:getWidth()) / 2 , -card:getHeight() * 1.2)
			end
		elseif seatId == T_SEAT_OPP then
				card:setParent(pWnd)
				card:setAlignX(ALIGN_LEFT)
				card:setAlignY(ALIGN_TOP)
				card:setPosition((pWnd:getWidth() - card:getWidth()) / 2 , pWnd:getHeight() - 5)
		elseif seatId == T_SEAT_RIGHT then
			local pWnd = self[sf("wnd_hand_%d", seatId)]
			if pWnd then
				card:setParent(pWnd)
				card:setKeyPoint(card:getWidth() / 2, card:getHeight() / 2)
				card:setAlignX(ALIGN_LEFT)
				card:setAlignY(ALIGN_CENTER)
				card:setPosition(- card:getWidth() + card:getParent():getWidth(), 0)
			end
		elseif seatId == T_SEAT_LEFT then
			local pWnd = self[sf("wnd_hand_%d", seatId)]
			if pWnd then
				card:setParent(pWnd)
				card:setKeyPoint(card:getWidth() / 2, card:getHeight() / 2)
				card:setAlignX(ALIGN_LEFT)
				card:setAlignY(ALIGN_CENTER)
				card:setPosition(card:getWidth() + card:getParent():getWidth(), 0)
			end
		end
		table.insert(self.gangCardControls, card)
	end
end

pBattlePanel.setCardImage = function(self, cardWnd, seatId, cardId,testChangeCardList)
	cardWnd:setImage(sf("ui:card/%d/show_%d.png", seatId, cardId))
end

pBattlePanel.setCardPosition = function(self, cardWnd,cardX,width,cardSeat,id,testChangeCardList)
	cardWnd:setPosition(cardX, 10)
	cardX = cardX + width
end

--显示牌
pBattlePanel.showCard = function(self, name, x, y, ids, s, isMagic, isDi, seatId, testChangeCardList)
	local modUIUtil = import("ui/common/util.lua")
	-- 是否存在不存在牌(42)
	if not ids then return end
	for _, id in pairs(ids) do
		if modUIUtil.getIsNormalCard and not modUIUtil.getIsNormalCard(id) then
			return
		end
	end

	-- 是否为两边
	local isLeftOrRight = function()
		return seatId == T_SEAT_LEFT or seatId == T_SEAT_RIGHT
	end

	-- 缩放比例
	local scale = 1
	if isMagic or isDi then
		scale = 0.7
	elseif s then
		scale = s
	end
	local diScale = scale * 1.4
	local count = table.size(ids)

	-- 尺寸
	local sizeSeat = seatId
	local cardSeat = seatId
	if not seatId or seatId == T_SEAT_MINE or seatId == T_SEAT_OPP then
		sizeSeat = T_SEAT_MINE
		cardSeat = T_SEAT_OPP
	end

	-- 描画
	if isLeftOrRight() then
		scale = 1.5
	end
	local width, height = self.showSizes[sizeSeat][1] * scale, self.showSizes[sizeSeat][2] * scale
	-- bg
	local wnd = pWindow:new()
	wnd:setName("s_bg_" .. name)
	wnd:setParent(self.wnd_table)
	wnd:setPosition(x, y)
	wnd:setColor(0xFFFFFFFF)
	wnd:setImage("ui:main_card_bg.png")
	wnd:setXSplit(true)
	wnd:setYSplit(true)
	wnd:setSplitSize(10)
	-- wnd:setZ(-2)
	if isLeftOrRight() then
		wnd:setSize(20 + width, 20 + count * height)
	else
		wnd:setSize(20 + count * width, 20 + height)
	end
	self[wnd:getName()] = wnd
	if testChangeCardList then
		table.insert(testChangeCardList, wnd)
	else
		table.insert(self.showCardControls, wnd)
	end

	local cardX = 10
	local diId = self:getCurGame():getDiCardId()
	-- card
	for idx, id in pairs(ids) do
		local card = pWindow:new()
		card:setParent(wnd)
		card.cardId = id
		card:setName("s_card_" .. idx .. id)
		self:setCardImage(card, cardSeat, id,testChangeCardList)
		card:setColor(0xFFFFFFFF)
		card:setSize(width, height)
		if isLeftOrRight() then
			card:setPosition(10, cardX)
			cardX = cardX + height - 3.5 * 2
		else
			self:setCardPosition(card,cardX,width,cardSeat,id,testChangeCardList)
		end
		self[card:getName()] = card
		if testChangeCardList then
			table.insert(testChangeCardList, card)
		else
			table.insert(self.showCardControls, card)
		end
		if self:isMagicCard(id)  then
			local gui = pWindow():new()
			gui:setName("wnd_gui_" .. idx .. id)
			gui:setParent(card)
			gui:setPosition(0, 0)
			gui:setAlignY(ALIGN_BOTTOM)
			gui:setSize(100 * scale * 0.53, 139 * scale * 0.53)
			self:setGuiImage(gui)
			-- if (self:getCurGame():getRuleType() == 14) then
			-- 	gui:setImage("ui:calculate_gui_ph.png")
			-- else
			-- 	gui:setImage("ui:calculate_gui.png")
			-- end
			gui:setColor(0xFFFFFFFF)
			self[gui:getName()] = gui
			table.insert(self.showCardControls, gui)
		elseif id == diId then
			local di = pWindow():new()
			di:setName("wnd_di_" .. idx .. id)
			di:setParent(card)
			di:setAlignX(ALIGN_LEFT)
			di:setOffsetY(2)
			di:setSize(100 * scale * 0.62, 139 * scale * 0.62)
			di:setPosition(-1, -2)
			di:setAlignY(ALIGN_BOTTOM)
			di:setImage("ui:calculate_di.png")
			di:setColor(0xFFFFFFFF)
			self[di:getName()] = di
			table.insert(self.showCardControls, di)
			-- 保存dicard 或特殊牌
			if self:getCurGame():isRongChengMJ() then
				di:setParent(nil)
			end
			self.currentDiCardWnd = card
		end
	end

	return wnd
end

pBattlePanel.setGuiImage = function ( self, img)
	img:setImage("ui:calculate_gui.png")
end

pBattlePanel.getCurrentDiCardWnd = function(self)
	return self.currentDiCardWnd
end

pBattlePanel.updateMagicAndDiCards = function(self)
	local cards = self:getCurGame():getMagicCard()
	local diId = self:getCurGame():getDiCardId()
	if table.getn(cards) > 0 then
		self:getCurGame():showMagic()
		return
	elseif diId ~= -1 then
		self:getCurGame():showDi()
		if not self:getCurGame():getSelfHasTing() then
			self:setCurrentDiCardHideImg()
		end
		return
	end
end

pBattlePanel.clearCurrentDiCardWnd = function(self)
	if not self.currentDiCardWnd then
		return
	end
	self.currentDiCardWnd:setParent(nil)
	self.currentDiCardWnd = nil
end

pBattlePanel.setCurrentDiCardHideImg = function(self)
	self.currentDiCardWnd:setImage("ui:card/0/show_hide.png")
end

pBattlePanel.showFlagWnd = function(self, player, isPass)
	local flags = player:getFlags()
	modFlagMenu.pFlagMenu:instance():open(flags, self.wnd_comb_parent, isPass)
end


pBattlePanel.updateScoreByStartGame = function(self, scores)
	if not scores then return end
	local seatMap = modBattleMgr.getCurBattle():getSeatMap()
	local seatId = seatMap[playerId]
	--local wnd = self[sf("wnd_role_%d_score",seatId)]
end

pBattlePanel.updateUndealtCardPos = function(self)
	-- 如果有保留牌数
	if self.wnd_reserved_card:isShow() and self.wnd_reserved_card:getText() and self.wnd_reserved_card:getText() ~= "" then
		self.wnd_undealt_card:setOffsetX( - 100)
		self.wnd_reserved_card:setOffsetX(self.wnd_undealt_card:getOffsetX() + self.wnd_reserved_card:getWidth() + 30)
	end
end

pBattlePanel.updateUndealtCard = function(self, c)
	local count = c
	self.wnd_undealt_card:setText(sf("剩余牌数：%d",count))
	self.wnd_undealt_card:show(true)
	self:updateUndealtCardPos()
	if self.currDiCard then
		local index = self:getCurGame():getDiCardIndex()
		self.currDiCard:setText("离地" .. count + index .. "张牌")
		self.currDiCard:show(true)
		if count > 0 and count + index < 0 then
			self:clearDiCardControls()
		end
	end
end

pBattlePanel.updateReservedCard = function(self, c)
	if not c or c <= 0 then return end
	local count = c
	self.wnd_reserved_card:setText(sf("保留牌数：%d", count))
	self.wnd_reserved_card:show(true)
	self:updateUndealtCardPos()
end

pBattlePanel.showUser = function(self, userInfos)
	if userInfos then
		for uid, isOnline in pairs(userInfos) do
			if isOnline == false then
				local seatId = -1
				for seat,player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
					if uid == player:getUid() then
						seatId = seat
					end
				end
				if seatId ~= -1 then
					self:offlineStatus(seatId)
				end
			end
		end
	end
end

pBattlePanel.initDir = function(self)
	local modUIUtil = import("ui/common/util.lua")
	local seatToDir = modBattleMgr.getCurBattle():getSeatToDir()
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local wnd = self[sf("wnd_dir_%d", i)]
		local hintWnd = self[sf("hint_%d", i)]
		local showDirWnd = self[sf("wnd_show_dir_%d", i)]
		if wnd and seatToDir[i] then
			wnd:setColor(0xFFFFFFFF)
			wnd:setImage(modUIUtil.getDirImage("text", seatToDir[i], i, false))
			hintWnd:setImage(modUIUtil.getDirImage("bg", nil, i))
			showDirWnd:setImage(modUIUtil.getDirImage("text", seatToDir[i], i, true))
		end
	end

end

pBattlePanel.hostMark = function(self, pid, maxPlayerCount)
	local seatId = -1
	for seat, player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
		if player:getPlayerId() == pid then
			seatId = seat
			break
		end
	end

	if seatId ~= -1 then
		if self["wnd_host"] then
			self["wnd_host"]:setParent(nil)
		end
		local wnd = pWindow:new()
		wnd:setName("wnd_host")
		local parentWnd = self[sf("wnd_role_%d_front",seatId)]
		if parentWnd then
			wnd:setParent(parentWnd)
		end
		wnd:setColor(0xFFFFFFFF)
		wnd:setImage("ui:calculate_host.png")
		wnd:setAlignX(ALIGN_RIGHT)
		wnd:setAlignY(ALIGN_BOTTOM)
		wnd:setZ(0)
		wnd:setSize(41 * 0.8, 41 * 0.8)
		wnd:setOffsetX(wnd:getWidth() / 3)
		wnd:setOffsetY(wnd:getHeight() / 5)
		self[wnd:getName()] = wnd
	end
end

pBattlePanel.ownerMark = function(self)
	local ownerId = self.param[K_ROOM_OWNER]
	local seatId = -1
	if modUserData.getUID() == ownerId then
		seatId = 0
	else
		local uidToSeat = modBattleMgr.getCurBattle():getUidToSeat()
		seatId = uidToSeat[ownerId]
	end
	if seatId ~= -1 and not self["wnd_owner"] and seatId then
		local wnd = pWindow:new()
		wnd:setName("wnd_owner")
		local parentWnd = self[sf("wnd_role_%d",seatId)]
		if parentWnd then
			wnd:setParent(parentWnd)
		end
		wnd:setColor(0xFFFFFFFF)
		wnd:setImage("ui:end_calculate_fangzhu.png")
		wnd:setSize(56, 49)
		wnd:setZ(-10)
		wnd:enableEvent(false)
		wnd:setPosition(- wnd:getWidth() / 2, - wnd:getHeight() / 1.5)
		self[wnd:getName()] = wnd
	end
end

pBattlePanel.clearOwnerMark = function(self)
	if self["wnd_owner"] then
		self["wnd_owner"]:setParent(nil)
	end
end

pBattlePanel.updateSeatBeforStart = function(self,wndName)
	if self.playerCount == 3 then
		self[sf(wndName,2)]:show(false)
		self[sf(wndName,3)]:show(true)
	elseif self.playerCount == 2 then
		self[sf(wndName,1)]:show(false)
		self[sf(wndName,3)]:show(false)
	end
end

pBattlePanel.clearOkReady = function(self)
	for i = 0,3 do
		local wnd = self[sf("wnd_role_%d_ok",i)]
		if wnd then
			wnd:setParent(nil)
		end
	end
end

pBattlePanel.updatePlayerScores = function(self)
	for _, player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
		local wnd = self[sf("wnd_role_%d_score", player:getSeat())]
		if wnd then wnd:setText(player:getScore()) end
	end
end


pBattlePanel.showOkReady = function(self)
	for seatId,player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
		local wnd = self[sf("wnd_role_%d_ok", seatId)]
		if seatId == 0 or modBattleMgr.getCurBattle():getAllPlayers()[seatId] then
			if wnd then
				wnd:show(true)
			end
		else
			if wnd then
				wnd:show(false)
			end
		end
	end
end

pBattlePanel.gameOverShowOk = function(self, seatId, isShow)
	local wnd = self[sf("wnd_role_%d_ok", seatId)]
	local pWnd = self[sf("wnd_role_%d_front", seatId)]
	if wnd and pWnd then
		if not isShow then
			pWnd = nil
		end
		wnd:show(isShow)
		wnd:setParent(pWnd)
	end
end

pBattlePanel.showCurrDiscard = function(self, cardId, seatId)
	local modUIUtil = import("ui/common/util.lua")
	if not cardId or not seatId then
		return
	end
	if modUIUtil.getIsNormalCard and not modUIUtil.getIsNormalCard(cardId) then
		return
	end
	if self["wnd_crrdiscard_" .. seatId .. cardId] then
		self["wnd_crrdiscard_" .. seatId .. cardId]:setParent(nil)
	end
	if self["wnd_crrdiscard_bg_" .. seatId .. cardId] then
		self["wnd_crrdiscard_bg_" .. seatId .. cardId]:setParent(nil)
	end
	local bg = pWindow:new()
	bg:setName("wnd_crrdiscard_bg_" .. seatId .. cardId)
	bg:setParent(self[sf("wnd_hand_%d", seatId)])
	bg:setSize(self.showSizes[T_SEAT_MINE][1] * 1.6, self.showSizes[T_SEAT_MINE][2] * 1.4)
	bg:setColor(0xFFFFFFFF)
	bg:setAlignX(ALIGN_CENTER)
	bg:setZ(C_BATTLE_UI_Z)
	bg:setRenderLayer(C_BATTLE_UI_RL)
	bg:setImage("ui:main_card_bg.png")
	bg:setXSplit(true)
	bg:setYSplit(true)
	bg:setSplitSize(10)
	if seatId == T_SEAT_MINE then
		bg:setPosition(0, -bg:getHeight() * 1.5)
		bg:setAlignX(ALIGN_CENTER)
		bg:setOffsetX(bg:getWidth() / 4.5)
	elseif seatId == T_SEAT_OPP then
		bg:setAlignX(ALIGN_CENTER)
		bg:setPosition(0, self.showSizes[seatId][2] * 1.3)
	elseif seatId == T_SEAT_LEFT then
		bg:setAlignX(ALIGN_LEFT)
		bg:setAlignY(ALIGN_CENTER)
		bg:setPosition( self.showSizes[seatId][1] * 2.5, 0)
	elseif seatId == T_SEAT_RIGHT then
		bg:setAlignX(ALIGN_LEFT)
		bg:setAlignY(ALIGN_CENTER)
		bg:setPosition( -self.showSizes[seatId][1] * 2.5, 0)
	end
	self[bg:getName()] = bg
	table.insert(self.controls, bg)

	local wnd = pWindow:new()
	wnd:setName("wnd_crrdiscard_" .. seatId .. cardId)
	wnd:setParent(bg)
	wnd:setSize(self.showSizes[T_SEAT_MINE][1] * 1.2, self.showSizes[T_SEAT_MINE][2] * 1.2)
	wnd:setColor(0xFFFFFFFF)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setAlignY(ALIGN_CENTER)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setImage(sf("ui:card/2/show_%d.png", cardId))
	self[wnd:getName()] = wnd
	table.insert(self.controls, wnd)
	local fream = modUtil.s2f(0.2)
	modUIUtil.timeOutDo(fream, nil, function()
		if self[wnd:getName()] then
--			self[wnd:getName()]:setParent(nil)
			modUIUtil.fadeOut(self[wnd:getName()], 4)
		end
		if self[bg:getName()] then
--			self[bg:getName()]:setParent(nil)
			modUIUtil.fadeOut(self[bg:getName()], 4)
		end
	end)
end

pBattlePanel.clearControls = function(self)
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
end

pBattlePanel.showCombEffect = function(self, combt, seatId, isZimo)
	logv("info","pBattlePanel.showCombEffect")
	logv("info","combt",combt,"seatId",seatId,"isZimo",isZimo)
	if not combt then return end
	local modUIUtil = import("ui/common/util.lua")
	local image = modUIUtil.getImageByComb(combt, isZimo)
	if combt == modGameProto.MING then
		image = "ui:battle/ming.png"
	end
	if not image or not seatId then return end
	local pos = {
		[T_SEAT_MINE] = {gGameWidth * 0.45, gGameHeight * 0.6},
		[T_SEAT_RIGHT] = {gGameWidth * 0.8, gGameHeight * 0.4},
		[T_SEAT_OPP] = {gGameWidth * 0.45, gGameHeight * 0.2},
		[T_SEAT_LEFT] = {gGameWidth * 0.15, gGameHeight * 0.4},
	}
	local x, y = pos[seatId][1], pos[seatId][2]
	if combt == modGameProto.TING then
		local plus = {
			[T_SEAT_MINE] = gGameWidth * 0.05,
			[T_SEAT_RIGHT] = - gGameWidth * 0.13,
			[T_SEAT_OPP] =  gGameWidth * 0.05,
			[T_SEAT_LEFT] = gGameWidth * 0.05,
		}
		x = x + plus[seatId]
	end
	local wnd = pWindow:new()
	local width, height = 87, 87
	if combt == modGameProto.TING or combt == modGameProto.HU or combt == "shuai" or isZimo then
		width, height = 148, 136
	end
	wnd:setName("comb_effect" .. combt .. seatId)
	wnd:setImage(image)
	wnd:setParent(self.wnd_table)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setSize(width, height)
	wnd:setPosition(x, y)
	wnd:setColor(0xFFFFFFFF)
	wnd:show(false)
	self[wnd:getName()] = wnd

	-- 特效
	local fream = modUtil.s2f(0.35)
	modUIUtil.timeOutDo(fream,
		modUIUtil.combEffect(fream, wnd, 0.5),
	function()
		if wnd then
			modUIUtil.fadeOut(wnd, 2)
--			wnd:setParent(nil)
		end
	end)
end

pBattlePanel.discardFunction = function(self, cards, player)
	if not cards or not player then return end
	local battle = modBattleMgr.getCurBattle()
	local isShowBigCard = modChannelMgr.getCurChannel():getBigState()
	local lastIndex = table.getn(cards)
	local player = player
	local seatId = player:getSeat()
	local gender = player:getGender()
	modSound.getCurSound():playSound("sound:down.mp3")
	self:stopTimeoutSound()
	if lastIndex > 1 then
		if isShowBigCard and (not battle:getIsJieBaoPhase())then
			local bgWnd = self:showCard("gang_", 0, 0, cards, nil, nil, nil, seatId)
			self:setGangDealCardPos(bgWnd, seatId)
			local modUIUtil = import("ui/common/util.lua")
			local fream = modUtil.s2f(0.1)
			modUIUtil.timeOutDo(fream, nil, function()
				if battle and battle:getBattleUI() then
					self:clearGangCardControls()
				end
			end)
		end
	elseif lastIndex > 0 then
		if isShowBigCard  then
			for _, id in ipairs(cards) do
				battle:getBattleUI():showCurrDiscard(id, seatId)
			end
		end
	end
	if lastIndex > 0 then
		if battle:getIsJieBaoPhase() then
		else
			modSound.getCurSound():playCardSound(cards[lastIndex], gender)
		end
		battle:getCurGame():setDiscardMark(cards[lastIndex], player)
	end
end

pBattlePanel.setDiscardSetDiscardMark = function(self, cards, player)
	if not cards or not player then return end
	local battle = modBattleMgr.getCurBattle()
	local lastIndex = table.getn(cards)
	battle:getCurGame():setDiscardMark(cards[lastIndex], player)
end

pBattlePanel.discardBeforeFunction = function(self, id)
	-- 先清理
	self:getCurGame():clearDiscardBeforPorto()
	self:getCurGame():setCardIdToCurDiscard(id)
	local discardBeforePorto = self:getCurGame():getDiscardBeforPorto()
	-- 在加入弃牌堆
	local player = self:getCurGame():getCurPlayer()
	player:addCardsToPool(T_POOL_DISCARD, discardBeforePorto)
	-- 显示打牌效果
	self:discardFunction(discardBeforePorto, self:getCurGame():getCurPlayer())
	-- 更新card排序
	player:getHandPool():saveAndClearDeals()
	player:getHandPool():discardSort(discardBeforePorto)
	self:updatePlayerFrontCards(player, true)
	-- 预出牌后马上排序
	self:updatePlayerDiscardCards(player)
	-- 清除听牌建议
	self:clearSuggestionMenu()
	-- 胡牌提示
--	self:discardShowHuCardWnds(id, true)
end

pBattlePanel.hideDiscardedCard = function(self)
	if not self.discardedCard then return end
	for _, card in pairs(self.discardedCard) do
		card:setParent(nil)
	end
end

pBattlePanel.clearNotSortCards = function(self)
	if not self.notSortCards then return end
	self.notSortCards = {}
end

pBattlePanel.clearDiscardBeforCard = function(self)
	-- 先清理
	local player = self:getCurGame():getCurPlayer()
	local cards = player:getDiscardPool():getCards()
	-- 从弃牌堆删除保存的cardId
	self:getCurGame():delBeforeCard()
	-- 更新弃牌堆
	self:updatePlayerDiscardCards(player)
	-- 清掉预打牌
	self:getCurGame():clearDiscardBeforPorto()
end

pBattlePanel.discardSuccessWork = function(self)
	local battle = modBattleMgr.getCurBattle()
	battle:getCurGame():setCanDiscardCardFlag(false)
	modBattleMgr.getCurBattle():getBattleUI().btn_change:show(false)
	self.isMingState = false
	self:updateIsShowBtnTellAll()
end

pBattlePanel.discardFailedWork = function(self, player)
	if not player then return end
	local battle = modBattleMgr.getCurBattle()
	self:clearDiscardBeforCard()
	player:getHandPool():setDeals()
	player:getHandPool():delDealsInHands()
	self:updatePlayerFrontCards(player)
	self:suggMark()
--	self:showMingGuoWnd() \?????
end

pBattlePanel.discardWork = function(self)
	local battle = modBattleMgr.getCurBattle()
	battle:getCurGame():delBeforeCard()
	self.__wait_discard = false
	self:clearNotSortCards()
	self:clearDiscardedCard()
	self:clearChooseWnds()
end

pBattlePanel.tryDiscardCard = function(self, card, callback)
	if not card then return end
	local cardId = card:getCardId()
	if self.__wait_discard then
		return
	end
	local battle = modBattleMgr.getCurBattle()
	if battle:getCurGame():getIsCanDiscardCard(cardId) then
		self.__wait_discard = true
		local player =  battle:getCurPlayer()
		local discardBeforePorto = battle:getCurGame():getDiscardBeforPorto()
		-- 预先加入弃牌堆并更新弃牌
		self:clearDiscardedCard()
		self:discardBeforeFunction(cardId)
		table.insert(self.discardedCard, card)

		-- 发送打牌协议
		modBattleRpc.discardCard(cardId, self:getCurGame():getIsPreting(), function(success, reason)
			if success then
				if callback then
					callback(true)
					self:setMineHandCard(nil)
					self:updatePlayerDiscardCards(player)
				end
				-- 成功处理
				self:discardSuccessWork()
			else
				if callback then
					callback(false)
				end
				-- 失败处理
				self:discardFailedWork(player)
			end
			self:discardWork()
		end)
	else
		self.__wait_discard = false
		callback(false)
	end
end

pBattlePanel.clearDiscardedCard = function(self)
	if not self.discardedCard then self.discardedCard = {} end
	for _, c in pairs(self.discardedCard) do
		c:setParent(nil)
	end
	self.discardedCard = {}
end

pBattlePanel.discardMark = function(self, parentWnd)
	local modUIUtil = import("ui/common/util.lua")
	if not parentWnd or (modUIUtil.getIsNormalCard and not modUIUtil.getIsNormalCard(parentWnd:getCardId())) then return end
	if self.discardMarkId then
		local name = "wnd_discard_mark"
		if self[name] then
			self[name]:setParent(nil)
		end
		local mark = pWindow():new()
		mark:setName(name)
		mark:setParent(parentWnd)
		mark:setAlignX(ALIGN_CENTER)
		mark:setAlignY(ALIGN_CENTER)
		mark:setOffsetY(-mark:getHeight() * 3)
		mark:setSize(32,39)
		mark:setZ(C_BATTLE_UI_Z)
		--mark:setRenderLayer(C_BATTLE_UI_RL + 1)
		mark:setImage("ui:battle_mark.png")
		mark:setColor(0xFFFFFFFF)
		self[name] = mark
		self:floatMark()
		return mark
	end
end

pBattlePanel.floatMark = function(self)
	local modUIUtil = import("ui/common/util.lua")
	local wnd = self["wnd_discard_mark"]
	local distance = 20
	if wnd then
		--self:floatUp(wnd,16,-distance)
		modUIUtil.floatUp(wnd, modUtil.s2f(0.5), -distance)
	end
end

pBattlePanel.chooseCardShowTestWnd = function(self, wnd)
	if not self:getCurGame():canDiscardCard() or
		not self:isDebugVersion() then
		return
	end
	self.btn_change:show(true)
	self.btn_change:setPosition(wnd:getPos() - math.abs((wnd:getWidth() - self.btn_change:getWidth()) / 2 + 8), - wnd:getHeight() * 1.1)
end

pBattlePanel.resetTestChangeWnd = function(self)
	self.btn_change:show(false)
end

pBattlePanel.getMaxChooseCardCount = function(self)
	return 1
end

pBattlePanel.isOverMaxChooseCards = function(self)
	if not self.curChooseWnds then return false end
	return #self.curChooseWnds >= self:getMaxChooseCardCount()
end

pBattlePanel.notChooseCard = function(self, cardWnd)
	return
end

pBattlePanel.getNotDragCard = function(self, cardWnd)
	if not cardWnd then return end
	if modBattleMgr.getCurBattle():getCurPlayer() ~= modBattleMgr.getCurBattle():getCurTurnPlayer() then
		return true
	end
	return self:notChooseCard(cardWnd)
end


pBattlePanel.notSameCardChoose = function(self, card, removeCards)
	if not card or not removeCards then return end
	-- 其他牌全部reset
	card:resetWork()
	card:clearSuggMenuWnd()
	table.insert(removeCards, card)
end

pBattlePanel.setMineHandCard = function(self, cardWnd)
	if not self.curChooseWnds then self.curChooseWnds = {} end
	if not cardWnd then
		self:clearChooseWnds()
		return
	end
	-- 是否已经点过
	local isJoinChooseWnds = true
	local removeCards = {}
	for idx, wnd in pairs(self.curChooseWnds) do
		-- 点击已经选择的牌
		if wnd == cardWnd then
			-- 已经选择并选中则打牌或者reset
			if wnd:isOnChoose() then
				self:cardToResetOrDiscard(wnd)
				isJoinChooseWnds = false
			end
		else
			self:notSameCardChoose(wnd, removeCards)
		end
	end
	-- 移除reset掉的
	self:removeCardsInCardlist(removeCards, self.curChooseWnds)
	if self:notChooseCard(cardWnd) then return end
	if not isJoinChooseWnds then return end
	-- 特殊选牌或多选
	local spCards = self:speicalChooseCard(cardWnd)
	if not spCards or table.getn(spCards) <= 0 then spCards = { cardWnd } end
	for _, wnd in pairs(spCards) do
		table.insert(self.curChooseWnds, wnd)
	end
	-- 选择事件
	self:chooseCardWork()
end

pBattlePanel.resetSetColor = function(self, card)
	if not card then return end
	self:updateAllPlayersTingCard()
end

pBattlePanel.chooseSetColor = function(self, card)
	if not card then return end
	self:updateCardIsShow(card:getCardId())
	self:updateAllPlayersTingCard()
end

pBattlePanel.speicalChooseCard = function(self, cardWnd)
	return
end

pBattlePanel.chooseCardWork = function(self)
	for _, card in pairs(self.curChooseWnds) do
		-- 没有点击过
		if not card:isOnChoose() then
			local cardId = card:getCardId()
			--添加平和麻将金牌不能点击的判断
			local magicId = self:getCurGame():getMagicCard()
			logv("warn",magicId[1])
			if(self:getCurGame():getRuleType() == 14)then
				if(cardId ~= magicId[1]) then
					self:cardToChoose(card)
				end
			else
				self:cardToChoose(card)
			end
		end
	end
end

pBattlePanel.getCurGame = function(self)
	return modBattleMgr.getCurBattle():getCurGame()
end

pBattlePanel.cardToChoose = function(self, card)
	if not card then return end
	card:chooseWork()
	card:addSuggClick()
	self:chooseCardShowTestWnd(card)
end

pBattlePanel.cardToResetOrDiscard = function(self, card)
	if not card then return end
	-- 可以出牌 点击出牌
	if self:getCurGame():getIsCanDiscardCard(card:getCardId()) then
		card:tryDiscardCard()
		return
	end
	-- 不能出牌就reset 或者 特殊处理
	self:parsonalRestCard(card)
end

pBattlePanel.parsonalRestCard = function(self, card)
	if not card then return end
	card:resetWork()
	self:removeChooseCard(card)
end

pBattlePanel.removeChooseCard = function(self, card)
	if not card then return end
	if not self.curChooseWnds then return end
	local index = -1
	for idx, wnd in pairs(self.curChooseWnds) do
		if wnd == card then
			index = idx
		end
	end
	if index ~= -1 then
		table.remove(self.curChooseWnds, index)
	end
end

pBattlePanel.chooseGuoWork = function(self, comb, combWnd)
	combWnd:rpcChooseComb(-1)
end

pBattlePanel.chooseCombWork = function(self, idx, comb, combWnd)
	if not idx or not combWnd then return end
	-- 没有鬼牌和地牌
	if not combWnd:hasMagic(idx) and not combWnd:hasDi(idx) then
		combWnd:rpcChooseComb(idx)
		return
	end
	if not comb then return end
	if self:getIsCombShowTipMagicWnd() then
		local tipText = combWnd:getChooseCombTipText(comb)
		self:newMagicTipWnd(tipText, function(success)
			combWnd:rpcChooseComb(idx)
		end)
	else
		combWnd:rpcChooseComb(idx)
	end
end

pBattlePanel.getIsCombShowTipMagicWnd = function(self)
	return true
end

pBattlePanel.newMagicTipWnd = function(self, text, callback)
	if not text then text = "您确定吗?" end
	local modAskWnd = import("ui/common/askwindow.lua")
	-- 提示窗口
	self.askWnd = modAskWnd.pAskWnd:new(self, text, function(success)
		if success then
			if callback then
				callback(true)
			end
		end
		self.askWnd:setParent(nil)
		self.askWnd = nil
	end)
	self.askWnd:setParent(self)
end

pBattlePanel.combOnChoose = function(self, idx, comb, combWnd)
	if not idx or not combWnd then return end
	if idx == -1 then
		self:chooseGuoWork(comb, combWnd)
		return
	end
	self:chooseCombWork(idx, comb, combWnd)
end

pBattlePanel.clearChooseWnds = function(self)
	if not self.curChooseWnds then return end
	self.curChooseWnds = {}
end

pBattlePanel.getMineHandCard = function(self)
	return self.curChooseWnds
end

pBattlePanel.getIsShowDiscardMagic = function(self, card)
	if not card then return end
	return card:isMagicCard()
end

pBattlePanel.findCardIncards = function(self, card, cards)
	if not card or not cards then return end
	for _, c in pairs(cards) do
		if  c == card or c:getCardId() == card:getCardId()then
			return true
		end
	end
	return false
end

pBattlePanel.findSameCardInHands = function(self, card)
	local hands = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
	local wnds = self:findSameIdCard(card:getCardId(), hands)
	return wnds
end

pBattlePanel.findSameCardInHandsByMax = function(self, card, max)
	if not max then max = 3 end
	local hands = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
	local wnds = self:findSameIdCardByMax(card:getCardId(), hands, max)
	return wnds
end


pBattlePanel.notSelectCardSetTingColorWork = function(self, ids, hands)
	if not ids or not hands then return end
	local modUIUtil = import("ui/common/util.lua")
	-- 可选列表
	local cardIds = self:getCurGame():getChooseWndProp(modBattleMgr.getCurBattle():getMyPlayerId(), "ids")
	local idTocount = modUIUtil.getListIdToCount(cardIds)
	if not idTocount then return end
	-- 取同id手牌数量和可选列表数量
	local handIds = ids
	local handIdToCount = modUIUtil.getListIdToCount(handIds)
	for id, count in pairs(idTocount) do
		if handIdToCount[id] then
			handIdToCount[id] = handIdToCount[id] - count
		end
	end

	local colorCards = {}
	-- 压暗
	for _, card in pairs(hands) do
		if not idTocount[card:getCardId()] then
			table.insert(colorCards, card)
		else
			if handIdToCount[card:getCardId()] > 0 then
				table.insert(colorCards, card)
				handIdToCount[card:getCardId()] = handIdToCount[card:getCardId()] - 1
			end
		end
	end
	self:setTingColorCard(colorCards)
	return colorCards
end



pBattlePanel.checkRemoveCard = function(self, card)
	return
end

pBattlePanel.printCards = function(self, cards, mark, isIds)
	if not mark then mark = "" end
	for idx, card in pairs(cards) do
		if isIds then
			local str = card
			if mark then str = str .. mark end
			print("idx:", idx, "cardId:", str)
		else
			local str = card:getCardId()
			if mark then str = str .. mark end
			print("idx:", idx, "cardId:", str)
		end
	end
end

pBattlePanel.getHasNotTableInTable = function(self, cs, ws)
	if not cs or not ws then return end
	local cards = self:getNewTable(cs)
	local wnds = self:getNewTable(ws)
	local removeIdxs = {}
	for idx, wnd in pairs(wnds) do
		for _, card in pairs(cards) do
			if wnd == card then
				table.insert(removeIdxs, idx)
			end
		end
	end
	for i = table.getn(removeIdxs), 1, -1 do
		table.remove(wnds, removeIdxs[i])
	end
	return wnds
end

pBattlePanel.getNewTable = function(self, cards)
	if not cards then return {} end
	local wnds = {}
	for _, card in pairs(cards) do
		table.insert(wnds, card)
	end
	return wnds
end

pBattlePanel.getHandCards = function(self, seatId)
	if not seatId then seatId = T_SEAT_MINE end
	return self:getAllCardWnds(seatId, T_CARD_HAND)
end


pBattlePanel.removeCardsInCardlist = function(self, wnds, hands)
	if not wnds or not hands then return end
	local idxs = {}
	for _, wnd in pairs(wnds) do
		for idx, hnd in pairs(hands) do
			if wnd == hnd then
				table.insert(idxs, idx)
			end
		end
	end
	for i = table.getn(idxs), 0, -1 do
		if idxs[i] then
			table.remove(hands, idxs[i])
		end
	end
end

pBattlePanel.findSameIdCard = function(self, id, wnds)
	local result = {}
	for _, wnd in pairs(wnds) do
		if id == wnd or id == wnd:getCardId() then
			table.insert(result, wnd)
		end
	end
	return result
end

pBattlePanel.findSameIdCardByMax = function(self, id, wnds, max)
	if not max then max = 3 end
	local result = {}
	for _, wnd in pairs(wnds) do
		if id == wnd or id == wnd:getCardId() then
			table.insert(result, wnd)
			if table.getn(result) >= max then
				break
			end
		end
	end
	return result
end

pBattlePanel.playFace = function(self, msgId, bgWnd)
	if not msgId then return end
	local roll = pSprite()
	roll:setTexture(sf("effect:%d.fsi", msgId), 0)
	roll:setParent(bgWnd)
	roll:setZ(C_BATTLE_UI_Z)
	roll:setSpeed(3)
	roll:play(5, true)
end

pBattlePanel.rollDices = function(self, message)
	local modUIUtil = import("ui/common/util.lua")
	local bg = pWindow:new()
	bg:setName("roll_bg")
	bg:setColor(0)
	bg:setSize(gGameWidth * 0.5, gGameHeight * 0.5)
	bg:setZ(C_BATTLE_UI_Z)
	bg:setAlignX(ALIGN_CENTER)
	bg:setAlignY(ALIGN_CENTER)
	bg:setParent(self.wnd_table)
	modUIUtil.makeModelWindow(bg, false, false)
	self[bg:getName()] = bg

	local roll = pSprite()
	roll:setTexture("effect:roll.fsi", 0)
	roll:setParent(bg)
	roll:setPosition(bg:getWidth() / 2, bg:getHeight() / 1.5)
	roll:setSpeed(3)
	roll:setZ(C_BATTLE_UI_Z)
	roll:play(1, true)

	local delayFrame = pSprite.getHitFrameByPath("effect:roll.fsi")
	local speed = roll:getSpeed()
	if speed <= 0 then
		speed = 3
	end
	local delay = speed * delayFrame
	modUIUtil.timeOutDo(delay, nil, function()
		local ids = message.dice_values
		local distance = 104 * 0.6
		for idx, id in ipairs(ids) do
			local wnd = self:createDice(idx .. id, id)
			wnd:setParent(bg)
			wnd:setOffsetX(wnd:getOffsetX() + (idx - 1) * (wnd:getWidth() + distance))
			modUIUtil.timeOutDo(modUtil.s2f(0.8), nil, function()
				wnd:setParent(nil)
				if idx == table.getn(ids) then
					bg:setParent(nil)
					bg = nil
				end
			end)
		end
	end)
end

pBattlePanel.createDice = function(self, name, id)
	local image = sf("ui:battle_roll_%d.png", id)
	local wnd = pWindow:new()
	wnd:setName("roll_" .. name)
	wnd:setParent(self.wnd_table)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setAlignY(ALIGN_CENTER)
	wnd:setImage(image)
	wnd:setSize(104, 120)
	wnd:setOffsetX(-wnd:getWidth())
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setColor(0xFFFFFFFF)
	self[wnd:getName()] = wnd
	return self[wnd:getName()]
end

pBattlePanel.addBLN = function(self, wnd)
	if not wnd then return end
	if self.blnAction then self.blnAction:stop() end
	self:clearBlns()
	self.blnAction = nil
	wnd.alphaValue = 0
	local modUIUtil = import("ui/common/util.lua")
	self.blnAction = modUIUtil.timeOutDo(1, nil, function()
		self:blnEffect(wnd)
	end)
end

pBattlePanel.blnEffect = function(self, wnd)
	local blnValue = 15
	if not wnd.alphaValue then
		wnd.alphaValue = 0
		self.isAdd = true
	end
	if not self.isAdd then blnValue = -blnValue end
	wnd.alphaValue = wnd.alphaValue + blnValue
	if wnd.alphaValue >= 255 then
		wnd.alphaValue = 255
		self.isAdd = false
	elseif wnd.alphaValue <= 0 then
		wnd.alphaValue = 0
		self.isAdd = true
	end
	wnd:setAlpha(wnd.alphaValue)
	local modUIUtil = import("ui/common/util.lua")
	local bln = modUIUtil.timeOutDo(1, nil, function()
		self:blnEffect(wnd)
	end)
	if not self.blns then self.blns = {} end
	self:clearBlns()
	table.insert(self.blns, bln)
end

pBattlePanel.clearBlns = function(self)
	if not self.blns then return end
	local idxs = {}
	for idx, bln in pairs(self.blns) do
		bln:stop()
		bln = nil
		table.insert(idxs, idx)
	end
	for _, idx in pairs(idxs) do
		table.remove(self.blns, idx)
	end
end

pBattlePanel.setCurTurnSeat = function(self, seatId, isWait)
	if isWait then
		for i = T_SEAT_MINE, T_SEAT_LEFT do
			if i ~= seatId then
				local hintWnd = self[sf("hint_%d", i)]
				hintWnd:show(false)
				if self.blnAction then self.blnAction:stop() end
				self:clearBlns()
				if self.__countdown_hdr then
					self.__countdown_hdr:stop()
				end
				self:stopTimeoutSound()
				self.wnd_game_time:setText(0)
			end
		end
		return
	end
	local hintWnd = self[sf("hint_%d", seatId)]
	local showDirWnd = self[sf("wnd_show_dir_%d", seatId)]
	hintWnd:show(true)
	hintWnd:setColor(0xFFFFFFFF)
	showDirWnd:setColor(0xFFFFFFFF)
	hintWnd:setAlpha(0)
	self:addBLN(hintWnd)

	for i = T_SEAT_MINE, T_SEAT_LEFT do
		if i ~= seatId then
			local hintWnd = self[sf("hint_%d", i)]
			hintWnd:show(false)
			hintWnd:setAlpha(0)
		end
	end
	-- 重新开始倒计时
	if self.__countdown_hdr then
		self.__countdown_hdr:stop()
	end
	local countdown = C_DISCARD_COUNTDOWN
	self.__countdown_hdr = setInterval(modUtil.s2f(1), function()
		self.wnd_game_time:setText(countdown)
		-- isOver
		if countdown == 5 and not modBattleMgr.getCurBattle():getIsCalculate() then
			if modBattleMgr.getCurBattle():isNormalDiscardPhase() then
				modSound.getCurSound():playSound("sound:timeout.mp3")
--				if T_SEAT_MINE == seatId then
--					modUtil.vibrateTelephone(1000)
--				end
				self:stopTimeoutSound()
				self.timeoutSound = self:playTimeOutSound(seatId)
			end
		end
		if not modBattleMgr.getCurBattle():getIsCalculate() then
			countdown = countdown - 1
		end
		if countdown < 0 then
			return C_INTERVAL_RET
		end
	end):update()
	if self.curSeatId and self.curSeatId ~= seatId then
		modBattleMgr.getCurBattle():getAllPlayers()[self.curSeatId]:setCurrentDealCard({})
		log("info", "current seatId" , self.curSeatId)
		self:updatePlayerFrontCards(modBattleMgr.getCurBattle():getAllPlayers()[self.curSeatId])
	end
	self.curSeatId = seatId
	self.curDiscardSeatId = seatId
end

pBattlePanel.playTimeOutSound = function(self, seatId)
	local modUIUtil = import("ui/common/util.lua")
	self.timeoutSound = modUIUtil.timeOutDo(modUtil.s2f(5), nil, function()
		if seatId == T_SEAT_MINE then
			modSound.getCurSound():playSound("sound:timeout.mp3")
			self.timeoutSound = self:playTimeOutSound(seatId)
		else
			self:stopTimeoutSound()
		end
	end)
	return self.timeoutSound
end

pBattlePanel.stopTimeoutSound = function(self)
	if self.timeoutSound then
		self.timeoutSound:stop()
		self.timeoutSound = nil
	end
end

pBattlePanel.clearDiscardMark = function(self)
	if self["wnd_discard_mark"] then
		self["wnd_discard_mark"]:setParent(nil)
	end
	if self.discardMarkId then
		self.discardMarkId = nil
	end
end

pBattlePanel.initCardSizes = function(self)
	self.handSizes = {
		[T_SEAT_MINE] = {100, 139},
		[T_SEAT_RIGHT] = {36 * 1.1, 72 * 1.1},
		[T_SEAT_OPP] = {100 * 0.6, 139 * 0.6},
		[T_SEAT_LEFT] = {36 * 1.1, 72 * 1.1},
	}
	self.showSizes = {
		[T_SEAT_MINE] = {100 * 0.90, 139 * 0.90},
		[T_SEAT_RIGHT] = {134 * 0.43, 104 * 0.43},
		[T_SEAT_OPP] = {100 * 0.55, 139 * 0.55},
		[T_SEAT_LEFT] = {134 * 0.43, 104 * 0.43},
	}
	self.DiscardSizes = {
		[T_SEAT_MINE] = {100 * 0.55, 139 * 0.55},
		[T_SEAT_RIGHT] = {134 * 0.43, 104 * 0.43},
		[T_SEAT_OPP] = {100 * 0.5, 139 * 0.5},
		[T_SEAT_LEFT] = {134 * 0.43, 104 * 0.43},
	}
end

pBattlePanel.initCardPos = function(self)
	self.handPos = {
		[T_SEAT_MINE] = -1,
		[T_SEAT_RIGHT] = -1,
		[T_SEAT_OPP] = -1,
		[T_SEAT_LEFT] = -1,
	}
	self.discardPos = {
		[T_SEAT_MINE] = {},
		[T_SEAT_RIGHT] = {},
		[T_SEAT_OPP] = {},
		[T_SEAT_LEFT] = {},
	}
end

pBattlePanel.initCardParents = function(self)
	self.discardParent = {
		[T_SEAT_MINE] = nil,
		[T_SEAT_RIGHT] = nil,
		[T_SEAT_OPP] = nil,
		[T_SEAT_LEFT] = nil,
	}
	self.discardCntPerLine = {
		[T_SEAT_MINE] = -1,
		[T_SEAT_RIGHT] = -1,
		[T_SEAT_OPP] = -1,
		[T_SEAT_LEFT] = -1,
	}
	self.flowerParent = {
		[T_SEAT_MINE] = nil,
		[T_SEAT_RIGHT] = nil,
		[T_SEAT_OPP] = nil,
		[T_SEAT_LEFT] = nil,
	}
end

pBattlePanel.initHandSize = function(self)
	self.szHandWnd = {
		[T_SEAT_MINE] = {self.wnd_hand_0:getWidth(), self.wnd_hand_0:getHeight()},
		[T_SEAT_RIGHT] = {self.wnd_hand_1:getWidth(), self.wnd_hand_1:getHeight()},
		[T_SEAT_OPP ] = {self.wnd_hand_2:getWidth(), self.wnd_hand_2:getHeight()},
		[T_SEAT_LEFT] = {self.wnd_hand_3:getWidth(), self.wnd_hand_3:getHeight()},
	}

end

pBattlePanel.getMaxWidthCount = function(self)
	return 2
end

pBattlePanel.getMaxHeightCount = function(self)
	return 2
end

pBattlePanel.calcPos = function(self)
	local isTwoPlayers = false
	local isThreePlayers = false
	if self.playerCount == 2 then
		isTwoPlayers = true
	elseif self.playerCount == 3 then
		isThreePlayers = true
	end

	-- 取得最新数据，初始化桌面为0
	self.handCnt = self:getCurGame():getMaxCardCount()
	local HAND_CNT = self.handCnt - 1.5
	-- 初始化坐标
	self:initCardPos()
	-- 初始化父节点
	self:initCardParents()
	-- 根据最大手牌数设置牌的尺寸
	self:initCardSizes()
	-- 初始化手牌大小
	self:initHandSize()
	local minScale = 9999
	for i = T_SEAT_RIGHT, T_SEAT_LEFT do
		local handw, handh = self.szHandWnd[i][1], self.szHandWnd[i][2]
		local s = -1
		if i == T_SEAT_MINE or
			i == T_SEAT_OPP then
			local w = self.handSizes[i][1]
			local ww = (HAND_CNT + 1) * w + w*GAP_RATE
			if ww > handw then
				local nw = handw / ((HAND_CNT + 1) / GAP_RATE + 1) / GAP_RATE
				s = nw / w
			end
		else
			local rh = self.handSizes[i][2]
			local h = rh * VERTICAL_DIFF_RATE
			local hh = (HAND_CNT) * h + rh + h*GAP_RATE
			if hh > handh then
				local nh = handh / ((HAND_CNT + 1) / GAP_RATE  + 1) / GAP_RATE
				s = nh / h
			end
		end
		if s > 0 then
			if s < minScale then
				minScale = s
			end
		end
	end
	if minScale < 1 then
		for i = T_SEAT_RIGHT, T_SEAT_LEFT do
			local hw, hh = self.handSizes[i][1], self.handSizes[i][2]
			local sw, sh = self.showSizes[i][1], self.showSizes[i][2]
			local nhw, nhh, nsw, nsh = 0, 0, 0, 0
			if i == T_SEAT_MINE or
				i == T_SEAT_OPP then
				nhw = hw * minScale
				nhh = hh/hw*nhw
				nsw = sw * minScale
				nsh = sh/sw*nsw
			else
				nhh = hh * minScale
				nhw = hw/hh*nhh
				nsh = sh * minScale
				nsw = sw/sh*nsh
			end
			self.handSizes[i] = {
				nhw, nhh
			}
			self.showSizes[i] = {
				nsw, nsh,
			}
			-- 直接设置尺寸，不会影响对齐方式为tb或lr的维度
			self[sf("wnd_hand_%d", i)]:setSize(self.handSizes[i][1], self.handSizes[i][2])
			--self[sf("wnd_hand_%d", i)]:setAlignX(ALIGN_CENTER)
		end
		self.szHandWnd = {
			[T_SEAT_MINE] = {self.wnd_hand_0:getWidth(), self.wnd_hand_0:getHeight()},
			[T_SEAT_RIGHT] = {self.wnd_hand_1:getWidth(), self.wnd_hand_1:getHeight()},
			[T_SEAT_OPP ] = {self.wnd_hand_2:getWidth(), self.wnd_hand_2:getHeight()},
			[T_SEAT_LEFT] = {self.wnd_hand_3:getWidth(), self.wnd_hand_3:getHeight()},
		}
	end

	-- T_SEAT_MINE
	local hw, hh= self.handSizes[T_SEAT_MINE][1], self.handSizes[T_SEAT_MINE][2]
	local sw, sh = self.showSizes[T_SEAT_MINE][1], self.showSizes[T_SEAT_MINE][2]
	local handw = self.szHandWnd[T_SEAT_MINE][1]
	local totalw = (HAND_CNT + 1) * hw + hw*GAP_RATE
	if totalw > handw then
		local nw = handw / ((HAND_CNT + 1) / GAP_RATE + 1) / GAP_RATE
		local scale = nw / hw
		local nhw = hw * scale
		local nhh = hh/hw*nhw
		local nsw = sw * scale
		local nsh = sh/sw*nsw
		self.handSizes[T_SEAT_MINE] = {nhw, nhh}
		self.showSizes[T_SEAT_MINE] = {nsw, nsh}
--		self.wnd_hand_0:setSize(nhw, nhh)
		self.szHandWnd[T_SEAT_MINE] = {self.wnd_hand_0:getWidth(), self.wnd_hand_0:getHeight()}
	end

	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local w, h = self.handSizes[i][1], self.handSizes[i][2] * VERTICAL_DIFF_RATE
		local hw, hh = self.szHandWnd[i][1], self.szHandWnd[i][2]
		if i == T_SEAT_MINE then
			self.handPos[i] = (hw - (HAND_CNT + 1) * w - w * GAP_RATE) / 2
		elseif i == T_SEAT_OPP then
			self.handPos[i] = (hw - (HAND_CNT + 1) * w - w * GAP_RATE) / 2 + w + w*GAP_RATE
		else
			self.handPos[i] = (hh - (HAND_CNT + 1) * h - h * GAP_RATE) / 2
		end
	end

	for i = T_SEAT_MINE, T_SEAT_LEFT do
		if self.discardParent[i] then
			self.discardParent[i]:setParent(nil)
		end
		local showw, showh = self:getDiscardSize(i)
		local szHandw = self.szHandWnd[i][1]
		local szHandh = self.szHandWnd[i][2]
		local pos = self.handPos[i]
		if i == T_SEAT_MINE then
			if showw * MAX_DISCARD_CNT_PER_LINE <= szHandw * 2 / 3 then
				self.discardCntPerLine[i] = MAX_DISCARD_CNT_PER_LINE
			else
				self.discardCntPerLine[i] = math.floor(szHandw * 2 / 3 / showw)
			end
			local h = 2
			local yh = 2
			if isTwoPlayers then
				h = 1.8
				yh = 2.2
			elseif self.playerCount == 4 then
				h = 1.8
				yh = 1.5
				if self:isOverLen() then
					h =  1.45
					yh = 2.8
				end
			end
			local x = (szHandw - showw * self.discardCntPerLine[i]) / h
			local wnd = pWindow:new()
			wnd:setColor(0)
			wnd:setParent(self.wnd_hand_0)
			wnd:setAlignY(ALIGN_BOTTOM)
			wnd:setPosition(x, 0)
			wnd:setZ(0)
			wnd:setRY(szHandh + showh/yh)
			wnd:setSize(showw * self.discardCntPerLine[i], showh*2)
			self.discardParent[i] = wnd
		elseif i == T_SEAT_RIGHT then
			if showh * MAX_DISCARD_CNT_PER_LINE <= szHandh * 2 / 3 then
				self.discardCntPerLine[i] = MAX_DISCARD_CNT_PER_LINE
			else
				self.discardCntPerLine[i] = math.floor(szHandh * 2 / 3 / showh)
			end
			local h = -30

			if isThreePlayers then
				h = -5
			end
			local y = (szHandh - showh * self.discardCntPerLine[i]) / h
			local wnd = pWindow:new()
			wnd:setColor(0)
			wnd:setParent(self.wnd_hand_1)
			wnd:setAlignX(ALIGN_RIGHT)
			wnd:setRX(showw + showw/5)
			wnd:setPosition(0, y)
			wnd:setSize(showw * 2, showw * self.discardCntPerLine[i])
			self.discardParent[i] = wnd
		elseif i == T_SEAT_OPP then
			if showw * MAX_DISCARD_CNT_PER_LINE <= szHandw  or isTwoPlayers then
				self.discardCntPerLine[i] = MAX_DISCARD_CNT_PER_LINE
			else
				self.discardCntPerLine[i] = math.floor(szHandw * 2 / 3 / showw)
			end
			local hx = 2.3
			local hy = 2.5
			if self:isOverLen() then
				hx = 3
				hy = 3
			end
			local x = (szHandw - showw * self.discardCntPerLine[i]) / hx
			local wnd = pWindow:new()
			wnd:setColor(0)
			wnd:setParent(self.wnd_hand_2)
			wnd:setZ(-5)
			wnd:setAlignY(ALIGN_TOP)
			wnd:setPosition(x, showh + showh / hy)
			wnd:setSize(showw * self.discardCntPerLine[i], showh * 2)
			self.discardParent[i] = wnd
		else -- T_SEAT_LEFT
			if showh * MAX_DISCARD_CNT_PER_LINE <= szHandh * 2 / 3 then
				self.discardCntPerLine[i] = MAX_DISCARD_CNT_PER_LINE
			else
				self.discardCntPerLine[i] = math.floor(szHandh * 2 / 3 / showh)
			end
			local h = 1.2
			if isThreePlayers then
				h = 1.9
			elseif self.playerCount == 4 then
				h = 1.5
				if self:isOverLen() then
					h = 1.05
				end
			end
			local y = (szHandh - showh * self.discardCntPerLine[i]) / h
			local wnd = pWindow:new()
			wnd:setColor(0)
			wnd:setParent(self.wnd_hand_3)
			wnd:setPosition(showw + showw * -0.02, y)
			wnd:setSize(showw*2, showw * self.discardCntPerLine[i])
			self.discardParent[i] = wnd
		end
--		self.discardParent[i]:setColor(0xFFEEEE00)
	end


	-- 花牌
	local maxWidth = self:getMaxWidthCount()
	local maxHeight = self:getMaxHeightCount()
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		if self.flowerParent[i] then
			self.flowerParent[i]:setParent(nil)
		end
		local handWnd = self[sf("wnd_hand_%d", i)]
		local width, height = self:getDiscardSize(i)
		local wnd = pWindow:new()
		wnd:setColor(0)
		--		wnd:setColor(0xFFEEEE00)
		--		wnd:enableEvent(false)
		if handWnd then
			local disWnd = self.discardParent[i]
			wnd:setParent(disWnd)
			if i == T_SEAT_MINE then
				wnd:setSize(maxWidth * width, maxHeight * height)
				wnd:setAlignY(ALIGN_BOTTOM)
				local h = 1
				wnd:setPosition(- wnd:getWidth() * h, 0)
			elseif i == T_SEAT_RIGHT then
				local h = 1.02
				wnd:setSize(maxHeight * width, maxWidth * height)
				wnd:setAlignY(ALIGN_BOTTOM)
				wnd:setAlignX(ALIGN_RIGHT)
				wnd:setOffsetY(wnd:getHeight() * h)
			elseif i == T_SEAT_OPP then
				wnd:setSize(maxWidth * width, maxHeight * height)
				if isTwoPlayers then
					wnd:setParent(handWnd)
					wnd:setAlignY(ALIGN_CENTER)
					wnd:setOffsetY(wnd:getHeight() * 1.3)
					wnd:setPosition(handWnd:getWidth() - 1 * width, 0)
				else
					wnd:setPosition(disWnd:getWidth(), 0)
				end
			elseif i == T_SEAT_LEFT then
				wnd:setSize(maxHeight * width, maxWidth * height)
				wnd:setPosition(0, - height * maxWidth + maxWidth * 3.5)
			end
			self.flowerParent[i] = wnd
		end
	end
end


pBattlePanel.clearPlayerCardsBySeatId = function(self, seatId)
	if self.cardInfo[seatId] then
		if self.cardInfo[seatId][T_CARD_HAND] then
			for _, wnd in ipairs(self.cardInfo[seatId][T_CARD_HAND]["wnds"]) do
				wnd:setParent(nil)
			end
			self.cardInfo[seatId][T_CARD_HAND]["wnds"] = {}
		end
		if self.cardInfo[seatId][T_CARD_SHOW] then
			for _, wnd in ipairs(self.cardInfo[seatId][T_CARD_SHOW]["wnds"]) do
				wnd:setParent(nil)
			end
			self.cardInfo[seatId][T_CARD_SHOW]["wnds"] = {}
		end
		if self.cardInfo[seatId][T_CARD_SHOW_HIDE] then
			for _, wnd in ipairs(self.cardInfo[seatId][T_CARD_SHOW_HIDE]["wnds"]) do
				wnd:setParent(nil)
			end
			self.cardInfo[seatId][T_CARD_SHOW_HIDE]["wnds"] = {}
		end
		if self.cardInfo[seatId][T_CARD_HAND] then
			if self.cardInfo[seatId][T_CARD_HAND]["dealCard"] then
				for _, wnd in ipairs(self.cardInfo[seatId][T_CARD_HAND]["dealCard"]) do
					wnd:setParent(nil)
				end
				self.cardInfo[seatId][T_CARD_HAND]["dealCard"] = {}
			end
		end
		if self.cardInfo[seatId][T_CARD_FLOWER] then
			if self.cardInfo[seatId][T_CARD_FLOWER] then
				for _, wnd in ipairs(self.cardInfo[seatId][T_CARD_FLOWER]) do
					wnd:setParent(nil)
				end
				self.cardInfo[seatId][T_CARD_FLOWER] = {}
			end
		end
	end
end

pBattlePanel.clearAllPlayerCards = function(self)
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		self:clearPlayerCardsBySeatId(i)
		self:clearDiscardBySeatId(i)
	end
	if self.curChooseWnds then
		for _, wnd in pairs(self.curChooseWnds) do
			wnd:setParent(nil)
		end
		self.curChooseWnds = {}
	end
	self.wnd_undealt_card:show(false)
	self.wnd_reserved_card:show(false)
	self:initPiaoWndText(true)
	self:clearCombMenu()
	self:clearDiCardControls()
	self:clearShowCardControls()
	self.wnd_time:setText("")
	self:showPiaoWnd(false)
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local wnd = self[sf("hint_%d", i)]
		if wnd then
			wnd:show(false)
		end
	end
	self.wnd_time:setOffsetY(0)
end

pBattlePanel.clearCalculate = function(self)
	if modCalcPanel.pCalculatePanel:getInstance() then
		modCalcPanel.pCalculatePanel:instance():close()
	end
end

pBattlePanel.gameOverClear = function(self)
	if not modBattleMgr.getCurBattle():getIsCalculate() then return end
	self:clearAllPlayerCards()
	self:clearLouControls()
end

pBattlePanel.getIsZimoSort = function(self, comb)
	if not comb then return end
	local modUIUtil = import("ui/common/util.lua")
	return modUIUtil.getIsZimoComb(comb, player)
end

pBattlePanel.getIsShowHuTriggerCard = function(self)
	return
end

pBattlePanel.getIsHideAnGang = function(self)
	return
end

-- 更新面前的牌 包括明牌和手牌
pBattlePanel.updatePlayerFrontCards = function(self, player, isSelfDiscard)
	local modUIUtil = import("ui/common/util.lua")
	-- 明牌
	local combs = player:getAllCardsFromPool(T_POOL_SHOW)
	local combCnt = #combs
	local dealCards = player:getCurrentDealCard()
	local dealCnt = self:getCurGame():getDealCount()
	--logv("info", combs)
	local seatId = player:getSeat()
	if not isSelfDiscard then
		player:getHandPool():sort()
	end
	local hands = player:getAllCardsFromPool(T_POOL_HAND, seatId)
	local handCnt = #hands
	local maxCardCount = self:getCurGame():getMaxCardCount()
	local isTing = modUIUtil.getIsTing(player)
	local isVideoState = modBattleMgr.getCurBattle():getIsVideoState()
	local z = 0
	-- 先清除所有的牌
	self:clearPlayerCardsBySeatId(seatId)

	local handDiff = self:getHandDiff(seatId)
	local showDiff = self:getShowDiff(seatId)
	local handw, handh = self:getHandCardSize(seatId)
	local showw, showh = self:getShowCardSize(seatId)
	showh = showh * VERTICAL_DIFF_RATE
	local updateShowCards = function(spos)
		if combCnt <= 0 then
			return spos
		end

		-- comb间距
		-- 起始位置
		local pos = spos
		local returnPos = pos
		local gapBetweenComb = 0
		if seatId == T_SEAT_MINE or
			seatId == T_SEAT_OPP then
			gapBetweenComb = ((self.szHandWnd[seatId][1] - handw*(handCnt + 1) - handw*GAP_RATE) - combCnt*6*showw) / combCnt
			gapBetweenComb = math.min(math.max(gapBetweenComb, 0), showw/3)
		else
			gapBetweenComb = ((self.szHandWnd[seatId][2] - handh*(handCnt + 1) - handh*GAP_RATE) - combCnt*3*showh) / combCnt
			gapBetweenComb = math.min(math.max(gapBetweenComb, 0), showh/2)
		end
		-- combs排序
		combs = self:sortCombs(combs, seatId)

		-- 描画
		for combIndex, comb in pairs(combs) do
			-- 是否需要胡牌单独排序
			if comb.t == modGameProto.HU then
				if self:getIsZimoSort(comb)  then
					comb:huAndZimoSort()
				end
			end
			local cards = comb:getCards()
			local t = comb:getType()
			-- 明牌
			local showType = T_CARD_SHOW
			-- 暗杠显示盖牌
			if t == modGameProto.ANGANG then
				showType = T_CARD_SHOW_HIDE
			end
			-- 明牌位置后移
			if self:isMingCardComb(t) then
				local swidth, sheight = self:getShowCardSize(seatId)
				swidth, sheight = swidth * table.getn(cards), sheight * table.getn(cards)
				local hwidth, hheight = self:getHandCardSize(seatId)
				hwidth, hheight = hwidth * table.getn(cards), hheight * table.getn(cards)
				if seatId == T_SEAT_MINE or seatId == T_SEAT_OPP then
					pos = pos + (hwidth - swidth) / 2
				elseif table.getn(hands) == 0 and table.getn(combs) == 1 then
					if seatId == T_SEAT_LEFT then
						pos = pos + (hheight - sheight)	/ 5.6
					else
						pos = pos + (hheight - sheight) / 5.5
					end
				end
			end

			-- 录像显示明牌
			if isVideoState then
				showType = T_CARD_SHOW
			end
			local cnt = #cards
			local mx, my = 0, 0
			local isMid = false
			local cardCount = 0

			-- 胡牌清除弃牌浮标
			if comb.t == modGameProto.HU then
				-- 清除浮标
				self:clearDiscardMark()
				-- 清除高亮
				self:updateCardIsShow(-1, true)
			end
			if seatId == T_SEAT_MINE then
			--	pos = pos + (3 * self.handSizes[seatId][1] - 3  * self.showSizes[seatId][1]) / 2
			end
			for idx, card in ipairs(cards) do
				local cardId = card:getId()
				local wnd = nil
				cardCount = cardCount + 1
				-- 血战到底特殊处理
				if self:getIsShowHuTriggerCard() then
					-- 胡牌情况
					if  t == modGameProto.HU then
						-- 胡牌后别人不能看到摊牌 但能看到胡的那张触发牌
						if  seatId ~= T_SEAT_MINE then
							if idx ~= table.getn(cards) then
								cardId = 42
							end
						else
							showType = T_CARD_HAND
						end
					end
				end

				if idx > 3 and self:getCurGame():isGang(comb.t)  then
					cardCount = cardCount - 1
					-- 四张牌的comb
					-- 放一张在中间的牌上面且向上
					local midType = showType
					if self:getCurGame():isKoupaimode() then
						midType = T_CARD_SHOW_HIDE
					else
						if self:getIsHideAnGang() then
							if seatId == T_SEAT_MINE then
								midType = T_CARD_SHOW
							end
						else
							midType = T_CARD_SHOW
						end

					end
					wnd = self:newCardWnd(seatId, cardId, midType)
					isMid = true
				else
					wnd = self:newCardWnd(seatId, cardId, showType,t)
					if t == modGameProto.HU then
						--showDiff = self:getHandDiff(seatId) - 3.5
						showDiff = self:getHandDiff(seatId) - 3.5
						if seatId == T_SEAT_LEFT or seatId == T_SEAT_RIGHT then
							showDiff = self:getShowDiff(seatId) + 3.5
						end
					end
				end
				if isMid then
					local d = 0
					if seatId == T_SEAT_MINE or
						seatId == T_SEAT_OPP then
							wnd:setOffsetY(- showh * 1/2)
					else
						wnd:setOffsetX(0)
						wnd:setOffsetY(-wnd:getHeight() / 6)
						if seatId == T_SEAT_LEFT then
							d = -4
						else
							d = 10
						end
					end
					wnd:setPos(pos + showDiff + d)
				else
					wnd:setPos(pos + (idx - 1) * showDiff)
				end
				if tmp and tmp == comb then
					if idx == table.size(cards) then
						wnd:setPos(math.abs(wnd:getPos()) + wnd:getWidth() / 3)
					end
				end

				if seatId == T_SEAT_RIGHT then
					if isMid then
						z = -1
					end
					wnd:setZ(z)
				end
				z =z + 1
			end
			if seatId == T_SEAT_RIGHT then
				returnPos = returnPos + cardCount * (self.handSizes[seatId][1] - 3.5)
--				returnPos = returnPos + cardCount * ( 1.5)
			else
				returnPos = returnPos + cardCount * (self.handSizes[seatId][1] - 3.5)
			end
			pos = returnPos
		end
		return pos
	end

	-- 手牌间距
	local updateHandCards = function(spos)
		if #hands <= 0 then
			return spos
		end
		local isShowHandCard = not self.isShowReturn
		local showCardCount = self:getCombCardCount(combs)
		local handCardCount = table.getn(hands)
		local pos = spos
		local returnPos = pos
		local isMax = false
--[[		local cardIdToCount = {}
		if seatId == T_SEAT_MINE then
			self:setCardCountToList(cardIdToCount)
		end]]--
		-- 有人胡了左边下调一格
		for idx, card in pairs(hands) do
			local cardId = card:getId()
			local wnd = {}
			wnd = self:newCardWnd(seatId, cardId, T_CARD_HAND)
			wnd:setPos(pos)
--[[			-- 换三张高亮处理
			if seatId == T_SEAT_MINE then
				self:changeSanZhangEvent(wnd, cardIdToCount)
			end]]--
			if seatId == T_SEAT_RIGHT then
				wnd:setZ(z)
				z = z + 1
			end
			if handCardCount + showCardCount > maxCardCount - dealCnt then
				isMax = true
				if idx == handCardCount then
					if seatId == T_SEAT_MINE then
						wnd:setPos(pos + wnd:getWidth() /3)
					elseif seatId == T_SEAT_LEFT then
						wnd:setPos(pos + wnd:getHeight() / 3)
					elseif seatId == T_SEAT_OPP then
						wnd:setPos(pos + wnd:getWidth() / 3)
						returnPos = returnPos + 3.5
					elseif seatId == T_SEAT_RIGHT then
						wnd:setPos(pos + wnd:getHeight() / 3)
					end
					-- 预出牌 不显示最后一张拉出来的
					if isSelfDiscard then wnd:show(false) end
				end
			end
			pos = pos + self.handSizes[seatId][1]
			if idx ~= table.getn(hands) then
				pos = pos - 3.5
			end
		end
			returnPos = returnPos + table.getn(hands) * self.handSizes[seatId][1]
			returnPos = returnPos - table.getn(hands) * 3.5
		if isMax then
			if seatId == T_SEAT_OPP then
				returnPos = returnPos + 3.5
			elseif seatId == T_SEAT_RIGHT then
				returnPos = returnPos + 3.5
			end
			isMax = false
		end
		return returnPos
	end

	local startPos = self.handPos[seatId]
	local maxCardCount = self:getCurGame():getMaxCardCount()
	if seatId == T_SEAT_LEFT then
		startPos = startPos - self.handSizes[seatId][2] * 1.1
	elseif seatId == T_SEAT_RIGHT then
		startPos = - self.handSizes[seatId][2] * 0.2
	end
	local endPos = nil

	endPos = updateShowCards(startPos)
	endPos = updateHandCards(endPos)

	if seatId == T_SEAT_MINE then
		endPos = endPos + handw * GAP_RATE
	elseif seatId == T_SEAT_RIGHT then
		endPos = startPos + (handCnt + self:getCombCardCount(combs) ) * self.handSizes[seatId][1]
	elseif seatId == T_SEAT_OPP then
		endPos = startPos + (handCnt + self:getCombCardCount(combs) ) * self.handSizes[seatId][1]
	else
		endPos = endPos + handh * GAP_RATE
	end
	if self.cardInfo[seatId] and
		self.cardInfo[seatId][T_CARD_HAND] then
		self.cardInfo[seatId][T_CARD_HAND]["lastPos"] = endPos
	elseif not self.cardInfo[seatId] or not self.cardInfo[seatId][T_CARD_HAND]  then
		if not self.cardInfo[seatId] then
			self.cardInfo[seatId] = {}
		end
		self.cardInfo[seatId][T_CARD_HAND] = {
			wnds = {},
			lastPos = endPos,
			["dealCard"] = {}
		}
	end

	if not isSelfDiscard then
		self:updateCurrentDealedCard(player, z)
	end
	self:updateFlowerCards(player)
	self:updateAllPlayersTingCard()
	z = 0
end

pBattlePanel.isMingCardComb = function(self, t)
	if not t then return end
	return t == modGameProto.MING
end

pBattlePanel.hasMingCardComb = function(self, combs)
	if not combs then return end
	for _, comb in pairs(combs) do
		if self:isMingCardComb(comb.t) then
			return true
		end
	end
	return false
end

pBattlePanel.getCombId = function(self, id, combs)
	if not id or not combs then return end
	if not combs[id] then return end
	local t = combs[id]:getType()
	if self:isMingCardComb(t) then
		return id + 100
	end
	if t == modGameProto.HU then
		return id + 1000
	end
	return id
end

pBattlePanel.sortCombs = function(self, combs, seatId)
	if not combs then return end
	local cbs = {}
	local keys = table.keys(combs)
	table.sort(keys, function(k1, k2)
		k1 = self:getCombId(k1, combs)
		k2 = self:getCombId(k2, combs)
		return k1 < k2
	end)
	for _, key in pairs(keys) do
		table.insert(cbs, combs[key])
	end
	return cbs
end

pBattlePanel.isVideoLeftOrRight = function(self, seatId)
	return modBattleMgr.getCurBattle():getIsVideoState()
	and (seatId == T_SEAT_LEFT or seatId == T_SEAT_RIGHT)
end

pBattlePanel.getCombCardCount = function(self, combs, isGang)
	local showCardCount = 0
	for _,comb in pairs(combs) do
		if comb then
			for _,card in pairs(comb:getCards()) do
				showCardCount = showCardCount + 1
			end
			if comb.t == modGameProto.ANGANG or comb.t == modGameProto.XIAOMINGGANG or comb.t == modGameProto.DAMINGGANG then
				if not isGang then
					showCardCount = showCardCount - 1
				end
			end
		end
	end
	return showCardCount
end

pBattlePanel.getIsShowFlowerCard = function(self)
	return true
end

pBattlePanel.updateFlowerCards = function(self, player)
	local seatId = player:getSeat()
	if self.cardInfo[seatId] then
		if self.cardInfo[seatId][T_CARD_FLOWER] then
			if self.cardInfo[seatId][T_CARD_FLOWER] then
				for _, wnd in ipairs(self.cardInfo[seatId][T_CARD_FLOWER]) do
					wnd:setParent(nil)
				end
				self.cardInfo[seatId][T_CARD_FLOWER] = {}
			end
		end
	end

	local cards = player:getAllCardsFromPool(T_POOL_FLOWER)
	local x, y = 0, 0
	local width, height = self:getDiscardSize(seatId)
	local maxWidth = self:getMaxWidthCount()
	local maxHeight = self:getMaxHeightCount()
	if table.getn(cards) > 0 then
		local pWnd = self.flowerParent[seatId]
		local dw, dh = 0, 0
		for idx, card in ipairs(cards) do
			local cardId = card:getId()
			local st = T_CARD_SHOW
			if not self:getIsShowFlowerCard() then
				st = T_CARD_SHOW_HIDE
			end
			local wnd = self:newCardWnd(seatId, cardId, st)
			wnd:setParent(pWnd)
			wnd:setSize(width, height)
			wnd:setAlignX(ALIGN_LEFT)
			wnd:setAlignY(ALIGN_TOP)
			local guiWnd = wnd:getGuiMark()
			if guiWnd then
				guiWnd:setSize(100 * 0.7 * 0.53, 139 * 0.7 * 0.53)
			end
			if seatId == T_SEAT_MINE or seatId == T_SEAT_OPP then
				wnd:setPosition(x * (width - 3.5), y * (height - dh))
				if seatId == T_SEAT_MINE then
					wnd:setAlignY(ALIGN_BOTTOM)
					wnd:setOffsetY(-y * (height - dh * 5))
					wnd:setZ(idx)
					dw, dh = 3.5, 2.5
				elseif seatId == T_SEAT_OPP then
					wnd:setAlignX(ALIGN_RIGHT)
					wnd:setOffsetX(- x * (width - 3.5))
					dw, dh = 3.5, 12
				end
				x = x + 1
				if x >= maxWidth then
					x = 0
					y = y + 1
				end
			else
				dw, dh = 2, 12
				wnd:setPosition((y) * (width - dw), x * (height - dh))
				if seatId == T_SEAT_RIGHT then
					dh = 15
					dw = 3
					wnd:setAlignX(ALIGN_RIGHT)
					wnd:setOffsetX(- y * (width - dw))
					wnd:setPosition(0, (maxWidth - x - 1) * (height - dh))
					wnd:setZ(idx)
				end
				x = x + 1
				if x >= maxWidth then
					x = 0
					y = y + 1
				end
			end
		end
	end
end

pBattlePanel.updateCurrentDealedCard = function(self, player, rz)
	local modUIUtil = import("ui/common/util.lua")
	local seatId = player:getSeat()
	if self.cardInfo[seatId] then
		if self.cardInfo[seatId][T_CARD_HAND] then
			if self.cardInfo[seatId][T_CARD_HAND]["dealCard"] then
				for _, wnd in ipairs(self.cardInfo[seatId][T_CARD_HAND]["dealCard"]) do
					wnd:setParent(nil)
				end
				self.cardInfo[seatId][T_CARD_HAND]["dealCard"] = {}
			else
				self.cardInfo[seatId][T_CARD_HAND]["dealCard"] = {}
			end
		end
	end
	local cards = player:getCurrentDealCard()
	local pos = 0
	local z = rz

	if not self.dealEffects then self.dealEffects = {} end
	for _, effect in pairs(self.dealEffects) do
		effect:stop()
	end
	self.dealEffects = {}
	if table.getn(cards) > 0 then
		for idx, card in pairs(cards) do
			local cardId = card:getId()
			local wnd = self:newCardWnd(seatId, cardId, T_CARD_HAND)
			if seatId == T_SEAT_RIGHT then
				wnd:setZ(z)
				z = z + 1
			end
			if self.cardInfo[seatId][T_CARD_HAND]["lastPos"] then
				pos = self.cardInfo[seatId][T_CARD_HAND]["lastPos"]
			end
			pos = pos + wnd:getWidth() * (idx - 1) - 3.5 * (idx - 1)
			wnd:setPos(pos)
			-- 渐显
--			wnd:setAlpha(0)
--			local effect  = modUIUtil.fadeIn(wnd, 5)
			table.insert(self.dealEffects, effect)
--			if wnd.magicCardWnd then
--				wnd.magicCardWnd:setAlpha(0)
--				modUIUtil.fadeIn(wnd.magicCardWnd, 5)
--			end
			if seatId == T_SEAT_RIGHT then
				local maxCardCount = self:getCurGame():getMaxCardCount()
				if table.getn(cards) < maxCardCount - 1 then
					wnd:setPos(pos - wnd:getWidth() * 0.6)
				end
			elseif seatId == T_SEAT_OPP then
				wnd:setPos(pos)
				local maxCardCount = self:getCurGame():getMaxCardCount()
				if table.getn(cards) < maxCardCount - 1 then
					wnd:setPos(pos - wnd:getWidth() * 0.5)
				end
			elseif seatId == T_SEAT_MINE then
				--			wnd:setPos(pos + wnd:getWidth() / 3)
			end
			table.insert(self.cardInfo[seatId][T_CARD_HAND]["dealCard"], wnd)
--			self:setCurrDiscardCard(cardId, self.)
		end
	end
end

pBattlePanel.updateDiscardByCardId = function(self, cardId,  cardType, isClear)
	if cardId or isClear then
		for i = 0, 4 do
			if self.cardInfo[i] then
				if self.cardInfo[i][cardType] then
					for _, card in pairs(self.cardInfo[i][cardType]["wnds"]) do
						if self:findCardIsInList(card, self.isNotChangeColorWnds) then
						else
							if isClear then
								if not card:isOnChoose() then
									card:setColor(0xFFFFFFFF)
								end
							else
								if not card:isOnChoose() then
									if card:getCardId() == cardId then
										if card:getShowType() == T_CARD_HAND then
											if i == T_SEAT_MINE then
												card:setColor(0xFFEEEE00)
											else
												card:setColor(0xFFFFFFFF)
											end
										else
											card:setColor(0xFFEEEE00)
										end

									else
										card:setColor(0xFFFFFFFF)
									end
								end
							end
						end
					end

				end

			end
		end
	end
end

pBattlePanel.updateAllPlayersTingCard = function(self)
	for seatId, player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
		self:updateTingCardColor(player:getSeat())
	end
end

pBattlePanel.updateTingCardColor = function(self, seatId)
	local modUIUtil = import("ui/common/util.lua")
	local i = seatId
	local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
	local isTing  = modUIUtil.getIsTing(player)
	if not isTing then
		return
	end

	local cardCount = 0
	if self.cardInfo[i] then
		if self.cardInfo[i][T_CARD_HAND] then
			for _, card in pairs(self.cardInfo[i][T_CARD_HAND]["wnds"]) do
				local color = card:getColor()
				if color ~= 0xFFEEEE00 and card:getAlpha() == 255 then
					card:setColor(tingColor)
				end
			end
		end
	end
end

pBattlePanel.setTingColorCard = function(self, ids, isOneTime)
	if not ids then return end
	local wnds = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
	for _, id in pairs(ids) do
		for _, wnd in pairs(wnds) do
			if id == wnd or wnd:getCardId() == id  then
				wnd:setColor(tingColor)
				if isOneTime then
					break
				end
			end
		end
	end
end

pBattlePanel.notInDiscardListSetTingColor = function(self)
	local canIds = self:getCurGame():getCanDiscardCardIds()
	if not canIds or table.getn(canIds) <= 0 then return end
	local hands = self:getCurGame():getCurPlayer():getAllCardsFromPool(T_POOL_HAND)
	local deals = self:getCurGame():getCurPlayer():getCurrentDealCard()
	local ids = {}
	if not canIds or table.getn(canIds) <= 0 then return end
	for _, hcard in pairs(hands) do
		if not self:findCardIsInListByParent(hcard, canIds) then
			table.insert(ids, hcard:getId())
		end
	end
	for _, dcard in pairs(deals) do
		if not self:findCardIsInListByParent(dcard, canIds) then
			table.insert(ids, dcard:getId())
		end
	end
	self:setTingColorCard(ids)
end

pBattlePanel.findCardIsInListByParent = function(self, card, ids)
	if not card or not ids then return end
	for _, id in pairs(ids) do
		if  card == id or card:getId() == id then
			return true
		end
	end
	return false
end

pBattlePanel.findNotChooseWndSetTingColor = function(self)
	if not modBattleMgr.getCurBattle():isPhaseHuanSanZhang() then return end
	if not self.curChooseWnds or table.size(self.curChooseWnds) <= 0 then return end
	local canNotChooseWnds = {}
	local findFromCard = nil
	for _, c in pairs(self.curChooseWnds) do
		if not findFromCard then
			findFromCard = c
			break
		end
	end
	local nums = nil
	if not findFromCard then return end
	nums = self:getHuaseFromCard(findFromCard)
	if not nums then return end
	local wnds = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
	for _, wnd in pairs(wnds) do
		if wnd:getCardId() < nums[1] or wnd:getCardId() > nums[2] then
			table.insert(canNotChooseWnds, wnd)
		end
	end
	self:setTingColorCard(canNotChooseWnds)
end

pBattlePanel.getHuaseFromCard = function(self, card)
	if not card then return end
	local id = card:getCardId()
	local numbers = self:getCurGame():getHuaSeFanWei()
	local nums = {}
	for _, ns in pairs(numbers) do
		if id >= ns[1] and id <= ns[2] then
			return ns
		end
	end
	return nil
end

pBattlePanel.getAllCardWnds = function(self, seatId, cardType, names)
	if not seatId or not cardType then return end
	if self.cardInfo[seatId] then
		if self.cardInfo[seatId][cardType] then
			return self.cardInfo[seatId][cardType][names or "wnds"]
		end
	end
	return nil
end


pBattlePanel.updateCardIsShow = function(self, cardId, isClear)
	self:updateDiscardByCardId(cardId, T_CARD_DISCARD, isClear)
	self:updateDiscardByCardId(cardId, T_CARD_SHOW, isClear)
	self:updateDiscardByCardId(cardId, T_CARD_HAND, isClear)
end

pBattlePanel.clearDiscardBySeatId = function(self, seatId)
	if self.cardInfo[seatId] then
		if self.cardInfo[seatId][T_CARD_DISCARD] then
			for _, wnd in ipairs(self.cardInfo[seatId][T_CARD_DISCARD]["wnds"]) do
				wnd:setParent(nil)
			end
			self.cardInfo[seatId][T_CARD_DISCARD]["wnds"] = {}
		end
	end
end

pBattlePanel.updatePlayerDiscardCards = function(self, player)
	local discards = player:getAllCardsFromPool(T_POOL_DISCARD)
	local seatId = player:getSeat()
	local parent = modBattleMgr.getCurBattle():getBattleUI().discardParent[seatId]
	local perlineCnt = self.discardCntPerLine[seatId]
	local showDiff = self:getDiscardDiff(seatId)
	local w, h = self:getDiscardSize(seatId)
	local discardIndex = player:getDiscardIndex()
	-- 清除弃牌
	self:clearDiscardBySeatId(seatId)

	local sx, sy = -1, -1
	local diffx, diffy = -1, -1
	if seatId == T_SEAT_MINE then
		sx = 0
		sy = parent:getHeight() - h
		diffx = w
		diffy = 0
	elseif seatId == T_SEAT_RIGHT then
		sx = parent:getWidth() - w
		sy = parent:getHeight() - h
		diffx = 0
		diffy = - showDiff + 2.5
	elseif seatId == T_SEAT_OPP then
		sx = parent:getWidth() - w
		sy = 0
		diffx = - showDiff
		diffy = 0
	else
		sx = 0
		sy = 0
		diffx = 0
		diffy = showDiff
	end
	local x, y = sx, sy
	local z = -100
	local lineCnt = 1

	-- 弃牌
	for idx, card in pairs(discards) do
		local cardId = card:getId()
		local t = T_CARD_DISCARD
		if self:getCurGame():isKoupaimode() then
			-- 不存在的牌42, 显示为盖牌
			cardId = 42
		end
		local wnd = self:newCardWnd(seatId, cardId, t)
		wnd:setAlignX(ALIGN_LEFT)
		wnd:setAlignY(ALIGN_TOP)
		wnd:setSize(w, h)
		wnd:setParent(parent)
		wnd:setPosition(x, y)
		-- 特殊弃牌变色
		if discardIndex and discardIndex > 0 then
			if idx == discardIndex then
				wnd:setColor(0xFFFFA07A)
				self.isNotChangeColorWnds = {}
				table.insert(self.isNotChangeColorWnds, wnd)
			end
		end

		if idx == table.size(discards)  then
			if self.discardMarkId then
				if self:isDrawDiscardMark(discards, cardId, idx, player:getSeat()) then
					self:discardMark(wnd)
				end
			else
				self:discardMark(wnd)
			end
		end
		wnd:setZ(z)
		if seatId == T_SEAT_LEFT or
			seatId == T_SEAT_OPP then
			z = z - 1
		else
			z = z + 1
		end
		x = x + diffx
		y = y + diffy
		lineCnt = lineCnt + 1
		if lineCnt > perlineCnt then
			local rate = 4/5
			if seatId == T_SEAT_MINE then
				x = sx
				y = y - h*rate
			elseif seatId == T_SEAT_RIGHT then
				x = x - w + 2
				y = sy
			elseif seatId == T_SEAT_OPP then
				x = sx
				y = y + h*rate
			else
				x = x + w - 2
				y = sy
			end
			lineCnt = 1
		end
		if seatId == T_SEAT_MINE and idx % MAX_DISCARD_CNT_PER_LINE ~= 0 then
			x = x - 2.7
		elseif seatId == T_SEAT_LEFT and idx % MAX_DISCARD_CNT_PER_LINE ~= 0 then
--			x = x - 0.3
		elseif seatId == T_SEAT_RIGHT and idx % MAX_DISCARD_CNT_PER_LINE ~= 0 then
--			x = x + 0.3
		elseif seatId == T_SEAT_OPP and idx % MAX_DISCARD_CNT_PER_LINE ~= 0 then
			x = x + 4.7
		end
	end
end

pBattlePanel.isDrawDiscardMark = function(self, discards, cardId, idx, seatId)
	if not self.discardMarkId or not self.curDiscardSeatId then
		return false
	end

	local isCardId = false
	local isLast = false
	local isSeat = false

	if self.discardMarkId == cardId then
		isCardId = true
	end
	if idx == table.size(discards) then
		isLast = true
	end
	if seatId == self.curDiscardSeatId then
		isSeat = true
	end
	if seatId == T_SEAT_MINE then
		if self:getCurGame():getIsCanDiscardCard() then
			return false
		end
	end
	return isCardId and isLast and isSeat
end

-- showType: T_CARD_HAND OR T_CARD_SHOW
pBattlePanel.newCardWnd = function(self, seatId, cardId, showType, combType, z)
	local w, h = self:getCardSize(seatId, showType)
	-- 录像摊牌
	local st = showType
	if modBattleMgr.getCurBattle():getIsVideoState() and showType == T_CARD_HAND then
		st = T_CARD_SHOW
		if seatId == T_SEAT_LEFT or seatId == T_SEAT_RIGHT then
			w, h = self:getCardSize(seatId, st)
			w, h = w * 1.1, h * 1.1
		end
	end

	-- 胡
	if showType == T_CARD_SHOW and (combType == modGameProto.HU ) then
		w, h = self:getCardSize(seatId, T_CARD_HAND)
		if seatId == T_SEAT_LEFT or seatId == T_SEAT_RIGHT then
			w, h = self:getCardSize(seatId, T_CARD_SHOW)
			w, h = w * 1.1, h * 1.1
		end
	end

	local modCardWnd = import("ui/battle/card.lua")
	local wnd = modCardWnd.pCardWnd:new(seatId, cardId, w, h, st, self, self:getCurGame():getMagicCard(), showType)
	wnd:setParent(self[sf("wnd_hand_%d", seatId)])
	if seatId == T_SEAT_OPP then
		wnd:setAlignY(ALIGN_MIDDLE)
		if showType ~= T_CARD_DISCARD then
			wnd:setAlignX(ALIGN_RIGHT)
		end
	elseif seatId == T_SEAT_MINE then
		wnd:setAlignY(ALIGN_BOTTOM)
	elseif seatId == T_SEAT_RIGHT then
		wnd:setAlignX(ALIGN_CENTER)
		if z then
			wnd:setZ(z)
		end
		if showType ~= T_CARD_DISCARD then
			wnd:setAlignY(ALIGN_BOTTOM)
		end
	else
		wnd:setAlignX(ALIGN_CENTER)
	end
	if not self.cardInfo[seatId] then
		self.cardInfo[seatId] = {}
	end
	if not self.cardInfo[seatId][showType] then
		self.cardInfo[seatId][showType] = {
			wnds = {},
			lastPos = -1,
			["dealCard"] = {}
		}
	end
	table.insert(self.cardInfo[seatId][showType]["wnds"], wnd)
	if seatId == T_SEAT_MINE then
		wnd:setZ(-5)
	else
		wnd:setZ(-1)
	end
	return wnd
end


pBattlePanel.initUI = function(self)
	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_BATTLE_UI_Z)
	-- 设置窗口位置
	self:initSetWindow()
	-- 未开始战斗记录icon位置
	self:initIconPos()
	-- 初始化@全体离线玩家
	self:initBtnTell()
	-- 更新@全体离线玩家
	self:updateBtnTell()
	-- 电量
	if app.getBatteryLevel then
		self:updateBatteryLevel(app:getBatteryLevel())
	end
	if app.getBatteryStatus then
		self:updateBatteryStatus(app:getBatteryStatus())
	end
end

pBattlePanel.initBtnTell = function(self)
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local btn = self[sf("btn_role_%d_tell", i)]
		if btn then
			btn:show(false)
			btn:addListener("ec_mouse_click", function()
				self:tellClick(i)
			end)
		end
	end
end

pBattlePanel.updateBtnTell = function(self)
	local playerOnlineInfos = modBattleMgr.getCurBattle():getPlayerOnlineInfos()
	local seatToUid = modBattleMgr.getCurBattle():getSeatToUid()

	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local uid = seatToUid[i]
		local btn = self[sf("btn_role_%d_tell", i)]
		if not modBattleMgr.getCurBattle():getIsGaming() then
			btn:show(false)
		else
			if uid and playerOnlineInfos[uid] then
				btn:show(false)
			else
				btn:show(true)
			end
		end
	end
end

pBattlePanel.tellClick = function(self, i)
	if not i then return end
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	local player = players[i]
	if not players or not player then return end
	local roomId = sf("%06d", modBattleMgr.getCurBattle():getRoomId())
	local text = "房号【" .. roomId .. "】开牌啦，快进入游戏吧！"
	local name = "@" .. player:getName() .. " "
	if puppy.sys.shareWeChatText then
		puppy.sys.shareWeChatText(2, TEXT(name .. text))
	end
	log("info", name .. text)
end

pBattlePanel.setIconPos = function(self, name, value)
	if not self.iconPos[name] then
		self.iconPos[name] = value
	end
end

pBattlePanel.saveIcon = function(self, wnd, name)
	local values = {
		["x"] = wnd:getOffsetX(),
		["y"] = wnd:getOffsetY(),
		["bgw"] = wnd:getWidth(),
		["bgh"] = wnd:getHeight(),
		["fs"] = wnd:getTextControl():getFontSize(),
		["img"] = wnd:getTexturePath()
	}
	local strs = string.split(name, ";")
	for _, s in pairs(strs) do
		local value = values[s]
		self:setIconPos(wnd:getName() .. s, value)
	end
end

pBattlePanel.initIconPos = function(self)
	if not self.isResetState then return end
	local scale = 1.3
	self.wnd_rule_bg:setPosition(0, -2)
	--	local rightTell = self[sf("btn_role_%d_tell", 1)]
	--	self:saveIcon(rightTell, "x;img")
	for i = 0,3 do
		local distace = gGameHeight * 0.25
		local imageBottom = self[sf("wnd_role_%d_bottom", i)]
		local imageWnd = self[sf("wnd_role_%d", i)]
		local imageFront = self[sf("wnd_role_%d_front", i)]
		local nameWnd = self[sf("wnd_role_%d_name", i)]
		local scoreWnd = self[sf("wnd_role_%d_score", i)]
		local wnd = self[sf("wnd_role_%d_bg",i)]
		-- 保存坐标和大小
		self:saveIcon(wnd, "x;y")
		self:saveIcon(wnd, "bgw;bgh")
		self:saveIcon(imageBottom, "bgw;bgh")
		self:saveIcon(imageWnd, "bgw;bgh")
		self:saveIcon(imageFront, "bgw;bgh")
		self:saveIcon(nameWnd, "y;bgw;bgh;fs")
		self:saveIcon(scoreWnd, "y;bgw;bgh;fs")
		self.iconPos[self.wnd_rule_bg:getName() .. "y"] = -2
		wnd:setAlignX(ALIGN_CENTER)
		wnd:setAlignY(ALIGN_MIDDLE)
		wnd:setOffsetX(0)
		wnd:setOffsetY(0)
		wnd:setParent(self.wnd_table)
		-- 放大
		wnd:setSize(wnd:getWidth() * scale, wnd:getHeight() * scale)
		imageWnd:setSize(imageWnd:getWidth() * scale, imageWnd:getHeight() * scale)
		imageBottom:setSize(imageWnd:getWidth() * 1.1, imageWnd:getHeight() * 1.1)
		imageFront:setSize(imageBottom:getWidth(), imageBottom:getHeight())
		nameWnd:setSize(nameWnd:getWidth() * scale, nameWnd:getHeight() * scale)
		scoreWnd:setSize(scoreWnd:getWidth() * scale, scoreWnd:getHeight() * scale)
		nameWnd:getTextControl():setFontSize(nameWnd:getTextControl():getFontSize() * scale)
		scoreWnd:getTextControl():setFontSize(scoreWnd:getTextControl():getFontSize() * scale)
		nameWnd:setOffsetY(nameWnd:getHeight() * (scale - 1))
		scoreWnd:setOffsetY(scoreWnd:getRY() - scoreWnd:getRY() * (scale))
		if i == 0 then
			wnd:setOffsetY(distace)
		elseif i == 1 then
			wnd:setOffsetX(distace * 2)
		elseif i == 2 then
			wnd:setOffsetY(-distace)
		elseif i == 3 then
			wnd:setOffsetX(-distace * 2)
		end
	end
	self.isResetState = false
end

pBattlePanel.updateSeat = function(self)
	local maxPlayerCount = self.param[K_ROOM_INFO].max_number_of_users
	if maxPlayerCount == 2 then
		self:updateSeatByPlayerCount(1,2)
	elseif maxPlayerCount == 3 then
		self:updateSeatByPlayerCount(2,3)
	end
end

pBattlePanel.showSeat = function(self)
	for i = 0, 3 do
		local wnd = self[sf("wnd_role_%d_bg",i)]
		local wnd_hand = self[sf("wnd_hand_%d", i)]
		if modBattleMgr.getCurBattle():getAllPlayers()[i] then
			wnd:show(true)
			wnd_hand:enableEvent(true)
		else
			wnd:show(false)
			wnd_hand:enableEvent(false)
		end
	end
end

pBattlePanel.showPlus = function(self)
	for i = 0, 3 do
		local wnd = self[sf("btn_role_%d_plus",i)]
		if modBattleMgr.getCurBattle():getAllPlayers()[i] then
			wnd:show(false)
		else
			wnd:show(true)
		end
	end
end

pBattlePanel.updatePlusBySeatId = function(self, seatId, isShow)
	local wnd = self[sf("btn_role_%d_plus", seatId)]
	if wnd then
		wnd:show(isShow)
	end
end

pBattlePanel.showScore = function(self)
	for i = 0, 3 do
		local wnd = self[sf("wnd_role_%d_score",i)]
		local player = modBattleMgr.getCurBattle():getAllPlayers()[i]
		if i == 0 or player then
			wnd:show(true)
			if player then
				wnd:setText(player:getScore())
			else
				wnd:setText(0)
			end
		else
			wnd:show(false)
		end
	end
end
pBattlePanel.showPlayerBg = function(self)
	for i = 0, 3 do
		local wnd = self[sf("wnd_role_%d_bg",i)]
		if i == 0 or modBattleMgr.getCurBattle():getAllPlayers()[i] then
			wnd:setColor(0xFFFFFFFF)
			wnd:show(true)
		else
			wnd:setColor(0)
		end
	end
end

pBattlePanel.showNickName = function(self)
	local modUIUtil = import("ui/common/util.lua")
	for i = 0, 3 do
		local wnd = self[sf("wnd_role_%d_name",i)]
		if i == 0 or modBattleMgr.getCurBattle():getAllPlayers()[i] then
			if modBattleMgr.getCurBattle():getAllPlayers()[i]:getName() then
				local name = modBattleMgr.getCurBattle():getAllPlayers()[i]:getName()
				if modUIUtil.utf8len(name) > 6 then
					name = modUIUtil.getMaxLenString(name, 6)
				end
				wnd:setText(name)
			else
				modBattleMgr.getCurBattle():getAllPlayers()[i]:updateUserProps(modBattleMgr.getCurBattle():getAllPlayers()[i]:getUid(),i)
			end
			wnd:show(true)
		else
			wnd:setText("")
			wnd:show(false)
		end
	end
end

pBattlePanel.clearWndByName = function(self,wndName, isAll)
	for i = 0, 3 do
		if not modBattleMgr.getCurBattle():getAllPlayers()[i] or isAll then
			local wnd = self[sf(wndName,i)]
			if wnd then
				wnd:setParent(nil)
			end
		end
	end
end

pBattlePanel.updateSeatByPlayerCount = function(self,index1,index2)
	local wndIndex1 = self[sf("wnd_role_%d_bg",index1)]
	local wndIndex2 = self[sf("wnd_role_%d_bg",index2)]
	wndIndex1:setOffsetX(wndIndex2:getOffsetX())
	wndIndex1:setOffsetY(wndIndex2:getOffsetY())
end

pBattlePanel.resetIconWnd = function(self, wnd)
	if self.iconPos[wnd:getName() .. "x"] then
		wnd:setOffsetX(self.iconPos[wnd:getName() .. "x"])
	end
	if self.iconPos[wnd:getName() .. "y"] then
		wnd:setOffsetY(self.iconPos[wnd:getName() .. "y"])
	end
	if self.iconPos[wnd:getName() .. "bgw"]  then
		wnd:setSize(self.iconPos[wnd:getName() .. "bgw"], wnd:getHeight())
	end
	if self.iconPos[wnd:getName() .. "bgh"] then
		wnd:setSize(wnd:getWidth(), self.iconPos[wnd:getName() .. "bgh"])
	end

	if self.iconPos[wnd:getName() .. "fs"] then
		wnd:getTextControl():setFontSize(self.iconPos[wnd:getName() .. "fs"])
	end

	if self.iconPos[wnd:getName() .. "img"] then
		wnd:setImage(self.iconPos[wnd:getName() .. "img"])
	end
end

pBattlePanel.resetIconPos = function(self)
	if not self.iconPos or table.size(self.iconPos) <= 0 then return end
	self.wnd_rule_bg:setColor(0)
--	local rightTell = self[sf("btn_role_%d_tell", 1)]
--	self:resetIconWnd(rightTell)
	for i = 0, 3 do
		local wnd = self[sf("wnd_role_%d_bg",i)]
		local parent = self[sf("wnd_hand_%d",i)]
		local imageBottom = self[sf("wnd_role_%d_bottom", i)]
		local imageWnd = self[sf("wnd_role_%d", i)]
		local imageFront = self[sf("wnd_role_%d_front", i)]
		local nameWnd = self[sf("wnd_role_%d_name", i)]
		local scoreWnd = self[sf("wnd_role_%d_score", i)]
		wnd:setParent(parent)
		self:resetIconWnd(wnd)
		self:resetIconWnd(imageBottom)
		self:resetIconWnd(imageWnd)
		self:resetIconWnd(imageFront)
		self:resetIconWnd(nameWnd)
		self:resetIconWnd(scoreWnd)
		self.wnd_rule_bg:setPosition(0, self.iconPos[self.wnd_rule_bg:getName() .. "y"])

		if i == 0 then
			wnd:setAlignX(ALIGN_LEFT)
			wnd:setAlignY(ALIGN_BOTTOM)
		elseif i == 1 then
			wnd:setAlignX(ALIGN_RIGHT)
			wnd:setAlignY(ALIGN_CENTER)
		elseif i == 2 then
			wnd:setAlignX(ALIGN_RIGHT)
			wnd:setAlignY(ALIGN_CENTER)
		elseif i == 3 then
			wnd:setAlignX(ALIGN_LEFT)
			wnd:setAlignY(ALIGN_CENTER)
		end
	end
	self:showSeat()
	self.isResetState = true
end

pBattlePanel.showPiaoWnd = function(self, isShow)
	for i = 0, 3 do
		local wnd = self[sf("wnd_piao_%d", i)]
		if self:getCurGame():getRuleType() == 14 then
			if wnd then
				wnd:show(false)
			end
		else
			if wnd then
				wnd:show(isShow)
			end
		end
	end
end

pBattlePanel.showPiaoWndBySeatId = function(self, seatId, isShow)
	if not seatId then return end
	local wnd = self[sf("wnd_piao_%d", seatId)]
	if wnd then
		wnd:show(isShow)
	end
end

pBattlePanel.initPiaoWndText = function(self, isInit, isHasValue)
	if isInit then
		for i = 0, 3 do
			self:setPiaoText(i, isHasValue or -1)
		end
	end
end

pBattlePanel.updatePlayerPiaoWnds = function(self)
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	if not players then return end
	for _, player in pairs(players) do
		local flags = player:getFlags()
		for _, f in pairs(flags) do
			if self:getCurGame():isPiaoCase(f) then
				self:setPiaoText(player:getSeat(), f)
			end
		end
	end
end

pBattlePanel.changePiaoWndProp = function(self, seatId, value)
	return
end

pBattlePanel.setPiaoText = function(self, seatId, value)
	if seatId and value then
		local wnd = self[sf("wnd_piao_%d", seatId)]
		local modUIUtil = import("ui/common/util.lua")
		local image = modUIUtil.getPiaoImage(self:getCurGame():getRuleType(), value)
		if wnd and image then
			wnd:show(true)
			wnd:setImage(image)
			wnd:setColor(0xFFFFFFFF)
			-- 是否改变飘的图片和大小
			self:changePiaoWndProp(seatId, value)
		end
	end
end

pBattlePanel.updatePiaoText = function(self, players)
	for _, player in pairs(players) do
		local flags = player:getFlags()
		for _, f in pairs(flags) do
			self:setPiaoText(player:getSeat(), f)
		end
	end
end

pBattlePanel.initPiaoWndPos = function(self)
	for i = 0, 3 do
		local wnd = self[sf("wnd_piao_%d", i)]
		if wnd then
			wnd:setSize(wnd:getWidth(), wnd:getHeight())
		end
	end
end

pBattlePanel.initSetWindow = function(self)
	self:showPiaoWnd(true)
	self.btn_return:show(false)
	self:initPiaoWndPos()
	self.wnd_comb_parent:setOffsetX(-50)
	self.wnd_comb_parent:setPosition(0, - self.wnd_table:getWidth() * 0.1)
	self.wnd_hand_0:setOffsetY(self.wnd_table:getHeight() * 0.01)
	self.wnd_hand_0:setPosition(12, 0)
	self.wnd_role_0_bg:setPosition(8, 0)
	self.wnd_role_0_bg:setOffsetY(- self.wnd_role_0_bg:getHeight() * 1.1)
	self.wnd_hand_1:setOffsetX(self.wnd_table:getWidth() * 0.01)
	self.wnd_role_1_bg:setOffsetX(self.wnd_role_1_bg:getWidth() * 1.1)
	self.wnd_role_1_bg:setOffsetY(-self.wnd_table:getHeight() * 0.1)
	self.wnd_hand_2:setPosition(self.wnd_hand_2:getX(), self.wnd_table:getHeight() * 0.07)
	self.wnd_role_2_bg:setOffsetX(self.wnd_role_2_bg:getWidth() / 6)
	self.wnd_role_2_bg:setOffsetY( self.wnd_table:getHeight() * 0.043)
	self.wnd_hand_3:setPosition(self.wnd_table:getWidth() * 0.1, 0)
	self.wnd_hand_3:setOffsetY(self.wnd_table:getHeight() * 0.08)
	self.wnd_role_3_bg:setPosition(-self.wnd_table:getWidth() * 0.085, 0)

	local time = os.date("%H:%M", os.time())
	self.wnd_show_time:setText(time)
	local modUIUtil = import("ui/common/util.lua")
	modUIUtil.timeOutDo(modUtil.s2f(60), nil, function()
		local time = os.date("%H:%M", os.time())
		self.wnd_show_time:setText(time)
	end)
	self.wnd_show_time:setPosition(gGameWidth * 0.86, 10)
	self.wnd_sign_bg:setPosition(self.wnd_show_time:getTextControl():getWidth() + 10, 0)
	self.wnd_battery_bg:setPosition(self.wnd_sign_bg:getWidth() + 10, 0)
	self.wnd_battery_bg:setColor(0)
end

pBattlePanel.changeRuleText = function(self, roomInfo, rs)
	return
end

pBattlePanel.setRoomInfo = function(self, roomInfo)
	local modUIUtil = import("ui/common/util.lua")
	local ruleShow = modUIUtil.getRuleShow()
	self:changeRuleText(roomInfo, ruleShow)
	local t = roomInfo.room_type
	local r = roomInfo.rule_type
	local mjStr = ruleShow[r]["room_type"][t]
	self.wnd_game_name:setText(mjStr)
	self.roomTypeStr = mjStr
	local typeName = ruleShow[r]["rule_type"][roomInfo.rule_type]
	local curRound = self:getCurGame():getCurRound()
	local totRound = ruleShow[r]["number_of_game_times"][roomInfo.number_of_game_times]
	local maxNumber = ruleShow[r]["max_number_of_users"][roomInfo.max_number_of_users]
	local roundStr = "局 "
	local subTimeCount = self:getCurGame():getCurSubTimeCount()
	if self:getIsCircle() then
		roundStr = "圈 "
		self.wnd_game_type:setText(typeName .. " " .. maxNumber  .. (" 第" .. subTimeCount + 1 .. "局/" .. totRound) .. roundStr)
	else
		self.wnd_game_type:setText(typeName .. " " .. maxNumber  .. (" 第" .. curRound .. "/" .. totRound) .. roundStr)
	end
	self.gameTypeStr = typeName
	-- 匹配房间设置邀请按钮不可见
	if t == modLobbyProto.CreateRoomRequest.MATCH or t == modLobbyProto.CreateRoomRequest.CLUB_SHARED then
		self:showYaoQing(false)
		self.btn_tell_all:show(false)
	end

	local ruleStr = modUIUtil.getRuleStr(roomInfo)
	self.wnd_roomid:setPosition(20, 0)
	self.wnd_rule_name:setText(ruleStr)
	self.ruleStr = ruleStr
	self.wnd_rule_name:setPosition(self.wnd_game_name:getX() + self.wnd_game_name:getTextControl():getWidth(),self.wnd_rule_name:getY())
	if not self.wnd_roomid:isShow() then
		self.wnd_game_type:setPosition(self.wnd_roomid:getX(), self.wnd_roomid:getY())
	else
		self.wnd_game_type:setPosition(self.wnd_roomid:getX() + self.wnd_roomid:getTextControl():getWidth() + 12,self.wnd_roomid:getY())
	end
	self.wnd_game_name:setPosition(self.wnd_game_type:getX() + self.wnd_game_type:getTextControl():getWidth() + 10,self.wnd_roomid:getY())
	self.wnd_rule_name:setPosition(self.wnd_game_name:getX() + self.wnd_game_name:getTextControl():getWidth() + 10,self.wnd_game_name:getY())
	self.wnd_rule_bg:setSize(self:getWndTextWidth() * 1.12, 50)
end

pBattlePanel.getWndTextWidth = function(self)
	return self.wnd_rule_name:getTextControl():getWidth() + self.wnd_game_name:getTextControl():getWidth() +
			self.wnd_game_type:getTextControl():getWidth() + self.wnd_roomid:getTextControl():getWidth()
end

pBattlePanel.getHandCardSize = function(self, seatId)
	return self.handSizes[seatId][1], self.handSizes[seatId][2]
end

pBattlePanel.getShowCardSize = function(self, seatId)
	return self.showSizes[seatId][1], self.showSizes[seatId][2]
end

pBattlePanel.getCardSize = function(self, seatId, showType)
	if showType == T_CARD_HAND then
		return self:getHandCardSize(seatId)
	else
		return self:getShowCardSize(seatId)
	end
end

pBattlePanel.getDiscardSize = function(self, seatId)
	return self.DiscardSizes[seatId][1], self.DiscardSizes[seatId][2]
end

pBattlePanel.getHandDiff = function(self, seatId)
	--logv("info", seatId, self.handSizes)
	if seatId == T_SEAT_MINE or
		seatId == T_SEAT_OPP then
		return self.handSizes[seatId][1]
	else
		return self.handSizes[seatId][2]*VERTICAL_DIFF_RATE
	end
end

pBattlePanel.getShowDiff = function(self, seatId)
	if seatId == T_SEAT_MINE or
		seatId == T_SEAT_OPP then
		return self.showSizes[seatId][1] - 3
	else
		return self.showSizes[seatId][2]*2/3
	end
end
pBattlePanel.getDiscardDiff = function(self, seatId)
	return self.DiscardSizes[seatId][2]*2/2.8
end

pBattlePanel.clearAutoPlayingWnds = function(self)
	if not self.autoPlayingWnds then return end
	for _, wnd in pairs(self.autoPlayingWnds) do
		wnd:setParent(nil)
	end
	self.autoPlayingWnds = {}
end

pBattlePanel.destroy = function(self)
	self:setParent(nil)
	self:clearAutoPlayingWnds()
	self:clearAutoPlayingBG()
	if modVoice.pVoice:getInstance() then
		modVoice.pVoice:getInstance():close()
		modVoice.pVoice:getInstance():cleanClose()
	end
	if self.__countdown_hdr then
		self.__countdown_hdr:stop()
		self.__countdown_hdr = nil
	end
	if self.discardParent then
		for _, p in pairs(self.discardParent) do
			p:setParent(nil)
		end
	end
	if self.flowerParent then
		for _, p in pairs(self.flowerParent) do
			p:setParent(nil)
		end
	end
	for _, info in pairs(self.cardInfo) do
		for _, _info in pairs(info) do
			for _, wnd in pairs(_info.wnds) do
				wnd:setParent(nil)
			end
		end
	end
	self.cardInfo = {}
	if self.blnAction then
		self.blnAction:stop()
		self.blnAction = nil
	end
	self:clearCloseRoom()
	if self.__add_user_hdr then
		modEvent.removeListener(self.__add_user_hdr)
		self.__add_user_hdr = nil
	end
	if self.__user_online_hdr then
		modEvent.removeListener(self.__user_online_hdr)
		self.__user_online_hdr = nil
	end
	if self.__card_pool_update_hdr then
		modEvent.removeListener(self.__card_pool_update_hdr)
		self.__card_pool_update_hdr = nil
	end

	if self.__choose_combs_hdr then
		modEvent.removeListener(self.__choose_combs_hdr)
		self.__choose_combs_hdr = nil
	end

	if self.__choose_angangs_hdr then
		modEvent.removeListener(self.__choose_angangs_hdr)
		self.__choose_angangs_hdr = nil
	end

	if self.__battery_level_changed_hdr then
		modEvent.removeListener(self.__battery_level_changed_hdr)
		self.__battery_level_changed_hdr = nil
	end

	if self.__next_turn_hdr then
		modEvent.removeListener(self.__next_turn_hdr)
		self.__next_turn_hdr = nil
	end
	if self.__update_user_prop then
		modEvent.removeListener(self.__update_user_prop)
		self.__update_user_prop = nil
	end

	if self.__game_calc_hdr then
		modEvent.removeListener(self.__game_calc_hdr)
		self.__game_calc_hdr = nil
	end

	if self.__update_disroom_result then
		modEvent.removeListener(self.__update_disroom_result)
		self.__update_disroom_result = nil
	end

	self:stopTimeoutSound()
	self:clearShowCardControls()
	self:clearSuggestionMenu()
	self:clearSuggControls()
	self:clearSelectTipWnd()
	self:clearWinnerCardWnds()
	self.handPos = {}
	self.discardPos = {}
	self.discardParent = {}
	self.discardCntPerLine = {}
	self.handSizes = {}
	self.showSizes = {}
	self.szHandWnd = {}
	self.showList = {}
	self.iconPos = {}
	self.curDiscardSeatId = nil
	self.showCardControls = {}
	self.diCardControls = {}
	self.gangCardControls = {}
	self.isNotChangeColorWnds = {}
	self.currDiCard = nil
	self.discardMarkId = nil
	self.lastPid = nil
	self.roomTypeStr = nil
	self.isResetState = true
	self.roomIdStr = nil
	self.ruleStr = nil
	self.gameTypeStr = nil
	self:clearLouControls()
	if self["wnd_owner"] then
		self["wnd_owner"]:setParent(nil)
	end
	if self["wnd_host"] then
		self["wnd_host"]:setParent(nil)
	end
	if self["wnd_off_line"] then
		self["wnd_off_line"]:setParent(nil)
	end
	if self["wnd_discard_mark"] then
		self["wnd_discard_mark"]:setParent(nil)
	end

	self:clearDiscardedCard()

	if modDisMissList.pDisMissList:getInstance() then
		modDisMissList.pDisMissList:instance():close()
	end
	self.controls = {}
	self:closeSet()
	if modCombWnd.pMenu:getInstance() then
		modCombWnd.pMenu:instance():close()
	end
	if modVideoPlayer.pVideoPlayer:getInstance() then
		modVideoPlayer.pVideoPlayer:instance():close()
	end
	if modCalcPanel.pCalculatePanel:getInstance() then
		modCalcPanel.pCalculatePanel:instance():close()
	end

	if modFlagMenu.pFlagMenu:getInstance() then
		modFlagMenu.pFlagMenu:instance():close()
	end

	self:showClubUI()
end

pBattlePanel.showClubUI = function(self)
	modEvent.fireEvent(EV_BATTLE_END)
end

pBattlePanel.checkPlayerInfo = function(self)
	if modPlayerInfo.pPlayerInfoMgr:getInstance() then
		modPlayerInfo.pPlayerInfoMgr:instance():destroy()
	end
end

pBattlePanel.closeSet = function(self)
	if self.menuWnd then
		self.menuWnd:setParent(nil)
		self.menuWnd:hideSelf()
		self.menuWnd = nil
	end
end

pBattlePanel.clearCloseRoom = function(self)
	if modCommonCue.pCommonCue:getInstance() then
		modCommonCue.pCommonCue:instance():close()
	end
end

pBattlePanel.showMenu = function(self)
	local modMenuWnd = import("ui/battle/battlemenu.lua")
	self.menuWnd = modMenuWnd.pBattleMenu:new(self, T_MAHJONG_ROOM)
end

pBattlePanel.clearMenuWnd = function(self)
	if self.menuWnd then
		self.menuWnd:setParent(nil)
		self.menuWnd = nil
	end
end


pBattlePanel.addDisRoomInfo = function(self,name,yesOrNo)
	local str = ""
	if yesOrNo then
		str = "同意"
	else
		str = "拒绝"
	end
	table.insert(self.disRoomInfoList,name .. "选择" .. str .. "解散房间")
end


pBattlePanel.getCurrentSeatId = function(self)
	return self.curSeatId
end

pBattlePanel.showReturnBtn = function(self,isShow)
	self.btn_return:show(isShow)
end

pBattlePanel.setAvatarUrl = function(self,seatId,url)
	local name = "wnd_role_" .. seatId
	if self[name] then
		self[name]:setImage(url)
		self[name]:setColor(0xFFFFFFFF)
	end
end

pBattlePanel.showYaoQing = function(self,isShow)
	self.btn_share:show(isShow)
	self.btn_copy_room_info:show(isShow)
end

pBattlePanel.setRoleWndShow = function(self,seatId,isShow)
	if self["wnd_role_" .. seatId] then
		self["wnd_role_" .. seatId]:show(isShow)
	end
end

pBattlePanel.getRuleStr = function(self)
	return self.ruleStr
end

pBattlePanel.getRoomType = function(self)
	return self.roomTypeStr
end

pBattlePanel.getRoomId = function(self)
	return self.roomIdStr
end

pBattlePanel.getGameName = function(self)
	return self.gameTypeStr
end

pBattlePanel.clearShowCardControls = function(self)
	if self.showCardControls then
		for k,v in pairs(self.showCardControls) do
			v:setParent(nil)
		end
		self.showCardControls = {}
	end
end

pBattlePanel.getCombParentWnd = function(self)
	return self.wnd_comb_parent
end

pBattlePanel.getInt = function(self, x)
	if x <= 0 then
		return math.ceil(x)
	end
	if math.ceil(x) == x then
		x = math.ceil(x)
	else
		x = math.ceil(x) - 1;
	end
	return x
end

pBattlePanel.clearAutoPlayingBG = function(self)
	if self.autoPlayingBG then
		self.autoPlayingBG:close()
	end
	self.autoPlayingBG = nil
end

pBattlePanel.updatePlayerAutoPlayingFlag = function(self, player)
	if not player then return end
--	print(player:getHasAutoPlayingFlag(), self.autoPlayingWnds[player:getSeat()])
	if not player:getHasAutoPlayingFlag() then
		if self.autoPlayingWnds[player:getSeat()] then
			self.autoPlayingWnds[player:getSeat()]:setParent(nil)
			self.autoPlayingWnds[player:getSeat()] = nil
		end
		return
	end
	-- 托管中
	local bgWnd = self[sf("wnd_role_%d_front", player:getSeat())]
	local autoWnd = pWindow:new()
	autoWnd:load("data/ui/auto_playing.lua")
	autoWnd:setParent(bgWnd)
	autoWnd:setZ(-2)
	if self.autoPlayingWnds[player:getSeat()] then
		self.autoPlayingWnds[player:getSeat()]:setParent(nil)
		self.autoPlayingWnds[player:getSeat()] = nil
	end
	self.autoPlayingWnds[player:getSeat()] = autoWnd
	if player:getSeat() == T_SEAT_MINE and not modBattleMgr.getCurBattle():getIsVideoState() then
		self:autoPlayingClear()
		self:clearAutoPlayingBG(player)
		self.autoPlayingBG = modStopAutoPlayingWnd.pStopAutoPlaying:new(function()
			self:clearAutoPlayingBG(player)
		end)
		self.autoPlayingBG:setParent(self.wnd_table)
	end
end

pBattlePanel.updateAllPlayersAtuoPlayingFlag = function(self)
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	for _, player in pairs(players) do
		self:updatePlayerAutoPlayingFlag(player)
	end
end

pBattlePanel.updateLouFlagWnds = function(self, player)
	if not player then return end
	local seatId = player:getSeat()
	if not seatId or seatId ~= T_SEAT_MINE then return end
	-- 清除漏flag控件
	self:clearLouControls()

	-- 取漏flag
	local flags = {}
	for _, f in pairs(player:getFlags()) do
		if self:isLouFlag(f) and not flags[f] then
			flags[f] = f
		end
	end
	-- 描画漏flag
	local x = gGameWidth * 0.1
	for _, f in pairs(flags) do
		local fWnd = self:newLouFlagWnd(f, x)
		x = x + fWnd:getWidth()
	end
end

pBattlePanel.newLouFlagWnd = function(self, f, x)
	local louImages = {
		[modGameProto.LOUPENG] = "ui:battle/lou_peng.png",
		[modGameProto.LOUHU_ZIMO] = "ui:battle/lou_hu.png",
		[modGameProto.LOUHU_DIANPAO] = "ui:battle/lou_hu.png",
	}
	local louSizes = {
		[modGameProto.LOUPENG] = {87, 87},
		[modGameProto.LOUHU_ZIMO] = {149, 131},
		[modGameProto.LOUHU_DIANPAO] = {149, 131}
	}
	local fWidth, fHeight = louSizes[f][1] or 0, louSizes[f][2] or 0
	local fImage = louImages[f] or ""
	local fWnd = pWindow:new()
	fWnd:setParent(self.wnd_comb_parent)
	fWnd:setAlignX(ALIGN_RIGHT)
	fWnd:setSize(fWidth, fHeight)
	fWnd:setImage(fImage)
	fWnd:setColor(0xFFFFFFFF)
	fWnd:setPosition(0, -fWnd:getHeight() * 1.1)
	fWnd:enableEvent(false)
	fWnd:setOffsetX(-x)
	if f ~= modGameProto.LOUHU_DIANPAO and f ~= modGameProto.LOUHU_ZIMO then
		fWnd:setOffsetY(fWnd:getOffsetY() - (louSizes[modGameProto.LOUHU_ZIMO][2] - fWnd:getHeight()) / 2)
	end
	table.insert(self.louControls, fWnd)
	return fWnd
end

pBattlePanel.checkLouFlag = function(self)
	-- 开始游戏检查是否漏胡
	if modBattleMgr.getCurBattle():getIsCalculate() then
		-- 结算或者等待中清除
		self:clearLouControls()
		return
	end
	-- 重登或者正常则描画
	for _, player in pairs(modBattleMgr.getCurBattle():getAllPlayers()) do
		if player:getSeat() ==  T_SEAT_MINE then
			self:updateLouFlagWnds(player)
		end
	end
end

pBattlePanel.clearLouControls = function(self)
	for _, wnd in pairs(self.louControls) do
		wnd:setParent(nil)
	end
	self.louControls = {}
end

pBattlePanel.isLouFlag = function(self, f)
	return f == modGameProto.LOUHU_ZIMO or f == modGameProto.LOUHU_DIANPAO or f == modGameProto.LOUPENG
end

pBattlePanel.showSendMessage = function(self, message)
	local modChatProto = import("data/proto/rpc_pb2/chat_pb.lua")
	local battle = modBattleMgr.getCurBattle()
	local chatData = message.chat_message.data
	local chatMessage = modChatProto.ChatMessage.Fixed()
	chatMessage:ParseFromString(chatData)
	local messageId = chatMessage.fixed_id
	local userId = message.from_user_id

	if messageId > 1000 then
		self:soundMessage(messageId, userId)
	elseif messageId <= 1000 then
		self:faceMessage(messageId, userId)
	end
end

pBattlePanel.messageIdToName = function(self, msgId)
	local messageId = msgId
	local number = modChannelMgr.getCurChannel():getControlNum()
	return messageId - number
end

pBattlePanel.textMessage = function(self, text, userId, delay)
	local battle = modBattleMgr.getCurBattle()
	local seatId = battle:getUidToSeat()[userId]
	local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
	if not player then 	return	end

	local pWnd = self[sf("wnd_role_%d_bg", seatId)]
	-- 描画
	if self["wnd_message_voice" .. seatId] then
		self["wnd_message_voice" .. seatId]:setParent(nil)
	end
	local wnd = self:newMessageWnd("voice" .. seatId, 0, 0, text, pWnd)
	wnd:setSize(wnd:getTextControl():getWidth() + 50, wnd:getTextControl():getHeight() + 25)

	-- pos
	local pos = {
		[T_SEAT_MINE] = { pWnd:getWidth() + 20, pWnd:getHeight() / 2 },
		[T_SEAT_RIGHT] = { - wnd:getWidth(), pWnd:getHeight() / 2},
		[T_SEAT_OPP] = { - wnd:getWidth(), 0},
		[T_SEAT_LEFT] = { pWnd:getWidth() + 20, pWnd:getHeight() / 2},
	}
	wnd:setPosition(pos[seatId][1], pos[seatId][2])
	if seatId == T_SEAT_MINE or seatId == T_SEAT_LEFT then
		wnd:setImage("ui:voice_text_left.png")
	end

	-- 消失
	local modUIUtil = import("ui/common/util.lua")
	modUIUtil.timeOutDo(delay or modUtil.s2f(2), nil, function()
		if wnd then
			wnd:setParent(nil)
		end
	end)
end

pBattlePanel.textMessageFinish = function(self, userId)
	local battle = modBattleMgr.getCurBattle()
	local seatId = battle:getUidToSeat()[userId]
	local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
	if not player then 	return	end

	local pWnd = self[sf("wnd_role_%d_bg", seatId)]
	-- 描画
	if self["wnd_message_voice" .. seatId] then
		self["wnd_message_voice" .. seatId]:setParent(nil)
		self["wnd_message_voice" .. seatId] = nil
	end
end

pBattlePanel.soundMessage = function(self, msgId, userId)
	local battle = modBattleMgr.getCurBattle()
	local seatId = battle:getUidToSeat()[userId]
	local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
	if not player then 	return	end
	local messageId = self:messageIdToName(msgId)
	local mjPath = modChannelMgr.getCurChannel():getFangYanPath()
	local sound =  modSound.getCurSound()
	local seatId = player:getSeat()
	sound:playSound(sound:getVoicePath(messageId, player:getGender(), mjPath))

	-- 描画
	-- finddata 根据收到协议的id查找
	local data = modChannelMgr.getCurChannel():getVoiceData()
	local pWnd = self[sf("wnd_role_%d_bg", seatId)]
	local text = data[messageId]["_text_"]
	-- 描画
	if self["wnd_message_voice" .. seatId] then
		self["wnd_message_voice" .. seatId]:setParent(nil)
	end
	local wnd = self:newMessageWnd("voice" .. seatId, 0, 0, text, pWnd)
	wnd:setSize(wnd:getTextControl():getWidth() + 50, wnd:getTextControl():getHeight() + 25)

	-- pos
	local pos = {
		[T_SEAT_MINE] = { pWnd:getWidth() + 20, pWnd:getHeight() / 2 },
		[T_SEAT_RIGHT] = { - wnd:getWidth(), pWnd:getHeight() / 2},
		[T_SEAT_OPP] = { - wnd:getWidth(), 0},
		[T_SEAT_LEFT] = { pWnd:getWidth() + 20, pWnd:getHeight() / 2},
	}
	wnd:setPosition(pos[seatId][1], pos[seatId][2])
	if seatId == T_SEAT_MINE or seatId == T_SEAT_LEFT then
		wnd:setImage("ui:voice_text_left.png")
	end

	-- 消失
	local modUIUtil = import("ui/common/util.lua")
	modUIUtil.timeOutDo(modUtil.s2f(4), nil, function()
		if wnd then
			wnd:setParent(nil)
		end
	end)
end

pBattlePanel.audioMessage = function(self, userId)
	local battle = modBattleMgr.getCurBattle()
	local seatId = battle:getUidToSeat()[userId]
	local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
	if not player then 	return	end

	local seatId = player:getSeat()
	local pWnd = self[sf("wnd_role_%d_front", seatId)]
	if pWnd.__audio_wnd then
		pWnd.__audio_wnd:setParent(nil)
		pWnd.__audio_wnd = nil
	end
	pWnd.__audio_wnd = pWindow:new()
	pWnd.__audio_wnd:setParent(pWnd)
	local pos = {
		[T_SEAT_MINE] = { pWnd:getWidth() + 10, 0},
		[T_SEAT_RIGHT] = { - pWnd.__audio_wnd:getWidth(), 0},
		[T_SEAT_OPP] = { - pWnd.__audio_wnd:getWidth(), pWnd:getHeight()},
		[T_SEAT_LEFT] = { pWnd:getWidth() + 10, pWnd:getHeight()},
	}
	pWnd.__audio_wnd:setPosition(pos[seatId][1], pos[seatId][2])
	pWnd.__audio_wnd:setSize(86, 55)
	if seatId == T_SEAT_MINE or
		seatId == T_SEAT_LEFT then
		pWnd.__audio_wnd:setImage("ui:im_audio_left.png")
	else
		pWnd.__audio_wnd:setImage("ui:im_audio_right.png")
	end
end

pBattlePanel.audioMessageFinish = function(self, userId)
	local battle = modBattleMgr.getCurBattle()
	local seatId = battle:getUidToSeat()[userId]
	local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
	if not player then 	return	end

	local seatId = player:getSeat()
	local pWnd = self[sf("wnd_role_%d_front", seatId)]
	if pWnd and pWnd.__audio_wnd then
		pWnd.__audio_wnd:setParent(nil)
		pWnd.__audio_wnd = nil
	end
end

pBattlePanel.faceMessage = function(self, messageId, userId)
	local battle = modBattleMgr.getCurBattle()
	local seatId = battle:getUidToSeat()[userId]
	local player = modBattleMgr.getCurBattle():getAllPlayers()[seatId]
	if not player then 	return	end

	-- 描画
	local seatId = player:getSeat()
	local pWnd = self[sf("wnd_role_%d_front", seatId)]

	-- 如果有就先清掉
	if self["wnd_message_face_" .. seatId] then
		self["wnd_message_face_" .. seatId]:setParent(nil)
	end
	local wnd = self:newMessageWnd("face_" .. seatId, 0, 0, nil, pWnd)
	--wnd:setImage("ui:faces/" .. messageId .. ".png")
	wnd:setColor(0)
	self:playFace(messageId, wnd)
	-- pos
	local pos = {
		[T_SEAT_MINE] = { pWnd:getWidth() + 10,  - pWnd:getHeight() * 0.6 },
		[T_SEAT_RIGHT] = { - wnd:getWidth() , pWnd:getHeight() / 2},
		[T_SEAT_OPP] = { -wnd:getWidth(), 0 },
		[T_SEAT_LEFT] = { pWnd:getWidth() + 10, - pWnd:getHeight() * 0.6},
	}
	wnd:setPosition(pos[seatId][1], pos[seatId][2])
	-- 消失
	local modUIUtil = import("ui/common/util.lua")
	modUIUtil.timeOutDo(modUtil.s2f(4), nil, function()
		if wnd then
			wnd:setParent(nil)
		end
	end)

end

pBattlePanel.newMessageWnd = function(self, name, x, y, text, pWnd)
	local wnd = pWindow:new()
	wnd:setName("wnd_message_" .. name)
	wnd:setParent(pWnd)
	wnd:setSize(54 * 2, 54 * 2)
	wnd:setImage("ui:voice_text_right.png")
	wnd:enableEvent(false)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setColor(0xFFFFFFFF)
	wnd:setPosition(x, y)
	if text then
		wnd:setText(text)
		wnd:getTextControl():setAutoBreakLine(false)
		wnd:getTextControl():setFontSize(27)
		wnd:getTextControl():setAlignY(ALIGN_TOP)
		wnd:getTextControl():setColor(0xFF223330)
		wnd:setXSplit(true)
		wnd:setYSplit(true)
		wnd:setSplitSize(50)
	end
	self[wnd:getName()] = wnd
	return wnd
end

pBattlePanel.isDebugVersion = function(self)
	return modUtil.isDebugVersion()
end

pBattlePanel.isMagicCard = function(self, id)
	local cards = self:getCurGame():getMagicCard()
	if not cards then return end
	local result = false
	for _, mId in pairs(cards) do
		if id == mId then
			result = true
			break
		end
	end
	return result
end

pBattlePanel.isOverLen = function(self)
	return self.handCnt and self.handCnt >= 17
end


pBattlePanel.suggMark = function(self)
	-- 先清理
	self:clearSuggControls()
	-- 取当前建议
	local suggestions = self:getCurGame():getSuggestions()
	if not suggestions then return end
	-- 取得所有的手牌牌
	local allCards = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
	-- 取建议打牌结构体
	for _, sugg in ipairs(suggestions) do
		-- 在画
		local ifId = sugg.card_id
		local winCards = sugg.winning_cards
		for _, card in pairs(allCards) do
			if card:getCardId() == ifId then
				self:drawSugg(card)
				card:setWinCards(winCards)
			end
		end
	end
end

pBattlePanel.getNotInSuggestionListCards = function(self)
	local suggestions = self:getCurGame():getSuggestions()
	if not suggestions then return end
	-- 手牌
	local hands = self:getAllCardWnds(T_SEAT_MINE, T_CARD_HAND)
	local notInlist = {}
	local suggIds = {}
	-- 建议打牌ids
	for _, sugg in ipairs(suggestions) do
		table.insert(suggIds, sugg.card_id)
	end
	-- 取不在建议列表的牌
	for _, card in pairs(hands) do
		if not self:findCardIsInList(card, suggIds) then
			table.insert(notInlist, card)
		end
	end
	return notInlist
end

pBattlePanel.setSuggestionTingColor = function(self)
	local suggestions = self:getCurGame():getSuggestions()
	if not suggestions or table.getn(suggestions) <= 0 then return end

	local notInlist = self:getNotInSuggestionListCards()
	-- 设置颜色
	for _, card in pairs(notInlist, card) do
		card:setColor(tingColor)
	end
end


pBattlePanel.drawSugg = function(self, card)
	local wnd = pWindow:new()
	wnd:setParent(card)
	wnd:setImage("ui:card_sug_choose.png")
	wnd:setColor(0xFFFFFFFF)
	wnd:setSize(28, 28)
	wnd:setZ(C_BATTLE_UI_Z)
	wnd:setPosition(0, 25)
	wnd:setAlignX(ALIGN_RIGHT)
	table.insert(self.suggControls, wnd)
end

pBattlePanel.clearSuggControls = function(self)
	for _, wnd in pairs(self.suggControls) do
		wnd:setParent(nil)
	end
	self.suggControls = {}
end

pBattlePanel.showWinnerCardWnds = function(self, pid, cards)
	if not pid  then return end
	-- 先清理
	if not self.huCardWnds then self.huCardWnds = {} end
	local seatId = modBattleMgr.getCurBattle():getSeatMap()[pid]
	if not seatId then return end
	self:clearWinnerCardBySeatId(seatId)
	local modHuCardWnd = import("ui/battle/hucardwnd.lua")
	local x, y = 0, 0
	if not cards or table.getn(cards) <= 0 then return end
	-- pos
	local pos = {
		[T_SEAT_MINE] = {
			[2] = { gGameWidth * 0.1, gGameHeight * 0.58},
			[3] = { gGameWidth * 0.13, gGameHeight * 0.68},
			[4] = { gGameWidth * 0.14, gGameHeight * 0.68},
		},
		[T_SEAT_OPP] = {
			[2] = { gGameWidth * 0.87, gGameHeight * 0.4},
			[3] = { 0, 0},
			[4] = { gGameWidth * 0.87, gGameHeight * 0.26},
		},
		[T_SEAT_RIGHT] = {
			[2] = { 0, 0},
			[3] = { gGameWidth * 0.87, gGameHeight * 0.20},
			[4] = { gGameWidth * 0.8, gGameHeight * 0.53},
		},
		[T_SEAT_LEFT] = {
			[2] = { 0, 0},
			[3] = { gGameWidth * 0.2, gGameHeight * 0.1},
			[4] = { gGameWidth * 0.18, gGameHeight * 0.175},
		},
	}

	-- 画界面
	local pWnd = self[sf("wnd_hand_%d", seatId)]
	local wnd = modHuCardWnd.pHuCardWnd:new(x, y, pid, cards)
	local count = table.size(modBattleMgr.getCurBattle():getAllPlayers())
	wnd:setPosition(pos[seatId][count][1], pos[seatId][count][2])
	-- 右边调整位置
	if seatId == T_SEAT_RIGHT or seatId == T_SEAT_OPP then
		wnd:setPosition(wnd:getX() - wnd:getWidth(), wnd:getY())
	end
	if self.huCardWnds[seatId] then
		self.huCardWnds[seatId]:setParent(nil)
		self.huCardWnds[seatId] = nil
	end
	self.huCardWnds[seatId] = wnd
end

pBattlePanel.updateWinnerCardsWnds = function(self)
	if modBattleMgr.getCurBattle():getIsCalculate() then return end
	-- 描画更新
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		local player = modBattleMgr.getCurBattle():getAllPlayers()[i]
		if player then
			local ids = player:getCanHuCardIds()
			self:showWinnerCardWnds(player:getPlayerId(), ids)
		end
	end
end

pBattlePanel.clearWinnerCardBySeatId = function(self, seatId)
	if not seatId or not self.huCardWnds then return end
	if not self.huCardWnds[seatId] then return end
	self.huCardWnds[seatId]:setParent(nil)
	self.huCardWnds[seatId] = nil
end

pBattlePanel.clearWinnerCardWnds = function(self)
	if not self.huCardWnds then return end
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		self:clearWinnerCardBySeatId(i)
	end
	self.huCardWnds = {}
end

pBattlePanel.updateHuWndsCountText = function(self, seatId)
	if not seatId then return end
	if not self.huCardWnds or not self.huCardWnds[seatId] then return end
	self.huCardWnds[seatId]:updateCountText()
end

pBattlePanel.updateAllHuWndsCountText = function(self)	
	for i = T_SEAT_MINE, T_SEAT_LEFT do
		self:updateHuWndsCountText(i)
	end
end
