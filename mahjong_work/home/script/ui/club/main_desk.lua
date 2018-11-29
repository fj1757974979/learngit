local modClubMgr = import("logic/club/main.lua")
local modMailMgr = import("logic/mail/main.lua")
local modEvent = import("common/event.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modMember = import("logic/club/member.lua")
local modClub = import("logic/club/club.lua")
local modMenuDesk = import("ui/club/menu_desk.lua")
local modRulePanel = import("ui/common/rule_panel.lua")

pMainDesk = pMainDesk or class(pWindow, pSingleton)

pMainDesk.init = function(self)
	self:load("data/ui/club_desk.lua")
	self:setParent(gWorld:getUIRoot())
	self:showDianWnd(false)
	modUIUtil.makeModelWindow(self, false, true)
end

pMainDesk.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_rule:addListener("ec_mouse_click", function()
		pClubDeskDesc:instance():open()
	end)

	self.btn_add_coin:addListener("ec_mouse_click", function() 
		self:addClubGold()	
	end)

	self.btn_add_tip:addListener("ec_mouse_click", function()
		self:showGetCoinMessage()
	end)

	self.__club_name_hdr = self.clubInfo:bind("name", function(cur, prev, defVal)
		self.wnd_name:setText(cur)
	end)

	self.__club_avatar_hdr = self.clubInfo:bind("avatar", function(cur, prev, defVal)
		self.wnd_image:setImage(cur)
	end)

	self.__club_gold_hdr = self.clubInfo:bind("gold", function(cur, prev, defVal) 
		self.club_coin:setText("" .. cur)
	end)

	self.__club_max_memeber = self.clubInfo:bind("max_member", function(cur, prev, defVal)
		self.wnd_member:setText(table.getn(self.clubInfo:getMemberUids()) .. " / " .. cur)
	end)

	self.__club_refresh_ground = self.clubInfo:bind("ground_ids", function()
--		self:refreshGrounds()
	end)

	self.chk_record:addListener("ec_mouse_click", function()
		self:updateCurrClubInfo(function() 
			local modMenuRecord = import("ui/club/menu_record.lua")
			modMenuRecord.pMenuRecord:instance():open(self.clubInfo, gWorld:getUIRoot(), self.selfMemberInfo)
		end)
	end)
	self.chk_member:addListener("ec_mouse_click", function()
		self:updateCurrClubInfo(function() 
			local modMenuMember = import("ui/club/menu_member.lua")
			modMenuMember.pMenuMember:instance():open(self.clubInfo, self)
		end)
	end)
	self.chk_info:addListener("ec_mouse_click", function()
		self:updateCurrClubInfo(function() 
			local modMenuInfo = import("ui/club/menu_info.lua")
			modMenuInfo.pMenuInfo:instance():open(self.clubInfo, self)
		end)
	end)
	self.chk_mail:addListener("ec_mouse_click", function()
		self:updateCurrClubInfo(function() 
			local modMenuMail = import("ui/club/menu_mail.lua")
			modMenuMail.pMenuMail:instance():open(self.clubInfo, self)
		end)
	end)
	self.__process_mail_hdr = modEvent.handleEvent(EV_PROCESS_MAIL, function(hasNewMails)
		self:showDianWnd(hasNewMails)
	end)

	self.__battle_begin_hdr = modEvent.handleEvent(EV_BATTLE_BEGIN, function()
		self:show(false)
	end)

	self.__battle_end_hdr = modEvent.handleEvent(EV_BATTLE_END, function() 
		self:show(true)
	end)

	self.chk_share:addListener("ec_mouse_click", function()
		local modChannelMgr = import("logic/channels/main.lua")
		local id = self.clubInfo:getClubId()
		local name = self.clubInfo:getClubName()
		local downLoadLink = modChannelMgr.getCurChannel():getShareClubUrl(id)
		local desc = self.clubInfo:getDesc()
		local modClubShareMgr = import("logic/share/club_share_mgr.lua")
		modClubShareMgr.pClubShareMgr:instance(name, id, desc, downLoadLink):showSharePanel()
	end)
end

pMainDesk.updateCurrClubInfo = function(self, callback)
	modClubMgr.getCurClub():updateClubInfoById(self.clubInfo:getClubId(), function(info)
		if not info then
			if self.host then
				self.host:refreshClubs()
			end
			self:close()
			return
		end
		self.clubInfo = info
		if callback then
			callback(info)
		end
	end)
end

pMainDesk.updateHasNewMails = function(self)
	modMailMgr.getCurMail():updateHasNewMails()
end

pMainDesk.showDianWnd = function(self, isShow)
	self.wnd_dian:show(isShow)
end


pMainDesk.showGetCoinMessage = function(self)
	if self:getIsCreator() then
		local modGrant = import("ui/club/grant.lua")
		local modUserData = import("logic/userdata.lua")
		modGrant.pGrant:instance():open(self.clubInfo, nil, modUserData.getUID())
		return
	end

	if self.creatorName then
		infoMessage(sf("如需金豆请联系管理员：\n #co%s#n", self.creatorName))
		return 
	end
	local uid = self.clubInfo:getCreator()
	if not uid then return end
	local modBattleRpc = import("logic/battle/rpc.lua")
	modBattleRpc.updateUserProps(uid, function(success, reply) 
		local name = reply.nickname
		if modUIUtil.utf8len(name) > 6 then
			name = modUIUtil.getMaxLenString(name, 6)
		end
		self.creatorName = name
		infoMessage(sf("如需金豆请联系管理员：\n #co%s#n", self.creatorName))
	end)
end

pMainDesk.addClubGold = function(self)
	local modExchangeWnd = import("ui/club/exchange.lua")
	modExchangeWnd.pExchange:instance():open(self.clubInfo, self)
end

pMainDesk.refreshClubInfo = function(self)
	modClubMgr.getCurClub():getClubInfos({ self.clubInfo:getClubId() }, function(reply) 
		if not reply then 
			return 
		end
		local infos = reply.clubs
		self.clubInfo = modClub.pClubObj:new(infos[table.getn(infos)])	
		self:initUI()
	end)	
end

pMainDesk.updateSelfMemberInfo = function(self)
	if not self.selfMemberInfo then return end
	self.selfMemberInfo:updateSelf()
end

pMainDesk.refreshMemberInfo = function(self, reply)
	if not reply then return end
	local clubId = reply.club_id
	local gold = reply.gold_coin_count
	local uid = reply.user_id
	if clubId ~= self.clubInfo:getClubId() then return end
	self.selfMemberInfo:modifyProp("self_gold", gold - self.selfMemberInfo:getGold())
	self.selfMemberInfo:setGold(gold)
--	self:updateMemberGold()
--	self.selfMemberInfo:updateSelf()
end

pMainDesk.open = function(self, clubInfo, host)
	modClubMgr.getCurClub():updateClubInfoById(clubInfo:getClubId(), function(info)
		if not info then
			host:refreshClubs()
			self:close()
			return	
		end
		self.host = host
		self.clubInfo = info 
		self:initUI()
		self:regEvent()
		self:getMemberInfo()
		self:updateHasNewMails()
		self:drawGrounds()
	end)
end

pMainDesk.refreshGrounds = function(self)
	modClubMgr.getCurClub():updateClubInfoById(self.clubInfo:getClubId(), function(reply)
		if not reply then
			self:close()	
			return
		end
		self.clubInfo = reply
		self:drawGrounds()
	end)
end

pMainDesk.clearMenuDesk = function(self)
	if modMenuDesk.pMenuDesk:getInstance() then
		modMenuDesk.pMenuDesk:instance():close()
	end
end

pMainDesk.drawGrounds = function(self)
	-- 清除窗口
	self:clearMenuDesk()
	modMenuDesk.pMenuDesk:instance():open(self.clubInfo, self, self.bg2)
end

pMainDesk.initUI = function(self)
	if not self:getIsCreator() then self.club_coin:show(false) end
	self.wnd_id:setText(sf("ID:  %06d", self.clubInfo:getClubId()))
end

pMainDesk.getIsCreator = function(self)
	return self.clubInfo:getIsCreator(self.clubInfo) 
end

pMainDesk.getMemberInfo = function(self, callback)
	self.clubInfo:getSelfMember(function(selfMemberInfo)
		self.selfMemberInfo = selfMemberInfo
		if not self.__self_gold_hdr then
			self.__self_gold_hdr = self.selfMemberInfo:bind("self_gold", function(cur, prev, defVal) 
				self.my_coin:setText(sf("%d", cur))
			end)
		end
		if callback then
			callback(self.selfMemberInfo)
		end
	end)
end

pMainDesk.clearCreateClub = function(self)
	local modClubCreate = import("ui/club/create_ground.lua")
	if modClubCreate.pMainCreate:getInstance() then
		modClubCreate.pMainCreate:instance():destroy()
	end
end

pMainDesk.clearRecord = function(self)
	local modMenuRecord = import("ui/club/menu_record.lua")
	if modMenuRecord.pMenuRecord:getInstance() then
		modMenuRecord.pMenuRecord:instance():close()	
	end
end

pMainDesk.close = function(self)
	self:removeEvent()
	self.lastChkMark = nil
	if self.__process_mail_hdr then
		modEvent.removeListener(self.__process_mail_hdr)
        self.__process_mail_hdr = nil
	end
	if self.__battle_begin_hdr then
		modEvent.removeListener(self.__battle_begin_hdr)
		self.__battle_begin_hdr = nil
	end
	if self.__battle_end_hdr then
		modEvent.removeListener(self.__battle_end_hdr)
		self.__battle_end_hdr = nil
	end
	self.host = nil
	self:clearMenuDesk()
	self:clearCreateClub()
	self:clearRecord()
	self.classes = nil
	self.creatorName = nil
	pMainDesk:cleanInstance()
end

pMainDesk.removeWork = function(self, name, event)
	if event then
		modEvent.removeListener(name, event)
		if self.clubInfo then
			self.clubInfo:unbind(name, event)
		end
		event = nil
	end
end

pMainDesk.menuCloseClick = function(self)
--	self:saveLastClick("desk")
end

pMainDesk.removeEvent = function(self)
	local list = {
		["name"] = self.__club_name_hdr,
		["avatar"] = self.__club_avatar_hdr,
		["gold"] = self.__club_gold_hdr,
		["max_member"] = self.__club_max_memeber,
		["self_gold"] = self.__self_gold_hdr,
		["ground_ids"] = self.__club_refresh_ground,
	}
	for name, event in pairs(list) do
		self:removeWork(name, event)
	end
end

pClubDeskDesc = pClubDeskDesc or class(modRulePanel.pRulePanel, pSingleton)

pClubDeskDesc.open = function(self)
	local message = ""
	local channel = modUtil.getOpChannel()
	if channel == "nc_tianjiuwang" then
		message = TEXT("#cr1.金豆干什么用的？#n\n答：俱乐部内部使用金豆作为积分进行游戏，金豆由管理员发放。如果不再进行游戏，可以赠送给俱乐部其他成员或俱乐部。\n声明：金豆只用于计分，请勿赌博。\n\n#cr2.金豆从哪里来？#n\n答：管理员提供。俱乐部金豆由管理员从系统兑换，管理员可将俱乐部金豆发放给成员。\n\n#cr3.金豆可以在别的俱乐部用吗？#n\n答：不能，每个俱乐部的金豆只能在所属的俱乐部内部使用，无法携带至其他俱乐部。\n\n#cr4.什么是入场？#n\n答：入场是指是进入牌局所需最低金豆数量。对局中你的金豆低于50%入场要求时，将无法继续对局。\n\n#cr5.什么是小费？#n\n答：小费只是每场对局的大赢家负责支付给系统的金豆，小费1=1个金豆。由管理员决定是否需要支付小费。\n\n#cr6.如果牌局关闭了，对我有影响吗？#n\n答：不会有影响。管理员关闭牌局时，当前未结束的对局会继续进行，直到结算后再离开对局。\n\n#cr7.能中途修改规则吗？#n\n答：不能。牌局规则无法中途修改，只能关闭牌局，再重新开启一个新的牌局。\n\n#cr8. 房费由谁负责？#n\n答：由管理员负责，成员参与游戏无需支付房卡。每场对局消耗管理员6个房卡，管理员房卡不足时，将无法继续对局。")
	else
		message = TEXT("#cr1.金豆干什么用的？#n\n答：俱乐部内部使用金豆作为积分进行游戏，金豆由管理员发放。如果不再进行游戏，可以赠送给俱乐部其他成员或俱乐部。\n声明：金豆只用于计分，请勿赌博。\n\n#cr2.金豆从哪里来？#n\n答：管理员提供。俱乐部金豆由管理员从系统兑换，管理员可将俱乐部金豆发放给成员。\n\n#cr3.金豆可以在别的俱乐部用吗？#n\n答：不能，每个俱乐部的金豆只能在所属的俱乐部内部使用，无法携带至其他俱乐部。\n\n#cr4.什么是底注、入场？#n\n答：底注是指在对局中底番所代表的金豆数量（如1分=5金豆），入场是指是进入牌局所需最低金豆数量。对局中你的金豆低于50%入场要求时，将无法继续对局。\n\n#cr5.什么是小费？#n\n答：小费只是每场对局的大赢家负责支付给系统的金豆，小费1=1个金豆。由管理员决定是否需要支付小费。\n\n#cr6.如果牌局关闭了，对我有影响吗？#n\n答：不会有影响。管理员关闭牌局时，当前未结束的对局会继续进行，直到结算后再离开对局。\n\n#cr7.能中途修改规则吗？#n\n答：不能。牌局规则无法中途修改，只能关闭牌局，再重新开启一个新的牌局。\n\n#cr8. 房费由谁负责？#n\n答：由管理员负责，成员参与游戏无需支付钻石。每场对局消耗管理员4个钻石，管理员钻石不足时，将无法继续对局。")
	end
	modRulePanel.pRulePanel.open(self, message, "ui:public_title.png")
end

pClubDeskDesc.cleanSelfInstance = function(self)
	pClubDeskDesc:cleanInstance(self)
end


