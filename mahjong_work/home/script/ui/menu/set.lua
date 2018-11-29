local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modEvent = import("common/event.lua")
local modCommonCue = import("ui/common/common_cue.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modUserData = import("logic/userdata.lua")
local modMenuMain = import("logic/menu/main.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modSound = import("logic/sound/main.lua")
local modSessionMgr = import("net/mgr.lua")
local modChannelMgr = import("logic/channels/main.lua")

pSetMain = pSetMain or class(pWindow, pSingleton)

pSetMain.init = function(self)
	self:load("data/ui/set.lua")
	self:setParent(gWorld:getUIRoot())
	self.maxX = self.pro_sound:getWidth()
	self.btnNameToSave = {
		[self.btn_zhengdong:getName()] = "zhengdong",
		[self.btn_fangyan:getName()] = "fangyan",
		[self.btn_click:getName()] = "click",
		[self.btn_big:getName()] = "big",
	}
	self.btnPos = {
		["zhengdong"] = 0,
		["fangyan"] = 0,
		["click"] = 0,
		["big"] = 0,
	}
	self.wnd_sound:setText("音效")
	self.wnd_music:setText("音乐")
	self.wnd_zhengdong:setText("震动")
	self.wnd_click:setText("单击出牌")
	self.wnd_big:setText("放大出牌")
	self.wnd_fangyan:setText("方言")
	local version = modUtil.getCurrentVersion()
	self.wnd_version:setText("当前版本：" .. version)
	--self.wnd_verison:setOffsetX( - self.wnd_verison:getTextControl():getWidth() / 2)
	--self.wnd_verison:setOffsetY( - self.wnd_verison:getTextControl():getHeight() / 2 - 10)
	self:regEvent()
	modUIUtil.makeModelWindow(self,false,true)  --此处可能有问题
end

pSetMain.clickProgress = function(self, btn)
	if not btn then
		return
	end
	local x = btn:getX()
	local parentWnd = btn:getParent()
	if x < 10 then
		btn:setPosition(parentWnd:getWidth() - btn:getWidth(), 0)
		self:setProgress(parentWnd, 1)
	else
		btn:setPosition(0, 0)
		self:setProgress(parentWnd, 0)
	end
	self.btnPos[self.btnNameToSave[btn:getName()]] = btn:getX()
	modChannelMgr.getCurChannel():setBtnState(self.btnNameToSave[btn:getName()], x < 10)
end

pSetMain.setProgress = function(self, pro, percent)
	if not pro or not percent then
		log("error", "percent or pro is nil", percent)
		return
	end
	if percent > 1 then
		percent = 1
	end
	if percent < 0 then
		percent = 0
	end
	pro:setPercent(percent)
end

pSetMain.open = function(self, isBattleWnd, isLeave)
	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_BATTLE_UI_Z)
	self:loadData()
	if isBattleWnd then
		self.btn_return:show(false)
	else
		self.wnd_return:setImage("ui:main_return.png")
		self.btn_return:addListener("ec_mouse_click", function()
			if modBattleMgr.getCurBattle() then
				modBattleMgr.pBattleMgr:instance():battleDestroy()
			end
			modSessionMgr.instance():closeSession(T_SESSION_BATTLE)
			modSessionMgr.instance():closeSession(T_SESSION_PROXY)
			modMenuMain.pMenuMgr:instance():close()
			-- 清理微信session
			local modLoginMain = import("logic/login/main.lua")
			modLoginMain.pLoginMgr:instance():clearLoginData()
			modLoginMain.pLoginMgr:instance():getCurLoginPanel():show(true)
			self:close()
		end)
	end
	if modUtil.isAppstoreExamineVersion() then
		if not isBattleWnd  then
			self.btn_return:show(false)
		end
	end
end

pSetMain.setBtnPos = function(self, btn, per)
	local dx = btn:getWidth() / 6
	local x = 0
	if per <= 0 then
		x = 0
	elseif per >= 1 then
		x = self.maxX - btn:getWidth() * 0.8
	else
		x = self.maxX * per - dx
	end
	btn:setPosition(x, 0)
end



pSetMain.initWindow = function(self)

end

pSetMain.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_sound_point:addListener("ec_mouse_drag", function(e)
		self:movePoint(self.btn_sound_point, e)
		local p = self:getPercentFromBtn(self.btn_sound_point)
		self:setProgress(self.pro_sound, p)
		modSound.getCurSound():setSoundVolumeRate(p)
		log("warn", p)
	end)

	self.btn_music_point:addListener("ec_mouse_drag", function(e)
		self:movePoint(self.btn_music_point, e)
		local p = self:getPercentFromBtn(self.btn_music_point)
		self:setProgress(self.pro_music, p)
		modSound.getCurSound():setMusicVolumeRate(p)
		log("warn", p)
	end)

	self.btn_zhengdong:addListener("ec_mouse_click", function()
--		self:clickProgress(self.btn_zhengdong)
		infoMessage(TEXT("此功能尚未开放, 敬请期待!"))
	end)
	self.btn_click:addListener("ec_mouse_click", function()
--		self:clickProgress(self.btn_click)
		infoMessage(TEXT("此功能尚未开放, 敬请期待!"))
	end)
	self.btn_fangyan:addListener("ec_mouse_click", function()
		self:clickProgress(self.btn_fangyan)
	end)
	self.btn_big:addListener("ec_mouse_click", function()
		self:clickProgress(self.btn_big)
	end)
end

pSetMain.getPercentFromBtn = function(self, btn)
	local x = btn:getX() + btn:getWidth() * 0.2
	if btn:getX() <= 1 then
		x = btn:getX()
	elseif btn:getX() + btn:getWidth() >= btn:getParent():getWidth() then
		x = btn:getX() + btn:getWidth()
	end

	local p = x / self.maxX
	return p
end

pSetMain.movePoint = function(self, btn, e)
	local x = btn:getX()
	local dx = e:dx()
	local d = btn:getWidth()

	local moveX = x + dx
	if moveX < 0 then
		moveX = 0
	elseif moveX > self.maxX - d * 0.8 then
		moveX = self.maxX - d * 0.8
	end
	btn:setPosition(moveX, 0)
end

pSetMain.close = function(self)
	modSound.getCurSound():saveData(self.pro_sound, self.pro_music, self.btnPos)
	self.btnPos = {}
	self.btnNameToSave = {}
	pSetMain:cleanInstance()
end


pSetMain.loadData = function(self)
	local setData = modSound.getCurSound():loadData()
	if not setData then
		self:setProgress(self.pro_sound, 1.0)
		self:setProgress(self.pro_music, 0.5)
		self:setBtnPos(self.btn_sound_point, 1.0)
		self:setBtnPos(self.btn_music_point, 0.5)
		for name, mark in pairs(self.btnNameToSave) do
			if mark == "big" and modChannelMgr.getCurChannel():getBigState() then
				self:clickProgress(self[name])
			elseif mark == "fangyan" and modChannelMgr.getCurChannel():hasFangyan() then
				self:clickProgress(self[name])
			end
		end
		return
	end
	local soundP, musicP = setData.soundPercent, setData.musicPercent
	-- 设置进度条
	if soundP then
		self:setProgress(self.pro_sound, soundP)
		self:setBtnPos(self.btn_sound_point, soundP)
	end
	if musicP then
		self:setProgress(self.pro_music, musicP)
		self:setBtnPos(self.btn_music_point, musicP)
	end
	-- 设置进度条按钮位置

	if not setData.btnPos then
		return
	end
	self.btnPos = setData.btnPos

	for key, pos in pairs(setData.btnPos) do
		local name = nil
		for n, mark in pairs(self.btnNameToSave) do
			if key == mark then
				name = n
				break
			end
		end
		if name then
			if pos > 0 then
				if self[name] then
					self:clickProgress(self[name], true)
				end
			end
		end
	end
end
