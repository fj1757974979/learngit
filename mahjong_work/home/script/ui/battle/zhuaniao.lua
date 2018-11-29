local modUIUtil = import("ui/common/util.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modEasing = import("common/easing.lua")
local modFunctionManager = import("ui/common/uifunctionmanager.lua")
local modDisMissList = import("ui/battle/dismisslist.lua")
local modBattleMgr = import("logic/battle/main.lua")

pMainZhuaNiao  = pMainZhuaNiao or class(pWindow,pSingleton)

pMainZhuaNiao.init = function(self)
	self:load("data/ui/zhuaniao.lua")
	self:setParent(gWorld:getUIRoot())
	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_BATTLE_UI_Z)
	self.controls = {}
--	modDisMissList.pDisMissList:instance():close()
end

pMainZhuaNiao.open = function(self,message)
	self.message = message
	local cards = self.message.niao_card_ids
	local validCards = self.message.valid_niao_card_ids
	if modBattleMgr.getCurBattle():getRoomInfo()["zhuaniao_count"] ~= 0 then
		self.wnd_card_parent:setSize(self.wnd_card_parent:getWidth() / 2 + (table.getn(cards)-2) * 100 + 40,self.wnd_card_parent:getHeight() / 2 + 10)
		self.wnd_card_parent:setPosition(self.wnd_card_parent:getX() + ((6 - table.getn(cards) - 1) / 2) * 100 + 20,self.wnd_card_parent:getY())
		if table.getn(cards) > 0 then
			self:showCards(cards,validCards)
		else
			modFunctionManager.pUIFunctionManager:instance():stopFunction()
		end
	else
		self.wnd_card_parent:showSelf(false)
	end
end

pMainZhuaNiao.close = function(self)
	for _,c in pairs(self.controls) do
		c:setParent(nil)
	end
	self.controls = nil
	self.message = nil
	pMainZhuaNiao:cleanInstance()
end



pMainZhuaNiao.showCards = function(self,cards,validCards)
	local count = table.size(cards)
	local scale = 3
	local width = 100 * scale
	local height = 139 * scale
	local x = - (width / scale) / 2
	local y = 0 - ((height * scale - height) / 8) - 50 
	local cardWnds = {}
	local cardGui = {}
	for k,v in ipairs(cards) do
		local wnd = self:createWnd(k,x,y,"ui:card/2/show_" .. v .. ".png",width,height)
		local isDi = false
		if v == modBattleMgr.getCurBattle():getCurGame():getDiCardId() then
			isDi = true
		end
		if self:isMagicCard(v) or isDi then
			local wnd_gui = self:createWnd("magic_" .. k, -3.5, 38, "ui:calculate_gui.png", 81, 102)
			if isDi then
				wnd_gui:setImage("ui:calculate_di.png")
			end
			wnd_gui:setColor(0xFFEEEE00)
			wnd_gui:showSelf(false)
			wnd_gui.index = k
			wnd_gui:setParent(wnd)
			wnd_gui:setAlignX(ALIGN_LEFT)
			table.insert(cardGui,wnd_gui)
		end
		wnd:showSelf(false)
		wnd.isValid = false
		if validCards then
			for _,valid in pairs(validCards) do
				if valid == v or self:isMagicCard(v) then
					wnd.isValid = true
					break
				end
			end
		end
		table.insert(cardWnds,wnd)
		x = x + width / scale
	end
	self:timeOut(1,nil,function() runProcess(1,function()
		local endTime = 30
		local endWidth = 100
		local endHeight = 139
		local endX = 28 
		local endY = 0 + 10 + 13
		cardWnds[1]:showSelf(true)
		for idx,wnd in pairs(cardWnds) do
			local startPosX = wnd:getX()
			local distanceX = endX - startPosX
			local startPosY = wnd:getY()
			local distanceY = endY - startPosY
			local startWidth = endWidth * scale
			local distanceWidth = endWidth - startWidth
			local startHeight = endHeight * scale
			local distanceHeight = endHeight - startHeight
			local guiStartX = -3
			local guiDistanceX = -2 - guiStartX 
			local guiStartY =  38 * scale
			local guiDistanceY = 38 - guiStartY
			local guiStartWidth = 81 * scale
			local guiDistanceWidth = 81 - guiStartWidth
			local guiStartHeight = 102 * scale
			local guiDistanceHeight = 102 - guiStartHeight
			for i = 1,endTime do
				local nx = modEasing.outElastic(i,startPosX,distanceX,endTime)
				local ny = modEasing.outElastic(i,startPosY,distanceY,endTime)
				local nw = modEasing.outElastic(i,startWidth,distanceWidth,endTime)
				local nh = modEasing.outElastic(i,startHeight,distanceHeight,endTime)
				local gw = modEasing.outElastic(i,guiStartWidth,guiDistanceWidth,endTime)
				local gh = modEasing.outElastic(i,guiStartHeight,guiDistanceHeight,endTime)
				local gx = modEasing.outElastic(i,guiStartX,guiDistanceX,endTime)
				local gy = modEasing.outElastic(i,guiStartY,guiDistanceY,endTime)

				wnd:setPosition(nx,ny)
				wnd:setSize(nw,nh)
				for _,gui in pairs(cardGui) do
					if gui.index == idx then
						gui:showSelf(true)
						gui:setSize(gw,gh)
						gui:setPosition(gx,gy)
					end
				end
				--yield()
			end
			if wnd.isValid then
				wnd:setColor(0xFFEEEE00)
			end
			if idx < table.getn(cardWnds) then
				cardWnds[idx + 1]:showSelf(true)
			end
			endX = endX + endWidth
		end
		self:timeOut(60,nil,function()
			modFunctionManager.pUIFunctionManager():instance():stopFunction()
			self:close()
		end)
	end)
end)

end


pMainZhuaNiao.createWnd = function(self,id,x,y,image_path,width,height,text)
	local wnd = pWindow():new()
	wnd:setName("wnd_niao_" .. id)
	wnd:setParent(self.wnd_card_parent)
	wnd:setPosition(x,y)
	wnd:setAlignX(ALIGN_LEFT)
	wnd:setAlignY(ALIGN_TOP)
	if text then
		wnd:setText(text)
	end
	wnd:getTextControl():setFontSize(45)
	wnd:getTextControl():setAlignX(ALIGN_RIGHT)
	wnd:getTextControl():setAlignY(ALIGN_BOTTOM)
	wnd:getTextControl():setAutoBreakLine(false)
	if image_path then
		wnd:setColor(0xFFFFFFFF)
		wnd:setImage(image_path)
	else
		wnd:setColor(0)
	end
	wnd:setSize(width,height)
	return wnd
end

pMainZhuaNiao.getInt = function(self,x)
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


pMainZhuaNiao.timeOut = function(self,endTime,doSomething,afterDo)
	local time = endTime
	runProcess(1,function()
		for i = 1,time do
			if doSomething then
				doSomething(i)
			end
			yield()	
		end
		if afterDo then
			afterDo()
		end
	end)
end

pMainZhuaNiao.isMagicCard = function(self, id)
	local cards = modBattleMgr.getCurBattle():getCurGame():getMagicCard()
	if not cards then return end
	local result = false
	for _, mId in pairs(cards) do
		if id == mId then
			result = true
			break
		end
	end
	return result
end
