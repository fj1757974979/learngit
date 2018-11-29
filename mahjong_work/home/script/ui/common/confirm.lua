local modUtil = import("util/util.lua")

pConfirmDilog = pConfirmDilog or class(pWindow, pSingleton)

pConfirmDilog.init = function(self)
	self:load("data/ui/common_cue.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	self:show(false)

	self:initUI()
	self:regEvent()
	self.txt_ok:setText("确定")
	self.txt_cancel:setText("取消")
	self.txt_title:setText("提示")
	self:setRenderLayer(C_MAX_RL or 6)
	self:setZ(C_MAX_Z or -99999)
end

pConfirmDilog.initUI = function(self)
	self.txt_title:setText(TEXT(19))
	self.txt_dec:setText("")
end

pConfirmDilog.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_ok:addListener("ec_mouse_click", function()
		if self.okCb then
			self.okCb()
		end
		self.okCb = nil
		self.noCb = nil
		self:close()
	end)

	self.btn_cancel:addListener("ec_mouse_click", function()
		self:close()
	end)
end

pConfirmDilog.close = function(self)
	if self.noCb then
		self.noCb()
	end
	self.noCb = nil
	self.okCb = nil
	pConfirmDilog:cleanInstance()
end

pConfirmDilog.open = function(self, title, msg, okCb, noCb)
	title = title or TEXT(19)
	self.txt_title:setText(title)
	self.txt_dec:setText(msg)
	self.okCb = okCb
	self.noCb = noCb
	self:show(true)
end

pConfirmDilog.openCustom = function(self, msg, okCb, noCb, okImg, cancelImg)
	if okImg then
		self.txt_ok:setImage(sf("ui:%s", okImg))
	end
	if cancelImg then
		self.txt_cancel:setImage(sf("ui:%s", cancelImg))
	end
	self:open(TEXT(19), msg, okCb, noCb)
end

-------------------------------------------------------

pForceConfirmDialog = pForceConfirmDialog or class(pWindow, pSingleton)

pForceConfirmDialog.init = function(self)
	self:load("data/ui/common_notice.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	self:show(false)

	self:initUI()
	self:regEvent()
end

pForceConfirmDialog.initUI = function(self)
	self:setText("")
	self.txt_title:setText(TEXT("提示"))
	self.txt_ok:setText(TEXT("确定"))
end

pForceConfirmDialog.regEvent = function(self)
	self.btn_ok:addListener("ec_mouse_click", function()
		self:close()
	end)
end

pForceConfirmDialog.open = function(self, msg, okCb)
	self.txt_dec:setText(msg)
	self.okCb = okCb
	self:show(true)
end

pForceConfirmDialog.close = function(self)
	if self.okCb then
		self.okCb()
	end
	self.okCb = nil
	pForceConfirmDialog:cleanInstance()
end
