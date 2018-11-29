local modClubMgr = import("logic/club/main.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modUserData = import("logic/userdata.lua")

pJoinClubInfo = pJoinClubInfo or class(pWindow)

pJoinClubInfo.init = function(self, clubInfo, host)
	self:load("data/ui/club_join_card.lua")
	self.clubInfo = clubInfo
	self.host = host
	self:initUI()
	self:regEvent()
	self:hideJoin()
end

pJoinClubInfo.initUI = function(self)
	self.wnd_name:setText(self.clubInfo:getClubName())
	self.wnd_image:setImage(self.clubInfo:getAvatar())
	self.wnd_location:setText(modUIUtil.getNameByProviceCithCode(self.clubInfo:getProvinceCode(), self.clubInfo:getCityCode()))
	self.wnd_member:setText(table.getn(self.clubInfo:getMemberUids()) .. " / " .. self.clubInfo:getMaxMember())
	self.wnd_desc:setText(self.clubInfo:getDesc())
	--self.btn_join:setText("申请加入")
end

pJoinClubInfo.regEvent = function(self)
	self.btn_join:addListener("ec_mouse_click", function()
		if not self.host then return end
		self.host:clubClick(self)
	end)
end

pJoinClubInfo.hideJoin = function(self)
	local memberUids = self.clubInfo:getMemberUids()
	for _, uid in pairs(memberUids) do
		if uid == modUserData.getUID() then
			self.btn_join:show(false)
			self.wnd_join:setText("#cg已加入#n")
			break
		end
	end
end

pJoinClubInfo.clubClick = function(self)
	local modClubInfo = import("ui/club/club_info.lua")
	modClubInfo.pClubInfo:instance():open(self.clubInfo)
end

