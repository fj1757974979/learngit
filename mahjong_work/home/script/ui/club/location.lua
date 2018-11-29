local modUIUtil = import("ui/common/util.lua")
local modWndList = import("ui/common/list.lua")
local modProvince = import("data/info/info_club_province.lua")
local modCity = import("data/info/info_club_city.lua")

local T_CODE_PROVINCE = 1
local T_CODE_CITY = 2

pClubLocation = pClubLocation or class(pWindow, pSingleton)

pClubLocation.init = function(self)
	self:load("data/ui/club_location.lua")
	self:setParent(gWorld:getUIRoot())
	
	self:initUI()
	self:regEvent()
	modUIUtil.makeModelWindow(self, false, true)
end

pClubLocation.initUI = function(self)
	self.txt_choosen:setText(TEXT("所在地"))
	self.btn_province:setText(TEXT("省"))
	self.btn_city:setText(TEXT("市"))
	self.provinceCode = nil
	self.cityCode = nil
	--self.btn_ok:setText(TEXT("确定"))
end

pClubLocation.regEvent = function(self)
	self.btn_province:addListener("ec_mouse_click", function() 
		self:showProvince()
	end)

	self.btn_city:addListener("ec_mouse_click", function() 
		self.cityCode = nil
		self.btn_city:setText("市")
	end)

	self.btn_ok:addListener("ec_mouse_click", function()
		if self.callback then
			self.callback(self.provinceCode, self.cityCode or 0)
		end
		self:close()
	end)
end

pClubLocation.open = function(self, host, callback)
	self.host = host
	self.callback = callback
	self:showProvince()
end

pClubLocation.showProvince = function(self)
	self:initUI()
	local provinces = modProvince.data
	self:showCards(provinces, T_CODE_PROVINCE)
end

pClubLocation.initCitys = function(self)
	self.cityCode = nil
	self.btn_city:setText("市")
end

pClubLocation.showCitys = function(self, provinceCode)
	if not provinceCode then return end
	local citys = self:findCityData(provinceCode)
	if not citys or table.getn(citys) <= 0 then return end
	self:showCards(citys, T_CODE_CITY)
end

pClubLocation.findCityData = function(self, provinceCode)
	if not provinceCode then return end
	local modCitys = import("data/info/info_club_city.lua")
	local citys = {}
	for _, data in pairs(modCitys.data) do
		if data["province_code"] == provinceCode then
			table.insert(citys, data)
		end
	end
	return citys
end

pClubLocation.showCards = function(self, datas, cardt)
	if not datas or not cardt then return end
	-- 先清除
	self:clearCards()
	self:clearDragWnd()
	self:clearWindowList()
	-- 活动窗口
	self.dragWnd = self:newListWnd()
	self.windowList = modWndList.pWndList:new(self.wnd_list:getWidth(), self.wnd_list:getHeight(), 1, 0, 0, T_DRAG_LIST_VERTICAL)
	local scale = 1
	local w, h = 160 * scale, 66 * scale
	local maxX = 3
	local dx, dy = (self.wnd_list:getWidth() - maxX * w) / (maxX + 1), 5
	local x, y = dx, dy
	-- 描画
	for index, data in pairs(datas) do
		local wnd = self:newCard(x, y, cardt, data["code"], data["name"])
		x = x + dx + wnd:getWidth()
		if index % maxX == 0 then
			x = dx
			y = y + wnd:getHeight() + dy
		end
	end
	-- 设置滑动窗口
	self.dragWnd:setSize(self.wnd_list:getWidth(), y + 200)
	self.windowList:addWnd(self.dragWnd)
	self.windowList:setParent(self.wnd_list)
end

pClubLocation.newCard = function(self, x, y, cardt, code, name)
	local wnd = pWindow:new()
	wnd:load("data/ui/club_location_card.lua")
	wnd:setPosition(x, y)
	wnd:setParent(self.dragWnd)
	wnd.btn_location:setText(name or  "")
	wnd["cardt"] = cardt
	if not self.cardControls then self.cardControls = {} end
	wnd.btn_location:addListener("ec_mouse_click", function() 
		if wnd["cardt"] == T_CODE_PROVINCE then
			self:provinceClick(code, name)
		elseif wnd["cardt"] == T_CODE_CITY then
			self:cityClick(code, name)
		end
--		self:setBtnColor(wnd)
	end)
	table.insert(self.cardControls, wnd)
	return wnd
end

pClubLocation.setBtnColor = function(self, btn)
	if not btn then return end
	for _, b in pairs(self.cardControls) do
		if btn == b then
			b:setColor(0xFFEEEE00)
		else
			b:setColor(0xFFFFFFFF)
		end
	end
end

pClubLocation.provinceClick = function(self, code, name)
	self.provinceCode = code
	self.btn_province:setText(name)
	self:showCitys(code)
end

pClubLocation.cityClick = function(self, code, name)
	self.cityCode = code
	self.btn_city:setText(name)
end

pClubLocation.clearCards = function(self)
	if not self.cardControls then return end
	for _, wnd in pairs(self.cardControls) do
		wnd:setParent(nil)
	end
	self.cardControls = nil
end

pClubLocation.close = function(self)
	self.provinceCode = nil
	self.cityCode = nil
	self.callback = nil
	self.host = nil
	self:clearDragWnd()
	self:clearWindowList()
	pClubLocation:cleanInstance()
end

pClubLocation.newListWnd = function(self)
	local pWnd = pWindow:new()
	pWnd:setSize(100, 100)
	pWnd:setParent(self.club_list)
	pWnd:setPosition(0,0)
	pWnd:setColor(0)
	return pWnd 
end

pClubLocation.clearDragWnd = function(self)
	if self.dragWnd then
		self.dragWnd:setParent(nil)
		self.dragWnd = nil
	end
end

pClubLocation.clearWindowList = function(self)
	if self.windowList then
		self.windowList:destroy()
	end
	self.windowList = nil
end
