local modClubMgr = import("logic/club/main.lua")
local modMember = import("logic/club/member.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")

pMainClubInfo = pMainClubInfo or class(pWindow)

pMainClubInfo.init = function(self, clubInfo, host)
	self:load("data/ui/club_main_card.lua")
	self.clubInfo = clubInfo
	self.host = host
	self:initUI()
	self:regEvent()
end

pMainClubInfo.initUI = function(self)
	self.wnd_id:setText(sf("ID:%06d", self.clubInfo:getClubId()))
	self:getMemberInfo()
end

pMainClubInfo.regEvent = function(self)
	self:addListener("ec_mouse_click", function() 
		if not self.host then return end
		self.host:clubClick(self)
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

	self.__club_cur_desc = self.clubInfo:bind("desc", function(cur, prev, defVal)
		if modUIUtil.utf8len(cur) > 15 then
			cur = modUIUtil.getMaxLenString(cur, 15)
		end
		self.wnd_desc:setText(cur)
	end)
end

pMainClubInfo.clubClick = function(self)
	local modMainDesk = import("ui/club/main_desk.lua")	
	modMainDesk.pMainDesk:instance():open(self.clubInfo, self.host)
end

pMainClubInfo.getMemberInfo = function(self)
	self.clubInfo:getSelfMember(function(selfMemberInfo) 
		self.selfMemberInfo = selfMemberInfo
		if not self.__self_gold then
			self.__self_gold = self.selfMemberInfo:bind("self_gold", function(cur, prev, defVal) 
				self.my_coin:setText("" .. cur)
			end)
		end
	end)
end

