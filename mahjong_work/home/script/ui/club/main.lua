local modClubMgr = import("logic/club/main.lua")
local modEvent = import("common/event.lua")
local modWndList = import("ui/common/list.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modUserData = import("logic/userdata.lua")
local modClubInfo = import("ui/club/main_info.lua")
local modMailMgr = import("logic/mail/main.lua")
local modRulePanel = import("ui/common/rule_panel.lua")

pClubMain = pClubMain or class(pWindow, pSingleton)

pClubMain.init = function(self)
	self:load("data/ui/club_main.lua")
	self:setParent(gWorld:getUIRoot())
	self:showDianWnd(false)
	self:initUI()
	self:regEvent()
	self:updateHasNewMails()
	modUIUtil.makeModelWindow(self, false, true)
end

pClubMain.initUI = function(self)
	self.dragWidth = self.club_list:getWidth()
	self.dragHeight = self.club_list:getHeight()
	self.infoX = 10
	self.infoY = 10
	self.infoDistanceX = 10
	self.infoDistanceY = 10
	--self.btn_rule:setText("点击查看帮助")
end

pClubMain.regEvent = function(self)

	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)

	self.btn_down:addListener("ec_mouse_click", function() 
		self:downList()
	end)

	self.btn_rule:addListener("ec_mouse_click", function()
		pClubMainDesc:instance():open()
	end)

	self.btn_mail:addListener("ec_mouse_click", function() 
		local modMenuMail = import("ui/club/menu_mail.lua")
		modMenuMail.pMenuMail:instance():open(nil, self)
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
end

pClubMain.updateHasNewMails = function(self)
	modMailMgr.getCurMail():updateHasNewMails()
end

pClubMain.showDianWnd = function(self, isShow)
	self.wnd_dian:show(isShow)
end

pClubMain.open = function(self)
	modClubMgr.getCurClub():getAllClubs(function(clubs)
		self.clubs = clubs
		self:showClubInfo(clubs)
	end)
end

pClubMain.refreshClubs = function(self)
	modClubMgr.getCurClub():refreshMgrClubs()
end

pClubMain.showClubInfo = function(self, clubs)
	-- 先清除
	self:refreshClear()
	if not clubs or table.size(clubs) <= 0 then
	--	self:close()
		self.club_list:setText("您还没有俱乐部，快创建或者加入一个俱乐部吧")
		return
	else
		self.club_list:setText("")
	end
	-- 滑动窗口
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self.club_list:getWidth(), self.club_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	-- 创建的俱乐部信息
--	self:showCreateClubInfo()
	self:showClubs(clubs)
end

pClubMain.showClubs = function(self, clubs)
	if not clubs then return end
	self:newClubInfoWndByInfos(clubs)
	self.dragWnd:setSize(self.dragWidth, self.dragHeight)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self.club_list)
end

pClubMain.newClubInfoWndByInfos = function(self, infos)
	if not infos then return end
	local index = 0
	for _, info in pairs(infos) do
		index = index + 1
		local wnd = self:newClubInfoWnd(info)
		self.infoX = self.infoX + wnd:getWidth() + self.infoDistanceX
		if index % 2 == 0 then
			self.infoX = 10
			self.infoY = self.infoY + wnd:getHeight() + self.infoDistanceY
		end
	end
	if self.infoY > self.dragHeight then
		self.dragHeight = self.infoY
		self.dragWnd:setSize(self.dragWidth, self.dragHeight)
	end
end

pClubMain.newClubInfoWnd = function(self, info)
	if not info then return end
	if not self.infoControls then self.infoControls = {} end
	local wnd = modClubInfo.pMainClubInfo:new(info, self)
	wnd:setPosition(self.infoX, self.infoY)
	wnd:setParent(self.dragWnd)
	table.insert(self.infoControls, wnd)	
	return wnd
end

pClubMain.clubClick = function(self, clubWnd)
	if not clubWnd then return end
	self:clearDownlistWnd()
	clubWnd:clubClick()
end

pClubMain.downList = function(self)
	if self.downlistWnd then 
		self:clearDownlistWnd()
	else
		local modDownlist = import("ui/club/main_down_list.lua")
		self.downlistWnd = modDownlist.pClubDownlist:new(self)	
	end
end

pClubMain.clearDownlistWnd = function(self)
	if not self.downlistWnd then return end
	self.downlistWnd:setParent(nil)
	self.downlistWnd = nil
end

pClubMain.clearInfoControls = function(self)
	if not self.infoControls then return end
	for _, wnd in pairs(self.infoControls) do
		wnd:setParent(nil)
	end
	self.infoControls = {}
end

pClubMain.getClubMgr = function(self)
	return modClubMgr.pClubMgr:instance()
end

pClubMain.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(self.dragWidth, self.dragHeight)
	pWnd:setParent(self.club_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pClubMain.getNewTableIds = function(self, ids)
	if not ids then return end
	local tmps = {}
	for _, id in ipairs(ids) do
		table.insert(tmps, id)
	end
	return tmps
end

pClubMain.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pClubMain.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end

pClubMain.refreshClear = function(self)
	self:clearInfoControls()
	self:clearDragWnd()
	self:clearWindowList()
	self:initUI()
end

pClubMain.clearMainDesk = function(self)
	local modMainDsk = import("ui/club/main_desk.lua")
	if modMainDsk.pMainDesk:getInstance() then
		modMainDsk.pMainDesk:instance():close()
	end
end

pClubMain.clearCreatorPanel = function(self)
	local modCreatorPanel = import("ui/club/creator_ground_panel.lua")
	if modCreatorPanel.pCreatorPanel:getInstance() then
		modCreatorPanel.pCreatorPanel:instance():close()
	end
end

pClubMain.close = function(self)
	self:clearWindowList()
	self:clearDragWnd()
	self:clearDownlistWnd()
	self:clearMainDesk() -- ari
	self:clearCreatorPanel()
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
	modClubMgr.pClubMgr:instance():destroy()
	pClubMain:cleanInstance()
end


pClubMainDesc = pClubMainDesc or class(modRulePanel.pRulePanel, pSingleton)

pClubMainDesc.open = function(self)
	local message = ""
	local channel = modUtil.getOpChannel()
	if channel == "nc_tianjiuwang" then
		message = TEXT("#cr1.如何创建我的俱乐部？#n\n答：点击左上角<+>按钮，选择<创建俱乐部>。创建俱乐部需要消耗一定的房卡。\n\n#cr2.如何加入一个俱乐部？#n\n答：点击左上角<+>按钮，选择<加入俱乐部>。可通过俱乐部ID、地区、或者名字搜索指定的俱乐部，然后<申请加入>等待管理员批准即可。\n\n#cr3.我可以创建/加入多少个俱乐部？#n\n答：加入无限制，创建默认为2个\n\n#cr4.我可以退出/解散俱乐部吗？#n\n答：可以，但请注意，<退出>会将你在该俱乐部的数据清除。如果你是俱乐部管理员，<解散>会清除俱乐部成员所有数据。")
	else
		message = TEXT("#cr1.如何创建我的俱乐部？#n\n答：点击左上角<+>按钮，选择<创建俱乐部>。创建俱乐部需要消耗一定的钻石。\n\n#cr2.如何加入一个俱乐部？#n\n答：点击左上角<+>按钮，选择<加入俱乐部>。可通过俱乐部ID、地区、或者名字搜索指定的俱乐部，然后<申请加入>等待管理员批准即可。\n\n#cr3.我可以创建/加入多少个俱乐部？#n\n答：加入无限制，创建默认为3个（不同的运营商会设定不同的上限）\n\n#cr4.我可以退出/解散俱乐部吗？#n\n答：可以，但请注意，<退出>会将你在该俱乐部的数据清除。如果你是俱乐部管理员，<解散>会清除俱乐部成员所有数据。")
	end
	modRulePanel.pRulePanel.open(self, message, "ui:public_title.png")
end

pClubMainDesc.cleanSelfInstance = function(self)
	pClubMainDesc:cleanInstance(self)
end
