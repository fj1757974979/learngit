local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modEvent = import("common/event.lua")
local modBattleRpc = import("logic/battle/rpc.lua")

pBeiLv = pBeiLv or class(pWindow)

pBeiLv.init = function(self, host, beiLvNumbers, markName, titleName, initValue)
	self:load("data/ui/beilv.lua")
	self.currBeiLvIndex = initValue or 1
	self.host = host
	self.name = markName or "dibei"
	self.beiLvNumbers = beiLvNumbers
	if not self.beiLvNumbers then 
		self.wnd_beilv:setText(1) 
	else
		self.wnd_beilv:setText(self.beiLvNumbers[self.currBeiLvIndex])
	end
	if titleName then 
		self.wnd_text:setText(titleName)
	end
	self:beiLvEvent(wnd)
end

pBeiLv.beiLvEvent = function(self)
	local count = table.size(self.beiLvNumbers)
	if count <= 0 then return end
	-- 加倍数
	self.btn_p:addListener("ec_mouse_left_down", function() 
		local blcount = self.currBeiLvIndex
		if blcount >= count then return end
		blcount = blcount + 1
		self.currBeiLvIndex = blcount
		self.wnd_beilv:setText(self.beiLvNumbers[blcount])
		self:setValue(self.name, self.beiLvNumbers[blcount], self.name)
	end)

	-- 减倍数
	self.btn_m:addListener("ec_mouse_left_down", function() 
		local blcount = self.currBeiLvIndex
		if blcount <= 1 then return end
		blcount = blcount - 1
		self.currBeiLvIndex = blcount
		self.wnd_beilv:setText(self.beiLvNumbers[blcount])	
		self:setValue(self.name, self.beiLvNumbers[blcount], self.name)
	end)
end

pBeiLv.setValue = function(self, name, value, saveName)
	if not self.host then return end
	self.host:setValue(name, value, saveName)
end

pBeiLv.setBeiLvIndex = function(self, idx)
	if not idx or idx <= 0 then return end
	if not self.beiLvNumbers then return end
	if idx > table.size(self.beiLvNumbers) then return end
	self.currBeiLvIndex = idx
end

pBeiLv.defaultCreateValue = function(self)
	self:setValue(self.name, 1, self.name)
end

pBeiLv.setBeiLvText = function(self, num)
	if not num then return end
	self.wnd_beilv:setText(num)
	self:setValue(self.name, num, self.name)
end

pBeiLv.findIndexInBLNValues = function(self, num)
	if not num then return end
	for idx, n in pairs(self.beiLvNumbers) do
		if n == num then 
			return idx
		end
	end
	return -1
end

pBeiLv.getValueName = function(self)
	return self.name
end
