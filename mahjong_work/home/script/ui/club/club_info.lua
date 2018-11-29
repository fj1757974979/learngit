local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")

pClubInfo = pClubInfo or class(pWindow, pSingleton)

pClubInfo.init = function(self, clubInfo, host)
	self:load("data/ui/club_info.lua")
	self:setParent(gWorld:getUIRoot())
	self.host = host
	modUIUtil.makeModelWindow(self, false, true)
end

pClubInfo.initUI = function(self)
	self.wnd_time:setText(os.date("创建于：%y-%m-%d", self.clubInfo:getDate()))
	self.wnd_id:setText(sf("ID:  %06d", self.clubInfo:getClubId()))
	self:getCreaterProp()
	self:isHideJoin()
end

pClubInfo.getCreaterProp = function(self)
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

pClubInfo.isHideJoin = function(self)
	local modUserData = import("logic/userdata.lua")
	local selfUid = modUserData.getUID()
	local clubUids = self.clubInfo.member_uids
	self.btn_join:show(not self:findIdIsInlist(selfUid, clubUids))
end

pClubInfo.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_join:addListener("ec_mouse_click", function() 
		local modJoinApply = import("ui/club/join_apply.lua")
		modJoinApply.pJoinApply:instance():open(self.clubInfo)
	end)

	self.__club_name_hdr = self.clubInfo:bind("name", function(cur, prev, defVal)
		self.wnd_name:setText(cur)
	end)

	self.__club_avatar_hdr = self.clubInfo:bind("avatar", function(cur, prev, defVal)
		self.wnd_image:setImage(cur)
	end)

	self.__club_province = self.clubInfo:bind("province", function(cur, prev, defVal)
		if not self.clubInfo then return end
		self.wnd_location:setText(modUIUtil.getNameByProviceCithCode(cur, self.clubInfo:getCityCode()) or "")
	end)

	self.__club_city = self.clubInfo:bind("city", function(cur, prev, defVal)
		if not self.clubInfo then return end
		self.wnd_location:setText(modUIUtil.getNameByProviceCithCode(self.clubInfo:getProvinceCode(), cur) or "")
	end)

	self.__club_max_memeber = self.clubInfo:bind("max_member", function(cur, prev, defVal)
		if not self.clubInfo then return end
		self.wnd_member:setText(table.getn(self.clubInfo:getMemberUids()) .. " / " .. cur)
	end)

	self.__club_cur_member = self.clubInfo:bind("member_uids", function(cur, prev, defVal)
		if not self.clubInfo then return end
		self.wnd_member:setText(cur .. " / " .. self.clubInfo:getMaxMember())
	end)

	self.__club_desc = self.clubInfo:bind("desc", function(cur, prev, defVal)
		self.wnd_desc:setText(cur)
	end)
end

pClubInfo.findIdIsInlist = function(self, id, list)
	if not id or not list then return end
	for _, lid in ipairs(list) do
		if lid == id then
			return true
		end
	end
	return false
end

pClubInfo.open = function(self, clubInfo)
	self.clubInfo = clubInfo
	self:initUI()
	self:regEvent()
end

pClubInfo.close = function(self)
	pClubInfo:cleanInstance()
end
