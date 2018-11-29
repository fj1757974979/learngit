local modClubMgr = import("logic/club/main.lua")
local modUIUtil = import("ui/common/util.lua")
local modUserData = import("logic/userdata.lua")

pPresent = pPresent or class(pWindow, pSingleton)

pPresent.init = function(self)
	self:load("data/ui/club_present_coin.lua")
	self:setParent(gWorld:getUIRoot())
	modUIUtil.makeModelWindow(self, false, false)
end

pPresent.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)

	--self.edit_coin:addListener("ec_focus", function()
	--	local text = self.edit_coin:getText()
	--	if not text or not tonumber(text) then return end
	--	self:setCoinText(tonumber(text))
	--end)

	--self.edit_coin:addListener("ec_unfocus", function() 
	--	local text = self.edit_coin:getText()
	--	if not text or not tonumber(text) or tonumber(text) > self.clubInfo:getGold() or tonumber(text) < 0 then
	--		self:setCoinText(self.curNumber)
	--		return
	--	end
	--	self:setCoinText(tonumber(text))
	--end)

	self.btn_send:addListener("ec_mouse_click", function() 
		self:moveGold()
	end)

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

pPresent.moveGold = function(self)
	local text = self.edit_coin:getText()
	if not text or not tonumber(text) then return end
	modClubMgr.getCurClub():userMoveGold(self.clubInfo:getClubId(), modUserData.getUID(), self.memberInfo:getUid(), tonumber(text), function(reply) 
		infoMessage("赠送成功")
		self.memberInfo:updateSelf()
		self:close()
	end)	
end

pPresent.setCoinText = function(self, number)
	if not number or not tonumber(number) then return end
	number = tonumber(number)
	self.edit_coin:setText(number)
	self.curNumber = number
end

pPresent.open = function(self, clubInfo, memberInfo, host)
	self.clubInfo = clubInfo
	self.memberInfo = memberInfo
	self.host = host
	self.clubInfo:getSelfMember(function(memberInfo)
		self.selfMemberInfo = memberInfo
		self:initUI()
		self:regEvent()
	end)
end


pPresent.initUI = function(self)
	self.curNumber = tonumber(self.edit_coin:getText() or 20)
	self.edit_coin:setupKeyboardOffset(gWorld:getUIRoot())
	--self.btn_send:setText("赠送")
	self.txt_desc:setText("请输入您要赠送的金豆数，该金豆只能在本俱乐部使用。")
	self.txt1:setText(sf("最多<%d>", self.selfMemberInfo:getGold()))
end

pPresent.close = function(self)
	self.host = nil
	self.clubInfo = nil
	self.curNumber = 0
	self.selfMemberInfo = nil
	pPresent:cleanInstance()
end

pPresent.getMaxGold = function(self)
	return self.selfMemberInfo:getGold()
end

pPresent.touchNumber = function(self, n)
	local code = self.edit_coin:getText()
	if not code or tonumber(code) == 0 then
		if self:checkNumberIsMax(n) then
			infoMessage("哪来这么多金豆，你想上天呀？")
			self:setCoinText(self:getMaxGold())
			return
		end
		self:setCoinText(n)
		return
	end
	
	if self:checkNumberIsMax(tonumber(code .. n)) then
		infoMessage("哪来这么多金豆，你想上天呀？")
		self:setCoinText(self:getMaxGold())
		return
	end
	self:setCoinText(code .. n)
end

pPresent.checkNumberIsMax = function(self, n)
	if n > self:getMaxGold() then
		return true
	end
	if string.len(tostring(n)) > 9 then
		return true
	end
end

pPresent.delNumber = function(self)
	local code = self.edit_coin:getText()
	if not code or code == "" then return end
	local len = string.len(self.edit_coin:getText())
	if len <= 1 then 
		self:reinput()
		return 
	end

	code = string.sub(code, 1, -2) 
	self.edit_coin:setText(code)
end

pPresent.reinput = function(self)
	self.edit_coin:setText("")
end



