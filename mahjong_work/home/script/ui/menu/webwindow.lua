local modUIUtil = import("ui/common/util.lua")

pWeb = pWeb or class(pWindow, pSingleton)

pWeb.init = function(self)
	self:load("data/ui/web.lua")
	self:setParent(gWorld:getUIRoot())
	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()	
	end)
	modUIUtil.setClosePos(self.btn_close)
	self:setZ(C_MAX_Z)
	modUIUtil.makeModelWindow(self, false, true)

	local webp = self.wnd_web
	webp:setPosition(webp:getX(), webp:getY())
	webwindow = pWebWindow()
	webwindow:setParent(webp)
	webwindow:setWorldSize(gGameWidth, gGameHeight)
	webwindow:setSize(webp:getWidth(), webp:getHeight())
	webwindow:setPosition(0, 0)
	self.webwindow = webwindow
end

pWeb.open = function(self, url)
	if self.webwindow then
		self.webwindow:show(true)
		if url then
			self.webwindow:loadUrl(url)
		end
	end
	self:show(true)
end

pWeb.close = function(self)
	if self.webwindow then
		self.webwindow:show(false)
	end
	self:show(false)
end
