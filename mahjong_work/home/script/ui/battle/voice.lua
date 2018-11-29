local modUIUtil = import("ui/common/util.lua")
local modWndList = import("ui/common/list.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUserData = import("logic/userdata.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modFaceData = import("data/info/info_voices_faces.lua")
local modChatMain = import("logic/chat/mgr.lua")
local modUtil = import("util/util.lua")
local modChannelMgr = import("logic/channels/main.lua")

pVoice = pVoice or class(pWindow, pSingleton)

pVoice.init = function(self)
	self:load("data/ui/voice.lua")
	self:setParent(gWorld:getUIRoot())
	self:setZ(C_BATTLE_UI_Z)
	self.controls = {}
	self:initWnds()
	self:regEvent()
	modUIUtil.makeModelWindow(self, true, true)
end

pVoice.initWnds = function(self)
	self.edit_input:setupKeyboardOffset(self)
	self.edit_input:set_max_input_str_len(20)
	self:setOffsetX(-gGameWidth * 0.08)
	self.cb_voice["child"] = self.cb_voice_child
	self.cb_face["child"] = self.cb_face_child
end

pVoice.open = function(self, pWnd)
	self:setParent(pWnd)
	self:defaultValue()
end

pVoice.defaultValue = function(self)
	-- 清空
	if self.voiceListWnd then
		self.voiceListWnd:destroy()
		self.voiceListWnd:setParent(nil)
		self.voiceListWnd = nil
	end
	if self.faceListWnd then
		self.faceListWnd:destroy()
		self.faceListWnd:setParent(nil)
		self.faceListWnd = nil
	end
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}

	-- 设置默认值
	self:clickCB(self.cb_voice, self.cb_face)
	self:showVoicesList()

	-- 设置reset false
	modChannelMgr.getCurChannel():resetFangYan(false)
end

pVoice.recordLastSendTime = function(self)
	self.__last_send_time = app:getCurrentFrame()
end

pVoice.getLastSendTime = function(self)
	return self.__last_send_time
end

pVoice.canSend = function(self)
	if not self.__last_send_time or
		app:getCurrentFrame() - self.__last_send_time >= modUtil.s2f(2) then
		return true
	else
		return false
	end
end

pVoice.regEvent = function(self)
	self.cb_voice:addListener("ec_mouse_click", function()
		self:clickCB(self.cb_voice, self.cb_face, self.voiceListWnd, self.faceListWnd)
		self:showVoicesList()
	end)
	self.cb_face:addListener("ec_mouse_click", function()
		self:clickCB(self.cb_face, self.cb_voice, self.faceListWnd, self.voiceListWnd)
		self:showFaceList()
	end)
	self.edit_input:addListener("ec_mouse_click", function()
		self.edit_input:setText("")
		self.edit_input:getTextControl():setColor(0xFF352114)
	end)
	self.btn_send:addListener("ec_mouse_click", function()
		if not self:canSend() then
			infoMessage(TEXT("您说话太快了，休息一下吧..."))
			return
		end
		self:recordLastSendTime()
		local txt = self.edit_input:getText()
		if txt and txt ~= "" then
			modChatMain.pChatMgr:instance():sendTextMsg(txt)
		end
		self.edit_input:setText("")
		--self.edit_input:fireEvent("ec_unfocus")
	end)
end

pVoice.showCB = function(self, cb, isShow)
	if not cb then return end
	cb:setCheck(isShow)
	if cb["child"] then
		cb["child"]:setCheck(isShow)
	end
end

pVoice.clickCB = function(self, cb, other, list, otherList)
	--if cb:isChecked() then
	--	cb:setSize(157, 58)
	--	other:setSize(157, 49)
	--end
	self:showCB(cb, true)
	self:showCB(other, false)
	if list then list:show(true) end
	if otherList then otherList:show(false) end
--[[	if list then list:destroy() end
	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}]]--
end

pVoice.showVoicesList = function(self)
	-- 摧毁listwnd
	if self.voiceListWnd then return end

	-- 滑动窗口
	self.voiceDragWnd = self:createListWnd(1)
	self.voiceListWnd = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)

	-- TODO
	local data = self:getVoiceData()
	data = modUIUtil.sortTableByKey(data)
	local y = 0
	local voiceBgHeight = 66
	local controlNum = modChannelMgr.getCurChannel():getControlNum()
	-- 描画文字
	for id, d in pairs(data) do
		local wnd = self:newVoice(id, d["_text_"], 0, y, id + controlNum)
		y = y + voiceBgHeight
	end
	-- 设置滑动窗口高度
	if y > self.voiceDragWnd:getHeight() then
		self.voiceDragWnd:setSize(self.voiceDragWnd:getWidth(), y)
	end
	self.voiceListWnd:addWnd(self.voiceDragWnd)
	self.voiceListWnd:setParent(self.wnd_list)
end

pVoice.showFaceList = function(self)
	-- 摧毁
	if self.faceListWnd then return end

	self.faceDragWnd = self:createListWnd(2)
	self.faceListWnd = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	-- TODO
	local data = self:getFacesData()
	local max = 3
	local scale = 0.5
	local width, height = 240 * scale, 240 * scale
	local distanceX, distanceY = 15, 10
	local x, y = distanceX, distanceY
	local index = 0
	for id, n in pairs(data) do
		index = index + 1
		local image = "ui:faces/" .. id .. ".png"
		local wnd = self:newWnd(id, x, y, image, nil, self.faceDragWnd)
		wnd:setSize(width, height)
		x = x + wnd:getWidth() + distanceX
		if index % max == 0 then
			x = distanceX
			y = y + wnd:getHeight() + distanceY
		end
		wnd:addListener("ec_mouse_click", function()
			self:sendMessage(id)
		end)
	end
	y = y + height + distanceY
	if y > self.faceDragWnd:getHeight() then
		self.faceDragWnd:setSize(self.faceDragWnd:getWidth(), y)
	end

	self.faceListWnd:addWnd(self.faceDragWnd)
	self.faceListWnd:setParent(self.wnd_list)
end

pVoice.newVoice = function(self, id, text, x, y, msgId)
	if not id or not msgId then return end
	local image = ""
	if tonumber(id) % 2 == 1 then
		image = "ui:voice_1.png"
	elseif tonumber(id) % 2 == 0 then
		image = "ui:voice_2.png"
	end
	local wnd = self:newWnd(id, x, y, image, text, self.voiceDragWnd)
	wnd:addListener("ec_mouse_click", function() self:sendMessage(msgId) end)
	return wnd
end

pVoice.sendMessage = function(self, id)
	if not self:canSend() then
		infoMessage(TEXT("您说话太快了，休息一下吧..."))
		return
	end
	if not id then return end
	local uids = {}
	local modBattleMgr = import("logic/battle/main.lua")
	local battle = modBattleMgr.getCurBattle()
	if not battle then
		local modCardbattleMgr = import("logic/card_battle/main.lua")
		battle = modCardbattleMgr.getCurBattle()
		if not battle then
			return
		end
	end
	local players = battle:getAllPlayers()
	for _, player in pairs(players) do
		table.insert(uids, player:getUid())
	end
	-- 发送请求
	modBattleRpc.sendMessage(id, uids, function(success, reason)
		if success then
			self:recordLastSendTime()
			self:close()
		else
			infoMessage(TEXT(reason))
		end
	end)
end

pVoice.getVoiceData = function(self)
	return modChannelMgr:getCurChannel():getVoiceData()
end

pVoice.getFacesData = function(self)
	return modFaceData.data
end

pVoice.newWnd = function(self, name, x, y, image, text, pWnd)
	local wnd = pWindow:new()
	wnd:setParent(pWnd)
	wnd:setSize(420, 66)
	wnd:setImage(image)
	--wnd:setClickDownImage("ui:voice_3.png")
	wnd:setColor(0xFFFFFFFF)
	wnd:setPosition(x, y)
	if text then
		wnd:setText(text)
		wnd:getTextControl():setAlignX(ALIGN_LEFT)
		wnd:getTextControl():setAutoBreakLine(false)
		wnd:getTextControl():setFontSize(30)
		wnd:getTextControl():setColor(0xFF352114)
	end
	table.insert(self.controls, wnd)
	return wnd
end

pVoice.close = function(self)
--[[	for _, wnd in pairs(self.controls) do
		wnd:setParent(nil)
	end
	self.controls = {}
	if self.voiceListWnd then
		self.voiceListWnd:destroy()
	end
	if self.faceListWnd then
		self.faceListWnd:destroy()
	end
	pVoice:cleanInstance()]]--
	self:show(false)
end

pVoice.cleanClose = function(self)
	pVoice:cleanInstance()
end

pVoice.createListWnd = function(self, name)
	local pWnd = pWindow:new()
	pWnd:setName("wnd_drag_" .. name)
	pWnd:setSize(self.wnd_list:getWidth(), 0)
	pWnd:setParent(self.wnd_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	table.insert(self.controls, pWnd)
	return pWnd
end

