local modPropMgr = import("common/propmgr.lua")
local modClubMgr = import("logic/club/main.lua")
local modUserData = import("logic/userdata.lua")
local modClubMgr = import("logic/club/main.lua")

pMemberObj = pMemberObj or class(modPropMgr.propmgr)

pMemberObj.init = function(self, memberInfo)
	modPropMgr.propmgr.init(self)
	self:initValues(memberInfo)
	self:initPropNameValue()
end

pMemberObj.initValues = function(self, memberInfo)
	self.clubId = memberInfo.club_id
	self.uid = memberInfo.user_id
	self.gold = memberInfo.gold_coin_count
	self.date = memberInfo.joined_date
end

pMemberObj.initPropNameValue = function(self)
	local list = { 
		["member_gold"] = "gold",
	}
	local props = {
	}
	for propName, valueName in pairs(list) do
		local value = self[valueName]
		if props[propName] then
			self:setProp(propName, table.getn(value))
		else
			self:setProp(propName, value)
		end
	end

end

pMemberObj.updateSelf = function(self)
	modClubMgr.getCurClub():getMemberInfos(self.clubId, {self.uid}, function(reply)
		local memberInfo = reply.club_members[table.getn(reply.club_members)]
		local old = self.gold
		self:initValues(memberInfo)
		local new = self.gold
		self:modifyProp("member_gold", new - old)
		if self.uid == modUserData.getUID() then
			self:modifyProp("self_gold", new - old)
		end
	end)
end

pMemberObj.getClubId = function(self)
	return self.clubId
end

pMemberObj.setGold = function(self, gold)
	if not gold then return end
	self.gold = gold
end

pMemberObj.getUid = function(self)
	return self.uid
end

pMemberObj.getGold = function(self)
	return self.gold
end

pMemberObj.getDate = function(self)
	return self.date
end

pMemberObj.getClubInfo = function(self)
	return modClubMgr.getCurClub():getClubById(self.clubId)
end

pMemberObj.destroy = function(self)
	self.clubId = nil 
	self.uid = nil 
	self.gold = nil 
	self.date = nil 
end

