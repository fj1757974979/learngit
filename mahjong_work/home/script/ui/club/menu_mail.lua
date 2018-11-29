local modWndList = import("ui/common/list.lua")
local modEvent = import("common/event.lua")
local modUIUtil = import("ui/common/util.lua")
local modMailMgr = import("logic/mail/main.lua")
local modMailWnd = import("ui/club/mail.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")

pMenuMail = pMenuMail or class(pWindow, pSingleton)

pMenuMail.init = function(self)
	self:load("data/ui/club_desk_list_mail.lua")
end

pMenuMail.open = function(self, clubInfo, host)
	self:setParent(host)
	self.host = host
	self.mailControls = {}
	self:initUI()
	self:regEvent()
	self:chkClick(self.chk_all)
	modUIUtil.makeModelWindow(self, false, false)
end

pMenuMail.initUI = function(self)
	self.chk_join["mark"] = modMailProto.Mail.JOIN_CLUB
	self.chk_donate["mark"] = modMailProto.Mail.RETURN_GOLD_COINS_TO_CLUB
	--self.chk_all:setText("全部")
	--self.chk_join:setText("申请列表")
	--self.chk_donate:setText("捐赠列表")
end

pMenuMail.regEvent = function(self)
	self.chk_all:addListener("ec_mouse_click", function() 
		self:chkClick(self.chk_all)
	end)

	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)

	self.chk_join:addListener("ec_mouse_click", function() 
		self:chkClick(self.chk_join)
	end)

	self.chk_donate:addListener("ec_mouse_click", function() 
		self:chkClick(self.chk_donate)
	end)
end

pMenuMail.chkClick = function(self, chk)
	if not chk then return end
	chk:setCheck(true)
	modMailMgr.getCurMail():getMailsByMailType(chk["mark"], function(reply)
		self:showMails(reply)
	end)
end

pMenuMail.sortMails = function(self, mails)
	if not mails then return end
	table.sort(mails, function(mail1, mail2)
		return mail1.id > mail2.id
	end)
end

pMenuMail.showMails = function(self, mailDatas)
	-- 先清理
	self:refreshClear()
	if not mailDatas or table.getn(mailDatas) <= 0 then
		self.wnd_list:setText("没有需要处理的邮件")
		return
	end
	-- 过滤
	local mails = {}
	for _, mail in ipairs(mailDatas) do
		if mail.state ~= modMailProto.Mail.PROCESSED then
			table.insert(mails, mail)
		end
	end
	if not mails or table.getn(mails) <= 0 then
		self.wnd_list:setText("没有需要处理的邮件")
		return
	end
	-- 排序
	self:sortMails(mails)

	self.wnd_list:setText("")
	-- 滑动窗口
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	-- 描画
	local y = 10
	for _, mail in pairs(mails) do
		local wnd = mail:newMailPanel(self)
		wnd:setParent(self.dragWnd)
		wnd:setPosition(0, y)
		y = y + wnd:getHeight() + 10
		table.insert(self.mailControls, wnd)
	end
	-- 
	self.dragWnd:setSize(self.wnd_list:getWidth(), y + 200)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self.wnd_list)
end

pMenuMail.clearMailContorls = function(self)
	if not self.mailControls then return end
	if table.getn(self.mailControls) <= 0 then return end
	for _, wnd in pairs(self.mailControls) do
		wnd:setParent(nil)
	end
	self.mailControls = {}
end

pMenuMail.refreshClear = function(self)
	self:clearMailContorls()
	self:clearDragWnd()
	self:clearWindowList()
	self:initUI()
end

pMenuMail.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pMenuMail.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end

pMenuMail.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(100, 100)
	pWnd:setParent(self.wnd_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pMenuMail.closeUpdateHasNewMail = function(self)
	if self.host then
		self.host:updateHasNewMails()
	end
--[[	modMailMgr.getCurMail():updateHasNewMails(function(hasNewMails)
		modEvent.fireEvent(EV_PROCESS_MAIL, hasNewMails)
	end)	]]--
end

pMenuMail.close = function(self)
	--if self.host then
		--self.host:menuCloseClick()
		--self.host = nil
	--end
	modMailMgr.getCurMail():writeMails()
	self:closeUpdateHasNewMail()
	self:clearDragWnd()
	self:clearWindowList()
	self:clearMailContorls()
	if self.host then 
		self.host = nil
	end
	pMenuMail:cleanInstance()
end
