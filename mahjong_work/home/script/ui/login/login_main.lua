local modEasing = import("common/easing.lua")
local modEvent = import("common/event.lua")

local modUserData = import("logic/userdata.lua")
local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modSound = import("logic/sound/main.lua")
local modLoginMgr = import("logic/login/main.lua")

-----------------------------------------------------------

pLoginMainPanel = pLoginMainPanel or class(pWindow, pSingleton)

pLoginMainPanel.init = function(self)
	-- UI
	self:initUI()
	self:setParent(gWorld:getUIRoot())
	self.breakStar = false
	self.controls = {}
	self.loginMgr = modLoginMgr.pLoginMgr:instance()
	self:show(false)
	self:setCurrentVersion()

	if modUtil.isAppstoreExamineVersion() then
		self.btn_tourist:show(false)
		self.btn_wechat:show(false)
	end

	self.btn_tourist:addListener("ec_mouse_click", function()
		self.loginMgr:touristAuth(self.wnd_name:getText())
	end)

	self.btn_wechat:addListener("ec_mouse_click", function()
		if puppy.sys.hasWeChatInstalled() then
			self.loginMgr:wechatAuth()
		else
			infoMessage(TEXT("请安装最新版的微信客户端"))
		end
	end)
	self.wnd_star:show(false)
	local time = 120

	local opp = puppy.world.app.instance()
	local platform = app:getPlatform()
	if not modUIUtil.isPlatform("macos") then
		self.wnd_name:show(false)
		self.btn_tourist:show(false)
	end
	--
	modUIUtil.turnAround(self.btn_wechat,time,self)
	modUIUtil.adjustSize(self.wnd_background, gGameWidth, gGameHeight)
end

pLoginMainPanel.initSizePos = function(self)
	return
end

pLoginMainPanel.initUI = function(self)
	local channel = modUtil.getOpChannel()
	logv("warn",channel)
	--加载不同的渠道界面
	local template = "data/ui/login_main_" .. channel .. ".lua"
	self:load(template)
	self:initSizePos()	
	self.wnd_background:setImage(modUIUtil.getChannelRes("login_bg.jpg"))	
	self.wnd_tip:setText("抵制不良游戏，拒绝盗版游戏。注意自我保护，谨防上当受骗。适度游戏益脑，沉迷游戏伤身。合理安排时间，享受健康生活。")
end

pLoginMainPanel.starBreak = function(self)
	self.breakStar = true
end

pLoginMainPanel.showDialog = function(self)
	--local modGameOverWnd = import("ui/card_battle/battles/niuniu/game_over.lua")
	--modGameOverWnd.testShow()
	--local modReportPanel = import("ui/card_battle/battles/niuniu/report.lua")
	--modReportPanel.testReport()
	--[[
	local modNiuniuView = import("ui/card_battle/battles/niuniu/table.lua")
	local panel = modNiuniuView.pNiuniuTableWnd:new()
	panel:setParent(gWorld:getUIRoot())
	panel:show(true)
	--]]
	self:show(true)
end

pLoginMainPanel.setCurrentVersion = function(self)
	local version = modUtil.getCurrentVersion()

	if not version then
		self.txt_newest_version:show(false)
	else
		self.txt_newest_version:show(true)
		self.txt_newest_version:setText(sf(TEXT(159), version))
	end
end

pLoginMainPanel.doClose = function(self)
	self.breakStar = false
	if self.controls then
		for _, wnd in pairs(self.controls) do
			wnd:setParent(nil)
		end
		self.controls = {}
	end
	if self.starWnd then
		self.starWnd = nil
	end
	pLoginMainPanel:cleanInstance()
end

pLoginMainPanel.close = function(self)
	self:doClose()
end

pLoginMainPanel.insertControl = function(self, wnd)
	if wnd then
		table.insert(self.controls, wnd)
		self.starWnd = wnd
	end
end
