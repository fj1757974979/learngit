local modVoice = import("ui/battle/voice.lua")
local modChatUtil = import("logic/chat/util.lua")
local modClipBoardMgr = import("logic/clipboard/mgr.lua")
local modBattleMenu = import("ui/battle/battlemenu.lua")
local modChatProto = import("data/proto/rpc_pb2/chat_pb.lua")
local modUtil = import("util/util.lua")

pBattlePanel = pBattlePanel or class(pWindow)

pBattlePanel.init = function(self, battle)
	self.battle = battle
	self:load("data/ui/card/battle.lua")
	self.wndTable = battle:newTableWnd()
	self.wndTable:setParent(self.wnd_table_parent)
	self.wndTable:adjustUI()
	self.wndTable:initFromBattle(battle)
	self:setParent(gWorld:getUIRoot())
	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_BATTLE_UI_Z)
	self:initUI()
	self:regEvent()
end

pBattlePanel.getTableWnd = function(self)
	return self.wndTable
end

pBattlePanel.initUI = function(self)
	self:updateRoomInfo()
end

pBattlePanel.shareRoomToWechat = function(self, paste)
	local modChannel = import("logic/channels/main.lua")
	local titleStr = self.battle:getGameName()
	local roomId = self.battle:getRoomId()
	local downLoadLink = modChannel.getCurChannel():getShareRoomUrl(roomId)
	local players = self.battle:getAllPlayers()
	local maxCnt = self.battle:getMaxPlayerCnt()
	local curCnt = table.size(players)
	local waitCnt = maxCnt - curCnt
	if self.battle:isClubRoom() then
		titleStr = sf("%s 俱乐部号【%06d】%s缺%s", titleStr, self.battle:getClubId(), modUtil.arabicNum2ChineseNum(curCnt), modUtil.arabicNum2ChineseNum(waitCnt))
	else
		titleStr = sf("%s【%06d】%s缺%s", titleStr, roomId, modUtil.arabicNum2ChineseNum(curCnt), modUtil.arabicNum2ChineseNum(waitCnt))
	end
	local content = self.battle:getRoomDesc()
	local idx = 0
	local welcomeStr = "("
	for _, player in pairs(players) do
		idx = idx + 1
		welcomeStr = welcomeStr .. player:getName()
		if idx ~= curCnt then
			welcomeStr = welcomeStr .. "、"
		end
	end
	welcomeStr = welcomeStr .. "等你来)"
	if paste then
		modClipBoardMgr.pClipBoardMgr:instance():setClipBoardText(titleStr .. "\n" .. content .. welcomeStr .. TEXT("（复制此消息打开游戏可直接进入房间哦）"), TEXT("复制成功！"))
	else
		puppy.sys.shareWeChat(2, titleStr, content .. welcomeStr, downLoadLink)
	end
end

pBattlePanel.getAudioInputWndRX = function(self)
	return 2 * self.btn_speak:getWidth()
end

pBattlePanel.regEvent = function(self)
	modChatUtil.initSpeakBtn(self, self.btn_speak)
	self.btn_chat:addListener("ec_mouse_click", function()
		if modVoice.pVoice:getInstance() then
			modVoice.pVoice:getInstance():show(true)
		else
			modVoice.pVoice:instance():open(self)
		end
	end)

	self.btn_setting:addListener("ec_mouse_click", function()
		if not self.menu then
			self.menu = modBattleMenu.pBattleMenu:new(self, T_POKER_ROOM)
			self.menu:setParent(self)
		end

		self.menu:show(true)
	end)

	self.btn_share:addListener("ec_mouse_click", function()
		self:shareRoomToWechat()
	end)

	self.btn_copy_room_info:addListener("ec_mouse_click", function()
		self:shareRoomToWechat(true)
	end)

	if app:getPlatform() == "macos" then
		self.wnd_room_info:addListener("ec_mouse_click", function()
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
end

pBattlePanel.onGameStart = function(self)
	self.btn_share:show(false)
	self.btn_copy_room_info:show(false)
	self:getTableWnd():onGameStart()
end

pBattlePanel.clearMenuWnd = function(self)
	if self.menu then
		self.menu:setParent(nil)
		self.menu = nil
	end
end

pBattlePanel.clearVoiceWnd = function(self)
	if modVoice.pVoice:getInstance() then
		modVoice.pVoice:instance():cleanClose()
	end
end

pBattlePanel.updateRoomInfo = function(self)
	self.wnd_room_info:setText(sf(TEXT("房号%06d %s %s"),
				      self.battle:getRoomId(),
				      self.battle:getTurnDesc(),
				      self.battle:getRoomDesc()
		      ))
end

pBattlePanel.showSendMessage = function(self, message, gameVoiceName)
	if message.chat_message.type == modChatProto.ChatMessage.FIXED then
		local fixedMsg = modChatProto.ChatMessage.Fixed()
		fixedMsg:ParseFromString(message.chat_message.data)
		local fromUid = message.from_user_id
		local fixedId = fixedMsg.fixed_id
		self:getTableWnd():handleFixedChatMessage(fromUid, fixedId, gameVoiceName)
	elseif message.chat_message.type == modChatProto.ChatMessage.TEXT then
		-- TODO
	end
end

pBattlePanel.textMessage = function(self, text, uid, delay)
	self:getTableWnd():handleTextChatMessage(uid, text)
end

pBattlePanel.textMessageFinish = function(self, uid)
end

pBattlePanel.audioMessage = function(self, uid)
	self:getTableWnd():handleAudioMessage(uid)
end

pBattlePanel.audioMessageFinish = function(self, uid)
	self:getTableWnd():finishAudioMessage(uid)
end

pBattlePanel.reset = function(self)
	if self.wndTable then
		self.wndTable:reset()
	end
end

pBattlePanel.destroy = function(self)
	if self.wndTable then
		self.wndTable:destroy()
		self.wndTable = nil
	end
	self:clearMenuWnd()
	self:clearVoiceWnd()
	self:setParent(nil)
end

