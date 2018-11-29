local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")

pMenuRecord = pMenuRecord or class(pWindow, pSingleton)

pMenuRecord.init = function(self)
	self:load("data/ui/club_desk_list_record.lua")
end

pMenuRecord.open = function(self, clubInfo, host, selfMemberInfo)
	self:setParent(host)
	self.clubInfo = clubInfo
	self.host = host
	self.selfMemberInfo = selfMemberInfo
	self:initUI()
	self:regEvent()
	self:menuClick(self.chk_personal_record)
	modUIUtil.makeModelWindow(self, false, false)
end

pMenuRecord.initUI = function(self)
	--self.chk_personal_record:setText("数据统计")
	--self.chk_personal_report:setText("牌局记录")
	--self.chk_club_record:setText("俱乐部统计")
	--self.chk_club_report:setText("俱乐部战报")
	self.chk_personal_record["mark"] = "p_gold"
	self.chk_personal_report["mark"] = "p_report"
	self.chk_club_record["mark"] = "c_gold"
	self.chk_club_report["mark"] = "c_report"
	if not self.clubInfo:getIsCreator(self.clubInfo) then
		self.chk_club_record:show(false)
		self.chk_club_report:show(false)
	end
end

pMenuRecord.initClsses = function(self)
	local modPersonalGold = import("ui/club/record_personal_gold.lua")
	local modPersonalReport = import("ui/club/record_personal_report.lua")
	local modClubGold = import("ui/club/record_club_gold.lua")
	local modClubReport = import("ui/club/record_club_report.lua")
	self.classes = {
		["p_gold"] = modPersonalGold.pPersonalGold, 
		["p_report"] = modPersonalReport.pPersonalReport,
		["c_gold"] = modClubGold.pClubGold,
		["c_report"] = modClubReport.pClubReport,
	}
	self.classWnds = {}
end

pMenuRecord.clearClassWndByKey = function(self, mark)
	if not self.classWnds then return end
	self.classWnds[mark]:setParent(nil)
	self.classWnds[mark] = nil
end

pMenuRecord.newMenuPanel = function(self, mark)
	if not mark then return end
	if not self.classes then return end
	if not self.classes[mark] then return end
	if self.classWnds[mark] then return end
	-- 创建
	local wnd = self.classes[mark]:new(self.clubInfo, self.selfMemberInfo, self, self.wnd_list)
	wnd:setParent(self.wnd_list)
	self.classWnds[mark] = wnd
--	modUIUtil.makeModelWindow(wnd, false, true)
end

pMenuRecord.showPanels = function(self, mark)
	if not mark then return end
	if not self.classWnds then return end
	for m, wnd in pairs(self.classWnds) do
		wnd:show(mark == m)
	end
	local list = { self.chk_personal_record, self.chk_personal_report, self.chk_club_record, self.chk_club_report }
	for _, chk in pairs(list) do
		if chk["mark"] == mark then
			chk:setCheck(true)
			break
		end
	end
end

pMenuRecord.clearClassWnds = function(self)
	if not self.classWnds then return end
	for _, wnd in pairs(self.classWnds) do
		if wnd.close then
			wnd:close()
		end
		wnd:setParent(nil)
	end
	self.classWnds = nil
end

pMenuRecord.menuClick = function(self, chk, junior)
	if not chk or not chk["mark"] then return end
	local mark = chk["mark"]
	if not mark then return end
	if not self.classes then 
		self:initClsses()
	end
	if junior then
	end
	self:newMenuPanel(mark)
	self:showPanels(mark)
end

pMenuRecord.regEvent = function(self)
	local list = { self.chk_personal_record, self.chk_personal_report, self.chk_club_record, self.chk_club_report }
	for _, chk in pairs(list) do
		chk:addListener("ec_mouse_click", function()
			self:menuClick(chk)
		end)
	end

	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)
end

pMenuRecord.close = function(self)
	self:clearClassWnds()
	self.clubInfo = nil
	self.selfMemberInfo = nil
	--if self.host then
		--self.host:menuCloseClick()
		--self.host = nil
	--end
	pMenuRecord:cleanInstance()
end

