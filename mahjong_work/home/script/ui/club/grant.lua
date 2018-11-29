local modClubMgr = import("logic/club/main.lua")
local modUIUtil = import("ui/common/util.lua")
local modUserData = import("logic/userdata.lua")

pGrant = pGrant or class(pWindow, pSingleton)

pGrant.init = function(self)
	self:load("data/ui/club_present_coin.lua")
	self:setParent(gWorld:getUIRoot())
	self:regEvent()
	modUIUtil.makeModelWindow(self, false, false)
end

pGrant.regEvent = function(self)
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

pGrant.moveGold = function(self)
	local text = self.edit_coin:getText()
	if not text or not tonumber(text) then return end
	local userId = self.uid or self.memberInfo:getUid()
	if not userId then return end
	modClubMgr.getCurClub():clubMoveGold(self.clubInfo:getClubId(), userId, tonumber(text), function(reply) 
		infoMessage("发放成功")
		modClubMgr.getCurClub():updateClubInfoById(self.clubInfo:getClubId(), function()
			if self.memberInfo then
				self.memberInfo:updateSelf()
			end
			self:close()
		end)
	end)	
end

pGrant.setCoinText = function(self, number)
	if not number or not tonumber(number) then return end
	number = tonumber(number)
	self.edit_coin:setText(number)
	self.curNumber = number
end

pGrant.open = function(self, clubInfo, memberInfo, uid)
	self.clubInfo = clubInfo
	self.memberInfo = memberInfo
	self.uid = uid
	self:initUI()
end

pGrant.getMaxGold = function(self)
	return self.clubInfo:getGold()
end

pGrant.initUI = function(self)
	self.curNumber = tonumber(self.edit_coin:getText() or 1)
	self.edit_coin:setupKeyboardOffset(gWorld:getUIRoot())
	--self.btn_send:setText("发放")
	self.txt_desc:setText("请输入您要发放的金豆数量，该金豆只能在本俱乐部中使用。")
	self.txt1:setText(sf("最大<%d>", self.clubInfo:getGold()))
end

pGrant.close = function(self)
	self.clubInfo = nil
	self.curNumber = 0
	pGrant:cleanInstance()
end

pGrant.checkNumberIsMax = function(self, n)
	if n > self:getMaxGold() then
		return true
	end
	if string.len(tostring(n)) > 9 then
		return true
	end
end

pGrant.touchNumber = function(self, n)
	local code = self.edit_coin:getText()
	if not code or tonumber(code) == 0 then
		if self:checkNumberIsMax(n) then
			infoMessage("哪来这么多金豆，你想上天呀？")
			self.edit_coin:setText(self:getMaxGold())
			return
		end
		self.edit_coin:setText(n) 
		return
	end
	
	if self:checkNumberIsMax(tonumber(code .. n)) then
		infoMessage("哪来这么多金豆，你想上天呀？")
		self.edit_coin:setText(self:getMaxGold())
		return
	end
	self.edit_coin:setText(code .. n)
end

pGrant.delNumber = function(self)
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

pGrant.reinput = function(self)
	self.edit_coin:setText("")
end

