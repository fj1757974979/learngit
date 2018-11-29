local modMsg = import("common/ui/msgbox.lua")
local modFileList = import("common/ui/control/filelist.lua")

pLoadPanel = pLoadPanel or class(pWindow, pSingleton)

pLoadPanel.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:enableDrag(true)
	self:load("tool/uieditor/template/load.lua")

	self.filelist = modFileList.pFileList()
	self.filelist:setParent(self)
	local lang=gameconfig:getConfigStr("global", "locale","cn")
	if lang ~= "cn" then
		self.rootDir = string.format("home/locale/%s/script", lang)
	else
		self.rootDir = "home/script"
	end
	self.filelist:setRootDir(self.rootDir)
	self.filelist:setCurDir("data/ui/")
	self.filelist:setSize(300, 200)
	self.filelist:setPosition(50, 100)
	self.filelist.onFileSelect = function(fl,file)
		self.editPath:setText(fl:getSelectFile())
	end

	self.btnSure:addListener("ec_mouse_click", function()
		if self.callBack then
			self.callBack(self.editPath:getText())
		end
		self:close()
	end)
	self.btnSure:setZ(-1)
	self.btnClose:addListener("ec_mouse_click", function()
		self:close()
	end)
end

showLoadPanel = function(defaultPath, func)
	local panel = pLoadPanel:instance()
	panel:open()
	panel.callBack = func
	panel.editPath:setText(defaultPath or "")
end

