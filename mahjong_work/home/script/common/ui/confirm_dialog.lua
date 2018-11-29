local modUtil = import("util/util.lua")

SIZE = 30
GAP = 2
DEFINE_NUM = 2

pConfirmDialog = pConfirmDialog or class(pWindow, pSingleton)

pConfirmDialog.init = function(self)
	pSingleton.init(self)

	self.confirmCallBack = nil
	self.cancelCallback = nil
	self:load("data/ui/common_cue.lua")
	self:setParent(gWorld:getUIRoot())
	self:setZ(-100000)
	self:setRenderLayer(2)

	self:setTitle(TEXT("提示"))
	self:regEvent()

	modUtil.makeModelWindow(self)
	modUtil.addFadeAnimation(self)

	self.txt_ok:setText("确定")
	self.txt_cancel:setText("取消")
	self.txt_title:setText("提示")
	-- self.txt_1:setSize(SIZE*DEFINE_NUM+(DEFINE_NUM - 1)*GAP, SIZE)
	-- self.txt_2:setSize(SIZE*DEFINE_NUM+(DEFINE_NUM - 1)*GAP, SIZE)
end

pConfirmDialog.regEvent = function(self)
	-- self.btn_event_1:addListener("ec_mouse_click", function()
	-- 	if self.confirmCallBack then
	-- 		self.confirmCallBack()
	-- 	end
	-- 	self.cancelCallback = nil
	-- 	self:close()
	-- end)
	
	-- self.btn_event_2:addListener("ec_mouse_click", function()
	-- 	if self.cancelCallback then
	-- 		self.cancelCallback()
	-- 	end
	-- 	self.cancelCallback = nil
	-- 	self:close()
	-- end)

	self.btn_ok:addListener("ec_mouse_click", function()
		if self.confirmCallBack then
			self.confirmCallBack()
		end
		self.cancelCallback = nil
		self:close()
	end)
	
	self.btn_cancel:addListener("ec_mouse_click", function()
		if self.cancelCallback then
			self.cancelCallback()
		end
		self.cancelCallback = nil
		self:close()
	end)

	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)
end

pConfirmDialog.hideHookWnd = function(self)
	if self.chk_hook then
		self.chk_hook:show(false)
	end
	if self.txt_hook then
		self.txt_hook:show(false)
	end
end

pConfirmDialog.openCustom = function(self,msg,okCallback,cancelCallback, okImg, okNum, cancelImg, cancelNum)
	self:open()
	-- self.txt_desc:setText(TEXT(msg))
	self.txt_dec:setText(TEXT(msg))
	self.confirmCallBack = okCallback
	self.cancelCallback = cancelCallback

	-- okNum = okNum or DEFINE_NUM
	-- cancelNum = cancelNum or DEFINE_NUM
	-- if okImg and okImg ~= "" then
	-- 	self.txt_1:setImage(sf("ui:%s_txt1.png", okImg))
	-- 	self.txt_1:setClickDownImage(sf("ui:%s_txt2.png", okImg))
	-- 	self.txt_1:bindWithParent()
	-- 	self.txt_1:setSize(SIZE*okNum+(okNum - 1)*GAP, SIZE)
	-- 	self.txt_1:enableEvent(false)
	-- end
	-- if cancelImg and cancelImg ~= "" then
	-- 	self.txt_2:setImage(sf("ui:%s_txt1.png", cancelImg))
	-- 	self.txt_2:setClickDownImage(sf("ui:%s_txt2.png", cancelImg))
	-- 	self.txt_2:bindWithParent()
	-- 	self.txt_2:setSize(SIZE*cancelNum+(cancelNum - 1)*GAP, SIZE)
	-- 	self.txt_2:enableEvent(false)
	-- end
end

pConfirmDialog.open = function(self, msg, callback)
	self:show(true)
	-- self.txt_desc:setText(msg)
	self.txt_dec:setText(msg)
	self.confirmCallBack = callback
	-- add by cpz
	if self.bShowHook then
		self.bShowHook = false
	else
		self:hideHookWnd()
	end
end

pConfirmDialog.close = function(self)
	-- local okImg, cancelImg = "nsg_ok", "nsg_cancel"
	-- local okNum, cancelNum = 2, 2

	-- if okImg and okImg ~= "" and not self.bChangOKBtnText then
	-- 	self.txt_1:setImage(sf("ui:%s_txt1.png", okImg))
	-- 	self.txt_1:setClickDownImage(sf("ui:%s_txt2.png", okImg))
	-- 	self.txt_1:bindWithParent()
	-- 	self.txt_1:setSize(SIZE*okNum+(okNum - 1)*GAP, SIZE)
	-- 	self.txt_1:enableEvent(false)
	-- end
	-- if cancelImg and cancelImg ~= "" then
	-- 	self.txt_2:setImage(sf("ui:%s_txt1.png", cancelImg))
	-- 	self.txt_2:setClickDownImage(sf("ui:%s_txt2.png", cancelImg))
	-- 	self.txt_2:bindWithParent()
	-- 	self.txt_2:setSize(SIZE*cancelNum+(cancelNum - 1)*GAP, SIZE)
	-- 	self.txt_2:enableEvent(false)
	-- end

	-- self.txt_desc:setText(TEXT(""))
	self.txt_dec:setText(TEXT(""))
	self.confirmCallBack = nil
	self:show(false)
	-- pConfirmDialog:cleanInstance()
	modUtil.safeCallBack(self.closeCallBack)
	self.closeCallBack = nil
	modUtil.safeCallBack(self.cancelCallback)
	self.cancelCallback = nil
end

pConfirmDialog.setTitle = function(self, title)
	self.txt_title:setText(title)
end

pConfirmDialog.changeOKBtnTextWithPath = function(self, normalImgPath, selectedImgPath)
	if self.txt_1 and normalImgPath and normalImgPath ~= "" then
		if not selectedImgPath or selectedImgPath == "" then
			selectedImgPath = normalImgPath
		end

		self.txt_1:setImage(normalImgPath)
		self.txt_1:setClickDownImage(selectedImgPath)

		self.bChangOKBtnText = true
	end
end

pConfirmDialog.updataShow = function(self,msg)
   -- self.txt_desc:setText(TEXT(msg))
   self.txt_dec:setText(TEXT(msg))
end

pConfirmDialog.showChkHook = function(self, bDefaultSetCheck, strHookContent, hookCallback)
	if self.txt_hook and strHookContent then
		self.txt_hook:show(true)
		self.txt_hook:setText(tostring(strHookContent))
	end

	if self.chk_hook and type(hookCallback) == "function" then
		bDefaultSetCheck = bDefaultSetCheck or false
		self:setRenderLayer(0)

		self.chk_hook:showSelf(true)
		self.chk_hook:showChild(true)
		self.chk_hook:setCheck(bDefaultSetCheck)
		self.chk_hook:addListener("ec_mouse_click", function()
			modUtil.safeCallBack(hookCallback, self.chk_hook:isChecked())
		end)
	end

	self.bShowHook = true
end

pConfirmDialog.regCloseCallback = function(self, callback)
	self.closeCallBack = callback
end


updataSHowMsg = function(msg)
	pConfirmDialog:instance():updataShow(msg)
end

openConfirmDialog = function(msg, callback)
	pConfirmDialog:instance():open(msg, callback)
end

openConfirmDialogCustom = function(msg,okbtnCallback,cancelCallback)
	pConfirmDialog:instance():openCustom(msg,okbtnCallback,cancelCallback)
end

closeConfirmDialog = function()
	pConfirmDialog:instance():close()
end

-- add by cpz
getConfirmDialog = function()
	return pConfirmDialog:instance()
end


pNoticeDialog = pNoticeDialog or class(pWindow, pSingleton)

pNoticeDialog.init = function(self)
	pSingleton.init(self)
	self.confirmCallBack = nil

	self:load("data/ui/confirm_dialog_one_choice.lua")
	self.ok:addListener("ec_mouse_click", function()
		if self.confirmCallBack then
			self.confirmCallBack()
		end
		self:close()
	end)
	self:setParent(gWorld:getUIRoot())
	self.txt_title:setText("提示")
	self:setZ(-10000)
	modUtil.makeModelWindow(self)
end

pNoticeDialog.setTitle = function(self, title)
	self.txt_title:setText(title)
end

pNoticeDialog.setConfirmImg = function(self, img)
	self.wnd_ok_img:setImage(sf("ui:%s_txt1.png", img))
	self.wnd_ok_img:setClickDownImage(sf("ui:%s_txt2.png", img))
	self.wnd_ok_img:setToImgHW()
end

pNoticeDialog.openCustom = function(self, msg, okMsg, callback)
	self:show(true)
	self.txt:setText(TEXT(msg))
	self.confirmCallBack = callback
end

pNoticeDialog.close = function(self)
	self.txt:setText(TEXT(""))
	self.confirmCallBack = nil
	pNoticeDialog:cleanInstance()
end

