local modClubRpc = import("logic/club/rpc.lua")
local modEvent = import("common/event.lua")
local modWndList = import("ui/common/list.lua")
local modUIUtil = import("ui/common/util.lua")
local modClubMgr = import("logic/club/main.lua")
local modMemberInfo = import("ui/club/member_info.lua")
local modUserData = import("logic/userdata.lua")

pMenuMember = pMenuMember or class(pWindow, pSingleton)

pMenuMember.init = function(self)
	self:load("data/ui/club_desk_list_member.lua")
end

pMenuMember.open = function(self, clubInfo, host)
	self:setParent(host)
	self.host = host
	self.clubInfo = modClubMgr.getCurClub():getClubById(clubInfo:getClubId()) 
	self.controls = {}
	self:initUI()
	self:regEvent()
	self:refreshMember()
	modUIUtil.makeModelWindow(self, false, false)
end

pMenuMember.refreshMember = function(self)
	if not self.clubInfo then return end
	self.clubInfo:getMemberInfos(function(memberInfos)
		self.memberInfos = memberInfos
		self:showMemberInfos(self.memberInfos)
	end)
end

pMenuMember.updateMemberInfo = function(self)
	if not self.memberInfos then return end
	for _, info in pairs(self.memberInfos) do
		if info:getUid() == modUserData.getUID() then
			info:updateSelf()
			break
		end
	end
end

pMenuMember.showMemberInfos = function(self, members)
	if not members or table.size(members) <= 0 then
		infoMessage("找不到成员信息")
		return 
	end
	-- 转换
	local memberInfos = {}
	for _, m in pairs(members) do
		table.insert(memberInfos, m)
	end
	-- 金豆数量
	table.sort(memberInfos, function(m1, m2)
		return m1:getGold() > m2:getGold()
	end)

	-- 先清理
	self:clearControls()
	self:clearDragWnd()
	self:clearWindowList()
	-- 滑动窗口
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)

	-- 描画
	local y = 5
	for _, info in pairs(memberInfos) do
		local wnd = self:newMemberInfo(info, y)
		y = y + wnd:getHeight()
	end
	self.dragWnd:setSize(self.wnd_list:getWidth(),  y + 100)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self.wnd_list)
	
	-- 取玩家属性设置姓名
	if self.userProps then
		self:setWndProp(self.userProps)
	else
		self:getUserPropsToWnd(memberInfos)
	end
	local totalGold = 0
	for _, m in pairs(memberInfos) do
		local memberGold = m:getGold()
		totalGold = totalGold + memberGold
	end
	self.total_gold:setText(sf(totalGold))
end

pMenuMember.presentGold = function(self, junor)
	if not junor then return end
	junor:presentGold(self.memberInfos)
end

pMenuMember.grantGold = function(self, junor)
	if not junor then return end
	junor:grantGold(self.memberInfos)
end

pMenuMember.newMemberInfo = function(self, info, y)
	if not info or not y then return end
	local wnd = modMemberInfo.pMemberInfo:new(info, self.clubInfo, self)	
	wnd:setParent(self.dragWnd)
	wnd:setPosition(0, y)
	table.insert(self.controls, wnd)
	return wnd
end

pMenuMember.getUserPropsToWnd = function(self, memberInfos)
	if not memberInfos then return end
	-- 取uids
	local uids = {}
	for _, info in pairs(memberInfos) do
		table.insert(uids, info:getUid())
	end
	
	-- 取玩家属性
	local modBattleRpc = import("logic/battle/rpc.lua")
	modBattleRpc.getMultiUserProps (uids, { "name" }, function(success, reason, reply)
		if not self.controls or table.getn(self.controls) <= 0 then return end
		self.userProps = reply.multi_user_props
		self:setWndProp(self.userProps)
	end)
end

pMenuMember.findSerachUser = function(self)
	if not self.userProps then 
		infoMessage("数据正在加载中，请稍后再试。")
		return
	end
	local text = self.edit_search:getText()
	if not text or text == "" then 
		infoMessage("请输入搜索信息")
		return 
	end
	local findUsers = {}
	for _, prop in ipairs(self.userProps) do
		local name = prop.nickname
		local uid = prop.user_id
		if string.find(name, text) then
			table.insert(findUsers, uid)
		end
	end
	if table.getn(findUsers) <= 0 then return end

	local tmps = {}
	for _, member in pairs(self.memberInfos) do
		if self:findUidIsInList(member:getUid(), findUsers) then
			table.insert(tmps, member)
		end
	end
	self:showMemberInfos(tmps)
end

pMenuMember.findUidIsInList = function(self, uid, list)
	if not uid or not list then return end
	for _, id in pairs(list) do
		if id == uid then
			return true
		end
	end
	return
end

pMenuMember.setWndProp = function(self, props)
	for _, wnd in pairs(self.controls) do
		local prop = self:findPropInReplys(wnd:getUid(), props)
		wnd:setName(prop.nickname)
	end
end

pMenuMember.searchById = function(self, uid, memberInfos)
	if not uid then return end
	if not self.memberInfos then return end
	-- 找对应玩家
	local tmps = {}
	for _, info in ipairs(self.memberInfos) do
		if info:getUid() == uid then
			table.insert(tmps, info)
			break
		end
	end
	if table.size(tmps) <= 0 then return false end	
	-- 显示该玩家
	self:showMemberInfos(tmps)
	return true
end

pMenuMember.findPropInReplys = function(self, uid, props)
	if not uid or not props then return end
	for _, prop in ipairs(props) do
		local tuid = prop.user_id
		if tuid == uid then
			return prop
		end
	end
	return
end

pMenuMember.clearControls = function(self)
	if not self.controls then return end
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
end

pMenuMember.initUI = function(self)
	--self.txt_name:setText("名称")
	--self.txt_id:setText("ID")
	--self.txt_coin:setText("金豆")
	self.txt_search:setText(TEXT("输入玩家ID查找"))
	--self.btn_search:setText("搜索")
	self.txt_total:setText("总金豆")
end

pMenuMember.regEvent = function(self)
	self.edit_search:addListener("ec_focus", function() 
		self.txt_search:setText("")
	end)

	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)

	self.edit_search:addListener("ec_unfocus", function()
		local text = self.edit_search:getText()
		if not text or text == "" then
			self.txt_search:setText(TEXT("输入玩家ID查找"))
		end
	end)

	self.btn_search:addListener("ec_mouse_click", function() 
		self:searchInfos()
	end)
end

pMenuMember.searchInfos = function(self)
	local text = self.edit_search:getText()
	if not text or text == "" then
		infoMessage("请输入搜索信息")
		self:showMemberInfos(self.memberInfos)
		return
	end
	if tonumber(text) then
		local isSearched = self:searchById(tonumber(text), self.memberInfos)
		if not isSearched then
			self:findSerachUser()
		end
	else
		self:findSerachUser()
	end
end

pMenuMember.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(self.wnd_list:getWidth(), self.wnd_list:getHeight() / 2)
	pWnd:setParent(self.wnd_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pMenuMember.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pMenuMember.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end

pMenuMember.close = function(self)
	--if self.host then
		--self.host:menuCloseClick()
		--self.host = nil
	--end
	self.clubInfo = nil
	self:clearDragWnd()
	self:clearWindowList()
	self:clearControls()
	pMenuMember:cleanInstance()
end
