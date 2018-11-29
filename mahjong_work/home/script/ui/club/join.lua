local modClubMgr = import("logic/club/main.lua")
local modWndList = import("ui/common/list.lua")
local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modProvince = import("data/info/info_club_province.lua")
local modCity = import("data/info/info_club_city.lua")
local modClubInfo = import("ui/club/join_club_info.lua")
local modClubObj = import("logic/club/club.lua")

pClubJoin = pClubJoin or class(pWindow, pSingleton)

pClubJoin.init = function(self)
	self:load("data/ui/club_join.lua")
	self:setParent(gWorld:getUIRoot())
	--self.btn_search:setText(TEXT("搜索"))
	self.txt_id:setText(TEXT("通过俱乐部ID搜索"))
	self.txt_name:setText(TEXT("通过俱乐部名称搜索"))
	self.txt_location:setText(TEXT("点击选择地区"))
	self.edit_id:set_max_input_str_len(10)
	self.edit_name:set_max_input_str_len(20)
	self:initUI()
	self:regEvent()
	modUIUtil.makeModelWindow(self, false, true)
end

pClubJoin.initUI = function(self)
	self.edit_id:setupKeyboardOffset(gWorld:getUIRoot())
	self.edit_name:setupKeyboardOffset(gWorld:getUIRoot())
end

pClubJoin.regEvent = function(self)

	self.edit_id:addListener("ec_focus", function() 
		self.txt_id:setText("")
	end)

	self.edit_id:addListener("ec_unfocus", function()
		local text = self.edit_id:getText()
		if not text then
			self.txt_id:setText(TEXT("通过俱乐部ID搜索"))
		end
	end)

	self.edit_name:addListener("ec_focus", function() 
		self.txt_name:setText("")
	end)

	self.edit_name:addListener("ec_unfocus", function()
		local text = self.edit_name:getText()
		if not text then
			self.txt_name:setText(TEXT("通过俱乐部名称搜索"))
		end
	end)

	self.btn_close:addListener("ec_mouse_click", function()
		self:close()
	end)

	self.btn_search:addListener("ec_mouse_click", function() 
		self:searchClub()
	end)

	self.btn_location:addListener("ec_unfocus", function() 
		local txt = self.btn_location:getText()
		if not txt and (not self.provinceCode) then
			self.txt_location:setText(TEXT("点击选择地区"))
		end
	end)

	self.btn_location:addListener("ec_mouse_click", function() 
		self.txt_location:setText("")
		local modLocaltion = import("ui/club/location.lua")
		modLocaltion.pClubLocation:instance():open(self, function(provinceCode, cityCode) 
			self:selectedCode(provinceCode, cityCode)
		end)
	end)
end

pClubJoin.selectedCode = function(self, provinceCode, cityCode)
	if not provinceCode then return end
	self.provinceCode = provinceCode
	self.cityCode = cityCode
	local provinceData = self:findData(provinceCode, modProvince.data)
	local cityData = self:findData(cityCode, modCity.data)
	if not provinceData then return end
	if not cityData then
		self.btn_location:setText(provinceData["name"])
	else
		self.btn_location:setText(provinceData["name"] .. "-" .. cityData["name"])
	end
	self.txt_location:setText(TEXT(""))
	self:searchClub()
end

pClubJoin.findData = function(self, code, datas)
	if not code or not datas then return end
	for _, data in pairs(datas) do
		if data["code"] == code then
			return data
		end
	end
	return nil
end

pClubJoin.open = function(self)
end

pClubJoin.setEditId = function(self, id)
	if not id then return end
	self.edit_id:setText(id)
end

pClubJoin.searchClub = function(self)
	-- check
	local list = {
		["id"] = self.edit_id:getText(),
		["province_code"] = self.provinceCode,
		["club_name"] = self.edit_name:getText(),
	}
	if not list["id"] and not list["province_code"] and not list["club_name"] then
		infoMessage("请输入搜索信息")
		return
	end

	-- Id 
	local id = nil
	if not list["id"] then
		local text = self.edit_name:getText()
		if not text or text == "" then
			-- 没有id 按省份查找
			self:searchByPro()
		else
			self:searchByName()
		end
		return
	end
	id = tonumber(self.edit_id:getText())
	if not id then 
		-- 没有id 按省份查找
		self:searchByPro()
		return 
	end
	self:getSearchClubInfos({ id })
end

pClubJoin.searchByPro = function(self)
	if not self.provinceCode then 
		infoMessage("请选择地区")
		return 
	end
	-- 名称
	local name = nil

	-- 所在地
	modClubRpc.searchClubs(self.provinceCode, self.cityCode, name, function(success, reason, reply) 
		if success then
			local ids = {}
			for _, id in ipairs(reply.club_ids) do
				table.insert(ids, id)
			end
			self:getSearchClubInfos(ids)
		else
			infoMessage(reason)
		end
	end)						
end

pClubJoin.searchByName = function(self)
	local name = self.edit_name:getText()
	modClubRpc.searchClubByName(name, function(success, reason, reply)
		if success then
			local ids = {}
			for _, id in ipairs(reply.club_ids) do
				table.insert(ids, id)
			end
			self:getSearchClubInfos(ids)
		else
			infoMessage(reason)
		end
	end)
end

pClubJoin.getSearchClubInfos = function(self, ids)
	if not ids or table.getn(ids) <= 0  then 
		infoMessage("没有找到对应的俱乐部，俱乐部的ID或者名称是不是错啦？")
		return 
	end
	modClubRpc.getClubInfos(ids, function(success, reason, reply)
		if success then
			local clubs = {}
			for _, club in ipairs(reply.clubs) do
				table.insert(clubs, modClubObj.pClubObj:new(club))
			end
			self:showClubInfos(clubs)
		else
			infoMessage(reason)
		end
	end)		
end

pClubJoin.showClubInfos = function(self, infos)
	if not infos then return end
	-- 先清除
	self:refreshClear()
	-- 滑动窗口
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self.club_list:getWidth(), self.club_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)

	local y = 10
	for index, info in ipairs(infos) do
		local wnd = self:newClubInfoWnd(info, y)
		y = y + wnd:getHeight() + 10
	end
	self.dragWnd:setSize(self.dragWnd:getWidth(), y + 200)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self.club_list)
end

pClubJoin.newClubInfoWnd = function(self, info, y)
	if not info then return end
	if not self.infoControls then self.infoControls = {} end
	local wnd = modClubInfo.pJoinClubInfo:new(info, self)
	wnd:setAlignX(ALIGN_LEFT_RIGHT)
	wnd:setAlignY(ALIGN_TOP)
	wnd:setPosition(0, y)
	wnd:setParent(self.dragWnd)
	table.insert(self.infoControls, wnd)	
	return wnd
end

pClubJoin.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(200, 200)
	pWnd:setParent(self.club_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pClubJoin.clubClick = function(self, clubWnd)
	if not clubWnd then return end
	clubWnd:clubClick()
end

pClubJoin.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pClubJoin.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end

pClubJoin.clearInfoControls = function(self)
	if not self.infoControls then return end
	for _, wnd in pairs(self.infoControls) do
		wnd:setParent(nil)
	end
	self.infoControls = {}
end

pClubJoin.refreshClear = function(self)
	self:clearInfoControls()
	self:clearDragWnd()
	self:clearWindowList()
	self:initUI()
end

pClubJoin.close = function(self)
	self:refreshClear()
	pClubJoin:cleanInstance()
end
