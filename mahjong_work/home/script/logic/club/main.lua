local modUserData = import("logic/userdata.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modClubObj = import("logic/club/club.lua")

local pClubMain = pClubMain or class()

pClubMain.init = function(self)
	self.clubs = {}
	self.clubIds = {}
end

pClubMain.getClubById = function(self, id)
	if not id then return end
	return self.clubs[id]
end

pClubMain.updateClubInfoById = function(self, id, callback)
	if not id then return end
	self:getClubInfos({id}, function(reply)
		if not reply then
			if callback then
				callback(false)
			end
			return
		end
		local info = reply.clubs[table.getn(reply.clubs)]
		local newInfo = modClubObj.pClubObj:new(info)
		self:modifyProp(self.clubs[id], newInfo, info)
		if callback then
			callback(self.clubs[id])
		end
	end)
end

pClubMain.modifyProp = function(self, old, new, replyInfo)
	-- 临时变量 new 对比用
	if not old or not new then return end
	-- 所有变量
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
	-- 需要替换的
	local props = {
		["name"] = true,
		["province"] = true,
		["city"] = true,
		["ground_ids"] = true,
		["member_uids"] = true,
		["desc"] = true,
	}
	-- 累加
	local nameToValue = {}
	-- 替换
	local replaceNameToValue = {}
	for propName, clubPropName in pairs(list) do
		if props[propName] then
			if type(new[clubPropName]) == "table" then
				if table.size(old[clubPropName]) ~= table.size(new[clubPropName]) then
					replaceNameToValue[propName] = table.getn(new[clubPropName])
				end
			else
				if old[clubPropName] ~= new[clubPropName] then
					replaceNameToValue[propName] = new[clubPropName]
				end
			end
		else
			if old[clubPropName] ~= new[clubPropName] then
				nameToValue[propName] = new[clubPropName] - old[clubPropName]
			end
		end
	end
	-- 旧变量更新
	old:initValues(replyInfo)
	-- 更新事件
	for name ,value in pairs(nameToValue) do
		old:modifyProp(name, value)
	end
	-- setProp
	for name, value in pairs(replaceNameToValue) do
		old:setProp(name, value)
	end
end

pClubMain.getAllClubs = function(self, callback)
	local tmps = {}
	for _, id in ipairs(self.joinClubIds) do
		table.insert(tmps, id)
	end
	self:getClubInfos(tmps, function(reply)
		if not reply then
			if callback then
				callback(false)
			end
			return
		end
		local clubs = reply.clubs
		local index = nil
		-- 排序 先是创建
		for _, club in ipairs(clubs) do
			if self:findIdIsInList(club.id, self.createClubIds) then
				if not index then index = 0 end
				index = index + 1
				table.insert(self.clubIds, club.id)
				self.clubs[club.id] = self:newClub(club, index)
			end
		end

		if not index then index = 0 end
		-- 加入
		for _, club in ipairs(clubs) do
			if self:findIdIsInList(club.id, self.onlyJoinIds) then
				index = index + 1
				table.insert(self.clubIds, club.id)
				self.clubs[club.id] = self:newClub(club, index)
			end
		end
		table.sort(self.clubs, function(c1, c2)
			return c1["index"] < c2["index"]
		end)
		if callback then
			callback(self.clubs)
		end
	end)
end

pClubMain.clearClubs = function(self)
	self.clubs = {}
	self.createClubIds = {}
	self.joinClubIds = {}
	self.onlyJoinIds = {}
end

pClubMain.newClub = function(self, club, index)
	if not club then return end
	local newClub = modClubObj.pClubObj:new(club)
	newClub["index"] = index
	return newClub
end

pClubMain.setCreateClubIds = function(self, ids)
	self.createClubIds = ids
end

pClubMain.getCreateClubIds = function(self)
	return self.createClubIds or {}
end

pClubMain.setJoinClubIds = function(self, ids)
	self.joinClubIds = ids
	self.clubIds = ids
end

pClubMain.getJoinClubIds = function(self)
	return self.joinClubIds	or {}
end

pClubMain.destoryMailMgr = function(self)
	local modMailMgr = import("logic/mail/main.lua")
	if modMailMgr.pMailMgr:getInstance() then
		modMailMgr.pMailMgr:instance():destory()
	end
end

pClubMain.destroy = function(self)
	self.createClubIds = {}
	self.joinClubIds = {}
	self.onlyJoinIds = {}
	self.clubs = {}
	self.clubIds = {}
	self:destoryMailMgr()
end


pClubMain.refreshClubSelfMemberInfo = function(self, reply)
	if not reply then return end
	local clubId = reply.club_id
	local gold = reply.gold_coin_count
	local uid = reply.user_id
	local clubInfo = self.clubs[clubId]
	if not clubInfo then return end
	clubInfo:getSelfMember(function(selfMemberInfo)
	--	selfMemberInfo:updateSelf()
		clubInfo:updateMemberInfoByUid(uid)
		selfMemberInfo:modifyProp("self_gold", gold - selfMemberInfo:getGold())
		selfMemberInfo:setGold(gold)
	end)
end

pClubMain.leaveClub = function(self, clubId, uid, callback)
	modClubRpc.leaveClub(clubId, uid, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end


------------------ 俱乐部协议 ---------------------
pClubMain.refreshMgrClubs = function(self)
	self:getClubsByUid(modUserData.getUID(), function(success, reason, reply)
		local modClubMainPanel = import("ui/club/main.lua")
		if success then
			modClubMainPanel.pClubMain:instance():open()
		else
			modClubMainPanel.pClubMain:instance():close()
		end
	end)
end

pClubMain.getClubInfos = function(self, ids, callback)
	if not ids then return end
	modClubRpc.getClubInfos(ids, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			callback(false)
		end
	end)
end

pClubMain.setObjToObjlist =function(self, ids, list)
	if not ids or not list then return end
	for _, id in ipairs(ids) do
		table.insert(list, id)
	end
end

pClubMain.getClubsByUid = function(self, uid, callback)
	modClubRpc.getClubRelated(uid, function(success, reason, reply)
		if success then
			self:clearClubs()
			if uid == modUserData.getUID() then
				self:setCreateClubIds(reply.created_club_ids)
				self:setJoinClubIds(reply.joined_club_ids)
				self:getOnlyJoinIdsFromJoins()
			end
			if callback then
				callback(reply)
			end
		end
	end)
end

pClubMain.getGroundPlayers = function(self, clubId, groundId, callback)
	if not clubId or not groundId then return end
	modClubRpc.getGroundPlayers(clubId, groundId, function(reply)
		if callback then
			callback(reply)
		end
	end)
end

pClubMain.getMemberInfos = function(self, clubId, uids, callback)
	if not uids then return end
	modClubRpc.getMemberInfo(clubId, uids, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.getGroundMemberCount = function(self, clubId, groundIds, callback)
	if not clubId or not groundIds then return end
	modClubRpc.getGroundMemberCount(clubId, groundIds, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.getGroundInfos = function(self, clubId, groundIds, callback)
	if not clubId or not groundIds then return end
	modClubRpc.getClubGounds(clubId, groundIds, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.getOnlyJoinIds = function(self)
	return self.onlyJoinIds or {}
end

pClubMain.getOnlyJoinIdsFromJoins = function(self)
	if not self.createClubIds then return self.joinClubIds end
	self.onlyJoinIds = {}

	for _, jid in ipairs(self.joinClubIds) do
		if not self:findIdIsInList(jid, self.createClubIds) then
			table.insert(self.onlyJoinIds, jid)
		end
	end
end

pClubMain.clubJoinMatch = function(self, clubId, groundId, uid, rematch, callback)
	if not clubId or not groundId or not uid then
		return
	end
	modClubRpc.clubJoinMatch(clubId, groundId, uid, rematch, function(success, reason, reply)
		if success then
			if callback then
				callback(true, reply)
			end
		else
			infoMessage(reason)
			if callback then
				callback(false, reply)
			end
		end
	end)
end

pClubMain.addClubGold = function(self, clubId, count, callback)
	if not clubId or not count then return end
	modClubRpc.addClubGold(clubId, count, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.clubMoveGold = function(self, clubId, toUid, gold, callback)
	if not clubId or not toUid or not gold then return end
	modClubRpc.moveGold(clubId, UID_CLUB_ID, toUid, gold, function(sucess, reason, reply)
		if sucess then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.userMoveGold = function(self, clubId, fromUid, toUid, gold, callback)
	if not clubId or not fromUid or not toUid or not gold then
		return
	end
	modClubRpc.moveGold(clubId, fromUid, toUid, gold, function(sucess, reason, reply)
		if sucess then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.returnGold = function(self, clubId, gold, callback)
	if not gold or not clubId then return end
	modClubRpc.returnGold(clubId, gold, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.destroyGround = function(self, clubId, groundId, callback)
	modClubRpc.destroyGround(clubId, groundId, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.destroyClub = function(self, clubId, callback)
	if not clubId then return end
	modClubRpc.destroyClub(clubId, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.updateMemberInfo = function(self, clubId, callback)
	self:getClubInfos({clubId}, function(reply)
		if not reply then
			if callback then
				callback(false)
			end
			return
		end
		local clubInfo = reply.clubs[table.getn(reply.clubs)]
		if not clubInfo then return end
		local selfUid = modUserData.getUID()
		local clubUids = {}
		for _, uid in ipairs(clubInfo.member_uids) do
			table.insert(clubUids, uid)
		end
		self:getMemberInfos(clubInfo.id, clubUids, function(reply, clubInfo)
			if callback then
				callback(reply, clubInfo)
			end
		end)
	end)
end

pClubMain.getMemberWeeklyStat = function(self, clubId, uid, callback)
	if not clubId  then return end
	if not uid then uid = modUserData.getUID() end
	modClubRpc.getMemberWeeklyStat(clubId, uid, function(success, reason, reply)
		if success then
			if callback then
				callback(reply.member_daily_stats)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.getClubDailyStat = function(self, clubId, callback)
	if not clubId  then return end
	modClubRpc.getClubDailyStat(clubId, function(success, reason, reply)
		if success then
			if callback then
				callback(reply.daily_stat)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.getGoldTraces = function(self, clubId, callback)
	if not clubId then return end
	modClubRpc.getGoldTraces(clubId, function(success, reason, reply)
		if success then
			if callback then
				callback(reply.gold_coin_traces)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.getClubRecords = function(self, clubId, callback)
	if not clubId then return end
	modClubRpc.getClubRecords(clubId, function(success, reason, reply)
		if success then
			if callback then
				callback(reply.game_record_groups)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.getClubJilu = function(self, clubId, callback)
	if not clubId then return end
	local modBattleRpc = import("logic/battle/rpc.lua")
	modBattleRpc.getSharedRoomHistories(0, 200, clubId, function(success, reason, reply)
		if success then
			if callback then
				callback(reply.shared_room_histories)
			end
		else
			infoMessage(reason)
		end
	end)
end

pClubMain.setClub = function(self, list, callback)
	if not list then return end
	modClubRpc.setClub(list, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

------------------ 俱乐部协议 ---------------------

----------------------------------------------

pClubMain.findIdIsInList = function(self, id, list)
	if not list or not id then return end
	for _, tid in ipairs(list) do
		if tid == id then
			return true
		end
	end
	return false
end

-------------------------- mgr -----------------------

pClubMgr = pClubMgr or class(pSingleton)

pClubMgr.init = function(self)
end

pClubMgr.newClub = function(self)
	self.club = pClubMain:new()
end

getCurClub = function(self)
	if not pClubMgr:instance().club then
		pClubMgr:instance():newClub()
	end
	return pClubMgr:instance().club
end

pClubMgr.destroy = function(self)
	if self.club then self.club:destroy() end
	self.club = nil
	pClubMgr:cleanInstance()
end
