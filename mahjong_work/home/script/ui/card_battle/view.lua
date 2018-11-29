local modData = import("logic/card_battle/data.lua")
local modChatUtil = import("logic/chat/util.lua")
local modVoice = import("ui/battle/voice.lua")
local modBattleMenu = import("ui/battle/battlemenu.lua")
local modCalc = import("ui/card_battle/calc.lua")
local modHandCards = import("ui/card_battle/hand_cards.lua")
local modSeatWndBase = import("ui/card_battle/seat.lua")

pTableView = pTableView or class(pWindow, pSingleton)

pTableView.init = function(self)
	self:load("data/ui/card/table.lua")
	self:setParent(gWorld:getUIRoot())

	self.btn_setting:addListener("ec_mouse_click", function()
		if not self.menu then
			self.menu = modBattleMenu.pBattleMenu:new(self)
			self.menu:setParent(self)
		end

		self.menu:show(true)
	end)

	self.btn_chat:addListener("ec_mouse_click", function()
		if modVoice.pVoice:getInstance() then
			modVoice.pVoice:getInstance():show(true)
		else
			modVoice.pVoice:instance():open(self)
		end
	end)
	modChatUtil.initSpeakBtn(self, self.btn_speak)

	self.tableData = nil
	self.seatViews  = {}
	self.calcPanel = modCalc.pCalcPanel:new()
	self.calcPanel:setParent(self.point_calc)
	self.calcPanel:show(false)
	self.calcPanel:updateNumber(5, 6, 7, 18)

	self.handcard0 = modHandCards.pHandCardsSelf:new()
	self.handcard0:setParent(self.point_hand_cards0)

	for i=1,4 do
		self["hand_card"..i] = modHandCards.pHandCards:new()
		self["hand_card"..i]:setParent(self["point_hand_cards"..i])
	end

	self.txt_count_down:setFont("card_count_down", 50, 1)
	self.txt_count_down:setText("5")
end

pTableView.getData = function(self)
	return self.tableData
end

pTableView.setData = function(self, data)
	self.tableData = data
end

pTableView.updatePlayers = function(self)
	for _,view in pairs(self.seatViews) do
		view:setParent(nil)
	end
	
	self.seatViews = {}
	for i=0,4 do
		local view = modSeatWndBase.pSeatView:new(math.ceil(i/2))
		view:setParent(self["wnd_seat"..i])
		self.seatViews[i] = view
	end
end

pTableView.showCalc = function(self, flag)
	self.calcPanel:show(flag)
end
