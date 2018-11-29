local modMsg = import("common/ui/msgbox.lua")
local modFileList = import("common/ui/control/filelist.lua")

pSavePanel = pSavePanel or class(pWindow, pSingleton)

pSavePanel.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:enableDrag(true)
	self:load("tool/uieditor/template/save.lua")

	self.filelist = modFileList.pFileList()
	self.filelist:setParent(self)
	self.filelist:setRootDir("home/script/data/level")
	self.filelist:setSize(300, 200)
	self.filelist:setPosition(50, 100)
	self.filelist.onFileSelect = function(fl, file)
		self.editPath:setText("data/level/"..file)
	end
end

pSavePanel.onSave = function(self, btn, event)
	table.save(self.data, "home/script/" .. self.editPath:getText())
	self:close()
	modMsg.showMessage(string.format("%s保存成功", self.editPath:getText()))
end

pSavePanel.setData = function(self, table, defaultPath)
	self.editPath:setText(defaultPath)
	self.data = table
end

showSavePanel = function(table, defaultPath)
	local panel = pSavePanel:instance()
	panel:open()
	panel:setData(table, defaultPath)
end

