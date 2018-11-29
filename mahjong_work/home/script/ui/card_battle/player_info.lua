local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modChannelMgr = import("logic/channels/main.lua")

pPlayerInfoWnd = pPlayerInfoWnd or class(pWindow, pSingleton)

pPlayerInfoWnd.init = function(self)
	self:load("data/ui/card/player_info.lua")
	self:setParent(gWorld:getUIRoot())
	self:initUI()
	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_BATTLE_UI_Z)
end

pPlayerInfoWnd.initUI = function(self)
	self.wnd_real_name_value:setText("未认证")
	self.wnd_phone_value:setText("未认证")
	self.wnd_invite:show(false)
	self.btn_message:show(false)
	self.btn_phone:show(false)
	self.wnd_phone:show(false)
	self.wnd_line:show(false)
	self.wnd_room_card:setImage(modUIUtil.getChannelRes("main_room_card.png"))
	self.wnd_gold_bg:show(modChannelMgr.getCurChannel():isNeedGold())
	modUtil.makeModelWindow(self, false, true)
end

pPlayerInfoWnd.open = function(self, player)
	self.wnd_image:setImage(player:getAvatarUrl())
	local name = player:getName()
	if modUIUtil.utf8len(name) > 6 then
		name = modUIUtil.getMaxLenString(name, 6)
	end
	self.wnd_name:setText(name)
	self.wnd_uid:setText("ID:" .. player:getUserId())
	self.wnd_room_card_text:setText(player:getRoomCard())
	self.wnd_gold_text:setText(player:getGoldCount())
	local realName = player:getRealName()
	if realName and realName ~= "" then
		self.wnd_real_name_value:setText(realName)
		self.wnd_invite:show(true)
	end
	local phoneNo = player:getPhoneNo()
	if phoneNo and phoneNo ~= "" then
		self.wnd_phone_value:setText(phoneNo)
		self.wnd_line:show(true)
		self.btn_phone:show(true)
		self.wnd_phone:show(true)
		self.btn_phone:addListener("ec_mouse_click", function()
			self:callPhone(phoneNo, player:getUserId())
		end)
	end
	local ip = player:getIP()
	if tonumber(ip) then
		ip = modUIUtil.stringToIP(ip)
	end
	self.wnd_ip:setText(ip)
end

pPlayerInfoWnd.callPhone = function(self, number, uid)
	if not number or not uid then return end
	if uid == modUserData.getUID() then
		return
	end
	local num = tonumber(number)
	if not num then return end
	modUtil.callTelephone(num)
end

pPlayerInfoWnd.close = function(self)
	pPlayerInfoWnd:cleanInstance()
end
