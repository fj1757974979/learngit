local modChannelMgr = import("logic/channels/main.lua")
local modEasing = import("common/easing.lua")

pSeatView = pSeatView or class(pWindow)

-- type: 0 - self
--       1 - seat1 seat2
--       2 - seat3 seat4
pSeatView.init = function(self, t, player, parent)
	self:load(self:getTemplate(t))
	self:setSelected(false)
	self:showZhuangFlag(false)
	if self.wnd_offline then
		self.wnd_offline:show(false)
	end
	if self.wnd_hint then
		self.wnd_hint:setText("")
	end
	self:setParent(parent)
	self.player = player
	self:initUI()
	self:regEvent()
end

pSeatView.initUI = function(self)

end

pSeatView.getTemplate = function(self, t)
	return "data/ui/card/seat"..t..".lua"
end

pSeatView.setSelected = function(self, flag)
	self.wnd_select:show(flag)
end

pSeatView.showZhuangFlag = function(self, flag)
	self.wnd_flag_zhuang:show(flag)
	self.wnd_select:show(flag)
end

pSeatView.setPlayer = function(self, player)
	self.player = player
end

pSeatView.getOfflineCountdownWnd = function(self)
	return self.wnd_image_click
end

pSeatView.regEvent = function(self)
	self.__name_hdr = self.player:bind("name", function(name)
		self.txt_name:setText(name)
	end, "")
	self.__avatar_url_hdr = self.player:bind("avatarurl", function(url)
		if not url or url == "" then
			self.wnd_head:setImage("ui:image_default_female.png")
		else
			self.wnd_head:setImage(url)
		end
		self.wnd_head:setColor(0xffffffff)
	end, "ui:image_default_female.png")
	self.__online_state_hdr = self.player:bind("online", function(flag)
		log("error", sf("online ============ %d, %s", self.player:getUserId(), flag))
		self.wnd_offline:show(not flag)
	end, true)
	self.__is_ready_hdr = self.player:bind("ready", function(isReady)
		if self.wnd_hint then
			if isReady then
				if not self.__ready_wnd then
					self.__ready_wnd = pWindow:new()
					self.__ready_wnd:setImage("ui:battle_ok.png")
					self.__ready_wnd:setToImgHW()
					self.__ready_wnd:setParent(self.wnd_hint)
					self.__ready_wnd:setAlignX(ALIGN_CENTER)
					self.__ready_wnd:setAlignY(ALIGN_MIDDLE)
				end
			else
				if self.__ready_wnd then
					self.__ready_wnd:setParent(nil)
					self.__ready_wnd = nil
				end
			end
		end
	end, false)

	self:addListener("ec_mouse_click", function()
		if modChannelMgr.getCurChannel():isNeedGeoFunc() then
			local modPlayerInfoMgr = import("logic/menu/player_info_mgr.lua")
			modPlayerInfoMgr.newMgr(self.player:getUid(), T_POKER_ROOM)
		else
			local modPlayerInfoWnd = import("ui/card_battle/player_info.lua")
			modPlayerInfoWnd.pPlayerInfoWnd:instance():open(self.player)
		end
	end)
end

pSeatView.setHintText = function(self, txt)
	if self.__bankrupt then
		return
	end
	self.wnd_hint:setText(txt)
end

pSeatView.bankruptHintText = function(self, txt)
	self.__bankrupt = true
	self.wnd_hint:setText(txt)
	self.wnd_hint:getTextControl():setColor(0xffff0000)
end

pSeatView.getGoldTxtWnd = function(self)
	return self.txt_gold
end

pSeatView.playModifyScoreHint = function(self, mod)
	local goldWnd = self:getGoldTxtWnd()
	local wnd = pWindow:new()
	wnd:setSize(goldWnd:getWidth(), goldWnd:getHeight())
	wnd:getTextControl():setFontSize(30)
	local txt = ""
	if mod >= 0 then
		wnd:getTextControl():setColor(0xff00ff00)
		txt = "+" .. tostring(mod)
	else
		wnd:getTextControl():setColor(0xffff0000)
		txt = tostring(mod)
	end
	wnd:setText(txt)
	wnd:getTextControl():setAlignX(ALIGN_CENTER)
	wnd:getTextControl():setAlignY(ALIGN_MIDDLE)
	wnd:setParent(goldWnd)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setAlignY(ALIGN_TOP)
	wnd:setPosition(0, - goldWnd:getHeight())
	wnd:setColor(0)
	runProcess(1, function()
		local t = s2f(0.5)
		local offset = 50
		for i = 1, t do
			local offy = modEasing.outQuad(i, 0, - offset, t)
			wnd:setOffsetY(offy)
			yield()
		end
		wnd:setParent(nil)
	end)
end

pSeatView.onGameStart = function(self)
	if self.__ready_wnd then
		self.__ready_wnd:setParent(nil)
		self.__ready_wnd = nil
	end
end

pSeatView.setOnlineFlag = function(self, flag)
	self.wnd_offline:show(not flag)
end

pSeatView.getMessagePos = function(self)
end

pSeatView.getEmojiScale = function(self)
	return 1
end

pSeatView.newTextMessageWnd = function(self)
	local wnd = pWindow:new()
	local x, y = self:getMessagePos()
	local seatId = self.player:getSeatId()
	if seatId == 1 then
		wnd:setImage("ui:voice_text_right.png")
		wnd:setAlignX(ALIGN_RIGHT)
		wnd:setRX(self:getWidth())
	else
		wnd:setImage("ui:voice_text_left.png")
		if seatId == 0 then
			y = y * 4 / 5
		end
	end
	wnd:setPosition(x, y)
	wnd:setParent(self)
	return wnd
end

pSeatView.newEmojiMessageWnd = function(self)
	local emojiEff = pSprite()
	emojiEff:setParent(self)
	local x, y = self:getMessagePos()
	emojiEff:setPosition(x, y)
	local scale = self:getEmojiScale()
	emojiEff:setScale(scale, scale)
	return emojiEff
end

pSeatView.newAudioeMessageWnd = function(self)
	local wnd = pWindow:new()
	local x, y = self:getMessagePos()
	local seatId = self.player:getSeatId()
	if seatId == 1 then
		wnd:setImage("ui:im_audio_right.png")
		wnd:setAlignX(ALIGN_RIGHT)
		wnd:setRX(self:getWidth())
	else
		wnd:setImage("ui:im_audio_left.png")
		if seatId == 0 then
			y = y * 4 / 5
		end
	end
	wnd:setPosition(x, y)
	wnd:setParent(self)
	wnd:setSize(86, 55)
	return wnd
end

pSeatView.showFixedMessage = function(self, fixedId, gameVoiceName)
	if fixedId > 1000 then
		modChannelMgr.getCurChannel():playSoundMessage(fixedId, self.player:getGender(), gameVoiceName)
		local content = modChannelMgr.getCurChannel():getSoundMessageContent(fixedId)
		self:showTextMessageContent(content)
	else
		self:showEmojiMessageContent(fixedId)
	end
end

pSeatView.showTextMessage = function(self, text)
	self:showTextMessageContent(text)
end

pSeatView.showAudioMessage = function(self)
	self:cleanAudioMessage()
	self.audioMsgWnd = self:newAudioeMessageWnd()
end

pSeatView.hideAudioMessage = function(self)
	self:cleanAudioMessage()
end

pSeatView.showEmojiMessageContent = function(self, fixedId)
	self:cleanEmojiMessage()
	local emojiEff = self:newEmojiMessageWnd()
	emojiEff:setTexture(sf("effect:%d.fsi", fixedId), 0)
	emojiEff:setSpeed(3)
	emojiEff:play(5, true)
	emojiEff:setZ(C_MAX_Z)
end

pSeatView.showTextMessageContent = function(self, text)
	self:cleanTextMessage()
	self.textMsgWnd = self:newTextMessageWnd()
	self.textMsgWnd:enableEvent(false)
	self.textMsgWnd:setZ(C_MAX_Z)
	self.textMsgWnd:setColor(0xffffffff)
	self.textMsgWnd:getTextControl():setAutoBreakLine(false)
	self.textMsgWnd:getTextControl():setFontSize(27)
	self.textMsgWnd:getTextControl():setColor(0xff223330)
	self.textMsgWnd:getTextControl():setAlignY(ALIGN_TOP)
	self.textMsgWnd:setXSplit(true)
	self.textMsgWnd:setYSplit(true)
	self.textMsgWnd:setSplitSize(50)
	self.textMsgWnd:setText(text)
	self.textMsgWnd:setSize(self.textMsgWnd:getTextControl():getWidth() + 50, self.textMsgWnd:getTextControl():getHeight() + 25)
	self.__fixed_msg_hdr = setTimeout(s2f(4), function()
		self.textMsgWnd:setParent(nil)
		self.textMsgWnd = nil
		self.__fixed_msg_hdr = nil
	end)
end

pSeatView.cleanTextMessage = function(self)
	if self.textMsgWnd then
		self.textMsgWnd:setParent(nil)
		self.textMsgWnd = nil
	end
	if self.__fixed_msg_hdr then
		self.__fixed_msg_hdr:stop()
		self.__fixed_msg_hdr = nil
	end
end

pSeatView.cleanEmojiMessage = function(self)
end

pSeatView.cleanAudioMessage = function(self)
	if self.audioMsgWnd then
		self.audioMsgWnd:setParent(nil)
		self.audioMsgWnd = nil
	end
end

pSeatView.reset = function(self)
end

pSeatView.destroy = function(self)
	if self.__name_hdr then
		self.player:unbind(self.__name_hdr)
		self.__name_hdr = nil
	end
	if self.__avatar_url_hdr then
		self.player:unbind(self.__avatar_url_hdr)
		self.__avatar_url_hdr = nil
	end
	if self.__online_state_hdr then
		self.player:unbind(self.__online_state_hdr)
		self.__online_state_hdr = nil
	end
	if self.__is_ready_hdr then
		self.player:unbind(self.__is_ready_hdr)
		self.__is_ready_hdr = nil
	end
	if self.__ready_wnd then
		self.__ready_wnd:setParent(nil)
		self.__ready_wnd = nil
	end
	self:cleanTextMessage()
	self:cleanEmojiMessage()
	self:cleanAudioMessage()
	self.player = nil
	self:setParent(nil)
end
