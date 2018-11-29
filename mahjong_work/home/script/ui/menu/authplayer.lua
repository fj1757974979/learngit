local modUtil = import("util/util.lua")
local modEvent = import("common/event.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUserData = import("logic/userdata.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")

pAuthWindow = pAuthWindow or class(pWindow, pSingleton)

pAuthWindow.init = function(self)
	self:load("data/ui/auth.lua")
	self:setParent(gWorld:getUIRoot())
	self.wnd_text_1:setText("实名认证成功，赠送")
	self.wnd_text_2:setText(sf("%d钻石", modUIUtil.getYouHuiAuthCard()))
	self.wnd_text_3:setText("商城充值额外赠送")
	self.wnd_text_4:setText(modUIUtil.getYouHuiAuthPer() .. "%")
	self.wnd_name:setText("姓名：")
	self.wnd_phone_no:setText("手机号：")
	self.wnd_auth_code:setText("验证码：")
	self.wnd_show_info:setText("实名信息只用于游戏内防作弊系统，一经认证无法修改。")
	self.btn_close:addListener("ec_mouse_click", function() self:show(false)  end)
	self.edit_name:setupKeyboardOffset(gWorld:getUIRoot())
	self.edit_code:setupKeyboardOffset(gWorld:getUIRoot())
	self.edit_phone_no:setupKeyboardOffset(gWorld:getUIRoot())
	self:dongShan()
	self:pingHe()
	self:hideTextWnd()
	modUIUtil.makeModelWindow(self, false, false)
end

pAuthWindow.dongShan = function(self)
	if modUtil.getOpChannel() ~= "ds_queyue" then return end
	self.wnd_text_1:show(false)
	self.wnd_text_2:show(false)
	self.wnd_text_3:show(false)
	self.wnd_text_4:show(false)
end

pAuthWindow.pingHe = function(self)
	if modUtil.getOpChannel() ~= "qs_pinghe" then return end
	self.wnd_text_1:show(false)
	self.wnd_text_2:show(false)
	self.wnd_text_3:show(false)
	self.wnd_text_4:show(false)
end


pAuthWindow.hideTextWnd = function(self)
	local cardNum = modUIUtil.getYouHuiAuthCard()
	if not cardNum or cardNum <= 0 then
		self.wnd_text_1:show(false)
		self.wnd_text_2:show(false)
	end
	local perNum = modUIUtil.getYouHuiAuthPer()
	if not perNum or perNum <= 0 then
		self.wnd_text_3:show(false)
		self.wnd_text_4:show(false)
	end
end


pAuthWindow.open = function(self)

	-- test
--	self.edit_name:setText("刘珊")
--	self.edit_phone_no:setText("18898636911")

	self.btn_get:addListener("ec_mouse_click", function() 
		if not self:checkNilText() then 
			infoMessage(TEXT("请输入真实的姓名和手机号码"))
			return 
		end
		if not self:checkNoLength() then
			infoMessage(TEXT("请输入正确的11位手机号码"))
			return
		end
		
		local name = self.edit_name:getText()
		local no = self.edit_phone_no:getText()
		modBattleRpc.startRealNameAuth(name, no, function(success, reason, time)
			if success then
				modUIUtil.timeOutDo(modUtil.s2f(time), function(t)
					self.wnd_get_text:setText(sf("%d", t))
					self.wnd_get_text:setColor(0)
					self.btn_get:enableEvent(false)
					self.btn_get:setImage("ui:auth_btn_get_dis.png")
					self.wnd_get_text:setImage("ui:auth_get_text_dis.png")
				end, 
				function()
					local name = modUserData.getRealName()
					self.btn_get:setText("") 
					if not name or name == "" then
						self.wnd_get_text:setText("") 
						self.btn_get:setImage("ui:auth_btn_get.png") 
						self.wnd_get_text:setImage("ui:auth_btn_get_text.png")
						self.wnd_get_text:setColor(0xFFFFFFFF)
						self.btn_get:enableEvent(true)
					end
				end)
			end
			infoMessage(TEXT(reason))
		end)
	end)

	self.btn_ok:addListener("ec_mouse_click", function() 
		if not self:checkAuthCode() then
			infoMessage(TEXT("请输入四位有效验证码"))
			return
		end
		if not self:checkNilText() then
			infoMessage(TEXT("请输入真实的的姓名和手机号码"))
			return
		end
		
		local name = self.edit_name:getText()
		local no = self.edit_phone_no:getText()
		local code = tonumber(self.edit_code:getText())
		modBattleRpc.completeRealNameAuth(name, no, code, function(success, reason, ret) 
			if success then
				self:showSucess()
				self.btn_ok:enableEvent(false)
				self.btn_get:enableEvent(false)
				self.btn_get:setImage("ui:auth_btn_get_dis.png")
				self.wnd_get_text:setImage("ui:auth_get_text_dis.png")
				self.btn_ok:setImage("ui:auth_btn_ok_dis.png")
				self.wnd_btn_text:setImage("ui:auth_ok_text_dis.png")
				infoMessage(TEXT("认证成功，恭喜您获得钻石奖励和充值优惠"))
				modUIUtil.timeOutDo(modUtil.s2f(0.8), nil, function()
					self:close()
				end)
			else
				infoMessage(TEXT(reason))
			end
		end)
	end)
end

pAuthWindow.showSucess = function(self)
	local modAuthSuccess = import("ui/menu/authsuccess.lua")
	modAuthSuccess.pAuthSuccess:instance():open()
end

pAuthWindow.checkNoLength = function(self)
	if not self.edit_phone_no:getText() then return false end
	return string.len(self.edit_phone_no:getText()) == 11
end

pAuthWindow.checkAuthCode = function(self)
	if not self.edit_code:getText() then return false end
	return string.len(self.edit_code:getText()) == 4
end

pAuthWindow.close = function(self)
	pAuthWindow:cleanInstance()
end

pAuthWindow.checkNilText = function(self)
	local name = self.edit_name:getText()
	local no = self.edit_phone_no:getText()
	return name and name ~= "" and no and no ~= ""
end


