local modUtil = import("util/util.lua")

------------------------------
pRulePanel = pRulePanel or class(pWindow, pSingleton)

pRulePanel.init = function(self)
	self:load("data/ui/rule.lua")
	self:setParent(gWorld:getUIRoot())
	modUtil.makeModelWindow(self)
	modUtil.addFadeAnimation(self)
   	self:show(false)	
	self:regEvent()
end

pRulePanel.regEvent = function(self)
	self.btn_close:enableEvent(true)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)
end

pRulePanel.genTxtWnd = function(self, message)
	self.wnd_list:setColor(0x0)
	self.wnd_list:setClipDraw(true)
	self.dragWnd = pWindow()
   	self.dragWnd:setParent(self.wnd_list)
   	self.dragWnd:showSelf(false)
	self.dragWnd:setPosition(0, 0)
	
	local txtWnd = pWindow()
	txtWnd:load("data/ui/rule_txt.lua")
	txtWnd:setText(message)
	self.txtWnd = txtWnd

	local textH = txtWnd:getTextControl():getHeight()
	txtWnd:setSize(self.wnd_list:getWidth(), textH + 10)
	modUtil.buildDragWindowVertical(self.dragWnd, {txtWnd}, 0)
end

pRulePanel.setTitleImg = function(self, imgPath)
	self.txt_title:setImage(imgPath)
	self.txt_title:setToImgHW()
end

pRulePanel.open = function(self, msg, titleImgPath)
	self:bringTop()
	titleImgPath = titleImgPath or "ui:public_title.png"
	self:setTitleImg(titleImgPath)
	self:genTxtWnd(msg)
	self.bClose = false
	self:show(true)
end

pRulePanel.close = function(self)
	if self.bClose then
		return
	end
	self.bClose = true

	self:cleanDragWnd()
	self:cleanSelfInstance()
end

pRulePanel.cleanDragWnd = function(self)
	if self.txtWnd then
		self.txtWnd:setParent(nil)
		self.txtWnd = nil
	end
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pRulePanel.cleanSelfInstance = function(self)
	pRulePanel:cleanInstance(self)
end
