local modCreateParent = import("ui/create_main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modChannel = import("logic/channels/main.lua")

pMainCreate = pMainCreate or class(modCreateParent.pCreate, pSingleton)

pMainCreate.init = function(self)
	modCreateParent.pCreate.init(self)
end

pMainCreate.loadUI = function(self)
	self:load("data/ui/club_create_room.lua")
end

pMainCreate.getSaveFilePath = function(self)
	return "tmp:club_createroominfo_2.dat"
end

pMainCreate.open = function(self, clubInfo, callback)
	self:show(true)
	self.clubInfo = clubInfo
	self.callback = callback
	-- 读取描画麻将信息
	self:majiangDrag()
	-- app
	self:app()
end

pMainCreate.newShowWnd = function(self, index)
	-- 创建滑动窗口
	self:newListWnd()
	-- 创建对应麻将类型的bg窗体
	local bgWnd = self:newBgWnd(index)
	-- 创建俱乐部底倍
	local wnd = self:newClubDibei(bgWnd, index)
	-- 创建选项
	self:newSelect(index, bgWnd, wnd:getHeight())
--	self:newSelect(index, bgWnd, 200)
	-- 添加按钮隐藏关系
	self:addParentCB()
	-- 添加click事件
	self:addClick()
	-- 默认值
	self:setDefaultValue()
	-- 添加番型按钮事件
	self.btn_fanxing:addListener("ec_mouse_click", function() self:showFanxing() end)
end

pMainCreate.newClubDibei = function(self, bgWnd, index)
	if not bgWnd then return end
	local modCreateBeilv = import("ui/club/create_ground_beilv.lua")
	local wnd = modCreateBeilv.pCreateBeilv:new(self, index)
	wnd:setParent(bgWnd)
	self["beilv_" .. self.currDataIndex] = wnd
	return wnd
end

pMainCreate.shouldDrawMenu = function(self, menuName)
	local menuData = self:findMenuData(menuName)
	return menuData["clubHide"] ~= 1
end

pMainCreate.selectDefaultMenuStrs = function(self, selectData)
	if selectData["clubDefaultMenu"] and selectData["clubDefaultMenu"] ~= "" then
		return selectData["clubDefaultMenu"]
	else
		return modCreateParent.pCreate.selectDefaultMenuStrs(self, selectData)
	end
end

pMainCreate.needSkipRoundDraw = function(self)
	return self.currDataIndex ~= "paijiu_mpqz" and self.currDataIndex ~= "niuniu" and self.currDataIndex ~= "yy_niuniu"
end

pMainCreate.isSkipDraw = function(self, drawStr)
	if not drawStr then return end
	for _, str in pairs(drawStr) do
		if string.find(str, "round") and self:needSkipRoundDraw() then
			return true
		end
	end
	return false
end


pMainCreate.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click",function() self:close() end)
	self.btn_create:addListener("ec_mouse_click", function()
		self:createRoom(modLobbyProto.CreateRoomRequest.CLUB_SHARED)
	end)
end

pMainCreate.setCardsValue = function(self)
		self.result[self.currDataIndex]["cards"] = {
			0, 1, 3, 5, 6, 7, 9, 9, 15 , 15, 23 , 19, 19, 23,
			0, 1, 3, 5, 6, 7, 9, 9, 15 , 15, 23 , 19, 19, 23,
		}
		self.result[self.currDataIndex]["cards"] = {
			0, 0, 3, 3, 6, 6, 9, 9, 15 , 15, 23 , 24, 24, 23,
			0, 1, 3, 5, 6, 7, 9, 9, 15 , 15, 23 , 19, 19, 23,
		}
end

pMainCreate.speicalProps = function(self, roomType)
	-- 俱乐部托管时间
	self.result[self.currDataIndex]["auto_time"] = 30
	-- 俱乐部创建局数设置为1
	if self:needSkipRoundDraw() then
		self:setValue("round", 1)
	end
	-- 俱乐部房间类型
	self:setValue("room", modLobbyProto.CreatePokerRoomRequest.CLUB_SHARED)
end

pMainCreate.canCreateType = function(self, t)
	return not modChannel.getCurChannel():clubForbidGameType(t)
end

pMainCreate.isCanCreate = function(self)
	local userCreate = self.result[self.currDataIndex]
	if self.currDataIndex ~= "paijiu_kzwf" and
		self.currDataIndex ~= "paijiu_mpqz" and
		self.currDataIndex ~= "niuniu" and
		self.currDataIndex ~= "yy_niuniu" then
		--if not userCreate["cost"] or userCreate["cost"] > userCreate["dibei"] then
		--	infoMessage("金豆消耗不能大于底注！")
		--	return false
		--end
	end
	return true
end

pMainCreate.protoCreateRoom = function(self, createInfos)
	local modClubRpc = import("logic/club/rpc.lua")
	modClubRpc.createClubGround(self.clubInfo:getClubId(), createInfos[self.currDataIndex], createInfos[self.currDataIndex].realGameType, self:getGameType(self.currDataIndex), function(success, reason, reply)
		if success then
			infoMessage("恭喜您，创建成功")
			if self.callback then
				self.callback(createInfos[self.currDataIndex])
			end
			self:close()
		else
			infoMessage(reason)
		end
	end)
end

pMainCreate.destroy = function(self)
	pMainCreate:cleanInstance()
end

