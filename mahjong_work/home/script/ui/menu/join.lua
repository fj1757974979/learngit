local modUIUtil = import("ui/common/util.lua")
local modEvent = import("common/event.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modPokerBattleMgr = import("logic/card_battle/main.lua")
local modUtil = import("util/util.lua")

pMainJoin = pMainJoin or class(pWindow,pSingleton)

pMainJoin.init = function(self)
	self:load("data/ui/joinroom.lua")
	self:setParent(gWorld:getUIRoot())
	self.maxNumberCount = 6
	--self.wnd_join_logo:setSize(246, 65)
	modUIUtil.makeModelWindow(self,false,true)

	for i = 0,9 do
		local wnd = self["wnd_0"..i]
		local btn = self["btn_0"..i]
		--wnd:setFont("join_number",40, 600)
		--wnd:setText(tostring(i))
		btn:addListener("ec_mouse_left_down", function()
			self:touchNumber(i)
		end)
	end
	self.btn_del:addListener("ec_mouse_left_down",function() self:del() end)
	self.btn_reinput:addListener("ec_mouse_click",function() self:reset()end)
	self.btn_close:addListener("ec_mouse_click",function() self:close()  end)
	self:reset()
end

pMainJoin.open = function(self, isCode)
	if isCode then
		self.isCode = true
		self.maxNumberCount = 8
		self.wnd_join_logo:setSize(271, 57)
		self.wnd_join_logo:setImage("ui:main_code.png")
		for i = 1, self.maxNumberCount do
			local wnd = self[sf("wnd_text0%d", i)]
			if wnd then
				wnd:setPosition(wnd:getX() - 25 * i, wnd:getY())
--				wnd:getTextControl():setFontSize(60)
			end
		end
	end
end

pMainJoin.del = function(self)
	if self.currentText > 1 then
		self.currentText = self.currentText - 1
	end
	self["wnd_text0"..self.currentText]:setText("")
end

pMainJoin.isFull = function(self)
	return self.currentText > self.maxNumberCount
end

pMainJoin.touchNumber = function(self,number)
	if self:isFull() then return end

	self["wnd_text0"..self.currentText]:setFont("join_number2", 48, 1)
	self["wnd_text0"..self.currentText]:setText(number)
	self.currentText = self.currentText + 1

	if not self:isFull() then return end

	local roomId = self:getRoomNumber()

	if not roomId then return end

	modUIUtil.timeOutDo(modUtil.s2f(0.5), nil, function()
		if not roomId then return end
		if self.isCode then
			self:code()
		else
			modBattleRpc.lookupRoom(roomId, function(success, reason, roomId, roomHost, roomPort, gameType)
				if success then
					if gameType == T_MAHJONG_ROOM then
						modBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort, function(ss)
							if ss then
								self:close()
							end
						end)
					elseif gameType == T_POKER_ROOM then
						modPokerBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort, function(success)
							if success then
								self:close()
							end
						end)
					end
				else
					infoMessage(reason)
				end
			end)
		end
	end)
end


pMainJoin.close = function(self)
	self.isCode = false
	self.maxNumberCount= 6
	pMainJoin:cleanInstance()
end

pMainJoin.getRoomNumber = function(self)
	if not self:isFull() then return end

	local room_num = 0
	for i=1, self.maxNumberCount do
		local num = tonumber(self["wnd_text0"..i]:getText())
		room_num = room_num * 10 + num
	end
	return room_num
end

pMainJoin.reset= function(self)
	for i=1, self.maxNumberCount do
		self["wnd_text0"..i]:setText("")
	end
	self.currentText = 1
end


pMainJoin.code = function(self)
	if not self:getRoomNumber() then return end
	local id = tonumber(self:getRoomNumber())

	modBattleRpc.getGameVideoInfosByKeys({ id }, function(success, reason, reply)
		if not success then
			self:reset()
			infoMessage("请求记录失败。")
			return
		end

		if table.getn(reply.game_record_infos) <= 0 then
			infoMessage("找不到该录像。")
			return
		end

		local groupId = reply.game_record_infos[1].group_id
		modBattleRpc.getGameVideosByKeys({ groupId }, function(success, reason, reply)
			if success then
				if table.getn(reply.game_record_groups) <= 0 then
					infoMessage("暂无记录!")
					return
				end
				local videoGroup = reply.game_record_groups[1]
				local playerUids = {}
				local userIds = videoGroup.user_ids

				for pid, uid in ipairs(userIds) do
					playerUids[pid - 1] = uid
				end
				local namelist = {
					"name", "avatarurl"
				}
				modBattleRpc.getMultiUserProps (userIds, namelist, function(success, reason, ret)

					if not success then return end

					for id, prop in ipairs(ret.multi_user_props) do
						local avatarUrl = prop.avatar_url
						if not avatarUrl or avatarUrl == "" then
							avatarUrl = modUIUtil.getDefaultImage(gender)
						end
						prop.avatar_url = avatarUrl
					end

					local modVideoInfo = import("ui/menu/video_info.lua")

					modVideoInfo.pVideoInfo:instance():open(videoGroup, ret.multi_user_props, id)
					self:close()


				end)

			end
		end)
	end)

end

