local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modClubMgr = import("logic/club/main.lua")
local modBeilvs = import("data/info/info_club_min_gold.lua")
local modEvent = import("common/event.lua")

pCreateBeilv = pCreateBeilv or class(pWindow)

pCreateBeilv.init = function(self, host, gameIndex)
	self:load("data/ui/club_create_room_rule.lua")
	self:setParent(gWorld:getUIRoot())
	self.host = host
	self.gameIndex = gameIndex
	self:initUI()
	self:regEvent()
end

pCreateBeilv.needRateWnd = function(self)
	return self.gameIndex ~= "paijiu_kzwf" and self.gameIndex ~= "paijiu_mpqz"
end

pCreateBeilv.initUI = function(self)
	self:initDatas()
	self.txt_rate:setText("底注")
	self.txt_enter:setText("入场")
	self.txt_cost:setText("小费")
	self.txt_tips1:setText("*底番对应的金豆数量")
	self.txt_tips2:setText("*金豆低于该值无法上桌")
	self.txt_tips3:setText("*大赢家会消耗对应的金豆作为小费")
	self:btnClick(self.btn_rate_plus, self.wnd_rate, self.roundDatas, true)
	self:btnClick(self.btn_enter_plus, self.wnd_enter, self.groundDatas, true)
	self.edit_cost:setupKeyboardOffset(gWorld:getUIRoot())
	self.edit_cost:setText(0)
	self.costNumber = tonumber(self.edit_cost:getText())
	self:setCostNumber(self.costNumber)
	if not self:needRateWnd() then
		self.txt_rate:show(false)
		self.btn_rate_dec:show(false)
		self.btn_rate_plus:show(false)
		self.wnd_rate:show(false)
		self.txt_tips1:show(false)

		self.txt_enter:setOffsetY(-75)
		self.btn_enter_dec:setOffsetY(-75)
		self.btn_enter_plus:setOffsetY(-75)
		self.wnd_enter:setOffsetY(-75)
		self.txt_tips2:setOffsetY(-75)
		self.txt_cost:setOffsetY(-75)
		self.edit_cost:setOffsetY(-75)
		self.txt_tips3:setOffsetY(-75)

		if self.gameIndex == "paijiu_kzwf" then
			self.btn_enter_dec:show(false)
			self.btn_enter_plus:show(false)
		end

		self:setSize(self:getWidth(), self:getHeight() - 75)
	end
end

pCreateBeilv.initDatas = function(self)
	self.roundDatas = self:getBeilvData("round_min_gold")
	self.groundDatas = self:getBeilvData("ground_min_gold")
	self.wnd_rate["valueanme"] = "dibei"
	self.wnd_enter["valueanme"] = "enter"
end

pCreateBeilv.regEvent = function(self)
	self.btn_rate_plus:addListener("ec_mouse_click", function()
		self:btnClick(self.btn_rate_plus, self.wnd_rate, self.roundDatas, true)
	end)

	self.btn_rate_dec:addListener("ec_mouse_click", function()
		self:btnClick(self.btn_rate_dec, self.wnd_rate, self.roundDatas)
	end)

	self.btn_enter_plus:addListener("ec_mouse_click", function()
		self:btnClick(self.btn_enter_plus, self.wnd_enter, self.groundDatas, true)
	end)

	self.btn_enter_dec:addListener("ec_mouse_click", function()
		self:btnClick(self.btn_enter_dec, self.wnd_enter, self.groundDatas)
	end)

	self.edit_cost:addListener("ec_focus", function()
	end)

	self.edit_cost:addListener("ec_unfocus", function()
		self:focusEdit()
	end)

	self.__100_ev = modEvent.handleEvent(EV_PAIJIU_KZ_100, function()
	self.wnd_enter:setText(100)
	self.host:setValue(self.wnd_enter["valueanme"], 100)
	end)
	self.__200_ev = modEvent.handleEvent(EV_PAIJIU_KZ_200, function()
	self.wnd_enter:setText(200)
	self.host:setValue(self.wnd_enter["valueanme"], 200)
	end)
	self.__500_ev = modEvent.handleEvent(EV_PAIJIU_KZ_500, function()
	self.wnd_enter:setText(500)
	self.host:setValue(self.wnd_enter["valueanme"], 500)
	end)
end

pCreateBeilv.focusEdit = function(self)
	local text = self.edit_cost:getText()
	-- 没有输入
	if not text or not tonumber(text) then
		self.edit_cost:setText(self.costNumber)
		return
	end
	if self.gameIndex ~= "paijiu_kzwf" and
		self.gameIndex ~= "paijiu_mpqz" and
		self.gameIndex ~= "niuniu" then
		-- 消耗大于底注
		--if tonumber(text) > tonumber(self.wnd_rate:getText()) then
		--	self.edit_cost:setText(self.costNumber)
		--	infoMessage("金豆消耗不能大于底注！")
		--	return
		--end
	end
	-- 输入成功
	self.costNumber = tonumber(text)
	self:setCostNumber(self.costNumber)
end

pCreateBeilv.setCostNumber = function(self, number)
	if not self.host then return end
	self.host:setValue("cost", self.costNumber)
end

pCreateBeilv.btnClick = function(self, btn, wnd, datas, isPlus)
	if not btn or not wnd or not datas then return end
	if not wnd["index"] then
		self:setWndText(wnd, 1, datas)
		return
	end

	-- 加
	local index = wnd["index"]
	if isPlus then
		if index >= table.getn(datas) then
			index = table.getn(datas)
		else
			index = index + 1
		end
	else
		if index <= 1 then
			index = 1
		else
			index = index - 1
		end
	end
	self:setWndText(wnd, index, datas)
end

pCreateBeilv.setWndText = function(self, wnd, number, datas)
	if not wnd or not number or not datas then return end
	wnd["index"] = number
	wnd:setText(datas[number])
	if not self.host then return end
	self.host:setValue(wnd["valueanme"], tonumber(datas[number]))
end

pCreateBeilv.getBeilvData = function(self, str)
	local datas = modBeilvs.data
	local result = {}
	for idx, data in pairs(datas) do
		if data[str] and data[str] > 0 then
			result[tonumber(idx)] = data[str]
		end
	end
	return result
end

pCreateBeilv.getRoundGold = function(self)
	if not self.wnd_rate:getText() then return end
	return tonumber(self.wnd_rate:getText())
end

pCreateBeilv.getGroundGold = function(self)
	if not self.wnd_enter:getText() then return end
	return tonumber(self.wnd_enter:getText())
end



