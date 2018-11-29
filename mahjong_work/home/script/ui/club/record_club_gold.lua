local modClubRpc = import("logic/club/rpc.lua")
local modWndList = import("ui/common/list.lua")
local modClubMgr = import("logic/club/main.lua")
local modTrace = import("logic/club/trace.lua")
local modUtil = import("util/util.lua")

pClubGold = pClubGold or class(pWindow)

pClubGold.init = function(self, clubInfo)
	self:load("data/ui/club_desk_list_record_club_record.lua")
	self:setParent(gWorld:getUIRoot())
	self.clubInfo = modClubMgr.getCurClub():getClubById(clubInfo:getClubId()) 
	self.controls = {}
	self.traces = {}
	self:initUI()
	self:regEvent()
end


pClubGold.clearControls = function(self)
	if not self.controls then return end
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
end

pClubGold.getClubDailyStat = function(self)
	modClubMgr.getCurClub():getClubDailyStat(self.clubInfo:getClubId(), function(stats)
		local from, to = 0, 0
		for _, stat in ipairs(stats) do
			from = from + stat.gold_coin_count_from_members
			to = to + stat.gold_coin_count_to_members
		end
		self.wnd_today_present:setText(to)
		self.wnd_today_donate:setText(from)
	end)
end

pClubGold.getGoldTraces = function(self)
	modClubMgr.getCurClub():getGoldTraces(self.clubInfo:getClubId(), function(traces)
		self:showTraces(traces)
	end)
end

pClubGold.getTodayTraces = function(self)
	if not self.traces then return end
	local todays = {}
	local d2 = os.date("%Y%m%d", os.time())
	for _, trace in pairs(self.traces) do
		local d1 = os.date("%Y%m%d", trace:getDate())
		if  d1 == d2 then
			table.insert(todays, trace)
		end
	end

	-- 总发放
	local grantGold = 0
	local donateGold = 0
	for _, trace in pairs(todays) do
		if trace:isGrant() then
			grantGold = grantGold + trace:getGold()
		elseif trace:isDonate() then
			donateGold = donateGold + trace:getGold()
		end
	end
	self.wnd_today_present:setText(sf("%d", grantGold))
	self.wnd_today_donate:setText(sf("%d", donateGold))
end

pClubGold.showTraces = function(self, traces)
	if not traces then return end
	if table.getn(traces) <= 0 then
		self.wnd_list:setText("目前没有金豆记录")
		self.wnd_list:getTextControl():setFontSize(40)
		self.wnd_list:getTextControl():setColor(0xFF930000)
		return
	else
		self.wnd_list:setText("")
	end
	-- 取玩家信息
	local uids = {}
	for _, trace in ipairs(traces) do
		if trace.from_user_id ~= UID_CLUB_ID then
			if not self:findIsInList(trace.from_user_id, uids) then
				table.insert(uids, trace.from_user_id)
			end
		elseif trace.to_user_id ~= UID_CLUB_ID then
			if not self:findIsInList(trace.to_user_id, uids) then
				table.insert(uids, trace.to_user_id)
			end
		end
	end
	--
	local modBattleRpc = import("logic/battle/rpc.lua")
	modBattleRpc.getMultiUserProps(uids, { "name" }, function(success, reason, reply) 
		if success then
			local playerInfos = reply.multi_user_props
			for _, trace in ipairs(traces) do
				local fromUid = trace.from_user_id
				local toUid = trace.to_user_id
				local findUid = nil
				if fromUid ~= UID_CLUB_ID then
					findUid = fromUid
				elseif toUid ~= UID_CLUB_ID then
					findUid = toUid
				end
				local info = self:findProp(findUid, playerInfos)
				table.insert(self.traces, modTrace.pTrace:new(trace, info))
				self:newTracePanels()
			end
			self:getTodayTraces()
		end
	end)
end

pClubGold.sortWnds = function(self)
	if not self.traces then return end
	local T_TYPE_CHARGE = 3
	local T_TYPE_GRANT = 2
	local T_TYPE_DONATE = 1
	local types = { T_TYPE_DONATE, T_TYPE_GRANT, T_TYPE_CHARGE	}
	if not self.curType then 
		self.curType = types[1] 
	else
		self.curType = types[self.curType + 1]
		if not self.curType then
			self.curType = types[1] 
		end
	end
	-- 排序
	local tmps = {}
	for _, trace in pairs(self.traces) do
		if trace:getType() == self.curType then
			table.insert(tmps, trace)
		end
	end
	local last = {}
	for _, trace in pairs(self.traces) do
		local t = types[self.curType + 1]
		if not t then t = types[1] end
		if trace:getType() == t then
			table.insert(tmps, trace)
		elseif trace:getType() ~= self.curType and trace:getType() ~= t then
			table.insert(last, trace)
		end
	end
	self.traces = tmps
	for _, t  in pairs(last) do
		table.insert(self.traces, t)
	end
	self:newTracePanels()
end


pClubGold.newTracePanels = function(self)
	if not self.traces then return end
	-- 先清理
	self:clearControls()
	self:clearDragWnd()
	self:clearWindowList()
	-- 滑动窗口
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)

	local y = 0
	for _, trace in pairs(self.traces) do
		local wnd = trace:newPanel()
		wnd:setParent(self.dragWnd)
		wnd:setPosition(0, y)
		y = y + wnd:getHeight()
		table.insert(self.controls, wnd)
	end

	self.dragWnd:setSize(self.wnd_list:getWidth(),  y + 100)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self.wnd_list)
end

pClubGold.findProp = function(self, uid, props)
	if not uid or not props then return end
	for _, prop in ipairs(props) do
		if uid == prop.user_id then
			return prop
		end
	end
	return nil
end

pClubGold.findIsInList = function(self, id, list)
	if not id or not list then return end
	for _, i in pairs(list) do
		if i == id then
			return i
		end
	end
	return false
end

pClubGold.initUI = function(self)
	self.txt_club_coin:setText("俱乐部金豆：")
	self.txt_today_present:setText("今日发放：")
	self.txt_today_donate:setText("今日获赠：")
	--self.txt_name:setText("名字")
	--self.txt_id:setText("ID")
	--self.btn_type:setText("类型")
	--self.txt_num:setText("数量")
	--self.txt_time:setText("时间")
	self:getClubDailyStat()
	self:getGoldTraces()
end

pClubGold.regEvent = function(self)
	self.btn_type:addListener("ec_mouse_click", function()
		self:sortWnds()
	end)

	self.__club_gold_hdr = self.clubInfo:bind("gold", function(cur, prev, defVal)
		self.wnd_club_coin:setText(cur)
	end)
end

pClubGold.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(self.wnd_list:getWidth(), self.wnd_list:getHeight() / 2)
	pWnd:setParent(self.wnd_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pClubGold.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pClubGold.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end
