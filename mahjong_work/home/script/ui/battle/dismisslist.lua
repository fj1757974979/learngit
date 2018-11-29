local modUIUtil = import("ui/common/util.lua")
local modDismissMgr = import("logic/dismiss/main.lua")
local modUtil = import("util/util.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modEvent = import("common/event.lua")
local modUserData = import("logic/userdata.lua")
local modFunctionManager = import("ui/common/uifunctionmanager.lua")

pDisMissList = pDisMissList or class(pWindow, pSingleton)

pDisMissList.init = function(self)
	self:load("data/ui/dissroomlist.lua")
	self.wnd_tishi:setText("(温馨提示：倒计时结束默认同意)")
	self.wnd_tishi:getTextControl():setFontSize(22)
	self.wnd_tishi:setPosition(self.wnd_time_out:getWidth() - 10,0)
	self.isReLoad = false
	self.isClearTimeOut = false
	self.wnd_tishi:show(false)
	self.controls = {}
	self:regEvent()
	modUIUtil.makeModelWindow(self,false,false)
end

pDisMissList.open = function(self, uid, gameType)
	self.dismissMgr = modDismissMgr.pDismissMgr:instance(gameType)
	self:setParent(self.dismissMgr:getDismissParent())
	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_BATTLE_UI_Z)
	local modCommonCue = import("ui/common/common_cue.lua")
	if modCommonCue.pCommonCue:getInstance() then
		modCommonCue.pCommonCue:instance():close()
	end

	local players = self.dismissMgr:getPlayers()
	self.uid = uid

	if self.uid and self.uid == modUserData.getUID() then
		self:isShowOkAndNo(false)
	else
		self:isShowOkAndNo(true)
	end

	-- 设置时间并倒数计时
	if self.isReLoad == false then
		local time = self.dismissMgr:getDisTime()
		self.wnd_time_out:setText(time)
		local fream = modUtil.s2f(1)
		modUIUtil.timeOutDo(time * fream,function(t)
			if t > -1 then
				self.wnd_time_out:setText(t)
			else
				self.wnd_time_out:setText(0)
			end
		end,nil)
	end


	-- 描画名字和线
	local x = 100
	local y = 20
	local scale = 0.75

	local realPlayers = {}
	for idx, player in pairs(players) do
		if not player.isFake or not player:isFake() then
			realPlayers[idx] = player
		end
	end
	for idx, player in pairs(realPlayers) do
		-- 下划线
		local lineWnd = self:createWnd("line_" .. player:getPlayerId(), 0, y, "ui:bottom_info.png",767,83)
		lineWnd:setAlignX(ALIGN_CENTER)
		lineWnd:setXSplit(true)
		lineWnd:setYSplit(true)
		lineWnd:setSplitSize(15)


		-- 描画头像
		local imageBg = self:createWnd("image_" .. idx, lineWnd:getWidth() * 0.05, 0, player:getAvatarUrl(), 64, 64)
		imageBg:setParent(lineWnd)
		imageBg:setAlignY(ALIGN_CENTER)
--		imageBg:addListener("ec_mouse_click", function()
--			local uid = player:getUid()
--			local modPlayerInfo = import("logic/menu/player_info_mgr.lua")
--			modPlayerInfo.newMgr(uid, T_MAHJONG_ROOM)
--		end)


		-- 描画头像框
		local imageFront = self:createWnd("image_front" .. idx, 0, 0, "ui:bg_top_mini.png", imageBg:getWidth() * 1.1, imageBg:getHeight() * 1.1)
		imageFront:setParent(imageBg)
		imageFront:setAlignY(ALIGN_CENTER)
		imageFront:setAlignX(ALIGN_CENTER)


		-- 名字
		local name = player:getName()
		if name == nil then
			name = "???"
		end
		local wnd = self:createWnd("name_" .. player:getPlayerId(), lineWnd:getWidth() * 0.17, 0, nil, 100, 50, name)
		wnd:setParent(lineWnd)
		wnd:setAlignY(ALIGN_CENTER)
		wnd:getTextControl():setAlignX(ALIGN_LEFT)
		wnd:getTextControl():setFontSize(36)
		wnd:getTextControl():setColor(0xFF352114)
		if player:getUid() == modUserData.getUID() then
			wnd:setColor(0)
		end

		-- 是否同意
		local resultWnd = self:createWnd("result_" .. player:getPlayerId(),0, 0,"",134,50)
		resultWnd:setParent(lineWnd)
		resultWnd:setAlignX(ALIGN_RIGHT)
		resultWnd:setAlignY(ALIGN_CENTER)
		resultWnd:setOffsetX(-30)
		resultWnd:setColor(0)

		if self.uid == player:getUid() then
			local image = "ui:dismiss_sure.png"
			local name = "wnd_dismisslist_result_" .. player:getPlayerId()
			self[name]:setImage(image)
			self[name]:setColor(0xFFFFFFFF)
		end

		y = lineWnd:getY() + lineWnd:getHeight() + 10
	end

end


pDisMissList.close = function(self)
	if self.controls then
		for _,c in pairs(self.controls) do
			c:setParent(nil)
		end
	end

	if self.__update_dissroom_result then
		modEvent.removeListener(self.__update_dissroom_result)
		self.__update_dissroom_result = nil
	end

	if self.__update_dissroom_nickname then
		modEvent.removeListener(self.__update_dissroom_nickname)
		self.__update_dissroom_nickname = nil
	end

	if self.dismissMgr then
		self.dismissMgr:destroy()
		self.dismissMgr = nil
	end
	if self.timeEvent then
		self.timeEvent:stop()
		self.timeEvent = nil
	end
	self.controls = nil
	self.isClearTimeOut = true
	pDisMissList:cleanInstance()
end

pDisMissList.createWnd = function(self,wndName,x,y,image_path,width,heigh,text,cardId,scale)
	local wnd = pWindow():new()
	wnd:setName("wnd_dismisslist_" .. wndName)
	wnd:setParent(self.wnd_list)
	wnd:setPosition(x,y)
	wnd:setAlignX(ALIGN_LEFT)
	wnd:setAlignY(ALIGN_TOP)
--	wnd:setRenderLayer(C_BATTLE_UI_RL)
--	wnd:setZ(C_BATTLE_UI_Z )
	if text then
		wnd:setText(text)
		wnd:getTextControl():setFontBold(1)
		wnd:getTextControl():setColor(0xFFFFFFFF)
	end
	wnd:getTextControl():setFontSize(45)
	wnd:getTextControl():setAlignX(ALIGN_RIGHT)
	wnd:getTextControl():setAlignY(ALIGN_CENTER)
	wnd:getTextControl():setAutoBreakLine(false)
	if image_path then
		wnd:setColor(0xFFFFFFFF)
		wnd:setImage(image_path)
	else
		wnd:setColor(0)
	end
	wnd:setSize(width,heigh)
	wnd:setZ(-1)
	self[wnd:getName()] = wnd
	table.insert(self.controls,self[wnd:getName()])
	return self[wnd:getName()]
end

pDisMissList.answerCloseRoom = function(self, yesOrCancel)
	local yesOrCancel = yesOrCancel
	if yesOrCancel ~= nil then
		self:isShowOkAndNo(false)
		self.dismissMgr:answerCloseRoom(yesOrCancel, function(success)
			if success then
				if self.dismissMgr then
					local players = self.dismissMgr:getPlayers()
					local pid = nil
					for _, player in pairs(players) do
						if player:getUid() == modUserData.getUID() then
							pid = player:getPlayerId()
							break
						end
					end
					local image = "ui:dismiss_cancel.png"
					if yesOrCancel then
						image = "ui:dismiss_sure.png"
					end
					local name = "wnd_dismisslist_result_" .. pid
					self[name]:setImage(image)
					self[name]:setColor(0xFFFFFFFF)
				end
			end
		end)
	end
end

pDisMissList.regEvent = function(self)
	self.__update_dissroom_result = modEvent.handleEvent(EV_UPDATE_DISSROOM_RESULT,function(message)
		local uid = message.user_id
		local yesOrNo = message.yes_or_no
		local players = self.dismissMgr:getPlayers()
		local player = nil

		for _,p in pairs(players) do
			if p:getUid() == uid then
				player = p
				break
			end
		end
		local image = "ui:dismiss_cancel.png"
		if yesOrNo then
			image = "ui:dismiss_sure.png"
		end
		name = "wnd_dismisslist_result_" .. player:getPlayerId()
		self[name]:setImage(image)
		self[name]:setColor(0xFFFFFFFF)
	end)


	self.__update_dissroom_nickname = modEvent.handleEvent(EV_UPDATE_DISSROOM_NAME,function(playerId, nickname, avatarUrl)
		local wndName = "wnd_dismisslist_name_" .. playerId
		if self[wndName] then
			self[wndName]:setText(nickname)
		end
		local imageWnd = "wnd_dismisslist_image_" .. playerId
		if self[imageWnd] then
			self[imageWnd]:setImage(avatarUrl)
			self[imageWnd]:setColor(0xFFFFFFFF)
			self[imageWnd]:show(true)
		end
	end)

	self.btn_ok:addListener("ec_mouse_click",function()
			self:answerCloseRoom(true)
	end)
	self.btn_cancel:addListener("ec_mouse_click",function()
			self:answerCloseRoom(false)
		end)
	end

pDisMissList.setTimeOut = function (self, time)
	if self.timeEvent then
		self.timeEvent:stop()
		self.timeEvent = nil
	end
	self.wnd_time_out:setText(time)
	local fream = modUtil.s2f(1)
	self.timeEvent = modUIUtil.timeOutDo(time * fream,function(t)
		if t < 0 then
			t = 0
		end
		self.wnd_time_out:setText(t)
	end,nil)
end

pDisMissList.timeOut = function(self, endTime, doSomething, afterDo)
	local time = endTime or 120
	runProcess(1,function()
		for i = 1,time do
			if doSomething and not self.isClearTimeOut then
				if (i % 30) == 0 then
					doSomething((endTime / 30) - (i / 30))
				end
			elseif self.isClearTimeOut then
				break
			end
			yield()
		end
		if afterDo then
			afterDo()
		end
	end)
end

pDisMissList.setReLoad = function(self, reload)
	self.isReLoad = reload
end

pDisMissList.isShowOkAndNo = function(self, isShow)
	self.btn_ok:show(isShow)
	self.btn_cancel:show(isShow)
end

