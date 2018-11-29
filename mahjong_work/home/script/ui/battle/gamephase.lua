local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modUtil = import("util/util.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")

pGamePhase = pGamePhase or class(pWindow, pSingleton)

pGamePhase.init = function(self)
	self.controls = {}
	self.dianControls = {}
	self:setColor(0)
	self:setZ(C_BATTLE_UI_Z)
end

pGamePhase.open = function(self, wndParent, phase, isNotBg)
	self:setParent(wndParent)
	self.wndParent = wndParent
	self:setSize(wndParent:getWidth(), wndParent:getHeight())
	self:setOffsetY(self:getHeight() * 0.1)
	self.phase = phase
	self.piaoType = self:getBattleUI():getPiaoType()
	if isNotBg then return end
	local bgWnd = self:createBG()
	self:drawDian(bgWnd, 1)
	modUIUtil.makeModelWindow(self, false, false)
end

pGamePhase.createBG = function(self)
	local scale = 1
	local bg = pWindow:new() 
	bg:setName("bg")
	bg:setParent(self)
	bg:setPosition(0, - gGameHeight * 0.55)
	bg:setOffsetX(-(gGameWidth - bg:getWidth()) / 2 + gGameWidth * 0.1)
	bg:setImage("ui:battle/" .. self.piaoType .."_title.png")
	bg:setSize(306 * scale, 133 * scale)
	bg:setColor(0xFFFFFFFF)
	self[bg:getName()] = bg
	table.insert(self.controls, bg)
	return bg
end

pGamePhase.drawDian = function(self, pWnd, count)
	local fream = modUtil.s2f(0.2)
	self.dianEffect = modUIUtil.timeOutDo(fream, nil, function() 
		if count > 3 then
			self:clearControls(self.dianControls)
			count = 1
		else
			local width, height = 27, 32
			local dianWnd = pWindow:new()
			dianWnd:setName("dama_dian_" .. count)
			dianWnd:setParent(pWnd)
			dianWnd:setAlignY(ALIGN_CENTER)
			dianWnd:setPosition(pWnd:getWidth() + 10 + (count - 1) * width + (count - 1) * 20, 0)
			dianWnd:setSize(width, height)
			dianWnd:setImage("ui:battle/piao_dian.png")
			dianWnd:setColor(0xFFFFFFFF)
			self[dianWnd:getName()] = dianWnd
			count = count + 1
			table.insert(self.dianControls, dianWnd)
		end
		self.effect = modUIUtil.timeOutDo(fream, nil, function() self:drawDian(pWnd, count) end)
	end)	
end

pGamePhase.close = function(self)
	self:clearControls(self.controls)
	self:clearControls(self.dianControls)
	if self.dianEffect then 
		self.dianEffect:stop()
	end
	if self.effect then
		self.effect:stop()
	end
	self.wndParent = nil
	self.piaoType = nil
	pGamePhase:cleanInstance()
end

pGamePhase.clearControls = function(self, controls)
	for _, wnd in pairs(controls) do
		wnd:setParent(nil)
	end	
	controls = nil
end

pGamePhase.getCurGame = function(self)
	return modBattleMgr.getCurBattle():getCurGame()
end

pGamePhase.getBattleUI = function(self)
	return modBattleMgr.getCurBattle():getBattleUI()
end
