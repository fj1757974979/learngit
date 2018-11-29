local modClubMgr = import("logic/club/main.lua")
local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")

pRecordGold = pRecordGold or class(pWindow)

pRecordGold.init = function(self, dayInfo, index)
	self:load("data/ui/club_desk_list_record_personal_record_card.lua")
	self:setParent(gWorld:getUIRoot())
	self.dayInfo = dayInfo
	self.index = index
	self:initUI()
	self:regEvent()
end

pRecordGold.getDayText = function(self)
	local days = {
		[1] = "今天",
		[2] = "昨天",
		[3] = "前天",
	}
	if self.index <= 3 then
		return days[self.index]
	end
	return sf("前%s天", modUtil.getUnits(self.index - 1))
end

pRecordGold.initUI = function(self)
	self.wnd_day:setText(self:getDayText())
	modUIUtil.setWndColorText(self.wnd_income, self.dayInfo.gold_coin_count_delta)
	modUIUtil.setWndColorText(self.wnd_present, self.dayInfo.gold_coin_count_from_club)
	modUIUtil.setWndColorText(self.wnd_donate, self.dayInfo.gold_coin_count_to_club, "r")
end


pRecordGold.regEvent = function(self)
end

