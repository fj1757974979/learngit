local modUIUtil = import("ui/common/util.lua")
local modUtil = import("util/util.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUserData = import("logic/userdata.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modWndList = import("ui/common/list.lua")
local modEvent = import("common/event.lua")

pDaiKai = pDaiKai or class(pWindow,pSingleton)
local currentIndex = currentIndex or 1

pDaiKai.init = function(self)
	self:load("data/ui/daikai.lua")
	self:setParent(gWorld:getUIRoot())
	self.controls = {}
	self.lists = {}
	self.roomCount = nil
	self.listControls = {}
	self.currJiluIndex = 1
	self:regEvent()
	self:initUI()
	modUIUtil.adjustSize(self, gGameWidth, gGameHeight)
	modUIUtil.makeModelWindow(self, false, false)
	self:setZ(C_BATTLE_UI_Z)
end

pDaiKai.createListWnd = function(self, name)
	local pWnd = pWindow:new()
	pWnd:setName("wnd_drag" .. name)
	pWnd:setSize(1000,1000)
	pWnd:setParent(self.wnd_item_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	self[pWnd:getName()] = pWnd
--	table.insert(self.controls, pWnd)
	return self[pWnd:getName()]
end

pDaiKai.showBtns = function(self, isShow)
	self.btn_next:show(isShow)
	self.btn_back:show(isShow)
end

pDaiKai.initUI = function(self)
	self:showTextWnd(false)
	self.wnd_item_list:setSize(self.wnd_bg:getWidth() * 0.97, self.wnd_bg:getHeight() * 0.80)
	self.wnd_item_list:setOffsetY(self.wnd_bg:getHeight() * 0.02)
--	self.wnd_title:setPosition(0, self.wnd_bg:getHeight() * 0.018)
--	self.wnd_bottom_text:setOffsetY(- self.wnd_bg:getHeight() * 0.048)
	self.wnd_daikai:setText(sf("已代开：0 / 10"))
	self.wnd_bottom_text:setText("注：最多代开10个房间。24小时内未开始牌局，房间将自动解散。")
	self.wnd_text:setText("您还没有代开的房间，赶紧给朋友们开房玩游戏去吧。")
--	self.wnd_bottom_text:setOffsetX(- self.wnd_bg:getWidth() * 0.1)
--	self.wnd_daikai:setPosition(self.wnd_bg:getWidth() * 0.025, 0)
--	self.wnd_daikai:setOffsetY(- self.wnd_bg:getHeight() * 0.048)
	self.wnd_daikai:getTextControl():setAlignX(ALIGN_LEFT)
	modUIUtil.setClosePos(self.btn_return)
	-- 默认点击代开房间
	self:initCheckBtn()
end

pDaiKai.showTextWnd = function(self, isShow)
	self.wnd_text:show(isShow)
end

pDaiKai.initCheckBtn = function(self)
	self.cb_room:setCheck(true)
	self:cbEvent(self.cb_room)
end

pDaiKai.open = function(self, isCreate)
end

pDaiKai.clearList = function(self, idx)
	if not idx then return end
	if not self.lists[idx] then
		return
	end
	self.lists[idx]:setParent(nil)
	self.lists[idx] = nil
	currentIndex = idx
	self:refreshEvent()
	self:showhideWnds()
end

pDaiKai.addTitleEvent = function(self)
	self.cb_room["wnd"] = self.wnd_room_text
	self.cb_room["wnd_img"] = "ui:daikai_room_text.png"
	self.cb_room["wnd_dis_img"] = "ui:daikai_room_text_dis.png"
	self.cb_jilu["wnd"] = self.wnd_jilu_text
	self.cb_jilu["wnd_img"] = "ui:daikai_jilu_text.png"
	self.cb_jilu["wnd_dis_img"] = "ui:daikai_jilu_text_dis.png"
	self.cb_room:addListener("ec_mouse_click", function()
			self:cbEvent(self.cb_room)
	end)
	self.cb_jilu:addListener("ec_mouse_click", function()
			self:cbEvent(self.cb_jilu)
	end)
end

pDaiKai.cbEvent = function(self, c)
	if not c then return end
	-- 设置当前点击index
	self:setCurrentIndex(c)
	-- 点击互斥cb事件
	self:showhideCB(c)
	-- 点击事件
	self:refreshEvent()
	-- 刷新text
	self:updatePageText()
end

pDaiKai.setCurrentIndex = function(self, c)
	if not c then return end
	if c == self.cb_room then
		currentIndex = 1
	else
		currentIndex = 2
	end
end

pDaiKai.refreshEvent = function(self)
	-- 刷新事件
	if currentIndex == 1 then
		self:refresh()
		self:showBtns(false)
	else
		-- 清空字体
		self:showTextWnd(false)
		self:showInfoWnds(false)
		self:jiluRefreshEvent()
		self:showBtns(true)
	end
	-- 显示隐藏界面
	self:showhideWnds()
end

pDaiKai.printWnds = function(self)
	for key, value in pairs(self.lists) do
		print(key, value:isShow())
	end
end

pDaiKai.jiluRefreshEvent = function(self)
	-- 已经存在
	if self.lists[currentIndex + self.currJiluIndex] then
		self:updateShowJiluWnds()
		return
	end

	-- 获取代开记录
	modBattleRpc.getSharedRoomHistories(self.currJiluIndex - 1, nil, nil, function(success, reason, reply)
		if success then
			local jilus = reply.shared_room_histories
			if table.getn(jilus) <= 0 then
				if self.currJiluIndex > 1 then
					self:clearListControls()
					self:changeWnd(-1)
					self:showhideWnds()
					self:updatePageText()
					return
				else
					self:showTextWnd(true)
				end
			end
			self:newLits(jilus)
			self:updateShowJiluWnds()
		else
			infoMessage(TEXT(reason))
		end
		self:updatePageText()
	end)

end

pDaiKai.newLits = function(self, jilus)
	if not jilus then return end
	if table.getn(jilus) <= 0 then
		return
	end
	local modJiluWnd = import("ui/menu/daikaijilu.lua")
	-- 创建滑动窗口
	local wnd_drag = self:createListWnd(currentIndex .. "_" .. self.currJiluIndex)
	wnd_drag:setSize(self.wnd_item_list:getWidth(), self.wnd_item_list:getHeight())
	local windowList = modWndList.pWndList:new(self.wnd_item_list:getWidth(), self.wnd_item_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	-- 描画记录
	local bgWidth, bgHeight = 591, 325
	local maxX = 2
	local distanceX = (self.wnd_item_list:getWidth() - bgWidth * maxX) / (maxX + 1)
	local distanceY = gGameHeight * 0.04
	local x, y = distanceX, 0
	local dragHeight = bgHeight

	-- 描画
	for idx, srh in ipairs(jilus) do
		local gameType = srh.game_type
		local detail = nil
		if gameType == modLobbyProto.MAHJONG then
			detail = modLobbyProto.GetSharedRoomHistoriesReply.MahjongSharedRoomDetail()
		else
			detail = modLobbyProto.GetSharedRoomHistoriesReply.PokerSharedRoomDetail()
		end
		detail:ParseFromString(srh.detail_data)
		local wnd = modJiluWnd.pJiluWnd:new(srh, detail, x, y, wnd_drag, self)
		x = x + bgWidth + distanceX
		if idx % maxX == 0 then
			x = distanceX
			y = y + bgHeight + distanceY
		end
		if not self.listControls[currentIndex + self.currJiluIndex] then
			self.listControls[currentIndex + self.currJiluIndex] = {}
		end
		table.insert(self.listControls[currentIndex + self.currJiluIndex], wnd)
	end
	-- 设置滑动窗口高度
	if y > dragHeight then
		dragHeight = y + bgHeight +  50
	end

	-- 滑动窗口加入list
	wnd_drag:setSize(wnd_drag:getWidth(), dragHeight)
	windowList:addWnd(wnd_drag)
	windowList:setParent(self.wnd_item_list)
	self.lists[currentIndex + self.currJiluIndex] = windowList
	self:updateShowJiluWnds()
end

pDaiKai.showhideWnds = function(self)
	local isShowRoom = currentIndex == 1
	if table.size(self.lists) < 1 then return end

	for key, value in pairs(self.lists) do
		if key == 1 then
			self.lists[key]:show(isShowRoom)
		else
			self.lists[key]:show(false)
		end
	end
	if not (currentIndex == 2) then return end
	if self.lists[currentIndex + self.currJiluIndex] then
		self.lists[currentIndex + self.currJiluIndex]:show(true)
	end
end

pDaiKai.delRoom = function(self)
	self:clearList(currentIndex + self.currJiluIndex)
end

pDaiKai.showhideCB = function(self, c)
	if not c then return end
	local cbtns = { self.cb_room, self.cb_jilu }
	for _, cb in pairs(cbtns) do
		if c == cb then
			cb["wnd"]:setImage(cb["wnd_img"])
			cb:setColor(0xFFFFFFFF)
		else
			cb["wnd"]:setImage(cb["wnd_dis_img"])
			cb:setColor(0)
		end
	end
end

pDaiKai.showInfoWnds = function(self, isShow)
--	self:showTextWnd(isShow)
	self.wnd_daikai:show(isShow)
	self.wnd_bottom_text:show(isShow)
	self.wnd_page:show(not isShow)
end

pDaiKai.refresh = function(self)
	self:showInfoWnds(true)
	if self.roomCount and self.roomCount == 0 then
		self:showTextWnd(true)
	else
		self:showTextWnd(false)
	end
	-- 是否存在
	if self.lists[1] then
		return
	end
	-- 展示信息
	self:showInfoWnds(true)
	self:clearControls()
	-- 创建滑动窗口
	local dragWidth = 0
	local wnd_drag = self:createListWnd(1)
	wnd_drag:setSize(self.wnd_item_list:getWidth(), self.wnd_item_list:getHeight())
	local windowList = modWndList.pWndList:new(self.wnd_item_list:getWidth(), self.wnd_item_list:getHeight(), 1, 0, 0, T_DRAG_LIST_HORIZONTAL)
	self.lists[1] = windowList
	-- 请求房间信息
	modBattleRpc.getOwnedRoom(nil, function(success,reply)
		if success then
			local roomInfos = reply.owned_room_infos
			local x = 10
			local y = 20
			local count = 0

			-- 排序满员往后排
			local fullIndexs = {}
			for idx, roomInfo in ipairs(roomInfos) do
				local creationInfo = roomInfo.creation_info
				if creationInfo.max_number_of_users == table.getn(roomInfo.user_infos) then
					fullIndexs[idx] = roomInfo
				end
			end
			for idx, roomInfo in pairs(fullIndexs) do
				table.remove(roomInfos, idx)
			end
			for _, roomInfo in pairs(fullIndexs) do
				table.insert(roomInfos, roomInfo)
			end

			-- 描画代开信息
			for i = 1, table.getn(roomInfos) do
				-- 有代开信息
				local roomInfo = roomInfos[i]
				local nameIndex = i
				if roomInfo  and roomInfo.creation_info.room_type  == modLobbyProto.CreateRoomRequest.SHARED then
					count = count + 1
					local address = roomInfo.address
					local creationInfo = roomInfo.creation_info
					local curRound = roomInfo.game_time_count
					local userInfo = roomInfo.UserInfoOfRoom
					local playerCount = creationInfo.max_number_of_users
					local bgWidth, bgHeight = 329, 560
					local users = roomInfo.user_infos
					local names = {}
					local isFull = false
					if playerCount == table.getn(users) then
						isFull = true
					end
					-- 描画item
					local image = "ui:bottom2.png"
					if isFull then
						image = "ui:daikai_full_bg.png"
					end
					local itemWnd = self:createWnd(wnd_drag, "item_" .. i, x, y, image, bgWidth, bgHeight)
					itemWnd:setXSplit(true)
					itemWnd:setYSplit(true)
					itemWnd:setSplitSize(15)

					-- 上部框
					local topImage = "ui:daikai_que_room_id_bg.png"
					if isFull then
						topImage = "ui:daikai_full_room_id_bg.png"
					end
					local topBg = self:createWnd(wnd_drag, "top_" .. i, 0, 10, nill, 369, 62)
					topBg:setParent(itemWnd)
					topBg:setAlignX(ALIGN_CENTER)

					-- 是否满人
					local fullImage = "ui:daikai_que.png"
					if isFull then
						fullImage = "ui:daikai_full.png"
					end
					local fullWnd = self:createWnd(wnd_drag, "full_" .. i, 0, 0, fullImage, 81, 75)
					fullWnd:setParent(topBg)
					fullWnd:setAlignY(ALIGN_BOTTOM)
					fullWnd:setAlignX(ALIGN_LEFT)
					fullWnd:setPosition(fullWnd:getWidth() / 3, 0)

					-- 描画房号
					local roomId = sf("%06d", address.id)
					local roomIdWnd = self:createWnd(wnd_drag, "roomId_" .. i, 0, 0, nil, 100, topBg:getHeight(), roomId)
					roomIdWnd:setParent(topBg)
					roomIdWnd:setAlignY(ALIGN_CENTER)
					roomIdWnd:setAlignX(ALIGN_CENTER)
					roomIdWnd:setOffsetX(topBg:getWidth() * 0.05)
					roomIdWnd:setOffsetY(- topBg:getHeight() * 0.05)
					roomIdWnd:getTextControl():setColor(0xFFFFFFFF)
					roomIdWnd:getTextControl():setFontSize(40)
					roomIdWnd:getTextControl():setAlignX(ALIGN_CENTER)
					roomIdWnd:getTextControl():setAlignY(ALIGN_CENTER)
					if isFull then
						roomIdWnd:setFont("end_win_number", 40, 1)
					else
						roomIdWnd:setFont("end_lose_number", 40, 1)
					end
					roomIdWnd:setScale(1.5,1.5)
					roomIdWnd:setText(sf("%06d",roomId))

					-- 中部框
					local image = "ui:bottom_list.png"
					if isFull then
						image = "ui:bottom_list.png"
					end
					local centerBg = self:createWnd(wnd_drag, "center_" .. i, 0, topBg:getY() + topBg:getHeight() , image, 297, 325)

					centerBg:setParent(itemWnd)
					centerBg:setAlignX(ALIGN_CENTER)
					centerBg:setXSplit(true)
					centerBg:setYSplit(true)
					centerBg:setSplitSize(15)

					-- 描画玩法
					local allRound = creationInfo.number_of_game_times
					local typeName = modUIUtil.getRuleStringByType(creationInfo.rule_type) .. "  " .. playerCount .. "人" .. "\n"
					local nameWnd = self:createWnd(wnd_drag, "name_" .. i, 0, 0, nil, 0, 0, typeName)
					nameWnd:setParent(centerBg)
					nameWnd:setAlignX(ALIGN_CENTER)
					nameWnd:getTextControl():setFontSize(30)
					nameWnd:getTextControl():setAlignY(ALIGN_TOP)
					nameWnd:getTextControl():setColor(0xFFFFFFFF)
					nameWnd:getTextControl():setShadowColor(0xFF000000)

					-- 描画play
					local str = self:getPlayInfo(creationInfo)
					local playWnd = self:createWnd(wnd_drag, "play_" .. i, 0, 0, nil, itemWnd:getWidth() * 0.90, itemWnd:getHeight() * 0.5, str)
					playWnd:setParent(centerBg)
					playWnd:setAlignX(ALIGN_LEFT)
					playWnd:setPosition(15, nameWnd:getY() + nameWnd:getTextControl():getHeight())
					playWnd:getTextControl():setFontSize(30)
					playWnd:getTextControl():setAlignX(ALIGN_LEFT)
					playWnd:getTextControl():setAlignY(ALIGN_TOP)
					playWnd:getTextControl():setColor(0xFFFFFFFF)
					playWnd:getTextControl():setShadowColor(0xFF000000)
					playWnd:getTextControl():setAutoBreakLine(true)
					if isFull then
						playWnd:getTextControl():setColor(0xFFFFFFFF)
					end

					-- 描画玩家
					local imageWidth, imageHeight = 64, 64
					local distance = (itemWnd:getWidth() - 4 * imageWidth - 10) / 5
					local imageX = distance
					for idx = 1, playerCount do
						local playerId = nil
						local uid = nil
						if users[idx] then
							playerId = users[idx].player_id
							uid = users[idx].user_id
						end
						local nameId = i
						if playerId then
							nameId = playerId
						end
						local imageBg = self:createWnd(wnd_drag, "image_bg" .. i .. idx, imageX, centerBg:getY() + centerBg:getHeight() + 10, "ui:end_calculate_icon_bg.png", imageWidth * 1.1, imageHeight * 1.1)
						imageBg:setParent(itemWnd)

						local imageWnd = self:createWnd(wnd_drag, "image_" .. i .. idx, 0, 0, nil, imageWidth, imageHeight)
						imageWnd:setParent(imageBg)
						imageWnd:setAlignX(ALIGN_CENTER)
						imageWnd:setAlignY(ALIGN_CENTER)

						local imageFront = self:createWnd(wnd_drag, "image_font_" .. i .. idx, 0, 0, "ui:bg_top_mini.png", imageWnd:getWidth() * 1.1, imageWnd:getHeight() * 1.1)
						imageFront:setParent(imageWnd)
						imageFront:setAlignX(ALIGN_CENTER)
						imageFront:setAlignY(ALIGN_CENTER)
						imageX = imageX + imageWidth + distance
						imageFront:addListener("ec_mouse_click", function()
							if uid then
								local modPlayerInfo = import("logic/menu/player_info_mgr.lua")
								modPlayerInfo.newMgr(uid, T_MAHJONG_ROOM)
							end
						end)
					end

					for k, v in ipairs(users) do
						local userInfo = v
						if userInfo then
							local uid = userInfo.user_id
							local playerId = userInfo.player_id
							modBattleRpc.updateUserProps(uid,function(success,reply)
								if success then
									local image = reply.avatar_url
									local nickName = reply.nickname
									if not image or image == "" then
										image = modUIUtil.getDefaultImage()
									end
									self["wnd_daikai_image_" .. i .. k]:setImage(image)
									self["wnd_daikai_image_" .. i .. k]:setColor(0xFFFFFFFF)
									table.insert(names, nickName)
								end
							end)
						end
					end
					-- btn
					local tWnd =  self[sf("wnd_daikai_image_bg%d1", nameIndex)]
					local btnWidth, btnHeight = 145, 60
					local distanceY = tWnd:getY() + tWnd:getHeight() + (itemWnd:getHeight() - tWnd:getHeight() - tWnd:getY() - btnHeight) / 2 - 2
					local distanceX =  (itemWnd:getWidth() - 2 * btnWidth) / 3
					local btnX = distanceX
					-- 描画解散
					local btnDis = self:createButton("dismiss_" .. i, btnX, distanceY, "ui:btn6.png", btnWidth, btnHeight)
					btnDis:setParent(itemWnd)
					if isFull then
						btnDis:setAlignX(ALIGN_CENTER)
						btnDis:setOffsetX(0)
					end
					self:onClick(btnDis:getName(),function() self:disMissRoom(roomId) end)
					local disWnd = self:createWnd(wnd_drag, "yq_text_" .. i, 0, 0, "ui:daikai_dismiss_text.png", 80, 29)
					disWnd:setParent(btnDis)
					disWnd:setAlignX(ALIGN_CENTER)
					disWnd:setAlignY(ALIGN_CENTER)
					disWnd:setOffsetX(-1)
					disWnd:setOffsetY(-2)
					disWnd:enableEvent(false)

					btnX = btnX + btnWidth + distanceX

					-- 描画邀请
					if not isFull then
						local btnYQ = self:createButton("yq_" .. i, btnX, distanceY, "ui:btn5.png", btnWidth, btnHeight)
						btnYQ:setParent(itemWnd)
						btnYQ:addListener("ec_mouse_click", function()
							local titleStr = modUIUtil.getRuleStringByType(creationInfo.rule_type)
							local downLoadLink = modUIUtil.getDownloadLink(creationInfo.rule_type)
							local totRound = creationInfo.number_of_game_times
							-- wait for you
							local welcomeStr = "("
							local nowCount = table.getn(names)
							for index, name in pairs(names) do
									welcomeStr = welcomeStr .. name
								if names[index + 1] then
									welcomeStr = welcomeStr .. "、"
								end
							end
							welcomeStr = welcomeStr .. "等你来)"

							local waitCount = playerCount - nowCount
							local waitStr = self:numberToChinese(nowCount) .. "缺" .. self:numberToChinese(waitCount)
							-- 标题
							titleStr = titleStr .. "【" .. roomId .. "】" .. waitStr
							-- 内容
							local roundStr = "局 "
							if creationInfo.rule_type == modLobbyProto.CreateRoomRequest.TIANJIN then
								roundStr = "圈"
							end
							local roomType = totRound .. roundStr .. modUIUtil.getRoomTypeStr(creationInfo.room_type) .. "," .. modUIUtil.getRuleStr(creationInfo) .. welcomeStr
							log("info", titleStr, roomType, downLoadLink)
							puppy.sys.shareWeChat(2, TEXT(titleStr), TEXT(roomType), downLoadLink)
						end)
						-- 邀请字
						local yqWnd = self:createWnd(wnd_drag, "yq_text_" .. i, 0, 0, "ui:daikai_yaoqing_text.png", 80, 29)
						yqWnd:setParent(btnYQ)
						yqWnd:setAlignX(ALIGN_CENTER)
						yqWnd:setAlignY(ALIGN_CENTER)
						yqWnd:setOffsetX(-1)
						yqWnd:setOffsetY(-2)
						yqWnd:enableEvent(false)

					end
					x = itemWnd:getX() + itemWnd:getWidth() + 5
					dragWidth = x + 5
				end

			end
			wnd_drag:setSize(dragWidth, wnd_drag:getHeight())
			windowList:addWnd(wnd_drag)
			windowList:setParent(self.wnd_item_list)
			-- 已代开
			self.wnd_daikai:setText(sf("已代开：%d / 10", count))
			-- 是否有记录
			if count < 1 then
				self:showTextWnd(true)
			else
				self:showTextWnd(false)
			end
			self.roomCount = count
		end
	end)
end

pDaiKai.createWnd = function(self, pWnd, wndName, x, y, image_path, width, heigh, text, cardId, scale)
	local wnd = pWindow():new()
	wnd:setName("wnd_daikai_" .. wndName)
	wnd:setParent(pWnd)
	wnd:setPosition(x,y)
	wnd:setAlignX(ALIGN_LEFT)
	wnd:setAlignY(ALIGN_TOP)
	if text then
		wnd:setText(text)
	end
	wnd:getTextControl():setFontSize(45)
	wnd:getTextControl():setColor(0xFFD2691E)
	wnd:getTextControl():setAlignX(ALIGN_CENTER)
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
pDaiKai.regEvent = function(self)

	self.btn_return:addListener("ec_mouse_click",function() self:close()  end)
	self.__refresh = modEvent.handleEvent(EV_REFRESH_DAIKAI,function()
		self:refresh()
	end)
	-- 添加title事件
	self:addTitleEvent()
	-- next back
	self.btn_next:addListener("ec_mouse_click", function()
		self:changeWnd(1)
		self:jiluRefreshEvent()
	end)
	self.btn_back:addListener("ec_mouse_click", function()
		self:changeWnd(-1)
		if self.lists[currentIndex + self.currJiluIndex] then
			self:updateShowJiluWnds()
		end
		self:updatePageText()
	end)
end

pDaiKai.updatePageText = function(self)
	local page = table.size(self.lists) - 1
	if page <= 0 then
		page = 1
	end
	self.wnd_page:setText(sf("第%d页", self.currJiluIndex))
end

pDaiKai.close = function(self)
	for _, wnd in pairs(self.lists) do
		wnd:setParent(nil)
	end
	self.lists = {}
	self:clearControls()
	self:destroyDismissMgr()
	pDaiKai:cleanInstance()
end

pDaiKai.clearControls = function(self)
	if self.wnd_drag then
		self.wnd_drag = nil
	end
	if self.controls then
		for k,v in pairs(self.controls) do
			v:setParent(nil)
		end
	end
end

pDaiKai.clearListControls = function(self)
	if self.listControls[currentIndex + self.currJiluIndex] then
		for _, wnd in pairs(self.listControls[currentIndex + self.currJiluIndex]) do
			wnd:setParent(nil)
		end
		self.listControls[currentIndex + self.currJiluIndex] = nil
	end
end

pDaiKai.getPlayInfo = function(self, creationInfo)
	local str = ""
	str = modUIUtil.getRuleStr(creationInfo, "\n")
	return str
end

pDaiKai.getInt = function(self,x)
    if x <= 0 then
        return math.ceil(x)
    end

    if math.ceil(x) == x then
        x = math.ceil(x)
    else
        x = math.ceil(x) - 1;
    end
    return x
end


pDaiKai.createButton = function(self, name, x, y, image, width, height, scale)

	local scale = scale
	local btnYQ = pButton():new()
	btnYQ:setName("btn_" .. name)
	btnYQ:setParent(self.wnd_bg)
	btnYQ:setAlignX(ALIGN_LEFT)
	btnYQ:setAlignY(ALIGN_TOP)
	btnYQ:setPosition(x,y)
	btnYQ:setImage(image)
	if not scale then
		scale = 1
	end
	btnYQ:setSize(width * scale,height * scale)
	btnYQ:setColor(0xFFFFFFFF)
	self[btnYQ:getName()] = btnYQ
	table.insert(self.controls,btnYQ)
	return btnYQ
end

pDaiKai.disMissRoom = function(self,roomId)
	local modAskWnd = import("ui/common/askwindow.lua")
	self.askWnd = modAskWnd.pAskWnd:new(self, "您确定要解散该房间吗？", function(yesOrNo)
		if not yesOrNo then
			self:clearAskWnd()
			return
		end
		local modDismissMgr = import("logic/dismiss/main.lua")
		modDismissMgr.pDismissMgr:instance(T_MAHJONG_ROOM):disOwnerRoom(tonumber(roomId), function()
			modEvent.fireEvent(EV_REFRESH_DAIKAI)
			self:clearList(1)
			self:destroyDismissMgr()
		end)
		self:clearAskWnd()
	end)
	self.askWnd:setParent(self)
end

pDaiKai.clearAskWnd = function(self)
	if self.askWnd then
		self.askWnd:setParent(nil)
	end
	self.askWnd = nil
end

pDaiKai.destroyDismissMgr = function(self)
	local modDismissMgr = import("logic/dismiss/main.lua")
	if modDismissMgr.pDismissMgr:getInstance() then
		modDismissMgr.pDismissMgr:instance():destroy()
	end
end

pDaiKai.onClick = function(self,name,event)
	self[name]:addListener("ec_mouse_click",function() event()  end)
end

pDaiKai.changeWnd = function(self, num)
	if not num then return end
	self:changeJiluIndex(num)
end

pDaiKai.changeJiluIndex = function(self, num)
	if not num then return end
	self.currJiluIndex = self.currJiluIndex + num
	if self.currJiluIndex <= 1 then
		self.currJiluIndex = 1
	end
end

pDaiKai.updateShowJiluWnds = function(self)
	for key, value in pairs(self.lists) do
		if key == currentIndex + self.currJiluIndex then
			value:show(true)
		else
			value:show(false)
		end
	end
end

pDaiKai.numberToChinese = function(self, s)
	local str = ""
	if s == 1 then
		str = "一"
	elseif s == 2 then
		str = "二"
	elseif s == 3 then
		str = "三"
	elseif s == 4 then
		str = "四"
	elseif s == 0 then
		str = "零"
	end
	if str ~= "" then
		return str
	end
end
