
pAudioInputWnd = pAudioInputWnd or class(pWindow)

pAudioInputWnd.init = function(self, parent)
	self:load("data/ui/audio_input.lua")
	self:setParent(parent)
	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_MAX_Z)
	self.txt_hint:setText(TEXT("手指滑动取消发送"))
end

pAudioInputWnd.startAnimation = function(self)
	if self.__hdr then
		self.__hdr:stop()
	end
	local i = 1
	self.__hdr = setInterval(10, function()
		for j = 1, i do
			self[sf("wnd_volume_%d", j)]:show(true)
		end
		for k = i + 1, 4 do
			self[sf("wnd_volume_%d", k)]:show(false)
		end
		i = i + 1
		if i > 4 then
			i = 1
		end
	end)
end

pAudioInputWnd.destroy = function(self)
	if self.__hdr then
		self.__hdr:stop()
		self.__hdr = nil
	end
	self:setParent(nil)
end
