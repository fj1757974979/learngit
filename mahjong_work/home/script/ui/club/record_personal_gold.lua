local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modClubMgr = import("logic/club/main.lua")
local modUserData = import("logic/userdata.lua")
local modMember = import("logic/club/member.lua")
local modRecordGold = import("ui/club/record_gold_info.lua")

pPersonalGold = pPersonalGold or class(pWindow)

pPersonalGold.init = function(self, clubInfo, selfMemberInfo, host)
	self:load("data/ui/club_desk_list_record_personal_record.lua")
	self:setParent(gWorld:getUIRoot())
	self.clubInfo = clubInfo
	self.selfMemberInfo = selfMemberInfo
	self.controls = {}
	self:initUI()
	self:getMemberInfo()
	self:regEvent()
end


pPersonalGold.clearControls = function(self)
	if not self.controls then return end
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
end

pPersonalGold.initUI = function(self)
	self.txt_income:setText("收支")
	self.txt_present:setText("从俱乐部")
	self.txt_donate:setText("往俱乐部")
	self.txt_day_income:setText("日均收支：")
	self.txt_all_income:setText("总收支：")
	self.txt_high:setText("单次最高：")
	self.txt_high:show(false)
	self.wnd_high:show(false)
	--self.btn_donate:setText("捐献给俱乐部")
	self:getSelfDayInfos()
end

pPersonalGold.getSelfDayInfos = function(self)
	modClubMgr.getCurClub():getMemberWeeklyStat(self.clubInfo:getClubId(), nil, function(weeklyStats)
		self:showWeeklyStats(weeklyStats)
		self:setWndText(weeklyStats)
	end)
end

pPersonalGold.setWndText = function(self, weeklyStats)
	local income= 0
	for _, stat in ipairs(weeklyStats) do
		local goldCount = stat.gold_coin_count_delta
		income = income + goldCount 
	end
	self.wnd_day_income:setText(sf("%.2f", income / table.getn(weeklyStats)))
	self.wnd_all_income:setText(income)
end

pPersonalGold.showWeeklyStats = function(self, weeklyStats)
	if not weeklyStats then return end
	self:clearControls()
	local y = 0
	for index, stat in ipairs(weeklyStats) do
		local wnd = self:newStatWnd(stat, index, y)
		y = y + wnd:getHeight()
	end
end

pPersonalGold.newStatWnd = function(self, stat, index, y)
	local wnd = modRecordGold.pRecordGold:new(stat, index)
	wnd:setParent(self.wnd_list)
	wnd:setPosition(0, y)
	table.insert(self.controls, wnd)
	return wnd
end

pPersonalGold.getMemberInfo = function(self)
	if self.selfMemberInfo then
		if not self.__self_gold_hdr then
			self.__self_gold_hdr = self.selfMemberInfo:bind("self_gold", function(cur, prev, defVal)
				self:setMyCoin(cur)
			end)
		end
		self:getSelfDayInfos()
	else
		self.clubInfo:getMemberInfoByUid(nil, function(memberInfo)
			self.selfMemberInfo = modMember.pMemberObj:new(memberInfo) 
			if not self.__self_gold_hdr then
				self.__self_gold_hdr = self.selfMemberInfo:bind("self_gold", function(cur, prev, defVal)
					self:setMyCoin(cur)
				end)
			end
		end)
		self:getSelfDayInfos()
	end
end

pPersonalGold.setMyCoin = function(self, number)
	if not number then return end
	self.my_coin:setText("" .. number)	
end

pPersonalGold.regEvent = function(self)
	self.btn_donate:addListener("ec_mouse_click", function() 
		self:returnGold()
	end)
end

pPersonalGold.returnGold = function(self)
	local modReturnGold = import("ui/club/club_return_gold.lua")	
	modReturnGold.pReturnGold:instance():open(self.clubInfo, self)
end
