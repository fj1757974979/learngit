local modUtil = import("util/util.lua")
local modSound = import("logic/sound/main.lua")
local modUserData = import("logic/userdata.lua")
local modChatInputWnd = import("ui/chat/input.lua")

pMessage = pMessage or class()

pMessage.init = function(self, t, uid, data)
	self.t = t
	self.uid = uid
	self.data = data
end

pMessage.play = function(self, chatMgr)
	local battle = chatMgr:getBattle()
	if not battle then
		return
	end
	if self.t == T_IM_MSG_AUDIO then
		setTimeout(1, function()
			chatMgr:playAudio(self.uid, self.data)
		end)
	elseif self.t == T_IM_MSG_TEXT then
		local delay = modUtil.s2f(2.5)
		battle:getBattleUI():textMessage(self.data, self.uid, delay)
		setTimeout(delay + 1, function()
			chatMgr:tryShowTextMessage(self.uid)
		end)
	end
end

pMessage.onFinish = function(self, chatMgr)
	local battle = chatMgr:getBattle()
	if self.t == T_IM_MSG_AUDIO then
		battle:getBattleUI():audioMessageFinish(self.uid)
	elseif self.t == T_IM_MSG_TEXT then
		battle:getBattleUI():textMessageFinish(self.uid)
	end
end

---------------------------------------

pChatMgr = pChatMgr or class(pSingleton)

pChatMgr.init = function(self)
	if puppy.im and puppy.im.pImMgr and
		puppy.im.pImMgr.getInstance and
		puppy.im.pImMgr.popRecvMessageId then
		self.imMgr = puppy.im.pImMgr:getInstance()
	else
		self.imMgr = nil
	end
	local app = puppy.world.pApp.instance()
	local ioMgr = app:getIOServer()
	if not ioMgr:fileExist("tmp:chatmark.ini") then
		self.firstLogin = true
	else
		self.firstLogin = false
	end

	self.soundMessages = {}
	self.textMessages = {}
end

pChatMgr.setBattle = function(self, battle)
	self.battle = battle
	if not battle then
		if self.imMgr then
			if self.imMgr:isPlaying() then
				self.imMgr:stopPlayAudio()
			end
			if self.imMgr:isRecording() then
				self.imMgr:cancelRecordAudio()
			end
		end
	end
end

pChatMgr.cleanBattle = function(self, battle)
	if self.battle == battle then
		self:setBattle(nil)
	end
end

pChatMgr.getBattle = function(self)
	return self.battle
end

pChatMgr.getImMgr = function(self)
	return self.imMgr
end

pChatMgr.initEnv = function(self)
	if self.imMgr then
		local imKey = gameconfig:getConfigStr("global", "im_key", "")
		local opChannel = modUtil.getOpChannel()
		local distribute = "dev"
		local cerName = sf("%s%s", string.gsub(opChannel, "_", ""), distribute)
		self.imMgr:initialize(imKey, cerName)
		self:initLoginEnv()
		self:initPlayAudioEnv()
		self:initMessageEnv()
	end
end

pChatMgr.initLoginEnv = function(self)
	if self.imMgr then
		self.imMgr.onLoginSuccess = function(imMgr)
			if self.firstLogin then
				local ioMgr = puppy.world.pApp.instance():getIOServer()
				local buff = puppy.pBuffer:new()
				buff:initFromString("1", len("1"))
				ioMgr:save(buff, "tmp:chatmark.ini", 0)
			end
		end

		self.imMgr.onLoginFailed = function(imMgr)
		end
	end
end

pChatMgr.initPlayAudioEnv = function(self)
	if self.imMgr then
		local onComplete = function()
			if not self.battle then
				self.__is_playing = false
				return
			end
			if self.__is_recording then
				self.__is_playing = false
				return
			end
			self:muteCurrentAudio(false)
			setTimeout(1, function()
				self.__is_playing = false
				self:tryPlaySoundMessage()
			end)
		end
		self.imMgr.onBeginPlayAudio = function(imMgr, success, reason, audioPath)
			if not success then
				infoMessage(reason)
				setTimeout(1, function()
					onComplete()
				end)
			else
				self.__wait_play_complete_flag = true
				if self.__wait_play_complete_hdr then
					self.__wait_play_complete_hdr:stop()
				end
				self:muteCurrentMusic(true)
				self.__wait_play_complete_hdr = setTimeout(modUtil.s2f(C_IM_MAX_AUDIO_DU * 1.5), function()
					if self.__wait_play_complete_flag then
						onComplete()
					end
					self.__wait_play_complete_hdr = nil
					self.__wait_play_complete_flag = false
				end)
			end
		end

		self.imMgr.onCompletePlayAudio = function(imMgr, success, reason, audioPath)
			self.__wait_play_complete_flag = false
			if self.__wait_play_complete_hdr then
				self.__wait_play_complete_hdr:stop()
				self.__wait_play_complete_hdr = nil
			end
			setTimeout(1, function()
				onComplete()
			end)
			if not success then
				infoMessage(reason)
			end
		end
	end
end

pChatMgr.initMessageEnv = function(self)
	if self.imMgr then
		if not self.__recv_loop_hdr then
			self.__recv_loop_hdr = setInterval(10, function()
				local messageId = self.imMgr:popRecvMessageId()
				if messageId then
					local messageType = self.imMgr:getMessageType(messageId)
					local messageFromAcc = self.imMgr:getMessageFromAcc(messageId)
					local messageContent = self.imMgr:getMessageContent(messageId)
					self.imMgr:popMessage(messageId)
					if not self.battle then
						return
					end
					local uid = self:dessembleIMAccount(messageFromAcc)
					if messageType == T_IM_MSG_TEXT then
						self:addTextMessage(uid, messageContent)
					elseif messageType == T_IM_MSG_AUDIO then
						self:addAudioMessage(uid, messageContent)
					end
				end
			end)
		end
	end
end

pChatMgr.addAudioMessage = function(self, uid, audioPath)
	local message = pMessage:new(T_IM_MSG_AUDIO, uid, audioPath)
	table.insert(self.soundMessages, message)
	self:tryPlaySoundMessage()
end

pChatMgr.addTextMessage = function(self, uid, text)
	if not self.textMessages[uid] then
		self.textMessages[uid] = {}
	end
	local message = pMessage:new(T_IM_MSG_TEXT, uid, text)
	table.insert(self.textMessages[uid], message)
	self:tryShowTextMessage(uid)
end

pChatMgr.tryPlaySoundMessage = function(self)
	if self.__is_playing then
		return
	end
	if self.__last_sound_message then
		self.__last_sound_message:onFinish(self)
	end
	if self.__is_recording then
		return
	end
	local message = self.soundMessages[1]
	if message then
		message:play(self)
		table.remove(self.soundMessages, 1)
	end
	self.__last_sound_message = message
end

pChatMgr.tryShowTextMessage = function(self, uid)
	if self.__last_text_message then
		self.__last_text_message:onFinish(self)
	end
	if not self.textMessages[uid] then
		return
	end
	local message = self.textMessages[uid][1]
	if message then
		message:play(self)
		table.remove(self.textMessages[uid], 1)
	end
	self.__last_text_message = message
end

pChatMgr.assembleIMAccount = function(self, uid)
	return sf("%s.%d", modUtil.getOpChannel(), uid)
end

pChatMgr.dessembleIMAccount = function(self, account)
	local opChannel = modUtil.getOpChannel()
	local pos = string.find(account, opChannel)
	if pos == nil then
		return tonumber(account)
	else
		return tonumber(string.sub(account, pos + string.len(opChannel) + 1, -1))
	end
end

pChatMgr.showAudioInputWnd = function(self)
	if not self.__input_wnd then
		self.__input_wnd = modChatInputWnd.pAudioInputWnd:new(self.battle:getBattleUI())
		self.__input_wnd:setRX(self.battle:getBattleUI():getAudioInputWndRX())
	end
	self.__input_wnd:startAnimation()
end

pChatMgr.hideAudioInputWnd = function(self)
	if self.__input_wnd then
		self.__input_wnd:destroy()
		self.__input_wnd = nil
	end
end

pChatMgr.login = function(self, uid, token)
	if self.imMgr then
		self.account = self:assembleIMAccount(uid)
		self.token = token
		self.imMgr:login(self.account, self.token, not self.firstLogin)
	end
end

pChatMgr.canSendAudioMsg = function(self)
	if not self.__last_send_time or
		app:getCurrentFrame() - self.__last_send_time >= modUtil.s2f(2) then
		return true
	else
		return false
	end
end

pChatMgr.recordLastSendTime = function(self)
	self.__last_send_time = app:getCurrentFrame()
end

pChatMgr.hasEnableIm = function(self)
	return self.imMgr ~= nil
end

pChatMgr.beginRecordAudio = function(self)
	if self.imMgr then
		if not self:canSendAudioMsg() then
			infoMessage(TEXT("您说话太快了，休息一下吧..."))
			return
		end
		if self.__sending_hdr then
			infoMessage(TEXT("正在发送消息，请休息一下，稍候再试吧"))
			return
		end
		if not self.imMgr:recordAudio(C_IM_MAX_AUDIO_DU * 2) then
			infoMessage(TEXT("开启录音设备失败，请检查录音权限是否开启"))
			self.__is_recording = false
		else
			self:showAudioInputWnd()
			self:muteCurrentAudio(true)
			self.__is_recording = true
		end
	end
end

pChatMgr.stopRecordAudio = function(self)
	if self.imMgr then
		self:hideAudioInputWnd()
		if self.__is_recording then
			self.imMgr:stopRecordAudio()
			self:sendAudioMsg("", 0)
		end
		self:tryPlaySoundMessage()
	end
end

pChatMgr.cancelRecordAudio = function(self)
	if self.imMgr then
		self:hideAudioInputWnd()
		self:muteCurrentAudio(false)
		setTimeout(1, function()
			self.imMgr:cancelRecordAudio()
			self:tryPlaySoundMessage()
		end)
	end
end

pChatMgr.isRecording = function(self)
	if self.imMgr then
		return self.imMgr:isRecording()
	else
		return false
	end
end

pChatMgr.playAudio = function(self, uid, audioPath)
	if self.imMgr then
		if self.__is_playing then
			--infoMessage(TEXT("正在播放另一个语音！"))
			return
		end
		self.__is_playing = true
		--self:muteCurrentMusic(true)
		setTimeout(33, function()
			local battle = self:getBattle()
			if battle then
				battle:getBattleUI():audioMessage(uid)
			end
			self.imMgr:playAudio(audioPath)
		end)
	else
		infoMessage("没有imMgr，播不了语音！")
	end
end

pChatMgr.muteCurrentAudio = function(self, flag)
	puppy.toggleSound(not flag)
	self:muteCurrentMusic(flag)
end

pChatMgr.muteCurrentMusic = function(self, flag)
	modSound.getCurSound():muteMusic(flag)
	if app:getPlatform() == "ios" then
		if flag then
			modSound.getCurSound():pauseMusic()
		else
			modSound.getCurSound():resumeMusic()
		end
	end
end

pChatMgr.sendTextMsg = function(self, txt)
	if self.battle and self.imMgr then
		local players = self.battle:getAllPlayers()
		for _, player in pairs(players) do
			local uid = player:getUid()
			if uid == modUserData.getUID() then
				self:addTextMessage(uid, txt)
			else
				if not player:isRobot() then
					local acc = self:assembleIMAccount(uid)
					self.imMgr:sendTextMessage(txt, acc, T_IM_SESSION_P2P)
				end
			end
		end
	end
end

pChatMgr.sendAudioMsg = function(self, audioPath, audioLength)
	if self.battle and self.imMgr then
		if self.__sending_hdr then
			self.__sending_hdr:stop()
		end
		local cnt = 10
		self.__sending_hdr = setInterval(10, function()
			cnt = cnt - 1
			if cnt < 0 then
				self.__sending_hdr = nil
				self.__is_recording = false
				infoMessage(TEXT("发送消息超时"))
				self:muteCurrentAudio(false)
				return "release"
			end
			if self.battle:getPlayerCnt(true) <= 1 then
				-- 只有一个非机器人玩家
				self.__sending_hdr = nil
				self.__is_recording = false
				self:muteCurrentAudio(false)
				return "release"
			end
			local players = self.battle:getAllPlayers()
			local bingo = false
			for _, player in pairs(players) do
				local uid = player:getUid()
				if uid ~= modUserData.getUID() then
					if not player:isRobot() and not player:isFake() then
						local acc = self:assembleIMAccount(uid)
						local ret = self.imMgr:sendAudioMessage(audioPath, acc, T_IM_SESSION_P2P, audioLength)
						if ret == -2 then
							infoMessage(TEXT("录音失败，请检查录音权限是否开启"))
							self:muteCurrentAudio(false)
							self.__sending_hdr = nil
							self.__is_recording = false
							return "release"
						elseif ret == 0 then
							bingo = true
						elseif ret == -1 then
							return
						end
					end
				end
			end
			if bingo then
				self.__sending_hdr = nil
				self.__is_recording = false
				local curAudioPath = self.imMgr:getRecordAudioPath()
				if curAudioPath then
					self:muteCurrentAudio(false)
					self:addAudioMessage(modUserData.getUID(), curAudioPath)
				else
					infoMessage(TEXT("播放失败"))
				end
				return "release"
			end
		end)
	end
end

pChatMgr.destroy = function(self)
	self:hideAudioInputWnd()
end
