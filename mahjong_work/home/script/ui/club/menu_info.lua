local modClubRpc = import("logic/club/rpc.lua")
local modEvent = import("common/event.lua")
local modUIUtil = import("ui/common/util.lua")
local modAskWnd = import("ui/common/askwindow.lua")
local modClubMgr = import("logic/club/main.lua")
local modClubObj = import("logic/club/club.lua")

pMenuInfo = pMenuInfo or class(pWindow, pSingleton)

pMenuInfo.init = function(self, clubInfo)
	self:load("data/ui/club_desk_list_info.lua")
end

pMenuInfo.open = function(self, clubInfo, host)
	self:setParent(host)
	self.btn_exit:show(false)
	self.btn_update:show(false)
	self.clubInfo = clubInfo
	self.host = host
	self:initUI()
	modUIUtil.makeModelWindow(self, false, false)
end

pMenuInfo.initUI = function(self)
	modClubMgr.getCurClub():getClubInfos({self.clubInfo:getClubId()}, function(reply)
		if not reply then
			self:clearAllClubWnds()
			return
		else
			local club = reply.clubs[table.getn(reply.clubs)]
			self.clubInfo:initValues(club)
			self.provinceCode = self.clubInfo:getProvinceCode()
			self.cityCode = self.clubInfo:getCityCode()
			self.wnd_time:setText(os.date("创建于：%y-%m-%d", self.clubInfo:getDate()))
			self.wnd_id:setText(sf("ID:%06d", self.clubInfo:getClubId()))
			self:getCreaterProp()
			--self.btn_exit:setText("解散俱乐部")
			--self.btn_update:setText("修改")
			--self.btn_leave_club:setText("退出俱乐部")
			self:setCreatorName()
			if self.clubInfo:getIsCreator(self.clubInfo) then
				self.btn_exit:show(true)
				self.btn_leave_club:show(false)
				self.btn_update:show(true)
			end
		end
		self:regEvent()
	end)
end

pMenuInfo.getCreaterProp = function(self)
	self.wnd_creater:setText("")
	local uid = self.clubInfo:getCreator()
	if not uid then return end
	local modBattleRpc = import("logic/battle/rpc.lua")
	modBattleRpc.updateUserProps(uid, function(success, reply)
		local name = reply.nickname
		if modUIUtil.utf8len(name) > 6 then
			name = modUIUtil.getMaxLenString(name, 6)
		end
		self.wnd_creater:setText("创建者：" .. name)
	end)
end

pMenuInfo.setCreatorName = function(self)
	self:getCreatorInfo(self.clubInfo.creator_uid, function(reply)
		local info = reply.multi_user_props[table.getn(reply.multi_user_props)]
		local name = info.nickname
		if name then
			self.wnd_creater:setText(name)
		end
	end)
end

pMenuInfo.getCreatorInfo = function(self, uid, callback)
	if not uid then return end
	local modBattleRpc = import("logic/battle/rpc.lua")
	modBattleRpc.getMultiUserProps({ uid }, { "name" }, function(success, reason, reply)
		if success then
			if callback then
				callback(reply)
			end
		else
			infoMessage(reason)
		end
	end)
end

pMenuInfo.askQuite = function(self)
	self.askWnd = modAskWnd.pAskWnd:new(self, "确定要解散俱乐部吗?", function(isQuite)
		self:destroyClub(isQuite)
		self.askWnd:setParent(nil)
		self.askWnd = nil
	end)
end

pMenuInfo.destroyClub = function(self, isQuite)
	if not isQuite then return end
	modClubMgr.getCurClub():destroyClub(self.clubInfo.id, function(reply)
		self:clearAllClubWnds()
		modClubMgr.getCurClub():refreshMgrClubs()
		self:close()
	end)
end

pMenuInfo.clearAllClubWnds = function(self)
	local modClubMainWnd = import("ui/club/main.lua")
	if modClubMainWnd.pClubMain:getInstance() then
		modClubMainWnd.pClubMain:instance():refreshClubs()
	end
	local modMainDesk = import("ui/club/main_desk.lua")
	if modMainDesk.pMainDesk:getInstance() then
		modMainDesk.pMainDesk:instance():close()
	end
end

pMenuInfo.regEvent = function(self)
	self.btn_exit:addListener("ec_mouse_click", function()
		self:askQuite()
	end)

	self.btn_update:addListener("ec_mouse_click", function()
		self:updateClick()
	end)

	self.btn_leave_club:addListener("ec_mouse_click", function()
		self:leaveClub()
	end)

	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.__club_name_hdr = self.clubInfo:bind("name", function(cur, prev, defVal)
		self.wnd_name:setText(cur)
		self.edit_name:setText(cur)
		self:showWndOrEdit("name")
		if not self.originName then
			self.originName = cur
		end
	end)

	self.__club_avatar_hdr = self.clubInfo:bind("avatar", function(cur, prev, defVal)
		self.wnd_image:setImage(cur)
		if not self.originAvatar then
			self.originAvatar = cur
		end
	end)

	self.__club_province = self.clubInfo:bind("province", function(cur, prev, defVal)
		if not self.clubInfo then return end
		self.wnd_location:setText(modUIUtil.getNameByProviceCithCode(cur, self.clubInfo:getCityCode()) or "")
		self.btn_location:setText(modUIUtil.getNameByProviceCithCode(cur, self.clubInfo:getCityCode()) or "")
		self:showWndOrEdit("province")
		if not self.originProveinceCode then
			self.originProveinceCode = cur
		end
	end)

	self.__club_city = self.clubInfo:bind("city", function(cur, prev, defVal)
		if not self.clubInfo then return end
		self.wnd_location:setText(modUIUtil.getNameByProviceCithCode(self.clubInfo:getProvinceCode(), cur) or "")
		self.btn_location:setText(modUIUtil.getNameByProviceCithCode(self.clubInfo:getProvinceCode(), cur) or "")
		self:showWndOrEdit("city")
		if not self.originCityCode then
			self.originCityCode = cur
		end
	end)

	self.btn_location:addListener("ec_mouse_click", function()
		local modLocaltion = import("ui/club/location.lua")
		modLocaltion.pClubLocation:instance():open(self, function(provinceCode, cityCode)
			self.btn_location:setText(modUIUtil.getNameByProviceCithCode(provinceCode, cityCode))
			self.provinceCode = provinceCode
			self.cityCode = cityCode
		end)
	end)

	self.__club_max_memeber = self.clubInfo:bind("max_member", function(cur, prev, defVal)
		if not self.clubInfo then return end
		self.wnd_member:setText(table.getn(self.clubInfo:getMemberUids()) .. "/" .. cur)
	end)

	self.__club_cur_member = self.clubInfo:bind("member_uids", function(cur, prev, defVal)
		if not self.clubInfo then return end
		self.wnd_member:setText(cur .. " / " .. self.clubInfo:getMaxMember())
	end)

	self.__club_desc = self.clubInfo:bind("desc", function(cur, prev, defVal)
		self.wnd_desc:setText(cur)
		self.edit_desc:setText(cur)
		self:showWndOrEdit("desc")
		if not self.originDesc then
			self.originDesc = cur
		end
	end)
end

pMenuInfo.updateClick = function(self)
	local nameText = self.edit_name:getText()
	local descText = self.edit_desc:getText()
	local imgText = self.wnd_image:getTexturePath()
	if nameText == self.originName and descText == self.originDesc and
		imgText == self.originAvatar and self.provinceCode == self.originProveinceCode and
		self.cityCode == self.originCityCode then
		infoMessage("请还没有修改任何信息")
		return
	end
	-- 更新信息
	local nameToValues = {
		["name"] = { nameText, self.originName },
		["brief_intro"] = { descText, self.originDesc },
		["avatar"] = { imgText, self.originAvatar },
		["province_code"] = { self.provinceCode, self.originProveinceCode},
		["city_code"] = { self.cityCode, self.originCityCode },
	}
	local list = { ["id"] = self.clubInfo:getClubId() }
	for name, values in pairs(nameToValues) do
		if values[1] ~= values[2] then
			list[name] = values[1]
		end
	end
	modClubMgr.getCurClub():setClub(list, function(reply)
		if not reply then
			self:clearAllClubWnds()
			return
		end
		modClubMgr.getCurClub():updateClubInfoById(self.clubInfo:getClubId(), function(clubInfo)
		end)
		infoMessage("修改成功")
	end)
end

pMenuInfo.showWndOrEdit = function(self, name)
	if not name then return end
	if not self.clubInfo then return end
	local isCreator = self.clubInfo:getIsCreator(self.clubInfo)
	local nameToContorls = {
		["name"] = { [true] = self.edit_name, [false] = self.wnd_name },
		["province"] = { [true] = self.btn_location, [false] = self.wnd_location },
		["city"] = { [true] = self.btn_location, [false] = self.wnd_location },
		["desc"] = { [true] = self.edit_desc, [false] = self.wnd_desc  },
	}
	if isCreator then
		nameToContorls[name][isCreator]:show(isCreator)
		nameToContorls[name][not isCreator]:show(not isCreator)
	else
		nameToContorls[name][isCreator]:show(not isCreator)
		nameToContorls[name][not isCreator]:show(isCreator)
	end
end

pMenuInfo.leaveClub = function(self)
	local modUserData = import("logic/userdata.lua")
	local name = self.clubInfo:getClubName()
	if modUIUtil.utf8len(name) > 6 then
		name = modUIUtil.getMaxLenString(name, 6)
	end
	self.askLeaveWnd = modAskWnd.pAskWnd:new(self, sf("确定要离开#cr%s#n俱乐部吗?", name), function(isLeave)
		if self.askLeaveWnd then
			self.askLeaveWnd:setParent(nil)
			self.askLeaveWnd = nil
		end
		if isLeave then
			modClubMgr.getCurClub():leaveClub(self.clubInfo:getClubId(), modUserData.getUID(), function(success)
				if success then
					infoMessage(sf("您已经离开(%s)俱乐部", name))
					modClubMgr.getCurClub():refreshMgrClubs()
					self:close()
				end
			end)
		end
	end)
end

pMenuInfo.close = function(self)
	self.clubInfo = nil
	--if self.host then
		--self.host:menuCloseClick()
		--self.host = nil
	--end
	if self.askLeaveWnd then
		self.askLeaveWnd:setParent(nil)
		self.askLeaveWnd = nil
	end
	if self.askWnd then
		self.askWnd:setParent(nil)
		self.askWnd = nil
	end
	self.provinceCode = nil
	self.cityCode = nil
	self.originName = nil
	self.originDesc = nil
	self.originAvatar = nil
	self.originProveinceCode = nil
	self.originCityCode = nil
	self:removeEvent()
	pMenuInfo:cleanInstance()
end

pMenuInfo.removeEvent = function(self)
	local list = {
		["name"] = self.__club_name_hdr,
		["avatar"] = self.__club_avatar_hdr,
		["max_member"] = self.__club_max_memeber,
		["member_uids"] = self.__club_cur_member,
		["province"] = self.__club_province,
		["city"] = self.__club_city,
		["desc"] = self.__club_desc,
	}
	for name, event in pairs(list) do
		self:removeWork(name, event)
	end
end

pMenuInfo.removeWork = function(self, name, event)
	if event then
		modEvent.removeListener(name, event)
		if self.clubInfo then
			self.clubInfo:unbind(name, event)
		end
		event = nil
	end
end
