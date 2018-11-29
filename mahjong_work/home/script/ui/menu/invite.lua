local modUtil = import("util/util.lua")
local modEvent = import("common/event.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUserData = import("logic/userdata.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")

pInviteWindow = pInviteWindow or class(pWindow, pSingleton)

pInviteWindow.init = function(self)
	self:load("data/ui/invite.lua")
	self:setParent(gWorld:getUIRoot())
	self.wnd_text_1:setText("绑定邀请码，赠送")
	self.wnd_text_2:setText(sf("%d钻石", modUIUtil.getYouHuiInviteCard()))
	self.wnd_text_3:setText("商城充值最多赠送")
	self.wnd_text_4:setText(modUIUtil.getYouHuiInvitePer() .. "%")
	self.wnd_bottom_text:setText("绑定成功后无法解除绑定。")
	self.wnd_code_1:setText("邀请码：")
	self.wnd_text_title:setText("绑定邀请码")
	self.btn_close:addListener("ec_mouse_click", function()
		self:show(false)
	end)
	self.btn_del:isScale(true)
	self.btn_reinput:isScale(true)
	self:regEvent()
	self:hideTextWnd()
	self:openewSpeical()
	modUIUtil.makeModelWindow(self, false, false)
end

pInviteWindow.openewSpeical = function(self)
	if not (modUtil.getOpChannel() == "openew") then return end
	self.wnd_daili:setText("代理咨询：kxmj2048\n公众号：kxgame2014")
end

pInviteWindow.hideTextWnd = function(self)
	local cardNum = modUIUtil.getYouHuiInviteCard()
	if not cardNum or cardNum <= 0 then
		self.wnd_text_1:show(false)
		self.wnd_text_2:show(false)
	end
	local perNum = modUIUtil.getYouHuiInvitePer()
	if not perNum or perNum <= 0 then
		self.wnd_text_3:show(false)
		self.wnd_text_4:show(false)
	end
end

pInviteWindow.regEvent = function(self)
	for i = 0, 9 do
		self["btn_"..i]:isScale(true)
		self["btn_"..i]:addListener("ec_mouse_left_down", function() 
			self:touchNumber(i)
		end)
	end

	self.btn_del:addListener("ec_mouse_left_down", function() 
		self:delNumber()
	end)

	self.btn_reinput:addListener("ec_mouse_left_down", function() 
		self:reinput()
	end)
end


pInviteWindow.open = function(self, host, callback)
	self:setParent(host)
	self.btn_invite:addListener("ec_mouse_click", function() 
		if not self:checkInviteCode() then
			infoMessage(TEXT("请输入9位以内有效邀请码。"))
			return 
		end
		local code = self.wnd_code:getText()
		modBattleRpc.inviteCode(tonumber(code), function(success, reason)
			if success then
				callback(true)
				self:close()
			end
			infoMessage(reason)	
		end)
	end)

end


pInviteWindow.checkInviteCode = function(self)
	local code = self.wnd_code:getText()
	if not code or code  == "" then return false end
	return string.len(self.wnd_code:getText()) <= 9 and type(tonumber(code)) == "number"
end

pInviteWindow.close = function(self)
	pInviteWindow:cleanInstance()
end

pInviteWindow.touchNumber = function(self, n)
	local code = self.wnd_code:getText()
	if not code then 
		self.wnd_code:setText(n) 
		return
	end
	local len = string.len(code)
	if len >= 9 then return end
	self.wnd_code:setText(code .. n)
end

pInviteWindow.delNumber = function(self)
	local code = self.wnd_code:getText()
	if not code or code == "" then return end
	local len = string.len(self.wnd_code:getText())
	if len <= 1 then 
		self:reinput()
		return 
	end

	code = string.sub(code, 1, -2) 
	self.wnd_code:setText(code)
end

pInviteWindow.reinput = function(self)
	self.wnd_code:setText("")
end

