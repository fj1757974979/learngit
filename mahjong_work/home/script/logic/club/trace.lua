local modPropMgr = import("common/propmgr.lua")
local modClubMgr = import("logic/club/main.lua")
local modUserData = import("logic/userdata.lua")
local modClubMgr = import("logic/club/main.lua")
local modTracePanel = import("ui/club/record_trace.lua")

local T_TYPE_CHARGE = 3
local T_TYPE_GRANT = 2
local T_TYPE_DONATE = 1

pTrace = pTrace or class(modPropMgr.propmgr)

pTrace.init = function(self, traceInfo, playerInfo)
	self:initValues(traceInfo)
	self.playerInfo = playerInfo
	self.types = {
		[T_TYPE_DONATE] = "捐赠",
		[T_TYPE_GRANT] = "发放",
		[T_TYPE_CHARGE] = "充值",
	}
end

pTrace.initValues = function(self, traceInfo)
	self.fromUid = traceInfo.from_user_id
	self.toUid = traceInfo.to_user_id
	self.gold = traceInfo.gold_coin_count
	self.date = traceInfo.deal_date
end

pTrace.getGold = function(self)
	return self.gold
end

pTrace.getFromUid = function(self)
	return self.fromUid
end

pTrace.getToUid = function(self)
	return self.toUid
end

pTrace.getType = function(self)
	if self.fromUid == UID_CLUB_ID then
		return T_TYPE_GRANT
	elseif self.toUid == UID_CLUB_ID and self.fromUid == UID_SYSTEM_ID then
		return T_TYPE_CHARGE
	elseif self.toUid == UID_CLUB_ID then
		return T_TYPE_DONATE
	end

end

pTrace.isGrant = function(self)
	return self:getType() == T_TYPE_GRANT
end

pTrace.isDonate = function(self)
	return self:getType() == T_TYPE_DONATE
end

pTrace.getName = function(self)
	if self:getType() == T_TYPE_CHARGE then
		return "系统"
	end
	return self.playerInfo.nickname
end

pTrace.getUid = function(self)
	if self:getType() == T_TYPE_CHARGE then
		return "--"
	end
	return self.playerInfo.user_id
end

pTrace.newPanel = function(self)
	self.panel = modTracePanel.pTracePanel:new(self)
	return self.panel
end

pTrace.getTypeStr = function(self)
	return self.types[self:getType()]
end

pTrace.getTextColor = function(self)
	local colors = {
		[T_TYPE_GRANT] = "r",
		[T_TYPE_DONATE] = "g",
	}
	return colors[self:getType()]
end

pTrace.getDate = function(self)
	return self.date
end

pTrace.destroy = function(self)
	self.traceInfo = nil
	self.playerInfo = nil
	self.panel:setParent(nil)
	self.panel = nil
end
