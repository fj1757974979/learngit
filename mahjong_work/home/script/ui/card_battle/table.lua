local modSound = import("logic/sound/main.lua")
local modPokerUtil = import("logic/card_battle/util.lua")

pTableWndBase = pTableWndBase or class(pWindow)

pTableWndBase.init = function(self, battle)
	self.battle = battle
	self.uidToSeatWnd = {}
	self.userIdToHandCardWnd = {}
	self:load(self:getTemplate())
	self:initUI()
	self:regEvent()
end

pTableWndBase.initUI = function(self)
	for i = 0, self:getMaxSeatCnt() - 1 do
		log("info", i)
		self:getSeatParent(i):setColor(0)
		self:getHandCardPoolParent(i):setColor(0)
	end
	self:getCountDownTxtWnd():setColor(0)
	self:getCountDownParent():show(false)
end

pTableWndBase.adjustUI = function(self)
end

pTableWndBase.regEvent = function(self)
end

pTableWndBase.getMaxSeatCnt = function(self)
	return 4
end

pTableWndBase.getTemplate = function(self)
	return ""
end

pTableWndBase.getCountDownTxtWnd = function(self)
	log("error", "[pTableWndBase.getCountDownTxtWnd] not implemented!")
end

pTableWndBase.getCountDownParent = function(self)
	log("error", "[pTableWndBase.getCountDownParent] not implemented!")
end

pTableWndBase.getSeatParent = function(self)
	log("error", "[pTableWndBase.getSeatParent] not implemented!")
end

pTableWndBase.getHandCardPoolParent = function(self)
	log("error", "[pTableWndBase.getHandCardPoolParent] not implemented!")
end

pTableWndBase.initFromBattle = function(self, battle)
	local players = battle:getAllPlayers()
	for userId, player in pairs(players) do
		local seatWnd = self:newSeatWnd(player)
		self.uidToSeatWnd[userId] = seatWnd
		seatWnd:setPlayer(player)
	end
end

pTableWndBase.newSeatWnd = function(self, player)
	log("error", "[pTableWndBase.newSeatWnd] not implemented!")
end

pTableWndBase.newHandCardWndObj = function(self, player)
	log("error", "[pTableWndBase.newHandCardWndObj] not implemented!")
end

pTableWndBase.newHandCardWnd = function(self, player)
	local handCardWnd = self:newHandCardWndObj(player)
	self.userIdToHandCardWnd[player:getUserId()] = handCardWnd
	local seatId = player:getSeatId()
	local parent = self:getHandCardPoolParent(seatId)
	handCardWnd:setParent(parent)
	return handCardWnd
end

pTableWndBase.getHandCardWnd = function(self, player)
	local userId = player:getUserId()
	local handCardWnd = self.userIdToHandCardWnd[userId]
	if not handCardWnd then
		handCardWnd = self:newHandCardWnd(player)
	end
	return handCardWnd
end

pTableWndBase.addHandCards = function(self, player, cards)
	local handCardWnd = self:getHandCardWnd(player)
	handCardWnd:addCards(cards)
	handCardWnd:show(true)
end

pTableWndBase.startCountDown = function(self, second, callback)
	self:stopCountDown()
	second = math.max(0, second or 0)
	local countdownParent = self:getCountDownParent()
	countdownParent:show(true)
	local wndCountdown = self:getCountDownTxtWnd()
	wndCountdown:setText(second)
	self.__count_down_callback = callback
	self.__count_down_hdr = setInterval(s2f(1), function()
		second = second - 1
		if second <= 0 then
			local callback = self.__count_down_callback
			self.__count_down_callback = nil
			if callback then
				callback()
			end
			self.__count_down_hdr = nil
			countdownParent:show(false)
			modSound.getCurSound():playSound(modPokerUtil.getCountdownSound(self.battle:getPokerType(), second))
			return "release"
		else
			if second <= 3 then
				modSound.getCurSound():playSound(modPokerUtil.getCountdownSound(self.battle:getPokerType(), second))
			end
			wndCountdown:setText(second)
		end
	end)
end

pTableWndBase.stopCountDown = function(self)
	if self.__count_down_hdr then
		self.__count_down_hdr:stop()
		self.__count_down_hdr = nil
	end
	self:getCountDownParent():show(false)
	if self.__count_down_callback then
		self.__count_down_callback = nil
	end
end

pTableWndBase.addPlayer = function(self, player)
	local userId = player:getUserId()
	if not self.uidToSeatWnd[userId] then
		local seatWnd = self:newSeatWnd(player)
		self.uidToSeatWnd[userId] = seatWnd
		seatWnd:setPlayer(player)
	else
		log("error", "[pTableWndBase.addPlayer] reduplicated user", userId)
	end
end

pTableWndBase.delPlayer = function(self, player)
	local userId = player:getUserId()
	if self.uidToSeatWnd[userId] then
		self.uidToSeatWnd[userId]:destroy()
		self.uidToSeatWnd[userId] = nil
	end
end

pTableWndBase.getSeatWnd = function(self, userId)
	return self.uidToSeatWnd[userId]
end

pTableWndBase.setHintText = function(self, userId, txt)
	local seatWnd = self:getSeatWnd(userId)
	seatWnd:setHintText(txt)
end

pTableWndBase.setOfflineCountdown = function(self, userId, sec)
	local seatWnd = self:getSeatWnd(userId)
	if seatWnd then
		local wnd = seatWnd:getOfflineCountdownWnd()
		if wnd then
			wnd:setText(sec)
		end
	end
end

pTableWndBase.showHands = function(self, userIds, types, callback)
	local _types = {}
	for _, t in ipairs(types) do
		table.insert(_types, t)
	end
	runProcess(s2f(1), function()
		for idx, userId in ipairs(userIds) do
			self:showUserHands(userId, _types[idx])
			yield()
		end
		if callback then
			callback()
		end
	end):update()
end

pTableWndBase.showUserHands = function(self, uid, t)
	local handCardWnd = self.userIdToHandCardWnd[uid]
	if handCardWnd then
		local gender = self.battle:getPlayer(uid):getProp("gender")
		local sound = modPokerUtil.getHandCardTypeSoundPath(self.battle:getPokerType(), t, gender)
		if sound then
			modSound.getCurSound():playSound(sound)
		end
		handCardWnd:showHands(t)
	end
end

pTableWndBase.handleFixedChatMessage = function(self, fromUid, fixedId, gameVoiceName)
	local seatWnd = self:getSeatWnd(fromUid)
	if seatWnd then
		seatWnd:showFixedMessage(fixedId, gameVoiceName)
	end
end

pTableWndBase.handleTextChatMessage = function(self, fromUid, text)
	local seatWnd = self:getSeatWnd(fromUid)
	if seatWnd then
		seatWnd:showTextMessage(text)
	end
end

pTableWndBase.handleAudioMessage = function(self, fromUid)
	local seatWnd = self:getSeatWnd(fromUid)
	if seatWnd then
		seatWnd:showAudioMessage()
	end
end

pTableWndBase.finishAudioMessage = function(self, fromUid)
	local seatWnd = self:getSeatWnd(fromUid)
	if seatWnd then
		seatWnd:hideAudioMessage()
	end
end

pTableWndBase.onGameStart = function(self)
	for _, wnd in pairs(self.uidToSeatWnd) do
		wnd:onGameStart()
	end
end

pTableWndBase.reset = function(self)
	for _, wnd in pairs(self.uidToSeatWnd) do
		wnd:reset()
	end
	for _, wnd in pairs(self.userIdToHandCardWnd) do
		wnd:reset()
		wnd:show(false)
	end
	self:stopCountDown()
end

pTableWndBase.destroy = function(self)
	for _, wnd in pairs(self.uidToSeatWnd) do
		wnd:destroy()
	end
	self.uidToSeatWnd = {}
	for _, wnd in pairs(self.userIdToHandCardWnd) do
		wnd:destroy()
	end
	self.userIdToHandCardWnd = {}
	self:stopCountDown()
	self:setParent(nil)
end
