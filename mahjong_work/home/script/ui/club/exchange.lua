local modClubMgr = import("logic/club/main.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modExchange = import("data/info/info_club_config.lua")
local modDeskMenu = import("ui/club/main_desk_menu.lua")
local modUserData = import("logic/userdata.lua")
local modChannelMgr = import("logic/channels/main.lua")

pExchange = pExchange or class(pWindow, pSingleton)

pExchange.init = function(self)
	self:load("data/ui/club_add_coin.lua")
	self:setParent(gWorld:getUIRoot())
	modUIUtil.makeModelWindow(self, false, false)
end

pExchange.regEvent = function(self)
	self.btn_plus:addListener("ec_mouse_click", function() 
		self:addRoomCard(1)	
	end)

	self.btn_dec:addListener("ec_mouse_click", function() 
		self:addRoomCard(-1)
	end)

	--self.edit_diamond:addListener("ec_focus", function()
	--end)

	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)

	self.btn_send:addListener("ec_mouse_click", function()
		local text = self.edit_diamond:getText()
		if tonumber(text) and tonumber(text) == 0 then
			infoMessage("请输入您想要兑换的金豆数量")
			return
		end
		modClubMgr.getCurClub():addClubGold(self.clubInfo:getClubId(), tonumber(self.edit_diamond:getText()), function(reply) 
			infoMessage("兑换金豆成功，现在可以将俱乐部的金豆发放给俱乐部的成员。")
			modClubMgr.getCurClub():updateClubInfoById(self.clubInfo:getClubId(), function(clubInfo)
				self.clubInfo = clubInfo
				self:close()	
			end)
		end)
	end)

	--self.edit_diamond:addListener("ec_unfocus", function() 
	--	if not self:checktText() then
	--		infoMessage("请输入正确的数字")
	--		self:setDiamonText(0)
	--	else
	--		self:setDiamonText(tonumber(self.edit_diamond:getText()))
	--	end
	--end)

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

pExchange.checktText = function(self)
	local text = self.edit_diamond:getText()
	if not text or not tonumber(text) or tonumber(text) <= 0 then
		return false
	end
	if math.floor(tonumber(text)) < tonumber(text) then
		return false
	end
	return true
end

pExchange.setDiamonText = function(self, number)
	if not number or not tonumber(number) then return end
	number = tonumber(number)
	self.edit_diamond:setText(number)
	self.curInputNumber = number
	self.txt_coin:setText(self:changeGold(number))
end

pExchange.changeGold = function(self, number)
	if not number then return end
	return number * self.ratio
end

pExchange.addRoomCard = function(self, number)
	if not number then return end
	if not self.edit_diamond:getText() then return end
	local curNumber = tonumber(self.edit_diamond:getText())
	if not curNumber then return end
	local max = modUserData.getRoomCardCount()
	local cardname = modChannelMgr.getCurChannel():getRoomcardText()
	local min = 0
	if curNumber + number > max then
		infoMessage("不能超过您拥有的"..cardname.."数量")
		return
	end
		
	if curNumber + number < min then
		return
	end
	self:setDiamonText(curNumber + number)
end

pExchange.checkNumberIsMax = function(self, n)
	if n > self:getMaxGold() then
		return true
	end
	if string.len(tostring(n)) > 9 then
		return true
	end
end

pExchange.open = function(self, clubInfo, host)
	self.clubInfo = clubInfo
	self.host = host
	self.selfMemberInfo = memberInfo
	self:initUI()
	self:regEvent()
end


pExchange.initUI = function(self)
	local channelId = modUtil.getOpChannel()
	self.ratio = modExchange.data[channelId]["gold_coins_per_room_card"]
	self.curInputNumber = tonumber(self.edit_diamond:getText() or 0)
	self.edit_diamond:setupKeyboardOffset(gWorld:getUIRoot())
	self.txt_desc:setText(sf("请输入您要兑换的金豆数量，该金豆只能在本俱乐部中使用", self.ratio))
	--self.btn_send:setText("确定")
	self.txt1:setText(sf("最多<%d>", self:getMaxGold()))
	self.txt2:setText("兑换比例1:".. self.ratio)
	local channel = modUtil.getOpChannel()
	if channel == "nc_tianjiuwang" then
		self.room_card:setImage("ui:channel_res/nc_tianjiuwang/main_room_card.png")
		self.room_card:setToImgHW()
		self.room_card:setScale(0.8,0.8)
	end
end

pExchange.getMaxGold = function(self)
	return modUserData.getRoomCardCount() 
end

pExchange.close = function(self)
	self.host = nil
	self.clubInfo = nil
	pExchange:cleanInstance()
end

pExchange.touchNumber = function(self, n)
	local code = self.edit_diamond:getText()
	local cardname = modChannelMgr.getCurChannel():getRoomcardText()
	if not code or tonumber(code) == 0 then
		if self:checkNumberIsMax(n) then
			infoMessage("哪来这么多"..cardname.."，你想上天呀？")
			self:setDiamonText(self:getMaxGold())
			return
		end
		self:setDiamonText(n)
		return
	end
	
	if self:checkNumberIsMax(tonumber(code .. n)) then
		infoMessage("哪来这么多"..cardname.."，你想上天呀？")
		self:setDiamonText(self:getMaxGold())
		return
	end
	self:setDiamonText(code .. n)
end

pExchange.delNumber = function(self)
	local code = self.edit_diamond:getText()
	if not code or code == "" then return end
	local len = string.len(self.edit_diamond:getText())
	if len <= 1 then 
		self:reinput()
		return 
	end

	code = string.sub(code, 1, -2) 
	self.edit_diamond:setText(code)
	self.txt_coin:setText(code * self.ratio)
end

pExchange.reinput = function(self)
	self.edit_diamond:setText("")
	self.txt_coin:setText("")
end

