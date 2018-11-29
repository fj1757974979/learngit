local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")

pMingGuo = pMingGuo or class(pWindow, pSingleton)

pMingGuo.init = function(self)
	self:load("data/ui/mingguo.lua")
	self:setParent(gWorld:getUIRoot())
	self:setZ(C_BATTLE_UI_Z)
	self.isMing = true
	self:canelEvent()
	if modBattleMgr.getCurBattle():getCurGame():isRongChengMJ() then
		self.btn_ming:setImage("ui:battle/ting.png")
		self.btn_ming:setSize(148, 136)
	end
	self:setPosition(-gGameWidth * 0.1, -gGameHeight * 0.05)
end

pMingGuo.open = function(self, pWnd)
	self:setParent(pWnd)
	self.btn_ming:addListener("ec_mouse_click", function() 
		self:mingEvent()
	end)

	self.btn_cancel:addListener("ec_mouse_click", function() 
		self:canelEvent()
	end)

	self.btn_guo:addListener("ec_mouse_click", function()
		-- 不能打的牌压暗
		modBattleMgr.getCurBattle():getBattleUI():notInDiscardListSetTingColor()
		self:close()
	end)
end

pMingGuo.mingEvent = function(self)
	if self.isMing then return end
	self.isMing = true
	
	local battle = modBattleMgr.getCurBattle()
	local battleUI = battle:getBattleUI()
	-- ui ming状态
	battleUI:setIsMingState(true)
	-- 隐藏取消按钮
	self.btn_cancel:show(true)
	self.btn_ming:show(false)
	self.btn_guo:show(false)
	-- 颜色
	battleUI:updateCardIsShow(-1, true)
	-- 设置建议打牌以外的牌为暗色
	battleUI:setSuggestionTingColor()

end

pMingGuo.canelEvent = function(self)
	if not self.isMing then return end
	self.isMing = false
	-- 隐藏按钮
	self.btn_ming:show(true)
	self.btn_cancel:show(false)
	self.btn_guo:show(true)
	local battle = modBattleMgr.getCurBattle()
	local battleUI = battle:getBattleUI()
	battleUI:setIsMingState(false)
	-- 颜色
	battleUI:updateCardIsShow(-1, true)
	-- 不能打的压暗
	battleUI:notInDiscardListSetTingColor()
end

pMingGuo.getIsMingState = function(self)
	return self.isMing
end

pMingGuo.changeMingState = function(self)
	self.isMing = not self.isMing
end

pMingGuo.close = function(self)
	self.isMing = false
	pMingGuo:cleanInstance()
end
