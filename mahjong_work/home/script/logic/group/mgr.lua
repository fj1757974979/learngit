local modGroupRpc = import("logic/group/rpc.lua")
local modGroup = import("logic/group/grp.lua")
local modEvent = import("common/event.lua")

pGroupMgr = pGroupMgr or class(pSingleton)

pGroupMgr.init = function(self)
	-- grpId --> group
	self.groups = {}
	self.initFlag = false
end

pGroupMgr.addGroup = function(self, group)
	self.groups[group:getGrpId()] = group
end

pGroupMgr.delGroup = function(self, grpId)
	self.groups[grpId] = nil
end

pGroupMgr.getGroup = function(self, grpId)
	return self.groups[grpId]
end

pGroupMgr.initGroups = function(self, callback)
	if self.initFlag then
		callback()
	else
		modGroupRpc.getGroups(function(success, reason, createdGrpIds, joinedGrpIds)
			if success then
				local grpIds = {}
				for _, grpId in ipairs(createdGrpIds) do
					table.insert(grpIds, grpId)
				end
				for _, grpId in ipairs(joinedGrpIds) do
					table.insert(grpIds, grpId)
				end
				modGroupRpc.getGroupsDetail(grpIds, function(success, reason, groupInfos)
					if success then
						local available = {}
						for _, groupInfo in ipairs(groupInfos) do
							local grpId = groupInfo.id
							if self.groups[grpId] then
								self.groups[grpId]:updateProps(groupInfo)
							else
								local group = modGroup.pGroup:new(groupInfo, self)
								self:addGroup(group)
							end
							available[grpId] = true
						end
						local unavailable = {}
						for grpId, _ in pairs(self.groups) do
							if not available[grpId] then
								table.insert(unavailable, grpId)
							end
						end
						for _, grpId in ipairs(unavailable) do
							self:delGroup(grpId)
						end
						--self.initFlag = true
						callback()
					else
						infoMessage(reason)
					end
				end)
			else
				infoMessage(reason)
			end
		end)
	end
end

pGroupMgr.getGroupCnt = function(self)
	return table.size(self.groups)
end

pGroupMgr.createGroup = function(self, name, brief, callback)
	modGroupRpc.createGroup(name, brief, function(success, reason, grpId)
		if success then
			modGroupRpc.getGroupsDetail({grpId}, function(success, reason, groupInfos)
				if success then
					local groupInfo = groupInfos[1]
					self:addGroup(modGroup.pGroup:new(groupInfo, self))
					callback(true, "")
				else
					callback(false, reason)
				end
			end)
		else
			callback(false, reason)
		end
	end)
end

pGroupMgr.getAllGroups = function(self)
	return self.groups
end

pGroupMgr.onGroupDismiss = function(self, group)
	self.groups[group:getGrpId()] = nil
	modEvent.fireEvent(EV_DISMISS_GROUP, group:getGrpId())
end

pGroupMgr.onLeaveGroup = function(self, group)
	self.groups[group:getGrpId()] = nil
	modEvent.fireEvent(EV_LEAVE_GROUP, group:getGrpId())
end
