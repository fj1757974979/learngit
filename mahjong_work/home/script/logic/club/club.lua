local modPropMgr = import("common/propmgr.lua")
local modClubMgr = import("logic/club/main.lua")
local modUserData = import("logic/userdata.lua")
local modGround = import("logic/club/ground.lua")
local modMember = import("logic/club/member.lua")

pClubObj = pClubObj or class(modPropMgr.propmgr)

pClubObj.init = function(self, clubInfo)
	modPropMgr.propmgr.init(self)
	self:initValues(clubInfo)
	self:initPropNameValue()
	self.selfMemberInfo = nil
	self:getSelfMember()
end

pClubObj.initPropNameValue = function(self)
	local list = { 
		["name"] = "name",
		["gold"] = "gold",
		["province"] = "province",
		["city"] = "city",
		["avatar"] = "avatar",
		["max_member"] = "maxMemberCount",
		["ground_ids"] = "groundIds",
		["member_uids"] = "memberUids",
		["desc"] = "desc",
	}
	local props = {
		["ground_ids"] = true,
		["member_uids"] = true,
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

pClubObj.initValues = function(self, clubInfo)
	if not clubInfo then 
		return 
	end
	self.id = clubInfo.id
	self.creator = clubInfo.creator_uid
	self.province = clubInfo.province_code
	self.city = clubInfo.city_code
	self.name = clubInfo.name
	self.avatar = clubInfo.avatar
	self.gold = clubInfo.gold_coin_count
	self.maxMemberCount = clubInfo.max_member_count
	self.maxGroundCount = clubInfo.max_ground_count
	self.groundIds = clubInfo.ground_ids
	self.memberUids = clubInfo.member_uids
	self.date = clubInfo.created_date
	self.desc = clubInfo.brief_intro
	if not self.avatar or self.avatar == "" then
		self.avatar = "ui:club/create_icon.png"
	end
end

pClubObj.getSelfMember = function(self, callback)
	local isSelfClub = false
	for _, uid in ipairs(self.memberUids) do
		if uid == modUserData.getUID() then
			isSelfClub = true	
			break
		end
	end
	if not isSelfClub then
		return
	end

	if self.selfMemberInfo then
		if callback then
			callback(self.selfMemberInfo)
		end
	else
		self:getMemberInfoByUid(nil, function(memberInfo)
			self.selfMemberInfo = modMember.pMemberObj:new(memberInfo)
			self.selfMemberInfo:setProp("self_gold", self.selfMemberInfo:getGold())
			if callback then
				callback(self.selfMemberInfo)
			end
		end)
	end
end

pClubObj.updateMemberInfoByUid = function(self, uid)
	if not uid then return end
	if not self.memberInfos or not self.memberInfos[uid] then
		return
	end
	self.memberInfos[uid]:updateSelf()
end

pClubObj.getGroundIds = function(self)
	return self.groundIds
end

pClubObj.getMemberUids = function(self)
	return self.memberUids
end

pClubObj.getIsCreator = function(self, clubInfo)
	local selfUid = modUserData.getUID()
	return clubInfo:getCreator() == selfUid
end

pClubObj.getGold = function(self)
	return self.gold
end

pClubObj.getAvatar = function(self)
	return self.avatar
end

pClubObj.setAvatar = function(self, avatar)
	self.avatar = avatar or "ui:club/create_icon.png" 
end

pClubObj.getClubId = function(self)
	return self.id
end

pClubObj.getCreator = function(self)
	return self.creator
end

pClubObj.getProvinceCode = function(self)
	return self.province
end

pClubObj.setProvinceCode = function(self, code)
	self.province = code
end

pClubObj.getCityCode = function(self)
	return self.city
end

pClubObj.setCityCode = function(self, code)
	self.city = code
end

pClubObj.getClubName = function(self)
	return self.name
end

pClubObj.setClubName = function(self, name)
	self.name = name or ""
end

pClubObj.getDesc = function(self)
	return self.desc
end

pClubObj.setDesc = function(self, desc)
	self.desc = desc or ""
end

pClubObj.getMaxMember = function(self)
	return self.maxMemberCount
end

pClubObj.getMaxGround = function(self)
	return self.maxGroundCount
end

pClubObj.getDate = function(self)
	return self.date
end

pClubObj.getMemberInfos = function(self, callback)
	local uids = {}
	for _, uid in ipairs(self.memberUids) do
		table.insert(uids, uid)
	end
	modClubMgr.getCurClub():getMemberInfos(self.id, uids, function(reply)
		self.memberInfos = {}
		for _, member in ipairs(reply.club_members) do
			self.memberInfos[member.user_id] = modMember.pMemberObj:new(member)
		end
		if callback then
			callback(self.memberInfos)
		end
	end)
end

pClubObj.getMemberInfoByUid = function(self, userId, callback)
	local uid = userId or modUserData.getUID()
	modClubMgr.getCurClub():getMemberInfos(self.id, {uid}, function(reply)
		if callback then
			local memberInfo = reply.club_members[table.getn(reply.club_members)]
			if self.memberInfos and self.memberInfos[uid] then
				self.memberInfos[uid] = self.memberInfos[uid]:initValues(memberInfo) 
			end
			callback(memberInfo)
		end
	end)
end


pClubObj.getMyMemberInfo = function(self, callback)
	self:getMemberInfoByUid(nil, function(memberInfo)
		if callback then
			callback(memberInfo)
		end
	end)	
end

pClubObj.updateGroundInfoByGroundId = function(self, groundId, callback)
	modClubMgr.getCurClub():getGroundInfos(self.id, { groundId }, function(reply)
		local tmp = reply.club_grounds[table.getn(reply.club_grounds)]
		local info  = modGround.pGroundObj:new(self.id, tmp)
		if callback then
			callback(info)
		end
	end)
	
end

pClubObj.getGroundInfos = function(self, callback)
	self.groundInfos = {}
	modClubMgr.getCurClub():getGroundInfos(self.id, self.groundIds, function(reply)
		for _, ground in ipairs(reply.club_grounds) do
			self.groundInfos[ground.id] = modGround.pGroundObj:new(self.id, ground)
		end
		if callback then
			callback(self.groundInfos)
		end
	end)
end

pClubObj.refreshClubInfo = function(self, callback)
	modClubMgr.getCurClub():getClubInfos({self.id}, function(reply) 
		if not reply then 
			if callback then
				callback(false)
			end
			return 
		end
		local clubInfo = reply.clubs[table.getn(reply.clubs)]
		self:initValues(clubInfo)
		if callback then
			callback(self)
		end
	end)	
end

pClubObj.destroy = function(self)
	self.id = nil 
	self.creator = nil 
	self.province = nil 
	self.city = nil 
	self.name = nil 
	self.avatar = nil 
	self.gold = nil 
	self.maxMemberCount = nil 
	self.maxGroundCount = nil 
	self.groundIds = nil 
	self.memberUids = nil 
	self.date = nil
	self.groundInfos = nil
	self.selfMemberInfo = nil
	self.memberInfos = nil
end

