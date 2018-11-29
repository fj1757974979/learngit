local modPropMgr = import("common/propmgr.lua")
local modUserPropCache = import("logic/userpropcache.lua")
local modUserData = import("logic/userdata.lua")
local modGroupRpc = import("logic/group/rpc.lua")

local allProp = {
	"name", "avatarurl", "gender", "gold", "invite", "realname", "phone", "ip", "roomcard"
}

pGrpMember = pGrpMember or class(modPropMgr.propmgr)

pGrpMember.init = function(self, group, memberInfo)
	modPropMgr.propmgr.init(self)
	self.group = group
	self.userId = memberInfo.user_id
	self:setProp("aka", memberInfo.aka)
	self:setProp("joinDate", memberInfo.joined_date)
	self:initUserProp()
end

pGrpMember.assembleProto = function(self, proto)
	proto.group_id = self.group:getGrpId()
	proto.user_id = self:getUserId()
	proto.aka = self:getAka()
	proto.joined_date = self:getJoinDate()
end

pGrpMember.saveInfoToSvr = function(self, callback)
	modGroupRpc.setMember(self, callback)
end

pGrpMember.initUserProp = function(self)
	modUserPropCache.pUserPropCache:instance():getPropAsync(self.userId, allProp, function(success, propData)
		if success then
			for k, v in pairs(propData) do
				self:setProp(k, v)
			end
		else
			infoMessage(sf(TEXT("获取玩家数据%d失败"), self.userId))
		end
	end)
end

pGrpMember.getUserId = function(self)
	return self.userId
end

pGrpMember.getAka = function(self)
	return self:getProp("aka")
end

pGrpMember.getJoinDate = function(self)
	return self:getProp("joinDate")
end

pGrpMember.isMyself = function(self, userId)
	userId = userId or modUserData.getUID()
	return userId == self.userId
end
