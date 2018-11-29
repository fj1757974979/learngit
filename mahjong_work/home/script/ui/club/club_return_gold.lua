local modClubMgr = import("logic/club/main.lua")
local modUIUtil = import("ui/common/util.lua")
local modUserData = import("logic/userdata.lua")

pReturnGold = pReturnGold or class(pWindow, pSingleton)

pReturnGold.init = function(self)
	self:load("data/ui/club_present_coin.lua")
	self:setParent(gWorld:getUIRoot())
	modUIUtil.makeModelWindow(self, false, true)
end

pReturnGold.regEvent = function(self)
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
	--	if not text or not tonumber(text) or tonumber(text) < 0 then
	--		self:setCoinText(self.curNumber)
	--		return
	--	end
	--	if self.memberInfo then
	--		self:setCoinText(self.curNumber)
	--		if tonumber(text) > self.memberInfo.gold_coin_count then
	--			return
	--		end
	--	end
	--	self:setCoinText(tonumber(text))
	--end)

	self.btn_send:addListener("ec_mouse_click", function() 
		self:returnGold()
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

pReturnGold.returnGold = function(self)
	local text = self.edit_coin:getText()
	if not text or not tonumber(text) then return end
	modClubMgr.getCurClub():returnGold(self.clubInfo.id, tonumber(text), function(reply) 
		infoMessage("捐赠成功，等待管理员同意")
		if self.host then
			self.host:getMemberInfo()
		end
		self:close()
	end)	
end

pReturnGold.deskRefreshClubInfo = function(self)
	local modMainDesk = import("ui/club/main_desk.lua")
	modMainDesk.pMainDesk:instance():refreshClubInfo()
end

pReturnGold.setCoinText = function(self, number)
	if not number or not tonumber(number) then return end
	number = tonumber(number)
	self.edit_coin:setText(number)
	self.curNumber = number
end

pReturnGold.open = function(self, clubInfo, host)
	self.clubInfo = clubInfo
	self.host = host
	self.clubInfo:getSelfMember(function(memberInfo)
		self.selfMemberInfo = memberInfo
		self:initUI()
		self:regEvent()
	end)
end


pReturnGold.initUI = function(self)
	self.curNumber = tonumber(self.edit_coin:getText() or 100)
	self.edit_coin:setupKeyboardOffset(gWorld:getUIRoot())
	self.txt_desc:setText("请输入您要捐赠给俱乐部的的金豆数量，捐赠后需要管理员确认，否则将退回给您。")
	self.txt1:setText(sf("最大<%d>", self:getMaxGold()))
	--self.btn_send:setText("捐赠")
end

pReturnGold.close = function(self)
	self.host = nil
	self.clubInfo = nil
	self.curNumber = 0
	pReturnGold:cleanInstance()
end

pReturnGold.delNumber = function(self)
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

pReturnGold.reinput = function(self)
	self.edit_coin:setText("")
end


pReturnGold.getMaxGold = function(self)
	return self.selfMemberInfo:getGold()
end

pReturnGold.touchNumber = function(self, n)
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

pReturnGold.checkNumberIsMax = function(self, n)
	if n > self:getMaxGold() then
		return true
	end
	if string.len(tostring(n)) > 9 then
		return true
	end
end
