local modPokerUtil = import("logic/card_battle/util.lua")
local modSound = import("logic/sound/main.lua")

pPlayerWnd = pPlayerWnd or class(pWindow)

pPlayerWnd.init = function(self)
	self:load("data/ui/card/niuniu_game_over_player.lua")
end

pPlayerWnd.setPlayer = function(self, playerInfo)
	if not playerInfo.isZhuang then
		self.img_zhuang:setParent(nil)
	end
	self.__name_hdr = playerInfo.player:bind("name", function(name)
		self.txt_name:setText(name)
	end)
	self.txt_card_type:setText(modPokerUtil.getNiuNameByType(playerInfo.cardType))
	if playerInfo.waterScore and playerInfo.waterScore > 0 then
		self.txt_score:setText(sf("%s(小费%d)", tostring(playerInfo.score), playerInfo.waterScore))
	else
		if playerInfo.isClub then
			if playerInfo.player:getScore() <= 0 then
				self.txt_score:setText(sf("%s(破产)", tostring(playerInfo.score)))
			else
				self.txt_score:setText(tostring(playerInfo.score))
			end
		else
			self.txt_score:setText(tostring(playerInfo.score))
		end
	end

	for i=1,5 do
		self["img_card"..i]:setImage(modPokerUtil.getPokerCardImageById(playerInfo.cardIds[i]))
	end
end

pGameOverWnd = pGameOverWnd or class(pWindow, pSingleton)

pGameOverWnd.init = function(self)
	self:load("data/ui/card/niuniu_game_over.lua")
	self.playerWnds = {}

	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_sure:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_leave:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_restart:addListener("ec_mouse_click", function()
		self:close(true)
	end)

	self:show(false)
	self:setParent(gWorld:getUIRoot())
	self:setRenderLayer(C_MAX_RL)
	self:setZ(C_MAX_Z)
	self.btn_leave:show(false)
	self.btn_restart:show(false)
end

pGameOverWnd.setWinFlag = function(self, isWin)
	if isWin then
		self.img_title:setImage("ui:card_game/game_over/img_win.png")
	else
		self.img_title:setImage("ui:card_game/game_over/img_lose.png")
	end
end
-- player { isZhuang, name, cards, cardType, score}

pGameOverWnd.setPlayerInfo = function(self, players)
	if self.playerWnds then
		for i, wnd in ipairs(self.playerWnds) do
			wnd:setParent(nil)
		end
	end
	self.playerWnds = {}

	local y = 150
	for i, info in ipairs(players) do
		local wnd = pPlayerWnd:new()
		wnd:setParent(self.wnd_info)
		wnd:setPosition(0, y)
		wnd:setPlayer(info)
		y = y + 61
		table.push_back(self.playerWnds, wnd)
	end
end

pGameOverWnd.setClubFlag = function(self)
	self.btn_sure:show(false)
	self.btn_leave:show(true)
	self.btn_restart:show(true)
	self.isClubFlag = true
end

pGameOverWnd.open = function(self, callback)
	self:show(true)
	self.callback = callback
	if not self.isClubFlag then
		setTimeout(s2f(5), function()
			self:close()
		end)
	end
	self:show(true)
end

pGameOverWnd.close = function(self, isClubRejoin)
	if self.callback then
		self.callback(isClubRejoin)
		self.callback = nil
	end
	pGameOverWnd:cleanInstance()
end


testShow = function()
	local testPanel = pGameOverWnd:instance()
	testPanel:open()
	testPanel:setWinFlag(true)
	testPanel:setPlayerInfo(
		{
			{isZhuang = true, name="姜小白", cardType="五花牛", score = 100, cards = {"ha", "h2", "h3", "h4", "h5"}},
			{isZhuang = false, name="孑孓", cardType="顺子", score = -50, cards = {"ha", "h2", "h3", "h4", "h5"}},
			{isZhuang = false, name="June", cardType="牛牛", score = 40, cards = {"ha", "h2", "h3", "h4", "h5"}},
			{isZhuang = false, name="春生", cardType="牛一", score = 30, cards = {"ha", "h2", "h3", "h4", "h5"}},
			{isZhuang = false, name="iScream", cardType="没牛", score = -30, cards = {"ha", "h2", "h3", "h4", "h5"}},
		})
end
