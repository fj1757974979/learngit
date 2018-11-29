local modClubMgr = import("logic/club/main.lua")
local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")

local T_TRACE_GRANT = true -- 发放
local T_TRACE_DONATE = false -- 捐赠

pTracePanel = pTracePanel or class(pWindow)

pTracePanel.init = function(self, traceMgr)
	self:load("data/ui/club_desk_list_record_club_record_card.lua")
	self:setParent(gWorld:getUIRoot())
	self.traceMgr = traceMgr
	self:initUI()
	self:regEvent()
end


pTracePanel.initUI = function(self)
	self.wnd_name:setText(self.traceMgr:getName())
	self.wnd_id:setText(self.traceMgr:getUid())
	self.wnd_type:setText(self.traceMgr:getTypeStr())
	self.wnd_time:setText(os.date("%m-%d %H:%M", self.traceMgr:getDate()))
--	self.wnd_num:setText(self.traceMgr:getGold())
	modUIUtil.setWndColorText(self.wnd_num, self.traceMgr:getGold(), self.traceMgr:getTextColor())
end


pTracePanel.regEvent = function(self)
end


