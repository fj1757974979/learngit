local modMsg = import("common/ui/msgbox.lua")
local modFileList = import("common/ui/control/filelist.lua")
local modConfirmDialog = import("common/ui/confirm_dialog.lua") 

pSavePanel = pSavePanel or class(pWindow, pSingleton)

pSavePanel.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:enableDrag(true)
	self:load("tool/uieditor/template/save.lua")

	self.filelist = modFileList.pFileList()
	self.filelist:setParent(self)
	local lang=gameconfig:getConfigStr("global", "locale","cn")
	if lang ~= "cn" then
		self.rootDir = string.format("home/locale/%s/script/", lang)
	else
		self.rootDir = "home/script/"
	end
	self.filelist:setRootDir(self.rootDir)
	self.filelist:setCurDir("data/ui/")
	self.filelist:setSize(300, 200)
	self.filelist:setPosition(50, 100)
	self.filelist.onFileSelect = function(fl, file)
		self.editPath:setText(fl:getSelectFile())
	end
end

pSavePanel.onSave = function(self, btn, event)
	
	local okFunc = function()

		if self.callBack then
			self.callBack(self.editPath:getText())
		end
		
		table.save(self.data, self.rootDir .. self.editPath:getText())
		self:close()
		modMsg.showMessage(string.format("%s保存成功", self.editPath:getText()))
	end

	local noFunc = function()
		self:close()
	end

	self.dialog = modConfirmDialog.pConfirmDialog:instance()
	self.dialog:openCustom(string.format("确定将界面保存为%s吗？", self.editPath:getText()),okFunc,noFunc)
end

pSavePanel.setData = function(self, table, defaultPath)
	self.editPath:setText(defaultPath)
	self.data = table
end

showSavePanel = function(table, defaultPath, func)
	local panel = pSavePanel:instance()
	panel.callBack = func
	panel:open()
	panel:setData(table, defaultPath)
end

