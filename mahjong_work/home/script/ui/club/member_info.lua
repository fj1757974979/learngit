local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modClubMgr = import("logic/club/main.lua")
local modUserData = import("logic/userdata.lua")

pMemberInfo = pMemberInfo or class(pWindow)

pMemberInfo.init = function(self, memberInfo, clubInfo, host)
	self:load("data/ui/club_desk_list_member_card.lua")
	self:setParent(gWorld:getUIRoot())
	self.clubInfo = clubInfo
	self.memberInfo = memberInfo
	self.host = host
	self:initUI()
	self:regEvent()
end

pMemberInfo.initUI = function(self)
	self.txt_id:setText(self.memberInfo:getUid())
	--self.btn_grant:setText("发放")
	--self.btn_present:setText("赠送")
	if not self.clubInfo:getIsCreator(self.clubInfo) then
		self.btn_grant:show(false)
	end
end

pMemberInfo.regEvent = function(self)
	self.btn_present:addListener("ec_mouse_click", function()
		if self.memberInfo:getUid() == modUserData.getUID() then
			infoMessage("不能赠送给自己")
			return 
		end
		if self.memberInfo:getUid() == self.clubInfo:getCreator() then
			infoMessage("不能赠送给管理员")
			return
		end
		if self.host then
			self.host:presentGold(self)
		end
	end)

	self.btn_grant:addListener("ec_mouse_click", function()
		if self.host then
			self.host:grantGold(self)
		end
	end)
	
	self.__member_gold_hdr = self.memberInfo:bind("member_gold", function(cur, prev, defVal) 
		self.txt_coin:setText(cur)
	end)
end

pMemberInfo.presentGold = function(self)
	local modPresent = import("ui/club/present.lua")
	modPresent.pPresent:instance():open(self.clubInfo, self.memberInfo, self)
end

pMemberInfo.grantGold = function(self)
	local modGrant = import("ui/club/grant.lua")
	modGrant.pGrant:instance():open(self.clubInfo, self.memberInfo)
end

pMemberInfo.getUid = function(self)
	local uid = self.txt_id:getText()
	if not uid then return end
	if not tonumber(uid) then return end
	return tonumber(uid)
end

pMemberInfo.setName = function(self, name)
	if not name then return end
	if not self.txt_name then return end
	if modUIUtil.utf8len(name) > 6 then
		name = modUIUtil.getMaxLenString(name, 6)
	end
	self.txt_name:setText(name)
end


