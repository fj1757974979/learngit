local modUIUtil = import("ui/common/util.lua")
local modJson = import("common/json4lua.lua")
local modUtil = import("util/util.lua")
local modSeclectData = import("data/info/info_rule_menus.lua")
local modWndList = import("ui/common/list.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modUserData = import("logic/userdata.lua")
local modBeiLvWnd = import("ui/menu/beilv.lua")
local modChannelMgr = import("logic/channels/main.lua")
local modCreateOption = import("ui/menu/create_option.lua")
local modUIAllFunction = import("ui/common/uiallfunction.lua")
local modEvent = import("common/event.lua")

pCreate = pCreate or class(pWindow)

local strToImageIndex = {}
local dataList = {}

for index, config in pairs(modCreateOption.getData()) do
	strToImageIndex[config.gameType] = index - 1
	dataList[config.gameType] = import(config.createConfigFile)
end

local mjToCost = mjToCost or {}

local cbImages = {
	[1] = {
		[false] = "ui:create_cbtn_bg.png",
		[true] = "ui:create_cbtn_checked.png",
	},
	[2] = {
		[false] = "ui:create_cbtn_bg.png",
		[true] = "ui:create_cbtn_checked.png",
	},
	[3] = {
		[false] = "ui:create_cbtn_select_dis.png",
		[true] = "ui:create_cbtn_select.png",
	}
}

local dragWidth = dragWidth or 0
local dragHeight = dragHeight or 0
local dragWidthType = dragWidthType or 0
local dragHeightType = dragHeightType or 85
local defaultValueToBoolean = {[100000] = true, [99999] = false }

pCreate.init = function(self)
	self:loadUI()
	self.currDataIndex = nil
	self:setParent(gWorld:getUIRoot())
	self.contorls = {}
	self.typeWnds = {}
	self.channelStrs = {}
	self.result = {}
	self.saveResult = {}
	self.defaultValues = {}
	self.magicAndChi = {}
	self.specialNiaos = {}
	self.normalNiaos = {}
	self.jinNiaoPos = {}
	self.fancbtns = {}
	self.beiLvWnds = {}
	self.speicalMaiMaMark = {}
	self.dingGuiMark = {}
	self.listWnds = {}
	self.dragWnds = {}
	self.fgsjkfWnds = {}
	self.valueNameToCB = {}
	self.costDataList = modChannelMgr.getCurChannel():getCostData()
	-- valueName对应的父子关系
	self.valueParents = {}
	-- 根据渠道取得麻将类型
	self:channelToData()
	-- 根据渠道去的房卡消耗
	self:cost()
	self.userResult = nil
	self.checkButtonGroup = 1
	self.saveGroupId = 1
--	self:initWindowPos()
	self:regEvent()
	self.btn_fanxing:setText("番型修改")
	self.grpId = nil
	modUIUtil.adjustSize(self.wnd_hnzz, gGameWidth, gGameHeight)
	modUIUtil.makeModelWindow(self, false, false)
end

pCreate.setGrpId = function(self, grpId)
	self.grpId = grpId
end

pCreate.loadUI = function(self)
	self:load("data/ui/createroom.lua")
end

pCreate.cost = function(self)
	for _, str in ipairs(self.channelStrs) do
		local mjt = str
		local fromData = self.costDataList
		local toData = {}
		for k, d in pairs(fromData) do
			toData[k] = d["room_card_cost"]
		end
		if table.size(toData) > 0 then
			mjToCost[mjt] = toData
		end
	end
end

pCreate.channelToData = function(self)
	local channelId = modUtil.getOpChannel()
	local channels = modChannelMgr.getCurChannel():getMJStrs()
	self.channelStrs = channels
	--[[
	for idx, str in ipairs(channels) do
		self.channelStrs[str] = idx
	end
	]]--
	self.majiangData = {}
	self.majiangData.data = {}
	self.cbtns ={}
	-- 初始化麻将类型
	for index, str in ipairs(self.channelStrs) do
		if dataList[str] then
			self.majiangData.data[str] = dataList[str]
			self.cbtns[str] = {}
		end
	end
	-- 设置默认选中
	self.data = self:loadData()
	-- 读取缓存
	if self.data and self.data["key"] then
		self.currDataIndex = self.data["key"]
		if not self:isNotDefalutMj(self.currDataIndex) then
			for index, str in ipairs(self.channelStrs) do
				self.currDataIndex = str
				break
			end
		end
	end
	-- 设置默认选中麻将
	if table.size(self.majiangData.data) > 0 then
		for n, d in pairs(self.majiangData.data) do
			d["default"] = nil
			if n == self.currDataIndex then
				d["default"] = true
			end
			if not self.data or not self.data["key"] then
				self.currDataIndex = n
				d["default"] = true
				break
			end
		end
	end
end

pCreate.isNotDefalutMj = function(self, s)
	local isNotDefalut = false
	for _, str in ipairs(self.channelStrs) do
		if str == s then return true end
	end
	return false
end

pCreate.open = function(self, specificList)
	logv("info", "==== ", specificList)
	-- 读取描画麻将信息
	self:majiangDrag(specificList)
	-- app
	self:app()
end

pCreate.app = function(self)
	if modUtil.isAppstoreExamineVersion() then
		self.btn_daifu:show(false)
--		self.btn_aa:setOffsetX(-325)
	end
end

pCreate.showFanxing = function(self)
	-- 清除
	if self["wnd_fanxing_bg" .. self.currDataIndex] then self["wnd_fanxing_bg" .. self.currDataIndex]:setParent(nil) end
	-- bg
	local bg = pWindow:new()
	bg:setName("wnd_fanxing_bg" .. self.currDataIndex)
	bg:setParent(self.wnd_hnzz)
	bg:setZ(-3)
	bg:setImage("ui:zhuaniao_bg.png")
	bg:setColor(0xFFFFFFFF)
	bg:setAlignX(ALIGN_CENTER)
	bg:setAlignY(ALIGN_CENTER)
	self[bg:getName()] = bg

	-- cb
	local distanceX, distanceY = 130, 20
	local x, y = 10, distanceY
	local scale = 1
	local max = 4
	local idx = 0
	for _, cb in pairs(self.fancbtns[self.currDataIndex]) do
		idx = idx + 1
		local pos = self:setCBPos(cb, x, y, scale)
		x, y = pos[1] + distanceX, pos[2]

		if idx % max == 0 then
			x = 10
			y = y + cb:getHeight() + distanceY
		end
		-- cb处理
		self:fancbClick(cb, bg)
		cb["append"]:getTextControl():setFontSize(30)
	end
	bg:setSize(bg:getWidth() + max * 220, bg:getHeight() + gGameHeight * 0.5)
	modUIUtil.makeModelWindow(bg, false, true)
end

pCreate.fancbClick = function(self, cb, bg)
	local wnd = cb["append"]
	cb:show(true)
	cb:setParent(bg)
	cb:setCheck(true)
	wnd:show(true)
	wnd:setParent(bg)

	local menuData = self:findMenuData(cb["markName"])
	self:setValue(cb["valueName"], menuData["value"], cb["markName"])
end

pCreate.setCBPos = function(self, cb, x, y, scale)
	local s = scale
	if not cb then return end
	if not scale then s = 1 end
	cb:setAlignX(ALIGN_LEFT)
	cb:setAlignY(ALIGN_TOP)
	cb:setSize(cb:getWidth() * scale, cb:getHeight() * scale)
	cb:setPosition(x, y)
	cb["append"]:setPosition(x + cb:getWidth() + 5, y)
	return { cb["append"]:getX() + 30, cb:getY() }
end

pCreate.majiangDrag = function(self, specificList)
	self.wnd_drag_type = self:createListWnd("type")
	self.wnd_drag_type:setParent(self.wnd_left_panel)
	self.wnd_drag_type:setSize(self.wnd_left_panel:getWidth(), self.wnd_left_panel:getHeight())
	self.windowList_type = modWndList.pWndList:new(self.wnd_left_panel:getWidth(), self.wnd_left_panel:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	-- 初始化麻将种类
	self:majiangType(specificList)
	self:groupPlus()
	-- 横向拉伸最小值
	--if dragWidthType > self.wnd_drag_type:getWidth() then
		--self.wnd_drag_type:setSize(dragWidthType, self.wnd_drag_type:getHeight())
	--end
	if dragHeightType > self.wnd_drag_type:getHeight() then
		self.wnd_drag_type:setSize(dragWidthType, dragHeightType)
	end
	self.windowList_type:setAlignX(ALIGN_TOP)
	self.windowList_type:setOffsetX(0)
	self.windowList_type:addWnd(self.wnd_drag_type)
	self.windowList_type:setParent(self.wnd_left_panel)
end



-- 麻将类型
pCreate.majiangType = function(self, specificList)
	logv("info", specificList)
	if not self.majiangData then
		log("error", "maJiangData is nil。")
		return
	end
	local parentWnd = self.wnd_left_panel
	local majiangData = self.majiangData.data
	if majiangData then
		local pos = 0
		local distance = 95
		--if table.size(majiangData) < 4 then
			--pos = pos + (self.wnd_drag_type:getHeight() - table.size(majiangData) * distance) / 2
		--end
		local defaultIndex = nil
		local defaultCb = nil
		for _, str in ipairs(self.channelStrs) do
			local data = majiangData[str]
			--for index, data in pairs(majiangData) do
			if self:canCreateType(str) then
				if not specificList or specificList[str] then
					local cb = self:typeCheckButton(pos, str, parentWnd)
					cb:setParent(self.wnd_drag_type)
					pos = pos + distance
					-- 默认选中
					if not defaultIndex or data["default"] then
						defaultCb = cb
						defaultIndex = str
					end
				end
			end
		end
		if defaultIndex and defaultCb then
			defaultCb:setCheck(true)
			self:typeCheckButtonClick(defaultIndex)
		end
	end
	return table.size(majiangData)
end

pCreate.canCreateType = function(self, t)
	return true
end


-- 类型checkbutton
pCreate.typeCheckButton = function(self, y, index, parentWnd)
	--logv("info","y",y,"index",index,"parentWnd",parentWnd)
	local cb = pCheckButton:new()
	cb:setName("cbtn_type_" .. index)
	cb:setParent(parentWnd)
	cb:setSize(214, 85)
	cb:setAlignX(ALIGN_CENTER)
	cb:setAlignY(ALIGN_TOP)
	--cb:setPosition(0, (parentWnd:getHeight() - cb:getHeight()) / 2 - 3)
	cb:setPosition(0, y + 10)
	cb:setImage("ui:btn4.png")
	cb:setClickDownImage("ui:btn1.png")
	cb:setCheckedImage("ui:btn1.png")
	cb:setColor(0xFFFFFFFF)
	cb:setGroup(self.checkButtonGroup)
	cb.__index = index
	cb:addListener("ec_mouse_click", function() self:typeCheckButtonClick(cb.__index) end)
	self[cb:getName()] = cb
	table.insert(self.contorls, cb)

	local wnd = pCheckButton:new()
	wnd:setName("wnd_type_" .. index .. "_text")
	wnd:setParent(cb)
	wnd:setOffsetY(-3)
	wnd:setSize(159, 32)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setAlignY(ALIGN_CENTER)
	wnd:enableEvent(false)
	wnd:setImage(sf("ui:create_type%d_dis.png", strToImageIndex[index]))
	wnd:setColor(0xFFFFFFFF)
	self[wnd:getName()] = wnd
	self.typeWnds[index] = wnd
	table.insert(self.contorls, wnd)

	--if cb:getX() + cb:getWidth() > dragWidthType then
		--dragWidthType = cb:getX() + cb:getWidth()
	--end
	if cb:getY() + cb:getHeight()> dragWidthType then
		dragHeightType = cb:getY() + cb:getHeight()
	end
	return cb
end

pCreate.typeCheckButtonClick = function(self, index)
	if index then
		log("warn", "==== currDataIndex ===", index)
		self.currDataIndex = index
		self.defaultValues = {}
		if not self.cbtns[self.currDataIndex] then
			self.cbtns[self.currDataIndex] = {}
		end
		self:changeImage(index)
		-- 取得默认值 或 缓存值
		self:getDefaultValues()
		if not self.listWnds[index] then
			self:newShowWnd(index)
		end
		self:isShowWndList(index)
		-- 是否显示番型按钮
		self:isShowFanxingBtn()
		self:adjustCreateBtn(index)
	end
end

pCreate.adjustCreateBtn = function(self, index)
	if not self.btn_create.__offx then
		self.btn_create.__offx = self.btn_create:getOffsetX()
	end
	if modCreateOption.isPoker(index) then
		self.btn_create:setAlignX(ALIGN_RIGHT)
		self.btn_create:setOffsetX(0)
		if self.btn_aa then
			self.btn_aa:show(false)
		end
		if not modChannelMgr.getCurChannel():isPokerNeedDaiKai() then
			if self.btn_daifu then
				self.btn_daifu:show(false)
			end
		end
	else
		self.btn_create:setAlignX(ALIGN_CENTER)
		self.btn_create:setOffsetX(self.btn_create.__offx)
		if self.btn_aa then
			self.btn_aa:show(true)
		end
	end
end

pCreate.isShowFanxingBtn = function(self)
	if self:isMaoMing() then
		self.btn_fanxing:show(true)
	else
		self.btn_fanxing:show(false)
	end
end

pCreate.newShowWnd = function(self, index)
	-- 创建滑动窗口
	self:newListWnd()
	-- 创建对应麻将类型的bg窗体
	local bgWnd = self:newBgWnd(index)
	-- 创建选项
	self:newSelect(index, bgWnd)
	-- 添加按钮隐藏关系
	self:addParentCB()
	-- 添加click事件
	self:addClick()
	-- 默认值
	self:setDefaultValue()
	-- 添加番型按钮事件
	self.btn_fanxing:addListener("ec_mouse_click", function() self:showFanxing() end)
end

pCreate.addParentCB = function(self)
	if not self.cbtns[self.currDataIndex] or table.getn(self.cbtns[self.currDataIndex]) <= 0 then
		return
	end
	-- 根据markName查找是否有隐藏关系
	for _, cb in pairs(self.cbtns[self.currDataIndex]) do
		local lists = self:findParentName(cb)
		cb["showl"] = lists[1]
		cb["hidel"] = lists[2]
	end
end

pCreate.findParentName = function(self, findCB)
	if not findCB then return end
	local markName = findCB["markName"]
	local showCBList = {}
	local hideCBList = {}
	for _, cb in pairs(self.cbtns[self.currDataIndex]) do
		local parentNames = cb["parentNames"]
		local valueName = cb["valueName"]
		local hideNames = cb["hideNames"]
		if parentNames then
			for _, name in pairs(parentNames) do
				if self:mateMarkAndParentName(name, markName) then
					-- 买马特殊处理
					if valueName == "maima" then
						if self:maimaSpecial(cb, markName) then
							table.insert(showCBList, cb)
						else
							 table.insert(hideCBList, cb)
						 end
					-- 定鬼牌特殊处理
					elseif self:isDingGuiPai(markName) then
						if self:dingguiSpecial(cb, markName) then
							table.insert(showCBList, cb)
						else
							table.insert(hideCBList, cb)
						end
					-- 其他默认是show
					else
						table.insert(showCBList, cb)
					end
				end
			end
		end

		-- 隐藏
		if hideNames then
			for _, name in pairs(hideNames) do
				if self:mateMarkAndParentName(name, markName) then
					table.insert(hideCBList, cb)
				end
			end
		end
	end
	return {showCBList, hideCBList}
end

-- 茂名麻将鬼牌隐藏关系处理
pCreate.dingguiSpecial = function(self, cb, markName)
	if not cb or not markName then return end
	local valueName = cb["valueName"]
	if not self:isDingGuiPai(markName) then return end
	if not self:isDingGuiValue(valueName) then return end
	if markName ~= "wuguipai" then
		return true
	end
	return false
end

pCreate.isDingGuiPai = function(self, markName)
	return markName == "wuguipai" or markName == "fanguipai" or
			markName == "baibangui" or markName == "hongzhonggui"
end

pCreate.isDingGuiValue = function(self, valueName)
	return valueName == "sidajingang" or valueName == "wuguix2"
end

pCreate.isMaiMaMark = function(self, markName)
	return markName == "baozhama" or markName == "zhuangjiamaima" or markName == "zimomaima"
end

pCreate.maimaSpecial = function(self, cb, markName)
	if not cb or not markName then return end
	local valueName = cb["valueName"]
	if not valueName or valueName ~= "maima" then return end
	-- 爆炸马
	local menuData = self:findMenuData(cb["markName"])
	local value = menuData["value"]
	if markName == "baozhama" and value then
		-- 爆炸马只有 0 和 1
		if value == 0 or value == 1 then
			return true
		end
	else
		-- 其他没有1马
		if value and value ~= 1 then
			return true
		end
	end
	return false
end

pCreate.mateMarkAndParentName = function(self, markName, parentName)
	if not markName or not parentName then return end
	if parentName == "fanxing" then return false end
	return parentName == markName
end

pCreate.addClick = function(self)
	for _, cb in pairs(self.cbtns[self.currDataIndex]) do
		-- 隐藏关系
		cb:addListener("ec_mouse_click", function()
			local showList = cb["showl"]
			local hideList = cb["hidel"]
			local isShow = cb:isChecked()
			self:cbShow(showList, hideList, isShow)
			modEvent.fireEvent(cb["eventName"])
		end)
		if cb["eventName"] then
			cb.setCheck_old = cb.setCheck_old or cb.setCheck
			cb.setCheck = function(cb, flag)
				if flag then
					modEvent.fireEvent(cb["eventName"])
				end
				cb:setCheck_old(flag)
			end
		end
		--
		local cbt = cb["type"]
		local valueName = cb["valueName"]
		local markName = cb["markName"]
		local mutexName = cb["mutexName"]
		-- 互斥按钮
		if cbt == 1 then
			if self:isSpecialBird(markName) then
				cb:addListener("ec_mouse_click", function() self:specialBirdClick(cb) end)
			else
				cb:addListener("ec_mouse_click", function() self:clickCbtn(cb) end)
			end
			-- 复选按钮
		elseif cbt == 3 then
			if self:isZhuanZhuan() and self:isMagicOrChi(valueName) then
				cb:addListener("ec_mouse_click", function() self:magicAndChiClick(cb) end)
			elseif self:isTJ159Niao(markName) then
				cb:addListener("ec_mouse_click", function()
					local niaos = {
						[true] = modLobbyProto.CreateRoomRequest.ZHONGNIAO_159,
						[false] = modLobbyProto.CreateRoomRequest.ZHONGNIAO_ROUND,
					}
					self:setValue(valueName, niaos[cb:isChecked()], cb["markName"])
				end)
			else
				cb:addListener("ec_mouse_click", function()
					local menuData = self:findMenuData(cb["markName"])
					local value = menuData["value"]

					if defaultValueToBoolean[value] ~= nil then
						if mutexName then
							local cbs = self:findMutexCB(cb)
							for _, mcb in pairs(cbs) do
								mcb:setCheck(false)
								local mvalue = false
								if defaultValueToBoolean[value] == nil then
									mvalue = 0
								end
								self:setValue(mcb["valueName"], mvalue, mcb["markName"])
							end
						end
						self:setValue(valueName, cb:isChecked(), cb["markName"])
					else
						if cb:isChecked() then
							value = menuData["value"]
						else
							value = 0
						end
						self:setValue(valueName, value, cb["markName"])
					end
				end)
			end
		end
	end
end

pCreate.findMutexCB =function(self, cb)
	if not cb then return {} end
	local mutexName = cb["mutexName"]
	if not mutexName then return {} end
	local cbs = {}
	for _, c in pairs(self.cbtns[self.currDataIndex]) do
		if self:findMarkNameIsInList(c["markName"], mutexName)  then
			table.insert(cbs, c)
		end
	end
	return cbs
end

pCreate.findMarkNameIsInList = function(self, markName, list)
	if not markName or not list then return end
	for _, name in pairs(list) do
		if name == markName then return true end
	end
	return false
end

pCreate.cbShow = function(self, showList, hideList, isShow)
	if not showList and not hideList then return end
	-- show
	local removeIndexs = {}
	if showList then
		for _, c in pairs(showList) do
			c:show(isShow)
			c["append"]:show(isShow)
			-- 清除或添加番型对应按钮
			self:showListToFanList(showList, isShow)
		end
	end

	-- 清除
	for _, str in pairs(removeIndexs) do
		self.fancbtns[self.currDataIndex][str] = nil
	end
	-- hide
	if not hideList then return end
	for _, c in pairs(hideList) do
		c:show(not isShow)
		c["append"]:show(not isShow)
	end
end

pCreate.showListToFanList = function(self, showList, isShow)
	for _, c in pairs(showList) do
		if self:isFanType(c["parentNames"]) then
			if isShow then
				if not self.fancbtns[self.currDataIndex][c["markName"]] then
					self.fancbtns[self.currDataIndex][c["markName"]] = c
				end
			else
				if self.fancbtns[self.currDataIndex][c["markName"]] then
					self.fancbtns[self.currDataIndex][c["markName"]] = nil
					self:setValue(c["valueName"], 0, c["markName"])
				end
			end
		end

	end
end

pCreate.setNoSaveDataCBValue = function(self, cb)
	if not cb then return end
	local valueName = cb["valueName"]
	local markName = cb["markName"]
	local cbtype = cb["type"]
	if cbtype ~= 1 then return end
	if not self.valueNameToCB[self.currDataIndex] or
		not self.valueNameToCB[self.currDataIndex][valueName] or
		table.size(self.valueNameToCB[self.currDataIndex][valueName]) < 2 then
		return
	end
	local cblist = self.valueNameToCB[self.currDataIndex][valueName]
	for _, c in pairs(cblist) do
		if c:isChecked() then
			return
		end
	end
	for _, c in pairs(cblist) do
		if self:findValueFalseCB(c["markName"]) or self:isMJDefalutMarkName(c["markName"]) then
			for _, c in pairs(cblist) do
				c:setCheck(false)
			end
			c:setCheck(true)
			--self:setValue(c["valueName"], self:getCBValue(c["markName"]))
			self:clickCbtn(c)
			self:clickFalseOneType(c)
		end
	end
end

pCreate.clickFalseOneType = function(self, c)
	if not c then return end
	local showl = c["showl"]
	if showl then
		local isHasValue = false
		for _, tc in pairs(showl) do
			if self:isSavedValue(tc["markName"]) then
				tc:setCheck(true)
				self:clickCbtn(tc)
				isHasValue = true
				break
			end
		end
		if not isHasValue then
			for _, tc in pairs(showl) do
				if self:isMJDefalutMarkName(tc["markName"]) then
					tc:setCheck(true)
					self:clickCbtn(tc)
					break
				end
			end
		end
	end
end

pCreate.isSavedValue = function(self, markName)
	if not markName then return end
	if not self.defaultValues[self.currDataIndex] then return end
	for name, value in pairs(self.defaultValues[self.currDataIndex]) do
		if markName == name then
			return true
		end
	end
	return false
end

pCreate.isFanType = function(self, strs)
	for _, str in pairs(strs) do
		if str == "fanxing" then
			return true
		end
	end
	return false
end

pCreate.setDefaultValue = function(self)
	if not self.currDataIndex then return end
	-- 赋值
	self:getDefaultValues()
	-- 设置默认值或者保存值
	self:defaultValueEvent()
	-- 底倍默认值
	self:defaultDiBeiValue()
end

pCreate.defaultDiBeiValue = function(self)
	-- 没有倍率窗口
	self:setValue("dibei", 1, "dibei")
	if not self.beiLvWnds[self.currDataIndex] then
		return
	else
		self.beiLvWnds[self.currDataIndex]:defaultCreateValue()
	end
	-- 有倍率窗口
	if self.data and self.data[self.currDataIndex] then
		local name = self.beiLvWnds[self.currDataIndex]:getValueName()
		local blValue = self.data[self.currDataIndex][name]
		if not blValue then return end
		local wnd = self.beiLvWnds[self.currDataIndex]
		wnd:setBeiLvText(blValue)
		local blCurIndex = wnd:findIndexInBLNValues(blValue)
		wnd:setBeiLvIndex(blCurIndex)
	end
end

pCreate.selectDefaultMenuStrs = function(self, selectData)
	return selectData["defaultMenu"]
end

pCreate.getDefaultValues  = function(self)
	self.defaultValues[self.currDataIndex] = {}
	-- 是否有缓存值
	if self.data and self.data[self.currDataIndex] then
		local tmp = self.data[self.currDataIndex]
		for _, cb in pairs(self.cbtns[self.currDataIndex]) do
			for k, v in pairs(tmp) do
				if k == cb["markName"] then
					self.defaultValues[self.currDataIndex][cb["markName"]] = v
				end
			end
		end
		return
	end
	-- 取表里的所有默认值
	local mjData = dataList[self.currDataIndex].data
	local menuData = modSeclectData.data
	for _, data in pairs(mjData) do
		local defaultMenuStrs = self:selectDefaultMenuStrs(data)
		if defaultMenuStrs and defaultMenuStrs ~= "" then
			local dvs = string.split(defaultMenuStrs, ";")
			for _, dv in pairs(dvs) do
				local value = defaultValueToBoolean[menuData[dv]["value"]]
				if value == nil then value = menuData[dv]["value"] end
				self.defaultValues[self.currDataIndex][dv] = value
			end
		end
	end
end

pCreate.findValueFalseCB = function(self, markName)
	local menuData = self:findMenuData(markName)
	local value = menuData["value"]
	if not value then return end
	if defaultValueToBoolean[value] or defaultValueToBoolean[value] == nil then return end
	if defaultValueToBoolean[menuData["value"]] == false then
		return true
	end
	return false
end

pCreate.isMJDefalutMarkName = function(self, markName)
	local mjData = dataList[self.currDataIndex].data
	for _, data in pairs(mjData) do
		if data["defaultMenu"] and data["defaultMenu"] ~= "" then
			local dvs = string.split(data["defaultMenu"], ";")
			for _, dv in pairs(dvs) do
				if dv == markName then
					return true
				end
			end
		end
	end
	return false
end

pCreate.defaultValueEvent = function(self)
	for _, cb in pairs(self.cbtns[self.currDataIndex]) do
		local markName = cb["markName"]
		local cbType = cb["type"]
		-- 隐藏和显示对应的showl, hidel
		local isShow = self.defaultValues[self.currDataIndex][markName]
		self:defaultIsShowList(cb, isShow)

		if cbType == 3 then
			self:defaultTypeThree(cb)
		elseif cbType == 1 then
			for mark, value in pairs(self.defaultValues[self.currDataIndex]) do
				--
				if markName == mark then
					cb:setCheck(true)
					self:defaultTypeOne(cb)
				end
			end
		end
	end

	-- 没有保存的1类互斥按钮赋值
	for _, cb in pairs(self.cbtns[self.currDataIndex]) do
		local cbType = cb["type"]
		if cbType == 1 then
			-- 设置没有保存 有按钮的值
--			local saveValue = self:getSavedValue(cb)
			self:setNoSaveDataCBValue(cb)
		end
	end
end

pCreate.getSavedValue = function(self, cb)
	if not cb then return end
	local markName = cb["markName"]
	local valueName = cb["valueName"]
	if not self.valueNameToCB[self.currDataIndex][valueName] or
		table.size(self.valueNameToCB[self.currDataIndex][valueName]) < 2
	then return end

	local list = self.valueNameToCB[self.currDataIndex][valueName]
	for _, c in pairs(list) do
		if self.defaultValues[self.currDataIndex][c["markName"]] then
			return self.defaultValues[self.currDataIndex][c["markName"]]
		end
	end
	return nil
end


pCreate.defaultIsShowList = function(self, cb, isShow)
	local showList = cb["showl"]
	local hideList = cb["hidel"]
	self:cbShow(showList, hidel, isShow)
end

pCreate.defaultTypeThree = function(self, cb)
	local valueName = cb["valueName"]
	local markName = cb["markName"]
	local menuData = self:findMenuData(markName)
	local value = menuData["value"]
	-- 有默认值或缓存值
	if value == 0 or self.defaultValues[self.currDataIndex][markName] == 0 then return end
	if self.defaultValues[self.currDataIndex][markName] then
		cb:setCheck(true)
		if self:isZhuanZhuan() and self:isMagicOrChi(markName) then
			self:magicAndChiClick(cb)
		elseif self:isTJ159Niao(markName) then
			local value = self.defaultValues[self.currDataIndex][markName]
			if value == modLobbyProto.CreateRoomRequest.ZHONGNIAO_ROUND then
				cb:setCheck(false)
			end
			self:setValue(valueName, value, cb["markName"])
		else
			self:setValue(valueName, defaultValueToBoolean[value] or value , cb["markName"])
		end
	else
		if self:isTJ159Niao(markName) then -- 默认值可能没有
			self:setValue(valueName, modLobbyProto.CreateRoomRequest.ZHONGNIAO_ROUND, cb["markName"])
		else
			if defaultValueToBoolean[value] == nil then
				self:setValue(valueName, 0, cb["markName"])
			else
				self:setValue(valueName, false, cb["markName"])
			end
		end
	end
end

pCreate.isTJ159Niao = function(self, str)
	if not self:isTaoJiang() then return false end
	return str == "159zhuaniao"
end

pCreate.magicAndChiClick = function(self, cb)
	if not self:isZhuanZhuan() or not cb then
		self:setValue(cb["valueName"], cb:isChecked(), cb["markName"])
		return
	end

	local isTrue = cb:isChecked()
	if not isTrue then
		self:setValue(cb["valueName"], false, cb["markName"])
		return
	end

	for _, c in pairs(self.magicAndChi) do
		if c == cb then
			c:setCheck(true)
			self:setValue(c["valueName"], true, c["markName"])
		else
			c:setCheck(false)
			self:setValue(c["valueName"], false, c["markName"])
		end
	end

end

pCreate.defaultTypeOne = function(self, cb)
	if self:isHongZhong() and self:isSpecialBird(cb["markName"]) then
		self:specialBirdClick(cb)
	else
		self:clickCbtn(cb)
	end
end

pCreate.specialBirdClick = function(self, cb)
	if not self:isHongZhong() or not self:isSpecialBird(cb["markName"]) then return end
	self:setValue(cb["valueName"], self:getCBValue(cb["markName"], cb["valueName"]), cb["markName"])

	if cb["markName"] == "jinniao" then
		self:showBtn(self.normalNiaos, false)
		self:showBtn(self.specialNiaos, true)
		local idx = table.size(self.specialNiaos)
		-- 换位置
		for _, c in pairs(self.specialNiaos) do
			local tmp = self.normalNiaos[idx]
			c:setPosition(tmp:getX(), tmp:getY())
			c["append"]:setPosition(tmp["append"]:getX(), tmp["append"]:getY())
			-- 设为默认值
			if c["markName"] == "bird_1" then
				c:setCheck(true)
				self:clickCbtn(c)
			else
				c:setCheck(false)
			end
			idx = idx - 1
		end
	else
		self:showBtn(self.specialNiaos, false)
		self:showBtn(self.normalNiaos, true)
		for _, c in pairs(self.normalNiaos) do
			-- 换位置
			if self.jinNiaoPos[c:getName()] then
				local pos =	self.jinNiaoPos[c:getName()]
				local wPos = self.jinNiaoPos[c["append"]:getName()]
				c:setPosition(pos[1], pos[2])
				c["append"]:setPosition(wPos[1], wPos[2])
			end
			-- 设为默认值
			if c["markName"] == "bird_2" then
				c:setCheck(true)
				self:clickCbtn(c)
				c:setCheck(true)
			else
				c:setCheck(false)
			end
		end
	end
end

pCreate.showBtn = function(self, list, isShow)
	for _, cb in pairs(list) do
		cb:show(isShow)
		cb["append"]:show(isShow)
	end
end

pCreate.isSpecialBird = function(self, str)
	return str == "jinniao" or str == "feiniao" or str == "159zhuaniao"
end

pCreate.clickShowAndHide = function(self, cb)
	if not cb or cb["type"] ~= 1 then return end
	local showList = cb["showl"]
	local hideList = cb["hidel"]
	if showList then
		for _, c in pairs(showList) do
			c:show(true)
			c["append"]:show(true)
		end
	end
	if hideList then
		for _, c in pairs(hideList) do
			c:show(false)
			c["append"]:show(false)
		end
	end
end

-- type为1的
pCreate.clickCbtn = function(self, cb)
	if not cb or not cb:isShow() then return end
	local valueName = cb["valueName"]
	local value = self:getCBValue(cb["markName"])
	-- 隐藏
	self:clickShowAndHide(cb)
	--
	self:clickFalseOneType(cb)
	-- 点击事件
	if cb["markName"] == "zimo" then
		self:zimoClick(valueName, value, cb)
	elseif  self:isMaiMaMark(cb["markName"]) then
		self:maiMaSetValue(cb)
	elseif self:isDingGuiPai(cb["markName"]) then
		self:dingGuiValue(cb)
	else
--		self:birdClick(cb)
		self:clickSetCheckFalse(cb)
		self:playerClick(cb)
		self:setValue(valueName, value, cb["markName"])
	end
end

pCreate.clickSetCheckFalse = function(self, cb)
	if not cb then return end
	local valueName = cb["valueName"]
	if not self.valueNameToCB[self.currDataIndex] or
		not self.valueNameToCB[self.currDataIndex][valueName] or
		table.size(self.valueNameToCB[self.currDataIndex][valueName]) < 2 then
		return
	end
	local list = self.valueNameToCB[self.currDataIndex][valueName]
	for _, c in pairs(list) do
		if c ~= cb then
			c:setCheck(false)
		end
	end
end


pCreate.birdClick = function(self, cb)
	if cb["valueName"] ~= "bird" then return end
	for _, c in pairs(self.normalNiaos) do
		if c ~= cb then
			c:setCheck(false)
		end
	end
	for _, s in pairs(self.specialNiaos) do
		if s ~= cb then
			s:setCheck(false)
		end
	end
end

pCreate.dingGuiValue = function(self, cb)
	if not self.dingGuiMark[self.currDataIndex] then return end

	cb:setCheck(true)
	-- 白板鬼 红中癞子设为false
	if cb["markName"] == "wuguipai" then
		self:setValue("hongzhong", false, "hongzhong")
	else
	-- 其他 红中癞子设为true 并设置相应值
		self:setValue("hongzhong", true, "hongzhong")
		self:setValue(cb["valueName"], self:getDingGuiValue(cb["markName"]), cb["markName"])
	end
	-- 其他按钮设为false
	for _, c in pairs(self.dingGuiMark[self.currDataIndex]) do
		if c ~= cb then
			c:setCheck(false)
		end
	end
end

pCreate.getDingGuiValue = function(self, markName)
	local guiValues = {
		["fanguipai"] = modLobbyProto.CreateRoomRequest.MaomingExtras.FAN_GUI,
		["baibangui"] = modLobbyProto.CreateRoomRequest.MaomingExtras.BAIBAN_GUI,
		["hongzhonggui"] = modLobbyProto.CreateRoomRequest.MaomingExtras.HONGZHONG_GUI,
	}
	return guiValues[markName]
end

pCreate.getMaValue = function(self, markName)
	local maValues = {
		["zhuangjiamaima"] = modLobbyProto.CreateRoomRequest.MaomingExtras.ZHUANG_MAIMA,
		["zimomaima"] = modLobbyProto.CreateRoomRequest.MaomingExtras.ZIMO_MAIMA,
		["baozhama"] = modLobbyProto.CreateRoomRequest.MaomingExtras.BAOZHAMA,
	}
	return maValues[markName]
end

pCreate.maiMaSetValue = function(self, cb)
	local markName = cb["markName"]
	local valueName = cb["valueName"]
	local showList = cb["showl"]
	-- 设置按钮是否被选中
	cb:setCheck(true)
	self:setValue(valueName, self:getMaValue(markName), markName)
	-- 其他关联按钮设置为false
	self:setFalseValueMaima(cb)
	-- 按钮默认值 爆炸马为1马 其他为2马
	for _, c in pairs(showList) do
		local menuData = self:findMenuData(c["markName"])
		local value = menuData["value"]
		if value ~= 1 and value ~= 4 then
			c:setCheck(false)
		else
			-- 爆炸马为1
			if markName == "baozhama" then
				if value == 1 then
					c:setCheck(true)
					self:clickCbtn(c)
				end
			else
				-- 其他为4
				if value == 4 then
					c:setCheck(true)
					self:clickCbtn(c)
				end
			end
		end
	end
end

pCreate.setFalseValueMaima = function(self, cb)
	if not self.speicalMaiMaMark[self.currDataIndex] then return end
	for _, c in pairs(self.speicalMaiMaMark[self.currDataIndex]) do
		if c ~= cb then
			c:setCheck(false)
		end
	end
end

pCreate.zimoClick = function(self, str, value, cb)
	if not str == "zimo" or not value then return end
	self:setValue(str, false, cb["markName"])
	self:setValue("zimo", true, cb["markName"])
end

pCreate.getCBValue = function(self, markName)
	-- 特殊抓鸟取值
	if self:isSpecialBird(markName) then
		local value = modLobbyProto.CreateRoomRequest.ZHONGNIAO_159
		local niaos = {
			["jinniao"] = modLobbyProto.CreateRoomRequest.HONGZHONG_ZHONGNIAO_JIN,
			["feiniao"] = modLobbyProto.CreateRoomRequest.HONGZHONG_ZHONGNIAO_FEI,
		}
		if niaos[markName] then value = niaos[markName] end
		return  value
	end
	-- 普通按钮取值
	local menuData = modSeclectData.data
	local value = defaultValueToBoolean[menuData[markName]["value"]]
	if value == nil then value = menuData[markName]["value"] end
	return value
end

pCreate.setValue = function(self, name, value, markName)
	-- 赋值
	if not name or value == nil then return end
	if not self.result[self.currDataIndex] then self.result[self.currDataIndex] = {} end
	self.result[self.currDataIndex][name] = value
	-- 保存
	if not self.saveResult[self.currDataIndex] then
		self.saveResult[self.currDataIndex] = {}
	end
	self:isUpdateValue(markName)
	if markName and value and not self:isNotSave(name) then
		self.saveResult[self.currDataIndex][markName] = value
	end
	log("info", "set value name:", name, "value:", value)
end


pCreate.isNotSave = function(self, str)
	if  not self:isMaoMing() then return end
	if str == "maima" then
		return true
	end
	return false
end

pCreate.isUpdateValue = function(self, markName)
	logv("isUpdateValue",markName)
	if not markName then return end
	local list = {}
	if not self:findMenuData(markName) then return end
	local m1 = self:findMenuData(markName)["name"]

	for m, v in pairs(self.saveResult[self.currDataIndex]) do
		if self:findMenuData(m) then
			local m2 = self:findMenuData(m)["name"]
			if self:isSpecialBird(m) then
				m2 = "159zhuaniao"
			end
			if m1 == m2 then
				table.insert(list, m)
			end

		end
	end

	for _, m in pairs(list) do
		self.saveResult[self.currDataIndex][m] = nil
	end
end

pCreate.isSkipDraw = function(self)
	return false
end

pCreate.newSelect = function(self, index, pWnd, tmpHeight)
	if not index or not pWnd then return end
	local mjData = dataList[index].data
	-- 排序
	table.sort(mjData, function(d1,d2)
		return d1["optionRanking"] < d2["optionRanking"]
	end)

	-- 描画
	local tx = self.dragWnds[self.currDataIndex]:getWidth() * 0.02
	local ty = self.dragWnds[self.currDataIndex]:getHeight() * 0.05 + (tmpHeight or 0)
	local sx, sy = tx, ty
	local distanceX, distanceY = 10, 20
	for n, data in pairs(mjData) do
		local drawStr = string.split(data["optionMenu"], ";")
		if not self:isSkipDraw(drawStr) then
			-- 描画标题
			local tWnd = self:drawTitle(data, tx, ty, pWnd)
			sx = tWnd:getX() + tWnd:getWidth()  + distanceX
			-- 描画选项

			local pos = self:drawSelectMenus(data, sx, ty - 10, pWnd)
			ty = pos[2] + distanceY
		end
	end

	-- 添加倍率窗口
	self:beiLvWnd(pWnd)
	local bly = self:setBeiLvWndPos(sx + distanceX * 3, ty - distanceY)
	if bly then ty = bly + distanceY end

	-- 滑动窗口拖动
	if ty > self.dragWnds[self.currDataIndex]:getHeight() then
		self.dragWnds[self.currDataIndex]:setSize(self.dragWnds[self.currDataIndex]:getWidth(), ty + 50)
	end
	self.listWnds[self.currDataIndex]:addWnd(self.dragWnds[self.currDataIndex])
	self.listWnds[self.currDataIndex]:setParent(self.wnd_list)
end
--添加创建放间的倍率
pCreate.beiLvWnd = function(self, pWnd)
	if (not self:isDongShan()) and (not self:isPingHe()) and (not self:isTaoJiang()) and (not self:isTianJin()) then return end
	if not pWnd then return end
	if not self.beiLvWnds[self.currDataIndex] then self.beiLvWnds[self.currDataIndex] = {} end
	local beiLvNumbers = { 1, 2, 3, 4, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 }
	if self:isTianJin() then
		beiLvNumbers = {1, 2, 5, 10}
	end
	local dfBeiLv = 1
	if self:isTaoJiang() then
		dfBeiLv = 2
	end
	local titleName = "倍率"
	if self:isDongShan() then titleName = "底分" end
	if self:isPingHe() then titleName = "底分" end
	local wnd = modBeiLvWnd.pBeiLv:new(self, beiLvNumbers, "dibei", titleName, dfBeiLv)
	wnd:setParent(pWnd)
	self.beiLvWnds[self.currDataIndex] = wnd
	return wnd
end

pCreate.setBeiLvWndPos = function(self, x, y)
	if not self.beiLvWnds or  not self.beiLvWnds[self.currDataIndex] then return end
	self.beiLvWnds[self.currDataIndex]:setPosition(x, y)
	return y + self.beiLvWnds[self.currDataIndex]:getWidth()
end

pCreate.findStr = function(self, list, s)
	local f = false
	for _, str in pairs(list) do
		if str == s then return true end
	end
	return false
end

pCreate.testAddPlayer = function(self, strs)
	if not modUtil.isDebugVersion() then return end
	if not strs or table.getn(strs) <= 0 then return end
	local st = strs[1]
	if not st or not string.find(st, "player") then return end
	local adds = { "player_4", "player_3", "player_2" }
	local tmps = {}
	for _, s in pairs(adds) do
		if not self:findStr(strs, s) then
			table.insert(tmps, s)
		end
	end
	for _, s in pairs(tmps) do
		table.insert(strs, s)
	end
end

pCreate.shouldDrawMenu = function(self, menuName)
	return true
end

pCreate.drawSelectMenus = function(self, data, sx, sy, pWnd)
	if not data or not pWnd then return end
	local x, y = sx, sy
	local distanceX, distanceY = 10, 20
	local drawStr = string.split(data["optionMenu"], ";")
	local cbType = data["optionType"]
	local drawCount = 0
	-- 测试版本加入2人三人
	self:testAddPlayer(drawStr)
	-- type为1的按钮增加groupid
	if cbType == 1 then self:groupPlus() end
	-- 测试增加两人三人
	self:testAddPlayer(drawStr)
	-- 描画按钮
	for n, str in pairs(drawStr) do
		if self:shouldDrawMenu(str) then
			x = x + distanceX
			-- cbtn
			local pos = self:drawSelect(str, x, y, cbType, pWnd)
			x, y  = pos[1], pos[2]
			drawCount = drawCount + pos[3]
			-- 非隐藏按钮达到三个换行
			if drawStr[drawCount + 1] and drawCount % 3 == 0 then
				x= sx
				y = y + 50  + distanceY
			end
		end
	end
	y = y + 50 + distanceY
	-- 隐藏按钮不算高度
	if drawCount <= 0 then return {sx, sy} end
	return {x, y}
end

pCreate.isInsertJinNiaoPos = function(self, cb)
	if not self:isHongZhong() or cb["valueName"] ~= "bird" then return end
	if table.size(self.jinNiaoPos) >= 1 and cb["markName"] ~= "bird_0" then return end
	self.jinNiaoPos[cb:getName()] = {cb:getX(), cb:getY()}
	self.jinNiaoPos[cb["append"]:getName()] = {cb["append"]:getX(), cb["append"]:getY()}
end

pCreate.isInsertFgsjkfWnds = function(self, cb)
	if not self:isDongShan() then return end
	if not self.fgsjkfWnds[self.currDataIndex] then self.fgsjkfWnds[self.currDataIndex] = {} end
	local markName = cb["markName"]
	if markName == "fgyjkf" or markName == "fgsjkf" then
		table.insert(self.fgsjkfWnds[self.currDataIndex], cb)
	end
end

pCreate.isInsertMagicOrChi = function(self, cb, str)
	if not self:isZhuanZhuan() then return end
	if str == "hongzhong" or str == "kechi" then
		table.insert(self.magicAndChi, cb)
	end
end

pCreate.isInsertSpecialNiao = function(self, cb)
	if not self:isHongZhong() then return end
	if self:isSpecialMenuBird(cb) then
		table.insert(self.specialNiaos, cb)
	end
end

pCreate.isInsertDingGui = function(self, cb)
	if not self.dingGuiMark[self.currDataIndex] then
		self.dingGuiMark[self.currDataIndex] = {}
	end
	if self:isDingGuiPai(cb["markName"]) then
		table.insert(self.dingGuiMark[self.currDataIndex], cb)
	end
end

pCreate.isInsertSpeicalMaiMa = function(self, cb)
	if not self.speicalMaiMaMark[self.currDataIndex] then
		self.speicalMaiMaMark[self.currDataIndex] = {}
	end
	if self:isMaiMaMark(cb["markName"]) then
		table.insert(self.speicalMaiMaMark[self.currDataIndex], cb)
	end
end

pCreate.isSpecialMenuBird = function(self, cb)
	if cb["valueName"] ~= "bird" then return end
	local menuData = self:findMenuData(cb["markName"])
	if menuData["value"] == 0 or menuData["value"] == 1 then
		return true
	end
	return false
end

pCreate.isNormalBird = function(self, cb)
	if cb["valueName"] ~= "bird" then return end
	local menuData = self:findMenuData(cb["markName"])
	if menuData["value"] ~= 1 then
		return true
	end
	return false
end


pCreate.isInsertNormalNiao = function(self, cb)
	if not self:isHongZhong() then return end
	if not self:isNormalBird(cb) then return end
	table.insert(self.normalNiaos, cb)
end

pCreate.drawSelect = function(self, str, sx, sy, cbType, pWnd)
	if not self:findMenuData(str) then
		log("error", str .. " is nil")
	end
	local menuData = self:findMenuData(str)
	local pName = menuData["parentName"]
	local hName = menuData["hideName"]
	local mutexName = menuData["mutex"]
	local eventName = menuData["event"]
	-- 描画cbtn
	local x, y = sx, sy
	local cb = self:newCheckButton(str, x, y, cbType, pWnd, menuData["name"], pName, hName, mutexName, eventName)
	x = x + cb:getWidth() + 5
	-- 追加text
	local text = menuData["optionMenuText"]
	local appendText = self:convertMark(menuData["appendText"], self.currDataIndex, menuData["value"])
	text = text .. appendText
	local wnd = self:newNormalWnd("text_" .. str, x, y, nil, 50, 50, pWnd, text)
	x = x + gGameWidth * 0.15

	-- 文字窗体
	cb["append"] = wnd
	-- 是否加入list
	self:isInsertMagicOrChi(cb, str)
	self:isInsertJinNiaoPos(cb)
	self:isInsertSpecialNiao(cb)
	self:isInsertNormalNiao(cb)
	self:isInsertSpeicalMaiMa(cb)
	self:isInsertDingGui(cb)
	self:isInsertFgsjkfWnds(cb)
	self:setValueToCB(cb)
	-- 是番行就不画，并且返回 0 或1 0为隐藏
	if self:isFanXing(pName) then
		cb:show(false)
		cb["append"]:show(false)
		if not self.fancbtns[self.currDataIndex] then
			self.fancbtns[self.currDataIndex] = {}
		end
		cb:setParent(nil)
		cb["append"]:setParent(nil)
		self.fancbtns[self.currDataIndex][str] =  cb
		return {sx, sy, 0}
	end
	return {x, y, 1}
end

pCreate.setValueToCB = function(self, cb)
	if not cb then return end
	if not self.valueNameToCB[self.currDataIndex] then self.valueNameToCB[self.currDataIndex] = {} end
	local valueName = cb["valueName"]
	if not self.valueNameToCB[self.currDataIndex][valueName] then self.valueNameToCB[self.currDataIndex][valueName] = {} end
	table.insert(self.valueNameToCB[self.currDataIndex][valueName], cb)
end

pCreate.isFanXing = function(self, pName)
	if not pName or pName == "" then return end
	local isFan = false
	local strs = string.split(pName, ";")
	for _, s in pairs(strs) do
		if s == "fanxing" then
			return true
		end
	end
	return false
end

pCreate.convertMark =function(self, str, mjStr, value)
	local channel = modUtil.getOpChannel()
	local cardName = ""
	if not self.costDataList or not self.costDataList[value] then return "" end
	local defalutPlayerCount = 4
	cardName = modChannelMgr.getCurChannel():getRoomcardText() or "钻石"
	return sf(str, cardName, self.costDataList[value]["room_card_cost" .. defalutPlayerCount])
end

pCreate.playerClick = function(self, cb)
	if not cb then return end
	if cb["valueName"] ~= "player" then return end
	local value = self:getCBValue(cb["markName"])
	local channel = modUtil.getOpChannel()
	local cardName = modChannelMgr:getCurChannel():getRoomcardText() or "钻石"
	for _, c in pairs(self.cbtns[self.currDataIndex]) do
		if c["valueName"] == "round" then
			local wnd = c["append"]
			local menuData = self:findMenuData(c["markName"])
			local appendText = menuData["appendText"]
			local roundValue = self:getCBValue(c["markName"])
			if self.costDataList[roundValue] then
				if self.costDataList[roundValue]["room_card_cost" .. value] then
					wnd:setText(sf(menuData["optionMenuText"] .. appendText, cardName, self.costDataList[roundValue]["room_card_cost" .. value]))
				end
			end
		end
	end
end

pCreate.findMenuData = function(self, str)
	return modSeclectData.data[str]
end

pCreate.newCheckButton = function(self, name, sx, sy, cbType, pWnd, valueName, pName, hName, mutexName, eventName)
	local cb = pCheckButton:new()
	cb:setName("cb_" .. self.currDataIndex .. name)
	cb:setParent(pWnd)
	cb:setPosition(sx, sy)
	cb:setSize(57, 57)
	cb:setImage(cbImages[cbType][false])
	cb:setClickDownImage(cbImages[cbType][true])
	cb:setCheckedImage(cbImages[cbType][true])
	cb["type"] = cbType
	cb["valueName"] = valueName
	cb["markName"] = name
	if pName and pName ~= "" then
		cb["parentNames"] = string.split(pName, ";")
	end
	if hName and hName ~= "" then
		cb["hideNames"] = string.split(hName, ";")
	end
	if mutexName and mutexName ~= "" then
		cb["mutexName"] = string.split(mutexName, ";")
	end
	if eventName and eventName ~= "" then
		cb["eventName"] = eventName
	end
	if cbType == 1 then cb:setGroup(self.saveGroupId) end
	table.insert(self.cbtns[self.currDataIndex], cb)
	return cb
end

pCreate.drawTitle = function(self, data, tx, ty, pWnd)
	if not data or not pWnd then return end
	local name = data["optionRanking"]
	local wnd = self:newNormalWnd(name, tx, ty, modCreateOption.getOptionTitleRes(data["optionText1"]), 91, 37, pWnd)
	return wnd
end

pCreate.newBgWnd = function(self, index)
	local wnd = pWindow:new()
	wnd:setName("wnd_bg_" .. index)
	wnd:setParent(self.dragWnds[self.currDataIndex])
	wnd:setAlignY(ALIGN_TOP)
	wnd:setAlignX(ALIGN_CENTER)
	wnd:setColor(0)
	wnd:setSize(self.dragWnds[self.currDataIndex]:getWidth(), self.dragWnds[self.currDataIndex]:getHeight())
	return wnd
end

pCreate.newNormalWnd = function(self, name, x, y, image, width, height, pWnd, text)
	local wnd = pWindow:new()
	wnd:setName("nor_wnd" .. self.currDataIndex .. name)
	wnd:setParent(pWnd)
	wnd:setPosition(x, y)
	wnd:setSize(width, height)
	wnd:enableEvent(false)
	wnd:setColor(0)
	if image then
		wnd:setImage(image)
		wnd:setColor(0xFFFFFFFF)
	end
	if text and text ~= "" then
		wnd:setText(text)
		wnd:getTextControl():setColor(0xFF352114)
		--wnd:getTextControl():setShadowColor(0xFFFFFFFF)
		wnd:getTextControl():setAutoBreakLine(false)
		wnd:getTextControl():setAlignX(ALIGN_LEFT)
		wnd:getTextControl():setFontBold(1)
		wnd:getTextControl():setFontSize(30)
	end
	table.insert(self.contorls, wnd)
	return wnd
end

pCreate.newListWnd = function(self)
	if self.dragWnds[self.currDataIndex] then return end
	local wnd_drag = self:createListWnd(self.currDataIndex)
	wnd_drag:setParent(self.wnd_list)
	wnd_drag:setSize(self.wnd_list:getWidth() , self.wnd_list:getHeight())
	local windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)

	self.dragWnds[self.currDataIndex] = wnd_drag
	self.listWnds[self.currDataIndex] = windowList
end

pCreate.isShowWndList = function(self, index)
	for idx, wnd in pairs(self.listWnds) do
		if idx == index then
			wnd:show(true)
		else
			wnd:show(false)
		end
	end
end

pCreate.changeImage = function(self, index)
	if self.typeWnds and index then
		for idx, wnd in pairs(self.typeWnds) do
			local wnd = self["wnd_type_" .. idx .. "_text"]
			--local cb = self["cbtn_type_" .. index]
			if idx == index then
				wnd:setImage(sf("ui:create_type%d.png", strToImageIndex[idx]))
				--cb:setImage("ui:btn4.png")
			else
				wnd:setImage(sf("ui:create_type%d_dis.png", strToImageIndex[idx]))
			end
		end
	end
end

-- checkbutton group数
pCreate.groupPlus = function(self)
--	self.checkButtonGroup = self.checkButtonGroup + 1
	self.saveGroupId = self.saveGroupId + 1
end

pCreate.regEvent = function(self)
	self.btn_close:addListener("ec_mouse_click",function() self:close() end)
	self.btn_create:addListener("ec_mouse_click",function() self:createRoom(modLobbyProto.CreateRoomRequest.NORMAL)end)
	self.btn_aa:addListener("ec_mouse_click",function() self:createRoom(modLobbyProto.CreateRoomRequest.AA) end)
	self.btn_daifu:addListener("ec_mouse_click",function() self:createRoom(modLobbyProto.CreateRoomRequest.SHARED)  end)
end

pCreate.setCardsValue = function(self)
		self.result[self.currDataIndex]["cards"] = {
			0, 1, 3, 5, 6, 7, 9, 9, 15 , 15, 23 , 19, 19, 23,
			0, 1, 3, 5, 6, 7, 9, 9, 15 , 15, 23 , 19, 19, 23,
		}
		self.result[self.currDataIndex]["cards"] = {
			0, 0, 3, 3, 6, 6, 9, 9, 15 , 15, 23 , 24, 24, 23,
			0, 1, 3, 5, 6, 7, 9, 9, 15 , 15, 23 , 19, 19, 23,
		}

--[[		self.result[self.currDataIndex]["cards"] = {
			1,1,1,1,1,1,1,1,1,1,1,1,1,1,
			2,2,2,2,2,2,2,2,2,2,2,2,2,2,
		}
		self.result[self.currDataIndex]["cards"] = {
			1,2,3,4,5,6,7,8,9,1,2,3,4,5,
			1,2,3,4,5,6,7,8,9,1,2,3,4,5,
		}]]--
--		self.result[self.currDataIndex]["cards"] = {
--			34,35,36,37,38,39,1,1,1,2,2,2,3,3,3,4,4,4,
--			34,35,36,37,38,39,1,1,1,2,2,2,3,3,3,4,4,4,
--			34,35,36,37,38,39,1,1,1,2,2,2,3,3,3,4,4,4,
--			34,35,36,37,38,39,1,1,1,2,2,2,3,3,3,4,4,4,
--		}
end

pCreate.hongzhongMJRule = function(self)
	-- 红中麻将
	if self.currDataIndex == "hzmj" then
		self:setValue("hongzhong", true)
		self:setValue("kechi", false)
		self:setValue("ruleType", modLobbyProto.CreateRoomRequest.HONGZHONG)
		self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZHUANG)
		self:setValue("tongpao", true)
		self:setValue("qianggang", true)
		self:setValue("jiepao", true)
		self:setValue("baxiaodui", true)
	end
end

pCreate.getResult = function(self, str)
	return self.result[self.currDataIndex][str]
end

pCreate.zhuanzhuanMJRule = function(self)
	-- 转转麻将
	if self.currDataIndex == "hnzz" then
		self:setValue("ruleType", modLobbyProto.CreateRoomRequest.ZHUANZHUAN)
		self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZHUANG)
		self:setValue("tongpao", self:getResult("jiepao"))
		self:setValue("qianggang", self:getResult("jiepao"))
		self:setValue("159zhuaniao", modLobbyProto.CreateRoomRequest.ZHONGNIAO_159)
		self:setValue("baxiaodui", true)
		self:setValue("dama", false)
--		self:setValue("dibei", 100 )
	end
end

pCreate.taojiangMJRule = function(self)
	-- 桃江麻将
	if self.currDataIndex == "tjmj" then
		self:setValue("ruleType", modLobbyProto.CreateRoomRequest.TAOJIANG)
		self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZUIHOUMOPAI)
		self:setValue("hongzhong", true)
		self:setValue("hostmode", false)
		self:setValue("qianggang", self:getResult("jiepao"))
		self:setValue("tongpao", false)
		self:setValue("baxiaodui", true)

	end
end

pCreate.dongshanMJRule = function(self)
	-- 东山麻将
	if self.currDataIndex == "dsmj" then
		self:setValue("ruleType", modLobbyProto.CreateRoomRequest.DONGSHAN)
		self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZUIHOUMOPAI)
		self:setValue("hongzhong", false)
		self:setValue("hostmode", false)
		self:setValue("kechi", true)
		self:setValue("qianggang", self:getResult("jiepao"))
		self:setValue("tongpao", true)
		self:setValue("bird", 0)
		self:setValue("jiepao", true)
		self:setValue("qianggang", true)
		self:setValue("dama", false)
		self:setValue("159zhuaniao", modLobbyProto.CreateRoomRequest.ZHONGNIAO_159)
	end
end

pCreate.pingheMJRule = function(self)
	-- 平和麻将
	if self.currDataIndex == "phmj" then
		self:setValue("ruleType", modLobbyProto.CreateRoomRequest.PINGHE)
		self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZUIHOUMOPAI)
		self:setValue("hongzhong", false)				
		self:setValue("hostmode", false)		
		self:setValue("kechi", true)		
		self:setValue("qianggang", self:getResult("jiepao"))
		self:setValue("tongpao", false)
		self:setValue("bird", 0)
		self:setValue("jiepao", true)
		self:setValue("qianggang", true)
		self:setValue("dama", false)
		self:setValue("159zhuaniao", modLobbyProto.CreateRoomRequest.ZHONGNIAO_159)		
	end
end

pCreate.zhaoanMJRule = function(self)
	-- 诏安麻将
	if self.currDataIndex == "zamj" then
		self:setValue("ruleType", modLobbyProto.CreateRoomRequest.ZHAOAN)
		self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZHUANG)
		self:setValue("hongzhong", false)
		self:setValue("hostmode", true)
		self:setValue("kechi", true)
		self:setValue("jiepao", true)
		self:setValue("qianggang", true)
		self:setValue("baxiaodui", false)
		self:setValue("bird", 0)
		self:setValue("159zhuaniao", modLobbyProto.CreateRoomRequest.ZHONGNIAO_159)
	end
end

pCreate.maomingMJRule = function(self)
	if self.currDataIndex == "mmmj" then
		self:setValue("ruleType", modLobbyProto.CreateRoomRequest.MAOMING)
		self:setValue("hostmode", false)
		self:setValue("jiepao", false)
		self:setValue("tongpao", true)
		self:setValue("dama", false)
	end
end

pCreate.tjtjmjRule = function(self)
	if self.currDataIndex == "tjtjmj" then
		self:setValue("ruleType", modLobbyProto.CreateRoomRequest.TIANJIN)
		self:setValue("hongzhong", true)
		self:setValue("hostmode", true)
		self:setValue("kechi", false)
		self:setValue("jiepao", false)
		self:setValue("qianggang", false)
		self:setValue("bird", 0)
		self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZHUANGXIAJIA)
	end
end

pCreate.yyhszmjRule = function(self)
	if not self:isHuanSanZhang() then return end
	self:setValue("hongzhong", false)
	self:setValue("hostmode", false)
	self:setValue("kechi", false)
	self:setValue("jiepao", true)
	self:setValue("tongpao", false)
	self:setValue("qianggang", true)
	self:setValue("dama", false)
	self:setValue("baxiaodui", true)
	self:setValue("bird", 0)
	self:setValue("ruleType", modLobbyProto.CreateRoomRequest.YUNYANG)
end

pCreate.cqddhmjRule = function(self)
	if not self:isDaoDaoHu() then return end
	self:setValue("ruleType", modLobbyProto.CreateRoomRequest.DAODAO)
	self:setValue("hongzhong", false)
	self:setValue("hostmode", false)
	self:setValue("chi", false)
	self:setValue("qianggang", true)
	self:setValue("tongpao", false)
	self:setValue("dama", false)
	self:setValue("baxiaodui", true)
	self:setValue("bird", 0)
	self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZUIHOUMOPAI)
end

pCreate.kawuxingRule = function(self)
	if not self:isKawuxing() then return end
	self:setValue("ruleType", modLobbyProto.CreateRoomRequest.XIANGYANG)
	self:setValue("hongzhong", false)
	self:setValue("chi", false)
	self:setValue("jiepao", true)
	self:setValue("tongpao", true)
	self:setValue("qianggang", true)
	self:setValue("dama", false)
	self:setValue("baxiaodui", true)
	self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZHUANG)
end

pCreate.baiheKawuxingRule = function(self)
	if not self:isBaiheKawuxing() then return end
	self:setValue("ruleType", modLobbyProto.CreateRoomRequest.XIANGYANG_BAIHE)
	self:setValue("hongzhong", false)
	self:setValue("chi", false)
	self:setValue("jiepao", true)
	self:setValue("tongpao", true)
	self:setValue("qianggang", true)
	self:setValue("dama", false)
	self:setValue("baxiaodui", true)
	self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZHUANG)
end

pCreate.rongchengRule = function(self)
	if not self:isRongCheng() then return end
	self:setValue("ruleType", modLobbyProto.CreateRoomRequest.RONGCHENG)
	self:setValue("hongzhong", true)
	self:setValue("hostmode", false)
	self:setValue("jiepao", true)
	self:setValue("qianggang", true)
	self:setValue("baxiaodui", true)
	self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_DONG)
end

pCreate.xzddRule = function(self)
	if not self:isXZDDMJ() then return end
	self:setValue("ruleType", modLobbyProto.CreateRoomRequest.CHENGDU)
	self:setValue("hongzhong", false)
	self:setValue("hostmode", false)
	self:setValue("kechi", false)
	self:setValue("jiepao", true)
	self:setValue("tongpao", true)
	self:setValue("qianggang", true)
	self:setValue("dama", false)
	self:setValue("baxiaodui", true)
	self:setValue("bird", 0)
	self:setValue("jingoudiao", true)
	self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZHUANGXIAJIA)
end

pCreate.sdjnRule = function(self)
	if not self:isJiningMj() then return end
	self:setValue("ruleType", modLobbyProto.CreateRoomRequest.JINING)
	self:setValue("hongzhong", false)
	self:setValue("hostmode", true)
	self:setValue("kechi", false)
	self:setValue("jiepao", true)
	self:setValue("tongpao", true)
	self:setValue("qianggang", true)
	self:setValue("baxiaodui", true)
	self:setValue("bird", 0)
	self:setValue("liujuzhuang", modLobbyProto.CreateRoomRequest.LIUJUZHUANG_ZHUANG)
end

pCreate.isXZDDMJ = function(self)
	return self.currDataIndex == "xzdd"
end

pCreate.isZhuanZhuan = function(self)
	return self.currDataIndex == "hnzz"
end

pCreate.isRongCheng = function(self)
	return self.currDataIndex == "sdrcmj"
end

pCreate.isHuanSanZhang = function(self)
	return self.currDataIndex == "yyhsz"
end

pCreate.isMagicOrChi = function(self, str)
	return str == "hongzhong" or str == "kechi"
end

pCreate.isDaoDaoHu = function(self)
	return self.currDataIndex == "cqddh"
end

pCreate.isJiningMj = function(self)
	return self.currDataIndex == "sdjnmj"
end

pCreate.speicalProps = function(self)
	return
end

pCreate.isCanCreate = function(self)
	return true
end

pCreate.isPoker = function(self)
	return modCreateOption.isPoker()
end

pCreate.getGameType = function(self)
	local types = {
		[T_MAHJONG_ROOM] = modLobbyProto.MAHJONG,
		[T_POKER_ROOM] = modLobbyProto.POKER
	}
	return types[modCreateOption.getGameStyle(self.currDataIndex)]
end

pCreate.isMahjong = function(self)
	return modCreateOption.isMahjong()
end

pCreate.protoCreateRoom = function(self, createInfos, roomType)	
	logv("warn","pCreate.protoCreateRoom", self.currDataIndex, createInfos)
	local createRoom = modCreateOption.getCreateRoomRpc(self.currDataIndex)
	createRoom(createInfos[self.currDataIndex], createInfos[self.currDataIndex].realGameType, function(success, reason, roomId, roomHost, roomPort, gameType, isRoomCardError)
		if success then
			if roomType ~= modLobbyProto.CreateRoomRequest.SHARED then
				modUIAllFunction.createInstanceBattleMgr(roomId, roomHost, roomPort, gameType)
				self:close()
			else
				local modDaiKai = import("ui/menu/daikai.lua")
				modDaiKai.pDaiKai:instance():open()
			end
		else
			if isRoomCardError then
				local modMenuMain = import("logic/menu/main.lua")
				modMenuMain.pMenuMgr:instance():getCurMenuPanel():buyCard()
				local modShopMgr = import("logic/shop/main.lua")
				local modInvite = import("ui/menu/invite.lua")
				if modShopMgr.pShopMgr:instance():getShopPanel(true) then
--					modShopMgr.pShopMgr:instance():getShopPanel():setParent(self)
					modShopMgr.pShopMgr:instance():getShopPanel():setZ(C_BATTLE_UI_Z)
				elseif modInvite.pInviteWindow:getInstance() then
					modInvite.pInviteWindow:instance():setParent(self)
					modInvite.pInviteWindow:instance():setZ(C_BATTLE_UI_Z)
				end
			end
			infoMessage(reason)
		end
	end)
end

-- 建立房间
pCreate.createRoom = function(self, roomType)
	self.result[self.currDataIndex]["room"] = roomType
	self.result[self.currDataIndex]["cards"] = {}
	logv("warn", "roomType", roomType)
	self:speicalProps(roomType)
	-- 测试牌
	if modUtil.isDebugVersion() then
--		self:setCardsValue()
--	self.result[self.currDataIndex]["player"] = 2
--	self.result[self.currDataIndex]["round"] = 1
	end

	-- 红中麻将特殊规则
	self:hongzhongMJRule()

	-- 转转麻将
	self:zhuanzhuanMJRule()

	-- 桃江麻将
	self:taojiangMJRule()

	-- 东山麻将
	self:dongshanMJRule()

	-- 平和麻将
	self:pingheMJRule()

	-- 诏安麻将
	self:zhaoanMJRule()

	-- 茂名麻将
	self:maomingMJRule()

	-- 天津麻将
	self:tjtjmjRule()

	-- 云阳换三张
	self:yyhszmjRule()

	-- 重庆倒倒胡
	self:cqddhmjRule()

	-- 卡五星
	self:kawuxingRule()

	-- 荣城麻将
	self:rongchengRule()

	-- 血战到底
	self:xzddRule()

	-- 白河卡五星
	self:baiheKawuxingRule()

	-- 济宁麻将
	self:sdjnRule()

	-- 子选项赋值修正
	local createInfos = {}
	createInfos[self.currDataIndex] = {}
	--logv("info", self.result[self.currDataIndex])
	for key, value in pairs(self.result[self.currDataIndex]) do
		createInfos[self.currDataIndex][key] = value
	end
	--logv()
	self:parentAndValueReset(createInfos[self.currDataIndex])

	local userCreate = self.result[self.currDataIndex]
	if not self:isCanCreate() then return end
	self:showLog(userCreate)
	log("warn", "save", roomType)
	createInfos[self.currDataIndex]["realGameType"] = modCreateOption.getGameRealType(self.currDataIndex)
	log("warn", "save", createInfos[self.currDataIndex])
	createInfos[self.currDataIndex]["grpId"] = self.grpId
	log("warn", "save", createInfos)
	for k,v in pairs (createInfos) do
		log("info","k","v",k,v)
		for m,j in pairs (v) do
			log("info","m","j",m,j)
		end		
	end
	self:protoCreateRoom(createInfos, roomType)
end

-- 初始适配
pCreate.initWndPos = function(self)
	local opp = puppy.world.app.instance()
	local platform = app:getPlatform()
	self.wnd_list:setOffsetX(0)
	self.wnd_list:setOffsetY(0)
end

pCreate.parentAndValueReset = function(self, infos)
	-- 父选项没有值,子选项设为false
	for _, cb in pairs(self.cbtns[self.currDataIndex]) do
		if (not cb:isSelfShow()) and (cb:isChecked()) then
			local vn = cb["valueName"]
			if type(infos[vn]) == "boolean" then
				infos[vn] = false
			end
		end
	end
end

-- 摧毁控件
pCreate.contorlsDestory = function(self, list)
	if not list then return end
	for k,v in pairs(list) do
		v:setParent(nil)
	end
	list = {}
end

pCreate.close = function(self)
	self:show(false)
	self:saveData()
	self.grpId = nil
--	pCreate:cleanInstance()
end

pCreate.destroy = function(self)
	pCreate:cleanInstance()
end

-- 滑动窗口
pCreate.createListWnd = function(self, name)
	local pWnd = pWindow:new()
	pWnd:setName("wnd_drag_" .. name)
	pWnd:setSize(dragWidth, dragHeight)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	self[pWnd:getName()] = pWnd
	return self[pWnd:getName()]
end


pCreate.initWindowPos = function(self)
	local distance = (self.wnd_hnzz:getWidth() - self.btn_daifu:getWidth() * 3) / 4
	modUIUtil.setClosePos(self.btn_close)
end

pCreate.isHongZhong = function(self)
	return self.currDataIndex == "hzmj"
end

pCreate.isTaoJiang = function(self)
	return self.currDataIndex == "tjmj"
end

pCreate.isDongShan = function(self)
	return self.currDataIndex == "dsmj"
end

pCreate.isPingHe = function ( self )
	return self.currDataIndex == "phmj"
end

pCreate.isZhaoAn = function(self)
	return self.currDataIndex == "zamj"
end

pCreate.isMaoMing = function(self)
	return self.currDataIndex == "mmmj"
end

pCreate.isKawuxing = function(self)
	return self.currDataIndex == "kawuxing"
end

pCreate.isBaiheKawuxing = function(self)
	return self.currDataIndex == "baihekawuxing"
end

pCreate.isTianJin = function(self)
	return self.currDataIndex == "tjtjmj"
end

pCreate.saveData = function(self)
	if not self.saveResult or not self.saveResult[self.currDataIndex] then
		return
	end
	local data = {}
	data[self.currDataIndex] = {}
	data["key"] = self.currDataIndex
	for name, value in pairs(self.saveResult[self.currDataIndex]) do
		data[self.currDataIndex][name] = value
	end
	logv("warn", "save", data)
	data = modJson.encode(data)
	log("info", "save user create room info")

	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	local buff= puppy.pBuffer:new()
	buff:initFromString(data, len(data))

	local ret = ioMgr:save(buff, self:getSaveFilePath(), 0)
	logv("info", "save user create room data write file ret", self:getSaveFilePath())
end

pCreate.getSaveFilePath = function(self)
	return
end

pCreate.loadData = function(self)
	local pApp = puppy.world.pApp.instance()
	local ioMgr = pApp:getIOServer()
	if not ioMgr:fileExist(self:getSaveFilePath()) then
		return nil
	end

	local data = ioMgr:getFileContent(self:getSaveFilePath())
	log("warn", "load file path",  self:getSaveFilePath(), data)
	if data and data ~= "" then
		local setData = modJson.decode(data)
		return setData
	else
		return nil
	end
end

pCreate.showLog = function(self, userCreate)
	--log("info", "createRoomInfo: player:", userCreate["player"], "round:", userCreate["round"], "hostmode", userCreate["hostmode"], "jiepao", userCreate["jiepao"], "tongpao", userCreate["tongpao"], "qianggang:", userCreate["qianggang"], "kechi", userCreate["kechi"], "hongzhong", userCreate["hongzhong"], "bird", userCreate["bird"], "159zhuaniao", userCreate["159zhuaniao"], "liujuzhuang", userCreate["liujuzhuang"], "dama", userCreate["dama"], "baxiaodui", userCreate["baxiaodui"], "dibei", userCreate["dibei"], "self.currDataIndex:", self.currDataIndex)

end

