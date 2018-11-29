local modUIUtil = import("ui/common/util.lua")
local modMainCreate = import("ui/menu/create.lua")
local modUtil = import("util/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modEasing = import("common/easing.lua")
local modUserData = import("logic/userdata.lua")
local modMailMgr = import("logic/mail/main.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")
local modSharePanel = import("ui/menu/share.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modEvent = import("common/event.lua")
local modSound = import("logic/sound/main.lua")
local modSet = import("ui/menu/set.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modChannelMgr = import("logic/channels/main.lua")
local modGroupConfig = import("logic/group/config.lua")

pMainMenu = pMainMenu or class(pWindow)

pMainMenu.init = function(self)
	self:show(false)
	self:setParent(gWorld:getUIRoot())
	self:initTemplate()
	self:templateInitWnd()
	-- 设置裁剪窗口
	self.wnd_radio_parent:setClipDraw(true)
	self.notices = { [modLobbyProto.Notice.SYSTEM] = {},[modLobbyProto.Notice.SCROLLING] = {}}
	self.isMoveEnd = true
	self.controls = {}
	self.breakFlag = false
	self:regEvent()
	self:adjustUI()
	self.initPosX = self.wnd_notice:getX()
	if self.wnd_background then
		modUIUtil.adjustSize(self.wnd_background, gGameWidth, gGameHeight)
	end
end
--加载不同渠道主界面
pMainMenu.initTemplate = function(self)
	local channel = modUtil.getOpChannel()
	local template = "data/ui/main_" .. channel .. ".lua"
	self:load(template)
	self:initWndPos()
	self:showDianWnd(false)
	if modChannelMgr.getCurChannel():getClubData() or
		modGroupConfig.isGroupOpen() then
		self:updateHasNewMails()
	end
end

pMainMenu.adjustUI = function(self)
end

pMainMenu.turnBuyWnd = function(self, angel, wnd)
	if not wnd then return end
	wnd:setPosition(self.btn_add_roomcard:getX() - wnd:getWidth() / 5 + wnd:getWidth() / 2,self.btn_add_roomcard:getY() - wnd:getHeight() / 3 + wnd:getHeight() / 2)
	self.turnWnd = modUIUtil.timeOutDo(1, nil, function()
		wnd:setKeyPoint(wnd:getWidth() / 2, wnd:getHeight() / 2)
		wnd:setRot(0, 0, angel)
		angel = angel + math.pi / 180
		if angel >= math.pi * 2 then
			angel = 0.1
		end
		self:turnBuyWnd(angel, wnd)
	end)
end

pMainMenu.templateInitWnd = function(self)
	self.wnd_id:setText("ID:" .. modUserData.getUID())
	local avatarUrl = modUserData.getUserAvatarUrl()
	self.wnd_image:setImage(avatarUrl)
	self:turnBuyWnd(0.1, self.wnd_buy_bg)
	self.btn_auth:show(false)
	if not self.wnd_eye_close then return end
	self.wnd_eye_close:show(false)
	self:showEyes(self.wnd_eye_close)
end

pMainMenu.floatupIcon = function(self)
	local time = modUtil.s2f(1)
	local vy = -20
	modUIUtil.floatUp(self.wnd_create_icon, time, vy)
	modUIUtil.floatUp(self.wnd_join_icon, time, -vy)
	modUIUtil.floatUp(self.wnd_speed_icon, time, vy)
end

pMainMenu.regEvent = function(self)
	self.btn_setting:addListener("ec_mouse_click", function()
		modSet.pSetMain:instance():open(false, false, true)
	end)
	if self.btn_buy_icon then
		self.btn_buy_icon:addListener("ec_mouse_click", function() self:buyCard() end)
	end
	self.btn_daikai:addListener("ec_mouse_click", function()
		local modDaiKai = import("ui/menu/daikai.lua")
		modDaiKai.pDaiKai:instance():open()
	end)

	self.wnd_icon_front:addListener("ec_mouse_click", function()
		local modPlayerInfo = import("logic/menu/player_info_mgr.lua")
		local uid = modUserData.getUID()
		modPlayerInfo.newMgr(uid, T_MAHJONG_ROOM)
	end)
	self.btn_join_room:addListener("ec_mouse_click",function() self:touchJoin() end)
	self.btn_auth:addListener("ec_mouse_click", function()
		local modAuthWindow = import("ui/menu/authplayer.lua")
		if modAuthWindow.pAuthWindow:getInstance() then
			modAuthWindow.pAuthWindow:instance():show(true)
		else
			modAuthWindow.pAuthWindow:instance():open()
		end
	end)
	self.btn_create_room:addListener("ec_mouse_click",function() self:touchCreate() end)
	self.btn_standings:addListener("ec_mouse_click", function() self:touchStandings() end)
	self.btn_add_roomcard:addListener("ec_mouse_click",function() self:buyCard() end)
	self.btn_howtoplay:addListener("ec_mouse_click",function()
		local modRule = import("ui/menu/rule.lua")
		modRule.pRule:instance():showWeb()
	end)

	self.btn_share:addListener("ec_mouse_click", function()
		modSharePanel.pSharePanel:instance():open()
	end)

	-- 红包事件
	self:redpacketEvent()

	self.btn_room_card:addListener("ec_mouse_click", function()	self:buyCard() end)

	self.__room_card_hdr = modUserData.bind("roomCards", function(cur, prev)
		self:setRoomCards(cur)
	end)
	self.__name_hdr = modUserData.bind("userName", function(cur, prev)
		if modUIUtil.utf8len(cur) > 6 then
			cur = modUIUtil.getMaxLenString(cur, 6)
		end
		self.wnd_name:setText(cur)
	end)
	self.__avatarUrl__hdr = modUserData.bind("avatarUrl", function(cur, prev)
		self.wnd_image:setImage(cur)
	end)
	self.__gold__hdr = modUserData.bind("goldCount", function(cur, prev)
		self.wnd_gold_text:setText(cur)
	end)

	self.__process_mail_hdr = modEvent.handleEvent(EV_PROCESS_MAIL, function(hasNewMails)
		self:showDianWnd(hasNewMails)
	end)

	self.btn_invite:addListener("ec_mouse_click", function()
		self:inviteClick()
	end)

	if self.btn_group then
		self.btn_group:addListener("ec_mouse_click", function()
			self:entrance()
		end)
	end

	self.btn_join_2:addListener("ec_mouse_click", function()
		if modBattleMgr.getCurBattle() then
			modBattleMgr.getCurBattle():getBattleUI():show(true)
		else
			modBattleRpc.joinMatchRoom(function(success, reason, room)
				if success then
					if room then
						modBattleMgr.pBattleMgr:instance():enterBattle(room.id, room.host, room.port, function(success)
							if not success	then
								if modBattleMgr.getCurBattle() then
									modBattleMgr.getCurBattle():battleDestroy()
								end
							end
						end)
					end
				else
					infoMessage(TEXT(reason))
				end

			end)
		end
	end)
end

pMainMenu.entrance = function(self)
	local modClubMgr = import("logic/club/main.lua")
	modClubMgr.getCurClub():getClubsByUid(self:getSelfUid(), function(reply)
		local createClubIds = reply.created_club_ids
		local joinClubIds = reply.joined_club_ids
		local modClubMain = import("ui/club/main.lua")
		modClubMain.pClubMain:instance():open()
		if (not createClubIds or table.getn(createClubIds) <= 0) and
			(not joinClubIds or table.getn(joinClubIds) <= 0 ) then
			local modClubEntrance = import("ui/club/entrance.lua")
			modClubEntrance.pClubEntrance:instance():open()
		end
	end)
	self:showDianWnd(false)
end

pMainMenu.showDianWnd = function(self, isShow)
	if self.wnd_dian then
		self.wnd_dian:show(isShow)
	end
end

pMainMenu.updateHasNewMails = function(self)
	modMailMgr.getCurMail():updateHasNewMails()
end

pMainMenu.touchJoin = function(self)
	if modBattleMgr.getCurBattle() then
		modBattleMgr.getCurBattle():getBattleUI():show(true)
	else
		local modMainJoin = import("ui/menu/join.lua")
		modMainJoin.pMainJoin:instance():open()
	end
end

pMainMenu.touchCreate = function(self, specificList)
	logv("info", "*******", specificList)
	if modBattleMgr.getCurBattle() then		
		modBattleMgr.getCurBattle():getBattleUI():show(true)
	else
		if specificList then
			if modMainCreate.pMainCreate:getInstance() then
				modMainCreate.pMainCreate:cleanInstance()
			end
			modMainCreate.pMainCreate:instance():open(specificList)
		else
			if modMainCreate.pMainCreate:getInstance() then
				modMainCreate.pMainCreate:instance():show(true)
			else
				modMainCreate.pMainCreate:instance():open(specificList)
			end
		end
	end
end

pMainMenu.touchStandings = function(self)
	local modVideo = import("ui/menu/video.lua")
	modVideo.pVideo:instance():open()
end

pMainMenu.hideShareDian = function(self)
	if not self.wnd_share_dian then return end
	self.wnd_share_dian:show(false)
end

pMainMenu.hideRedpacket = function(self)
	if not self.btn_hongbao then return end
	self.btn_hongbao:show(false)
end

pMainMenu.showRedpacket = function(self, count)
	local modRedpacket = import("ui/menu/redpacket.lua")
	modRedpacket.pRedpacket:instance():open(count)
end

pMainMenu.insertControl = function(self,wnd)
	if wnd then
		table.insert(self.controls,wnd)
	end
end


pMainMenu.buyCard = function(self)
	local modShopMgr = import("logic/shop/main.lua")
	if self:isHideInviteWnd() or modUtil.isAppstoreExamineVersion() then
		modShopMgr.pShopMgr:instance():getShopPanel():open()
	else
		local modInvite = import("ui/menu/invite.lua")
		if modInvite.pInviteWindow:getInstance() then
			modInvite.pInviteWindow:instance():show(true)
			modInvite.pInviteWindow:instance():setParent(self)
		else
			modInvite.pInviteWindow:instance():open(self, function(success)
				if success then
					modShopMgr.pShopMgr:instance():getShopPanel():open()
				end
			end)
		end
	end
end

pMainMenu.inviteClick = function(self)
	local modInvite = import("ui/menu/invite.lua")
	if modInvite.pInviteWindow:getInstance() then
		modInvite.pInviteWindow:instance():show(true)
		modInvite.pInviteWindow:instance():setParent(self)
	else
		modInvite.pInviteWindow:instance():open(self, function(success)
			if success then
				local modShopMgr = import("logic/shop/main.lua")
				modShopMgr.pShopMgr:instance():getShopPanel():open()
			end
		end)
	end
end

pMainMenu.isShowAuth = function(self)
	local name = modUserData.getRealName()

	if not name or name == "" then
		self.btn_auth:show(true)
	else
		self.btn_auth:show(false)
	end
end

pMainMenu.open = function(self)
	self:isShowAuth()
	self:isShowInvite()
	self:showGroundEnter()
	-- 测试用红包界面
--	self:showRedpacket()
	math.randomseed(tostring(os.time()):reverse():sub(1, 7))  --设置时间种子
	if modUtil.isAppstoreExamineVersion() then
		self.btn_invite:show(false)
		self.btn_auth:show(false)
		self.btn_daikai:show(false)
--		self.btn_group:show(false)
	end
	local shareTime = modUserData.getShareTime()
	if self.wnd_share_dian then
		self.wnd_share_dian:show(shareTime == 0)
	end
	local redpacketTime = modUserData.getRedpacketTime()
	if self.btn_hongbao then
		self.btn_hongbao:show(redpacketTime == 0)
	end
	if self.__eye_hdr then
		self.__eye_hdr:stop()
	end
	self:show(true)
	if modUtil.isAppstoreExamineVersion() then
		self.btn_invite:show(false)
		self.btn_auth:show(false)
		self.btn_daikai:show(false)
		if self.btn_hongbao then
			self.btn_hongbao:show(false)
		end
	end
end

pMainMenu.redpacketEvent = function(self)
	if not self.btn_hongbao then return end
	self.btn_hongbao:addListener("ec_mouse_click", function()
		local modRedpacketLock = import("ui/menu/redpacket_lock.lua")
		modRedpacketLock.pRedpacketLock:instance():open()
	end)
end

pMainMenu.showGroundEnter = function(self)
	if self.btn_group then
		local isShow = false
		if modChannelMgr.getCurChannel():getClubData() then
			isShow = true
		end
		self.btn_group:show(isShow)
	end
end

pMainMenu.isShowInvite = function(self)
	if self:isHideInviteWnd() then
		self.btn_invite:show(false)
	end
end

pMainMenu.setRoomCards = function(self, roomCards)
	self.wnd_room_card_text:setText(roomCards)
end

pMainMenu.showEyes = function(self, wnd)
	if not wnd then return end
	if self.jzeye then
		self.jzeye:stop()
		self.jzeye = nil
	end
	local time = math.random(1, 4)
	local fream = modUtil.s2f(0.1)
	self.jzeye = modUIUtil.timeOutDo(modUtil.s2f(time), nil, function()
		wnd:show(true)
		modUIUtil.timeOutDo(fream, nil, function()
			wnd:show(false)
		end)
		self.jzeye = self:showEyes(wnd)
	end)
end

pMainMenu.setNotic = function(self, noticeList)
	-- 提审
	if modUtil.isAppstoreExamineVersion() then
		local str = modUIUtil.getDownloadTitle()
		for _, notice  in ipairs(noticeList) do
			notice.message = "欢迎来到" .. str
		end
	end
	--clear notices
	for idx, notices in pairs(noticeList) do
		if notices.t == modLobbyProto.Notice.SYSTEM then
			self.notices[modLobbyProto.Notice.SYSTEM] = {}
		end
		if notices.t == modLobbyProto.Notice.SCROLLING then
			self.notices[modLobbyProto.Notice.SCROLLING] = {}
		end
		-- set notices value
		if notices then
			if notices.t == modLobbyProto.Notice.SCROLLING then
				if type(mes) ~= "table" then
					local mes = string.split(notices.message,"|")
					for _,m in pairs(mes) do
						table.insert(self.notices[modLobbyProto.Notice.SCROLLING],m)
					end
				else
					table.insert(self.notices[modLobbyProto.Notice.SCROLLING],mes)
				end
			elseif notices.t == modLobbyProto.Notice.SYSTEM then
				table.insert(self.notices[modLobbyProto.Notice.SYSTEM],notices.message)
			end
		end
	end
	-- draw notices
	if self.isMoveEnd then
		self:moveNotice(1)
	end
	if self.wnd_system_notice then
		self.wnd_system_notice:setText("    " .. self.notices[modLobbyProto.Notice.SYSTEM][1])
	end
end

pMainMenu.moveNotice = function(self,idx)
	local index = idx
	local noticeSize = table.size(self.notices[modLobbyProto.Notice.SCROLLING])
	local str = self.notices[modLobbyProto.Notice.SCROLLING][index]
	self.wnd_notice:setPosition(self.initPosX + 100,0)
	if self.isMoveEnd then
		self.isMoveEnd = false
		runProcess(1,function()
			self.wnd_notice:setText(str)
			local endTime = 500 * 2
			local startPos = self.initPosX + 100
			local distance = (-self.wnd_notice:getTextControl():getWidth() - 50) - startPos
			if self.wnd_notice:getText() then
				for i = 1, endTime 	do
					local nx = modEasing.linear(i,startPos,distance,endTime)
					self.wnd_notice:setPosition(nx,self.wnd_notice:getY())
					if self.breakFlag == true then
						break
					end
					yield()
				end
			end
			if self.isMoveEnd ~= nil and self.breakFlag == false then
				self.isMoveEnd = true
			end
			index = index + 1
			if index > noticeSize then
				index = 1
			end
			if self.breakFlag == false then
				self:moveNotice(index)
			end
		end)
	end
end


pMainMenu.clearText = function(self)
	self.wnd_notice:setText("")
	if self.wnd_system_notice then
		self.wnd_system_notice:setText("")
	end
end

pMainMenu.startMove = function(self)
	self.isMoveEnd = true
	self:clearText()
end

pMainMenu.getSelfUid = function(self)
	return modUserData.getUID()
end

pMainMenu.isInvited = function(self)
	local inviteCode = modUserData.getInviteCode()
	if inviteCode and inviteCode ~= 0 then
		return true
	end
	return false
end


pMainMenu.isHideInviteWnd = function(self)
	return self:isInvited()
end

pMainMenu.getRemoveDistance = function(self)
	return 0
end

pMainMenu.getBottomParent = function(self)
	return self.wnd_bottom
end

pMainMenu.initWndPos = function(self)
	local width  = gGameWidth
	local height = gGameHeight
	-- 底部
	local bottomWidth = self:getBottomParent():getWidth() - self:getRemoveDistance()
	local distance = (bottomWidth - 5 * self.btn_share:getWidth()) / 6
	local textDis = (distance + self.btn_share:getWidth()) / 2
	self.btn_share:setPosition(distance, 0)
	self.btn_standings:setPosition(self.btn_share:getX() + self.btn_share:getWidth() + distance, 0)
	self.btn_howtoplay:setPosition(self.btn_standings:getX() + self.btn_standings:getWidth() + distance, 0)
	self.btn_setting:setPosition(self.btn_howtoplay:getX() + self.btn_howtoplay:getWidth() + distance, 0)
	self.btn_add_roomcard:setPosition(self.btn_setting:getX() + self.btn_setting:getWidth() + distance, 0)
end

pMainMenu.closeClub = function(self)
	local modClubMain = import("ui/club/main.lua")
	if modClubMain.pClubMain:getInstance() then
		modClubMain.pClubMain:instance():close()
	end
end

pMainMenu.closeCreateRoom = function(self)
	if modMainCreate.pMainCreate:getInstance() then
		modMainCreate.pMainCreate:instance():destroy()
	end
end

pMainMenu.close = function(self)
	self.isMoveEnd = nil
	self:closeClub()
	if self.__room_card_hdr then
		modUserData.unbind("roomCards", self.__room_card_hdr)
		self.__room_card_hdr = nil
	end
	if self.__name_hdr then
		modUserData.unbind("userName", self.__name_hdr)
		self.__name_hdr = nil
	end
	if self.__avatarUrl__hdr then
		modUserData.unbind("avatarUrl", self.__avatarUrl__hdr)
        self.__avatarUrl__hdr = nil
	end
	if self.__gold__hdr then
		modUserData.unbind("goldCount", self.__gold__hdr)
        self.__gold__hdr = nil
	end

	if self.__process_mail_hdr then
		modEvent.removeListener(self.__process_mail_hdr)
        self.__process_mail_hdr = nil
	end

	self.initPosX = nil
	for _,v in pairs(self.notices) do
		v = {}
	end

	if self.controls then
		for _, wnd in pairs(self.controls) do
			wnd:setParent(nil)
		end
		self.controls = {}
	end
	if self.jzeye then
		self.jzeye:stop()
		self.jzeye = nil
	end
	self.breakFlag = true
	self.hairRight = 1
	self.notices = {}
	modUserData.pUserData:instance():destory()
	modSound.getCurSound():stopMusic()
	self:closeCreateRoom()
	self:setParent(nil)
end
