local modSeatWndBase = import("ui/card_battle/seat.lua")
local modHandCardWnd = import("ui/card_battle/battles/paijiu/hand_cards.lua")
local modTableBase = import("ui/card_battle/table.lua")
local modEasing = import("common/easing.lua")
local modSound = import("logic/sound/main.lua")

pPaijiuSeatWnd = pPaijiuSeatWnd or class(modSeatWndBase.pSeatView)

pPaijiuSeatWnd.getTemplate = function(self, t)
	return "data/ui/card/paijiu_seat.lua"
end

pPaijiuSeatWnd.initUI = function(self)
	if self.player:getSeatId() == 2 then
		self.wnd_hint:setPosition(0, 100)
	else
		self.wnd_hint:setPosition(0, -50)
	end
end

pPaijiuSeatWnd.regEvent = function(self)
	modSeatWndBase.pSeatView.regEvent(self)
	self.__score_hdr = self.player:bind("score", function(score)
		self.txt_gold:setText(score)
	end, 0)
	self.__banker_hdr = self.player:bind("banker", function(flag)
		log("error", sf("banker ============== %d, %s", self.player:getUserId(), flag))
		self:showZhuangFlag(flag)
	end, false)

	self.__random_banker_hdr = self.player:bind("randomBanker", function(flag)
		self:showZhuangFlag(flag)
	end, false)

	self.__antes_hdr = self.player:bind("bet", function(bet)
		if bet > 0 then
			self:setHintText(sf("x%d", bet))
		else
			self:setHintText("")
		end
	end, 0)

	if self.player:getBattle():isKzwf() then
		self.__antes2_hdr = self.player:bind("bet2", function(bet2)
			local player = self.player
			local bet = player:getProp("bet") or 0
			if bet > 0 then
				local bet2 = player:getProp("bet2")
				self:setHintText(sf("头套:%d 二套:%d", bet, bet2))
			else
				self:setHintText("")
			end
		end)
	end
end

pPaijiuSeatWnd.getIconWndPos = function(self)
	local wnd = self.img_gold
	return wnd:getX(true), wnd:getY(true)
end

pPaijiuSeatWnd.getMessagePos = function(self)
	local seatId = self.player:getSeatId()
	if seatId == 0 then
		return 0, -70
	elseif seatId == 1 then
		return -80, -4
	elseif seatId == 2 then
		return 0, 80
	else
		return 180, -4
	end
end

pPaijiuSeatWnd.getEmojiScale = function(self)
	return 0.8
end

pPaijiuSeatWnd.reset = function(self)
end

pPaijiuSeatWnd.destroy = function(self)
	if self.__score_hdr then
		self.player:unbind(self.__score_hdr)
		self.__score_hdr = nil
	end

	if self.__random_banker_hdr then
		self.player:unbind(self.__random_banker_hdr)
		self.__random_banker_hdr = nil
	end
	if self.__banker_hdr then
		self.player:unbind(self.__banker_hdr)
		self.__banker_hdr = nil
	end
	if self.__antes_hdr then
		self.player:unbind(self.__antes_hdr)
		self.__antes_hdr = nil
	end
	if self.__antes2_hdr then
		self.player:unbind(self.__antes2_hdr)
		self.__antes2_hdr = nil
	end

	modSeatWndBase.pSeatView.destroy(self)
end
-----------------------
pPaijiuFakeSeatWnd = pPaijiuFakeSeatWnd or class(modSeatWndBase.pSeatView)

pPaijiuFakeSeatWnd.getTemplate = function(self)
	return "data/ui/card/paijiu_fake_seat.lua"
end

pPaijiuFakeSeatWnd.regEvent = function(self)
end

pPaijiuFakeSeatWnd.reset = function(self)
end

pPaijiuFakeSeatWnd.destroy = function(self)
end

pPaijiuFakeSeatWnd.setSelected = function(self)
end

pPaijiuFakeSeatWnd.showZhuangFlag = function(self)
end

pPaijiuFakeSeatWnd.setPlayer = function(self, player)
end

pPaijiuFakeSeatWnd.setOnlineFlag = function(self, flag)
end
---------------------------------------------
pPaijiuTableWnd = pPaijiuTableWnd or class(modTableBase.pTableWndBase)

pPaijiuTableWnd.init = function(self, battle)
	modTableBase.pTableWndBase.init(self, battle)
	self.wnd_menu_parent:setColor(0)
end

pPaijiuTableWnd.getTemplate = function(self)
	return "data/ui/card/paijiu_table.lua"
end

pPaijiuTableWnd.adjustUI = function(self)
	modTableBase.pTableWndBase.adjustUI(self)
	local mySeatParent = self:getSeatParent(0)
	local myHandCardPoolParent = self:getHandCardPoolParent(0)

	local w = mySeatParent:getWidth()
	local offx = gGameWidth / 2 + mySeatParent:getOffsetX() + w / 2 + (myHandCardPoolParent:getOffsetX() + mySeatParent:getOffsetX()) + myHandCardPoolParent:getWidth() / 2
	log("info", "******* ", mySeatParent:getOffsetX(), w, gGameWidth, offx)
	self.wnd_menu_parent:setSize(gGameWidth - offx, self.wnd_menu_parent:getHeight())
	self.wnd_choose_row:show(false)
	for i = 1, 32 do
		self[sf("card%d", i)]:showSelf(false)
	end
end

pPaijiuTableWnd.regEvent = function(self)
	modTableBase.pTableWndBase.regEvent(self)
	self:addListener("ec_mouse_click", function()
		local myself = self.battle:getMyself()
		if not myself:isObserver() then
			return
		end
		myself:cleanPick()
	end)
end

pPaijiuTableWnd.getMenuParent = function(self)
	return self.wnd_menu_parent
end

pPaijiuTableWnd.newSeatWnd = function(self, player)
	local seatId = player:getSeatId()
	local parent = self[sf("wnd_seat%d", seatId)]
	if player:isFake() then
		return pPaijiuFakeSeatWnd:new(t, player, parent)
	else
		return pPaijiuSeatWnd:new(t, player, parent)
	end
end

pPaijiuTableWnd.newHandCardWndObj = function(self, player)
	return modHandCardWnd.pHandCards:new(player)
end

pPaijiuTableWnd.getSeatParent = function(self, seatId)
	return self[sf("wnd_seat%d", seatId)]
end

pPaijiuTableWnd.getHandCardPoolParent = function(self, seatId)
	return self[sf("point_hand_cards%d", seatId)]
end

pPaijiuTableWnd.getCountDownTxtWnd = function(self)
	return self.txt_count_down
end

pPaijiuTableWnd.getCountDownParent = function(self)
	return self.wnd_count_down
end

pPaijiuTableWnd.updateTableCard = function(self, idx, card)
	local parent = self[sf("card%d", idx)]
	if parent then
		card:getCardWnd():setParent(parent)
		card:getCardWnd():setSize(parent:getWidth(), parent:getHeight())
		if parent.__card_wnd then
			parent.__card_wnd:setParent(nil)
		end
		parent.__card_wnd = card:getCardWnd()
	end
end

pPaijiuTableWnd.playRollDiceEffect = function(self, d1, d2)
	local rowWnd = self.wnd_choose_row
	local effect = pSprite()
	effect:setTexture("effect:shaizi.fsi", 0)
	effect:setParent(rowWnd)
	effect:setZ(C_BATTLE_UI_Z)
	--effect:setScale(1.5, 1.5)
	effect:setPosition(rowWnd:getWidth()/2, rowWnd:getHeight()/2 + 20)
	effect:play(1, true)

	modSound.getCurSound():playSound("sound:touzi.mp3")

	if self.diceWnd1 then
		self.diceWnd1:setParent(nil)
	end

	if self.diceWnd2 then
		self.diceWnd2:setParent(nil)
	end

	local wnd1 = pWindow:new()
	local wnd2 = pWindow:new()

	wnd1:setSize(62, 72)
	wnd1:setKeyPoint(31, 36)
	wnd2:setSize(62, 72)
	wnd2:setKeyPoint(31, 36)
	wnd1:show(false)
	wnd2:show(false)

	local cx,cy = self.wnd_choose_row:getWidth()/2, self.wnd_choose_row:getHeight()/2
	wnd1:setPosition(cx - 50, cy)
	wnd2:setPosition(cx + 50, cy)

	wnd1:setParent(rowWnd)
	wnd2:setParent(rowWnd)
	wnd1:setImage(sf("ui:shaizi/shaizi%d.png", d1))
	wnd2:setImage(sf("ui:shaizi/shaizi%d.png", d2))

	self.diceWnd1 = wnd1
	self.diceWnd2 = wnd2

	setTimeout(39, function()
		self.diceWnd1:show(true)
		self.diceWnd2:show(true)
	end)
end

pPaijiuTableWnd.playChooseRowAnimation = function(self, curIdx, fromIdxs, callback)
	-- 动画效果
	if self._choose_row_hdr then
		self._choose_row_hdr:stop()
	end

	self.curIdx = curIdx
	self.curCard = 0
	self._choose_row_hdr = runProcess(s2f(0.2), function()
		for i=1,2 do
			for _, idx in ipairs(fromIdxs) do
				self.wnd_choose_row:show(true)
				local rowWnd = self[sf("wnd_row_%d", idx)]
				modSound.getCurSound():playSound("sound:card_game/randombanker.mp3")
				local y = rowWnd:getY()
				self.wnd_choose_row:setOffsetY(y)
				yield()
			end
		end

		modSound.getCurSound():playSound("sound:card_game/selectbanker.mp3")
		local rowWnd = self[sf("wnd_row_%d", curIdx)]
		local y = rowWnd:getY()
		self.wnd_choose_row:setOffsetY(y)
		if callback then
			callback()
		end
	end)
end

pPaijiuTableWnd.showCurIdxCards = function(self)
	if not self.curCard then return end
	for i=self.curCard + 1, 8 do
		local wnd = self["card"..(self.curIdx * 8 + i)].__card_wnd
		if wnd then
			wnd:setShowState(ST_CARD_BACK)
		end
	end
end

pPaijiuTableWnd.getNextFlyCard = function(self)
	if not self.curIdx then return end
	self.curCard = self.curCard + 1
	return self["card"..(self.curIdx * 8 + self.curCard)]
end

pPaijiuTableWnd._floatScore = function(self, fromUid, toUid, score, callback)
	local fromSeat = self:getSeatWnd(fromUid)
	local toSeat = self:getSeatWnd(toUid)
	local fx, fy = fromSeat:getIconWndPos()
	local tx, ty = toSeat:getIconWndPos()

	local floatWnds = {}
	for i=1, 10 do
		local floatWnd = pWindow:new()
		floatWnd:load("data/ui/card/paijiu_calc_floating.lua")
		floatWnd:setParent(self)
		floatWnd:setZ(C_MAX_Z)
		local dx, dy = math.random(-50, 50), math.random(-50, 50)
		floatWnd:setPosition(fx + dx, fy + dy)
		-- floatWnd.txt_score:setText(score)
		floatWnd.txt_score:setText("")
		table.push_back(floatWnds, floatWnd)
	end
	runProcess(1, function()
		local step = 0.025
		for i = 0,1,step do
			for j=1,10 do
				local floatWnd = floatWnds[j]
				local x, y = floatWnd:getX(), floatWnd:getY()
				local dx, dy = (tx - fx) * step, (ty - fy) * step
				floatWnd:setPosition(x + dx, y + dy)
			end
			yield()
		end
		for i=1,10 do
			floatWnds[i]:setParent(nil)
		end
		if callback then
			callback()
		end
	end)
end

pPaijiuTableWnd.playCalcAnimation = function(self, calcStatistic, winLoseInfos, callback)
	local bankerUserId = self.battle:getBankerUserId()
	local banker = self.battle:getPlayer(bankerUserId)
	for userId, info in pairs(winLoseInfos) do
		local score = info.score
		local relate = info.relate
		banker:modifyScore(score)
		if relate == 1 then
			self:_floatScore(userId, bankerUserId, score, function()
				player = self.battle:getPlayer(userId)
				player:modifyScore(- score)
			end)
		elseif relate == 2 then
			self:_floatScore(bankerUserId, userId, - score, function()
				player = self.battle:getPlayer(userId)
				player:modifyScore(- score)
			end)
		end
	end
	setTimeout(s2f(2), function()
		if callback then
			callback()
		end
	end)
end

pPaijiuTableWnd.playStartEffect = function(self)
	--self:playRollDiceEffect()
	--do return end
	local effect = pSprite()
	effect:setTexture("effect:card_game/start.fsi", 0)
	effect:setParent(self)
	effect:setZ(C_BATTLE_UI_Z)
	--effect:setAlignY(ALIGN_MIDDLE)
	--effect:setAlignX(ALIGN_CENTER)
	effect:setScale(1.5, 1.5)
	effect:setPosition(self:getWidth()/2, self:getHeight()/2)
	effect:play(1, true)
end


pPaijiuTableWnd.playGameOverEffect = function(self, isWin, allkill)
	local effect = pSprite()
	if isWin then
		modSound.getCurSound():playSound("sound:card_game/win.mp3")
		if allkill == 1 then
			effect:setTexture("effect:card_game/killall.fsi", 0)
		else
			effect:setTexture("effect:card_game/win.fsi", 0)
		end
	else
		modSound.getCurSound():playSound("sound:card_game/lose.mp3")
		if allkill == -1 then
			effect:setTexture("effect:card_game/allkill.fsi", 0)
		else
			effect:setTexture("effect:card_game/lose.fsi", 0)
		end
	end
	effect:setParent(self)
	effect:setZ(C_BATTLE_UI_Z)
	--effect:setAlignY(ALIGN_MIDDLE)
	--effect:setAlignX(ALIGN_CENTER)
	effect:setScale(1.5, 1.5)
	effect:setPosition(self:getWidth()/2, self:getHeight()/2)
	effect:play(1, true)
end

pPaijiuTableWnd.reset = function(self)
	if self._choose_row_hdr then
		self._choose_row_hdr:stop()
		self._choose_row_hdr = nil
	end
	self.wnd_choose_row:show(false)

	if self.diceWnd1 then
		self.diceWnd1:setParent(nil)
		self.diceWnd1 = nil
	end

	if self.diceWnd2 then
		self.diceWnd2:setParent(nil)
		self.diceWnd2 = nil
	end
	modTableBase.pTableWndBase.reset(self)
end

pPaijiuTableWnd.destroy = function(self)
	for i = 1, 32 do
		local cardWnd = self[sf("card%d", i)]
		if cardWnd.__card_wnd then
			cardWnd.__card_wnd:setParent(nil)
			cardWnd.__card_wnd = nil
		end
	end
	if self._choose_row_hdr then
		self._choose_row_hdr:stop()
		self._choose_row_hdr = nil
	end
	modTableBase.pTableWndBase.destroy(self)
end
