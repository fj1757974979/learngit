local modUtil = import("util/util.lua")
local modEvent = import("common/event.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUserData = import("logic/userdata.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")

pPlayerInfo = pPlayerInfo or class(pWindow, pSingleton)

pPlayerInfo.init = function(self)
	self:load("data/ui/playerinfo.lua")
	self:setParent(gWorld:getUIRoot())
    	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_BATTLE_UI_Z)
	self.wnd_straight_text:setText("本周局数:" )
	self.wnd_round_text:setText("本周胜率:")
	self.wnd_winner_text:setText("本周输赢:")
	self.wnd_winner:show(false)
	self.wnd_invite:show(false)
	self.wnd_real_name_value:setText("未认证")
	self.wnd_phone_value:setText("未认证")
	self.btn_message:show(false)
	self.btn_phone:show(false)
	self:dongShanSpecial()
	self:pingHeSpecial()
	self.wnd_line:show(false)
	self.__back_round_hdr = modEvent.handleEvent(EV_BACK_GROUND, function()
		self:close()
	end)
	modUtil.makeModelWindow(self, false, true)
	self.controls = {}
end

pPlayerInfo.hideWnds = function(self, uid)
	if not uid then return end
	if uid ~= modUserData.getUID() then
		self:hideInfoWnds()
	end
end

pPlayerInfo.dongShanSpecial = function(self)
	if not self:isDongShan() then return end
	--	self.wnd_player_bg:show(false)
	self:hideInfoWnds()
	self.wnd_real_name:show(false)
	self.wnd_phone:show(false)
end

pPlayerInfo.pingHeSpecial = function(self)
	if not self:isPingHe() then return end
	--	self.wnd_player_bg:show(false)
	self:hideInfoWnds()
	self.wnd_real_name:show(false)
	self.wnd_phone:show(false)
end

pPlayerInfo.hideInfoWnds = function(self)
	self.wnd_straight:show(false)
	self.wnd_round:show(false)
	self.wnd_winner:show(false)
end

pPlayerInfo.isDongShan = function(self)
	local channel = modUtil.getOpChannel()
	return channel == "ds_queyue"
end

pPlayerInfo.isPingHe = function(self)
	local channel = modUtil.getOpChannel()
	return channel == "test"
end

pPlayerInfo.createMapView = function(self)
	self.mapView = pMapView:new()
	self.mapView:setWorldSize(gGameWidth, gGameHeight)
	self.mapView:setParent(self.wnd_map)
	self.mapView:setPosition(0, 0)
	self.mapView:setSize(self.wnd_map:getWidth(), self.wnd_map:getHeight())
end

pPlayerInfo.open = function(self, infoMgr)
	self.infoMgr = infoMgr
	if self.infoMgr:getBattle() then
		self:setParent(self.infoMgr:getParnentPanel())
		if self.infoMgr:isClubRoom() then
			self.wnd_gold_bg:show(false)
		end
	end
	local uid = self.infoMgr:getUid()
	local cardCount, goldCount = "???", "???"
	self.wnd_uid:setText("ID:" .. uid)
	self.player = self.infoMgr:getMyPlayer()
	local name = self.infoMgr:getName()
	if modUIUtil.utf8len(name) > 6 then
		name = modUIUtil.getMaxLenString(name, 6)
	end
	self.wnd_name:setText(name)
	local img = self.infoMgr:getAvatarUrl()
	if not img or img == "" then
		img = modUIUtil.getDefaultImage(self.infoMgr:getGender() or T_GENDER_FEMALE)
	end
	self.wnd_image:setImage(img)
	self.wnd_image:setColor(0xFFFFFFFF)
	local ip = self.infoMgr:getIP()
	if tonumber(ip) then
		ip = modUIUtil.stringToIP(ip)
	end
	self.wnd_ip:setText(ip)
	self.wnd_room_card_text:setText(self.infoMgr:getRoomCard())
	self.wnd_gold_text:setText(self.infoMgr:getGoldCount())
	local realName = self.infoMgr:getRealName()
	local phoneNo = self.infoMgr:getPhoneNo()
	if realName and realName ~= "" then
		self.wnd_real_name_value:setText(realName)
		self.wnd_invite:show(true)
	end
	if phoneNo and phoneNo ~= "" then
		self.wnd_phone_value:setText(phoneNo)
		self.wnd_line:show(true)
		--			self.btn_message:show(true)
		self.btn_phone:show(true)
		self.wnd_phone:showSelf(false)
		self.btn_phone:addListener("ec_mouse_click", function()
			self:callPhone(phoneNo, self.infoMgr:getUid())
		end)
	end
	--------------------------------------------- 定位
	if not self.infoMgr:isBattleClick() then
		self:updatePref(uid, modUtil.getOpChannel())
		self:showSelfLocation()
		return
	end

	self.wnd_straight_text:setText("")
	self.wnd_round_text:setText("")
	self.wnd_winner_text:setText("")
	self.wnd_straight_value:setText("")
	self.wnd_round_value:setText("")
	self.wnd_winner_value:setText("")
	self.wnd_winner:setColor(0)
	self.wnd_round:setColor(0)
	self.wnd_straight:setColor(0)
	self.wnd_winner:show(true)
	self.wnd_round:show(true)
	self.wnd_straight:show(true)
	
	if self.mapView then
		self.mapView:destroy()
		self.mapView = nil
	end

	--- 录像
	if puppy.gui.pMapView then
		--createMapView()
		local players = self.infoMgr:getPlayers()
		if players then
			self.uidToPlayer = self.infoMgr:getUidToPlayer()
			-- 录像取坐标数据
			local videoLocations = self.infoMgr:getVideoLocation()
			if self.infoMgr:getVideoState() and videoLocations then
				local infos = {}
				local isHasCenterPlayer = false
				for _, location in ipairs(videoLocations) do
					local uid = location.user_id
					local longitude = tonumber(location.longitude)
					local latitude = tonumber(location.latitude)
					infos[uid] = {longitude, latitude}
					if self.player:getUid() == uid then
						isHasCenterPlayer = true
					end
				end

				if not isHasCenterPlayer then
					self.wnd_map:setText("该玩家没有开启定位权限")
					return
				end
				self:createMapView()
				self:showLocation(self.uidToPlayer, infos, self.player)
				-- 设置玩家距离
				self:setPlayersDistance(infos, players, self.player)
			else
				self.infoMgr:fetchGeoLocations({ self.player:getUid() }, function(success, reason, ret)
					if success then
						--createMapView()
						if table.size(ret) <= 0 then
							self.wnd_map:setText("该玩家没有开启定位权限")
							return
						end
						-- 从服务器取uids的位置
						self.infoMgr:fetchGeoLocations(table.keys(self.uidToPlayer), function(success, reason, ret)
							if not self._destroyed then
								self:createMapView()
								if success and not self._destroyed then
									--createMapView()
									self:showLocation(self.uidToPlayer, ret, self.player)
									-- 设置玩家距离
									self:setPlayersDistance(ret, players, self.player)
								else
									infoMessage(reason)
								end
							end
						end)
					else
						self.wnd_map:setText("该玩家没有开启定位权限")
						--self:showSelfLocation()
					end
				end)
			end
		else
			self:showSelfLocation()
		end
	end
end

pPlayerInfo.showSelfLocation = function(self)
	if puppy.location and puppy.location.pLocationMgr then
		puppy.location.pLocationMgr:instance():getLocation(function(longitude, latitude)
			if not longitude or longitude == "" or not latitude or latitude == "" then
				self.wnd_map:setText("您没有开启定位权限")
				return
			end
			setTimeout(1, function()
				if not self._destroyed then
					self:createMapView()
					self.mapView:addPointAnnotation(0, TEXT("您的当前位置"), longitude, latitude, true)
				end
			end)
		end)
	end
end

pPlayerInfo.showLocation = function(self, uidToPlayer, ret, player)
	setTimeout(1, function()
		for uid, info in pairs(ret) do
			--modUtil.consolePrint(sf("%d, %f, %f", uid, info[1], info[2]))
			local isCenter = (uid == player:getUid())
			if uid == modUserData.getUID() then
				self.mapView:addPointAnnotation(0, TEXT("您的当前位置"), info[1], info[2], isCenter)
			else
				self.mapView:addPointAnnotation(uid, uidToPlayer[uid]:getName(), info[1], info[2], isCenter)
			end
		end
	end)
end

pPlayerInfo.setPlayersDistance = function(self, ret, players, centerPlayer)
	if not ret or not players then
		return
	end
	if not centerPlayer then
		return
	end
	local seatToWnd = {
		[3] = self["wnd_winner_value"],
		[2] = self["wnd_round_value"],
		[1] = self["wnd_straight_value"],
	}
	local seatNames = {
		[3] = self["wnd_winner_text"],
		[2] = self["wnd_round_text"],
		[1] = self["wnd_straight_text"]
	}
	local seatImgWnd = {
		[3] = self["wnd_winner"],
		[2] = self["wnd_round"],
		[1] = self["wnd_straight"],
	}
	local selfInfo = self:getSelfLonLat(ret, centerPlayer)
	if not selfInfo then
		return
	end
	local centerLon, centerLat = selfInfo[1], selfInfo[2]
	if not centerLon or not centerLat then
		return
	end
	local index = 1
	local pUid = centerPlayer:getUid()
	self.wnd_straight_value:setText("")
	self.wnd_round_value:setText("")
	self.wnd_winner_value:setText("")
	local playerNames = {}
	for uid, info in pairs(ret) do
		local player = self:findPlayerByUid(players, uid)
		if  uid ~= centerPlayer:getUid() then
			local distance = modUIUtil.getDistanceByLatitudeLogitude(centerLon, centerLat, info[1], info[2])
			local dStr = ""
			if player then
				local name = player:getName()
				if modUIUtil.utf8len(name) > 6 then
					name = modUIUtil.getMaxLenString(name, 6)
				end
				distance = tonumber(sf("%0.1f", distance))
				if distance < 1000 and distance > 500 then
					dStr = "约" .. distance .. "m"
				elseif distance <= 500 then
					dStr = "过近(约" .. distance .. "m)"
					seatToWnd[index]:getTextControl():setColor(0xFFFF4040)
					seatNames[index]:getTextControl():setColor(0xFFFF4040)
				else
					distance = sf("%0.1f", distance / 1000)
					dStr = "约" .. distance .. "km"
				end
				seatToWnd[index]:setText("")
				seatNames[index]:setText("距" .. "[" .. name .. "]" .. dStr)
				seatNames[index]:show(true)
				seatNames[index]:setPosition(seatImgWnd[index]:getX(), seatNames[index]:getY())
				index = index + 1
				table.insert(playerNames, player:getName())
			else
			end
		end
	end
	local noNamePlayers = {}
	for _, player in pairs(players) do
		local name = player:getName()
		if name ~= centerPlayer:getName() and (not self:isInList(name, playerNames)) then
			table.insert(noNamePlayers, player:getName())
		end
	end
	for i = index, table.size(players) - 1 do
		local ridx = nil
		for idx, name in pairs(noNamePlayers) do
			if seatNames[index] then
				seatNames[index]:setText("[" .. name .. "]" .. "没有开启定位权限")
				seatNames[index]:setPosition(seatImgWnd[index]:getX(), seatNames[index]:getY())
				ridx = idx
				break
			end
		end
		if ridx then
			table.remove(noNamePlayers, ridx)
		end
		index = index + 1
	end
end

pPlayerInfo.isInList = function(self, name, list)
	if not list then return end
	for _, n in pairs(list) do
		if name == n then return true end
	end
	return false
end

pPlayerInfo.findPlayerByUid = function(self, players, uid)
	if not players or not uid then
		return
	end
	for _, player in pairs(players) do
		if player:getUid() == uid then
			return player
		end
	end
	return nil
end

pPlayerInfo.getSelfLonLat = function(self, ret, centerPlayer)
	if not ret  then
		return
	end
	if not centerPlayer then
		return
	end
	for uid, info in pairs(ret) do
		if uid == centerPlayer:getUid() then
			return {info[1], info[2]}
		end
	end
end

pPlayerInfo.updatePref = function(self, uid, channelId)
	if self.player then return end
	modBattleRpc.getUserPerf(uid, channelId, function(success, reason, ret)
		if success then
			self.wnd_straight_value:setText(ret.game_time_count)
			local win = ret.won_game_time_count / ret.game_time_count * 100
			win = string.format("%0.1f", win)
			if ret.game_time_count == 0 then
				win = 0
			end
			self.wnd_round_value:setText(win .. "%")
			local score = ret.cumulative_score
			if score > 0 then
				score = "+" .. score
			end
			self.wnd_winner_value:setText(score)
		else
			infoMessage(TEXT("战绩刷新失败!"))
		end
	end)
end

pPlayerInfo.destroyMgr = function(self)
	local modPlayerInfoMgr = import("logic/menu/player_info_mgr.lua")
	if modPlayerInfoMgr.pPlayerInfoMgr:getInstance() then
		modPlayerInfoMgr.pPlayerInfoMgr:instance():destroy()
	end
end

pPlayerInfo.callPhone = function(self, number, uid)
	if not number or not uid then return end
	if uid == modUserData.getUID() then
		return
	end
	local num = tonumber(number)
	if not num then return end
	modUtil.callTelephone(num)
end

pPlayerInfo.close = function(self)
	self.player = nil
	if self.mapView then
		self.mapView:destroy()
		self.mapView = nil
	end
	self:destroyMgr()
	self.player = nil
	self.uidToPlayer = {}
	if self.__back_round_hdr then
		modEvent.removeListener(self.__back_round_hdr)
		self.__back_round_hdr = nil
	end
	self._destroyed = true
	pPlayerInfo:cleanInstance()
end
