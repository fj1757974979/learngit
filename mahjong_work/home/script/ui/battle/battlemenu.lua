local modUIUtil = import("ui/common/util.lua")
local modSet = import("ui/menu/set.lua")
local modCommonCue = import("ui/common/common_cue.lua")
local modDismissMgr = import("logic/dismiss/main.lua")

pBattleMenu = pBattleMenu or class(pWindow)

pBattleMenu.init = function(self, host, gameType)
	logv("info","pBattleMenu.init")
	self:load("data/ui/battlemenu.lua")
	self.host = host
	self.menuMgr = modDismissMgr.pDismissMgr:instance(gameType)
	self:setParent(host.wnd_table)
	self:initUI()
	self:regEvent()

	modUIUtil.makeModelWindow(self, true, true)
	self:setZ(C_BATTLE_UI_Z)
end

pBattleMenu.initUI = function(self)
	-- 没有开始游戏，不是房主显示为离开
	if not self.menuMgr:getIsGaming() then
		if not self.menuMgr:getIsOwner() then
			self.btn_dismiss:setImage("ui:battle_leave_room.png")
			self.wnd_dismiss_text:setImage("ui:battle_leave_room_text.png")
		end
	end
	-- 录像
	if self.menuMgr:getIsVideoState() then
		self.btn_dismiss:show(false)
	end
	-- 俱乐部房间
	if self.menuMgr:getGameType() ~= T_POKER_ROOM and
		self.menuMgr:isClubRoom() then
		self.btn_dismiss:show(not self.menuMgr:getIsGaming())
		self.btn_dismiss:setImage("ui:battle_leave_room.png")
		self.wnd_dismiss_text:setImage("ui:battle_leave_room_text.png")
	end
end

pBattleMenu.regEvent = function(self)
	self.btn_set:addListener("ec_mouse_click", function()
		self:showCloseRoom()
	end)

	self.btn_help:addListener("ec_mouse_click", function()
		local modRuleInfo = import("ui/menu/rule.lua")
		modRuleInfo.pRule:instance():showWeb()
	end)

	self.btn_change_table:addListener("ec_mouse_click", function()
		infoMessage("此功能暂未开放，敬请期待")
	end)


	self.btn_dismiss:addListener("ec_mouse_click", function()
		self:dismiss()
	end)

	self.btn_hide:addListener("ec_mouse_click", function()
		self:hideSelf()
	end)
end

pBattleMenu.showCloseRoom = function(self)
	modSet.pSetMain:instance():open(true, not self.isOwner)
end

pBattleMenu.dismiss = function(self)
	if self.menuMgr:isObserver() then
		self:leaveRoom()
		return
	end
	if self.menuMgr:getIsGaming() then
		if self.menuMgr:getGameType() == T_POKER_ROOM or
			not self.menuMgr:isClubRoom() then
			self:showIsSure()
		end
	else
		if self.menuMgr:isClubRoom() then
			self:leaveRoom()
		else
			if self.menuMgr:getIsOwner() then
				self:showIsSure()
			else
				self:leaveRoom()
			end
		end
	end
end

pBattleMenu.leaveRoom = function(self)
	self.menuMgr:leaveRoom(function(success, reason)
		if not success then
			self:hideSelf()
		end
	end)
end

pBattleMenu.showIsSure = function(self)
	local roomId = self.menuMgr:getRoomId()
	modCommonCue.pCommonCue:instance():open(self, roomId, self.menuMgr:getGameType())
	self:close()
end

pBattleMenu.hideSelf = function(self)
	if self.ruleWnd then
		self.ruleWnd:setParent(nil)
		self.ruleWnd = nil
	end
	if modSet.pSetMain:getInstance() then
		modSet.pSetMain:instance():close()
	end
	if not self.host then
		self:setParent(nil)
		return
	end
	if self.host.clearMenuWnd then
		self.host:clearMenuWnd()
	else
		self:show(false)
	end
	if self.menuMgr then
		self.menuMgr:destroy()
		self.menuMgr = nil
	end
end
