local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modEasing = import("common/easing.lua")

pResourceLoadingPanel = pResourceLoadingPanel or class(pWindow, pSingleton)

pResourceLoadingPanel.init = function(self)
	self:load("data/ui/res_loading.lua")
	self:setParent(gWorld:getUIRoot())
	self:setZ(C_MAX_Z)
	self:setRenderLayer(C_MAX_RL)

	self.txt_newest_version:show(false)
	self.txt_current_version:show(false)
	
	self.wnd_background:setImage(modUIUtil.getChannelRes("login_bg.jpg"))

	modUIUtil.adjustSize(self.wnd_background, gGameWidth, gGameHeight)
	self:show(false)
end

pResourceLoadingPanel.open = function(self, callback)
	if modUtil.isFastLoadingChannel() then
		callback()
		return
	end
	self.hint:setText("正在加载资源...")
	self:show(true)
	runProcess(1, function()
		local t = modUtil.s2f(1)
		local f = self.progress:getPercent()
		local d = 1.0 - f
		for i = 1, t do
			local nf = modEasing.linear(i, f, d, t)
			self.progress:setPercent(nf)
			yield()
		end
		if callback then
			callback()
		end
		self:close()
	end)
end

pResourceLoadingPanel.close = function(self)
	pResourceLoadingPanel:cleanInstance()
end
