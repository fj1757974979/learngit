local modBattleRpc = import("logic/battle/rpc.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modPokerBattleMgr = import("logic/card_battle/main.lua")
local modUtil = import("util/util.lua")

pClipBoardMgr = pClipBoardMgr or class(pSingleton)

-- 获取系统剪贴板的文本内容
pClipBoardMgr.getClipBoardText = function()
	if puppy.sys.getClipBoardText then
		local txt = puppy.sys.getClipBoardText()
		if txt and txt ~= "" then
			return txt
		else
			return nil
		end
	else
		return nil
	end
end

pClipBoardMgr.setClipBoardText = function(self, text, hint)
	if text and puppy.sys.setClipBoardText then
		puppy.sys.setClipBoardText(text)
		infoMessage(hint or TEXT("复制成功"))
	else
		infoMessage(TEXT("功能暂未开放"))
	end
end

pClipBoardMgr.loginCheck = function(self)
	if app.enter_room_id then
		modBattleRpc.doEnterRoom(tonumber(app.enter_room_id))
		app.enter_room_id = nil
		return
	end
	local clipText = self:getClipBoardText()
	if clipText then
		local doEnterRoom = function(roomId)
			modBattleRpc.lookupRoom(roomId, function(success, reason, roomId, roomHost, roomPort, gameType)
				if success then
					if gameType == T_MAHJONG_ROOM then
						modBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort, function(success)
							if success then
							end
						end)
					elseif gameType == T_POKER_ROOM then
						modPokerBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort, function(success)
						end)
					end
				else
					infoMessage(reason)
				end
			end)
		end
		local pos = string.find(clipText, "【")
		if pos ~= nil then
			local roomIdStr = string.sub(string.sub(clipText, pos + string.len("【"), -1), 1, 6)
			local roomId = tonumber(roomIdStr)
			if roomId then
				modBattleRpc.doEnterRoom(roomId)
			end
		else
			if tonumber(clipText) and string.len(clipText) == 6 then
				modBattleRpc.doEnterRoom(tonumber(clipText))
			end
		end
	end
	self:checkJoinClub()
	self:checkJoinGroup()
end

pClipBoardMgr.checkJoinClub = function(self)
	if not app.join_club_id then return end
	local modClubMgr = import("logic/club/main.lua")
	local modUserData = import("logic/userdata.lua")
	local clubId = app.join_club_id
	modClubMgr.getCurClub():getClubInfos({clubId}, function(reply)
		if not reply then return end
		local clubInfo = reply.clubs[table.getn(reply.clubs)]
		local isJoined = false
		for _, uid in ipairs(clubInfo.member_uids) do
			if uid == modUserData.getUID() then
				isJoined = true
				break
			end
		end
		if isJoined then
			local modClubMain = import("ui/club/main.lua")
			modClubMain.pClubMain:instance():open()
		else
			local modClubJoin = import("ui/club/join.lua")
			modClubJoin.pClubJoin:instance():open()
			modClubJoin.pClubJoin:instance():setEditId(clubId)
			modClubJoin.pClubJoin:instance():searchClub()
		end
	end)
end

pClipBoardMgr.checkJoinGroup = function(self)
	if not app.join_group_id then return end
	local modGroupRpc = import("logic/group/rpc.lua")
	local modUserData = import("logic/userdata.lua")
	local grpId = app.join_group_id
	modGroupRpc.getGroupsDetail({grpId}, function(success, reason, groupInfos)
		if not success then
			return
		end
		if groupInfos[1] then
			local info = groupInfos[1]
			local isJoined = false
			for _, uid in ipairs(info.member_uids) do
				if uid == modUserData.getUID() then
					isJoined = true
					break
				end
			end
			if isJoined then
				local modGroupMgr = import("logic/group/mgr.lua")
				local modGroupMainPanel = import("ui/group/main.lua")
				modGroupMgr.pGroupMgr:instance():initGroups(function()
					modGroupMainPanel.pGroupMainPanel:instance():open()
				end)
			else
				local modGroupJoin = import("ui/group/join.lua")
				modGroupJoin.pGroupInfoPanel:instance():open(info)
			end
		end
	end)
end
