local modChatMain = import("mgr.lua")
local modUtil = import("util/util.lua")

initSpeakBtn = function(self, btn_speak)
	btn_speak:muteSound(true)
	btn_speak:addListener("ec_mouse_left_down", function(e)
		if not modChatMain.pChatMgr:instance():hasEnableIm() then
			infoMessage(TEXT("请下载最新包体，体验语音聊天的乐趣吧！"))
			return
		end
		self.__down_point = {e:ax(), e:ay()}
		self.__down_frame = app:getCurrentFrame()
		if self.__speak_timeout then
			self.__speak_timeout:stop()
		end
		self.__speak_timeout = setTimeout(modUtil.s2f(C_IM_MAX_AUDIO_DU), function()
			modChatMain.pChatMgr:instance():stopRecordAudio()
			self.__down_frame = nil
			self.__down_point = nil
			self.__speak_timeout = nil
		end)
		setTimeout(1, function()
			modChatMain.pChatMgr:instance():beginRecordAudio()
		end)
	end)
	btn_speak:addListener("ec_mouse_left_up", function(e)
		if self.__down_frame then
			local curFrame = app:getCurrentFrame()
			if curFrame - self.__down_frame >= 30 then
				local x, y = e:ax(), e:ay()
				if x < gGameWidth and x > 0 and y < gGameHeight and y > 0 then
					modChatMain.pChatMgr:instance():stopRecordAudio()
				else
					if modChatMain.pChatMgr:instance():isRecording() then
						modChatMain.pChatMgr:instance():cancelRecordAudio()
					end
				end
			else
				infoMessage(TEXT("您说的话时间太短了！"))
				modChatMain.pChatMgr:instance():cancelRecordAudio()
			end
		end
		self.__down_frame = nil
		self.__down_point = nil
		if self.__speak_timeout then
			self.__speak_timeout:stop()
			self.__speak_timeout = nil
		end
	end)
	btn_speak:addListener("ec_mouse_drag", function(e)
		if modChatMain.pChatMgr:instance():isRecording() and self.__down_point then
			local x, y = e:ax(), e:ay()
			if x and y then
				if modUtil.distance(self.__down_point, {x, y}) > 50 or
					x >= gGameWidth then
					modChatMain.pChatMgr:instance():cancelRecordAudio()
					self.__down_point = nil
					self.__down_frame = nil
					if self.__speak_timeout then
						self.__speak_timeout:stop()
						self.__speak_timeout = nil
					end
				end
			end
		end
	end)
end
