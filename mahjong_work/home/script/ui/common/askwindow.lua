local modUIUtil = import("ui/common/util.lua")

pAskWnd = pAskWnd or class(pWindow)

pAskWnd.init = function(self, host, text, callback)
	self:load("data/ui/asksure.lua")
	self:setParent(gWorld:getUIRoot())
	self.host = host
	self.callback = callback
	self:regEvent()
	self:setZ(C_BATTLE_UI_Z )
	self:setRenderLayer(C_BATTLE_UI_RL)
	if text then self.wnd_text:setText(text) end
	modUIUtil.makeModelWindow(self, false, true)
end

pAskWnd.regEvent = function(self)
	self.btn_cancel:addListener("ec_mouse_click", function() 
		self:work(false)
	end)
	self.btn_ok:addListener("ec_mouse_click", function() 
		self:work(true)
	end)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)
end

pAskWnd.work = function(self, yesOrNo)
	if not yesOrNo then
		if self.callback then
			self.callback(false)
		end
		self:close()
		return 
	end
	if self.callback then
		self.callback(true)
	end
end

pAskWnd.close = function(self)
	if self.host then 
		if self.host.clearAskWnd then
			self.host:clearAskWnd()
		end
	end
	self:setParent(nil)
	self.host = nil
end




