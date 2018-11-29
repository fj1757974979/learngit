local modSeatWndBase = import("ui/card_battle/seat.lua")
local modTableBase = import("ui/card_battle/table.lua")
local modHandCardWnd = import("ui/card_battle/battles/niuniu/hand_cards.lua")
local modSound = import("logic/sound/main.lua")
local modEasing = import("common/easing.lua")

pNiuniuSeatWnd = pNiuniuSeatWnd or class(modSeatWndBase.pSeatView)

pNiuniuSeatWnd.regEvent = function(self)
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

	self.__bet_hdr = self.player:bind("bet", function(bet)
		if bet > 0 then
			self:setHintText(sf("x%d", bet))
		else
			self:setHintText("")
		end
	end, 0)
end

pNiuniuSeatWnd.getMessagePos = function(self)
	local seatId = self.player:getSeatId()
	if seatId == 0 then
		return 15, -111
	elseif seatId == 1 then
		return -116, -6
	elseif seatId == 2 then
		return 14, 144
	elseif seatId == 3 then
		return 14, 144
	else
		return 156, -6
	end
end

pNiuniuSeatWnd.getGoldWnd = function(self)
	local wnd = self.img_gold
	return wnd
end

pNiuniuSeatWnd.reset = function(self)
end

pNiuniuSeatWnd.destroy = function(self)
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
	if self.__bet_hdr then
		self.player:unbind(self.__bet_hdr)
		self.__bet_hdr = nil
	end
	modSeatWndBase.pSeatView.destroy(self)
end

---------------------------------------------

pNiuniuTableWnd = pNiuniuTableWnd or class(modTableBase.pTableWndBase)

pNiuniuTableWnd.getTemplate = function(self)
	return "data/ui/card/niuniu_table.lua"
end

pNiuniuTableWnd.playStartEffect = function(self)
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

pNiuniuTableWnd.playGameOverEffect = function(self, isWin, allkill)
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

pNiuniuTableWnd.getMaxSeatCnt = function(self)
	return 5
end

pNiuniuTableWnd.getSeatParent = function(self, seatId)
	return self[sf("wnd_seat%d", seatId)]
end

pNiuniuTableWnd.getHandCardPoolParent = function(self, seatId)
	return self[sf("point_hand_cards%d", seatId)]
end

pNiuniuTableWnd.getCountDownTxtWnd = function(self)
	return self.txt_count_down
end

pNiuniuTableWnd.getCountDownParent = function(self)
	return self.wnd_count_down
end

pNiuniuTableWnd.initUI = function(self)
	modTableBase.pTableWndBase.initUI(self)
	self.point_calc:setColor(0)
	self.txt_count_down:setFont("card_count_down", 50, 1)
	self.txt_count_down:setText("")
end

pNiuniuTableWnd.newSeatWnd = function(self, player)
	local seatId = player:getSeatId()
	local seatIdToType = {
		[0] = 0,
		[1] = 1,
		[2] = 2,
		[3] = 2,
		[4] = 1,
	}
	local t = seatIdToType[seatId]
	local parent = self[sf("wnd_seat%d", seatId)]
	return pNiuniuSeatWnd:new(t, player, parent)
end

pNiuniuTableWnd.newHandCardWndObj = function(self, player)
	local handCardWnd = nil
	if player:isMyself() then
		handCardWnd = modHandCardWnd.pHandCardsSelf:new(player)
	else
		handCardWnd = modHandCardWnd.pHandCards:new(player)
	end
	return handCardWnd
end

pNiuniuTableWnd.showNiuType = function(self, flag, niuType)
	local handCardWnd = self:getHandCardWnd(player)
	handCardWnd:showNiuType(flag, niuType)
end

pNiuniuTableWnd.hintNiuCards = function(self, player)
	local niuCardIds = player:getNiuCardIds()
	local handCardWnd = self:getHandCardWnd(player)
	handCardWnd:hintNiuCards(niuCardIds)
end

pNiuniuTableWnd.resetNiuCards = function(self, player)
	local handCardWnd = self:getHandCardWnd(player)
	handCardWnd:resetNiuCards()
end

pNiuniuTableWnd.getUIChooseNiuCardIds = function(self, player)
	return self:getHandCardWnd(player):getChosenCardIds()
end

pNiuniuTableWnd._floatScore = function(self, fromPlayer, toPlayer, score, callback)
	local fid = fromPlayer:getUserId()
	local tid = toPlayer:getUserId()
	local fseat = self:getSeatWnd(fid)
	local tseat = self:getSeatWnd(tid)
	local fwnd = fseat:getGoldWnd()
	local twnd = tseat:getGoldWnd()
	local fx, fy = fwnd:getX(true) + fwnd:getWidth()/2, fwnd:getY(true) + fwnd:getHeight()/2
	local tx, ty = twnd:getX(true) + twnd:getWidth()/2, twnd:getY(true) + twnd:getHeight()/2
	local wnds = {}
	for i = 1, 10 do
		local wnd = pWindow:new()
		wnd:setImage(self.battle:getGoldImg())
		wnd:setSize(30, 30)
		wnd:setKeyPoint(15, 15)
		wnd:setParent(self)
		wnd.__fx = fx + math.random(-100, 100)
		wnd.__fy = fy + math.random(-100, 100)
		wnd:setPosition(fx, fx)
		wnd:setZ(C_MAX_Z)
		table.insert(wnds, wnd)
	end
	runProcess(1, function()
		local t1 = s2f(0.5)
		for i = 1, t1 do
			for _, wnd in ipairs(wnds) do
				local x = modEasing.outQuad(i, fx, wnd.__fx - fx, t1)
				local y = modEasing.outQuad(i, fy, wnd.__fy - fy, t1)
				wnd:setPosition(x, y)
				local s = modEasing.linear(i, 1, 1, t1)
				wnd:setScale(s, s)
			end
			yield()
		end
		local t = s2f(1)
		for i = 1, t do
			for _, wnd in ipairs(wnds) do
				local x = modEasing.inQuad(i, wnd.__fx, tx - wnd.__fx, t)
				local y = modEasing.inQuad(i, wnd.__fy, ty - wnd.__fy, t)
				wnd:setPosition(x, y)
				local s = modEasing.linear(i, 2, -1, t)
				wnd:setScale(s, s)
			end
			yield()
		end
		for _, wnd in ipairs(wnds) do
			wnd:setParent(nil)
		end
		if callback then
			callback()
		end
	end)
end

pNiuniuTableWnd.playCalcAnimation = function(self, param, callback)
	local bankerUserId = self.battle:getBankerUserId()
	local banker = self.battle:getPlayer(bankerUserId)
	for _, info in ipairs(param) do
		local player = info.player
		local userId = player:getUserId()
		local score = info.score
		if not player:isBanker() then
			if score > 0 then
				self:_floatScore(banker, player, score, function()
				end)
			elseif score < 0 then
				self:_floatScore(player, banker, math.abs(score), function()
				end)
			end
		end
	end
	setTimeout(s2f(2), function()
		for _, info in ipairs(param) do
			info.player:modifyScore(info.score)
		end
		setTimeout(s2f(1), function()
			if callback then
				callback()
			end
		end)
	end)
end

