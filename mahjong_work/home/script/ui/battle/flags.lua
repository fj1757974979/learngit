local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modGamePhase = import("ui/battle/gamephase.lua")

pFlagMenu = pFlagMenu or class(pWindow, pSingleton)

local piaofenTypes = {
	[modLobbyProto.CreateRoomRequest.TAOJIANG] = "dama",
	[modLobbyProto.CreateRoomRequest.HONGZHONG] = "piaofen",
	[modLobbyProto.CreateRoomRequest.RONGCHENG] = "piaofen",
	[modLobbyProto.CreateRoomRequest.ZHAOAN] = "chatai",
}

local T_CARD_TONG = 0
local T_CARD_SUO = 1
local T_CARD_WAN = 2
local prioritysToIndex = {
	[T_CARD_TONG] = 3,
	[T_CARD_SUO] = 2,
	[T_CARD_WAN] = 1,
}

pFlagMenu.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:setZ(C_BATTLE_UI_Z)
	self:setAlignX(ALIGN_RIGHT)
	self:setAlignY(ALIGN_CENTER)
	self.dianControls = {}
	self.controls = {}
	self:setSize(400,100)
	self:setOffsetY(-self:getHeight() * 0.1)
	self:setColor(0)
	self.piaoType = piaofenTypes[modBattleMgr.getCurBattle():getCurGame():getRuleType()]
end

pFlagMenu.open = function(self, flags, wndParent, isPass)
	logv("warn","flags",flags)
	self.flags = flags 
	self:setParent(wndParent)
	self.wndParent = wndParent
	local x = 0
	local y = 0
	local passX = 0
	local scale = 1	
	--判断是否是平和添加游金图标
	local width 
	local height 
	if (modBattleMgr.getCurBattle():getCurGame():getRuleType() == 14) then
		 width = 162 * scale
		 height = 135 * scale
	else
		 width = 87 * scale
		 height = 87 * scale
	end	
	-- 权重
	local curPriority = self:getSelfCardsPriority()	
	local RuleTypePH = modBattleMgr.getCurBattle():getCurGame():getRuleType()
	-- 是否可以过
	if isPass then
		x = - gGameWidth * 0.1		
		local btnPass	
		if (RuleTypePH == 14) then
			btnPass  = self:createButton("pass", passX, 0, "ui:battle/guo.png", 87 * scale, 87 * scale)
		else 
			btnPass  = self:createButton("pass", passX, 0, "ui:battle/guo.png", width, height) 
		end			
		btnPass:setParent(self)
		btnPass:setOffsetX(x)		
		if (RuleTypePH == 14) then
			x = btnPass:getOffsetX() - 10 - 87 * scale
		else 
			x = btnPass:getOffsetX() - 10 - width
		end		
		btnPass:addListener("ec_mouse_click", function() 
			self:callRpc(-1)
		end)
	else		
		--对平和麻将显示进行单独操作
		if(RuleTypePH == 14) then
			local DMWidth, DMHeight = 149 * scale, 131 * scale
			width, height = DMWidth, DMHeight
			x = - (gGameWidth - table.size(self.flags) * width) / 2 + wndParent:getParent():getWidth() * 0.4
		else
			local DMWidth, DMHeight = 187 * scale, 70 * scale
			width, height = DMWidth, DMHeight
			x = - (gGameWidth - table.size(self.flags) * width) / 2 + wndParent:getParent():getWidth() * 0.4
		end
	end
	-- 描画飘分
	local distance = nil
	for index, f in pairs(self.flags) do
		local flagValue = modUIUtil.getFlagValue(f, modBattleMgr.getCurBattle():getCurGame():getRuleType())
		logv("warn",flagValue,"xxxxx")
		if f ~= passIndex and flagValue then
			local image = ""
			-- 描画听
			if f == modGameProto.TING then
				image = "ui:battle/ting.png"
				width, height = 148 * scale, 136 * scale
			elseif f == modGameProto.PINGHE_YOUJIN then			
				image = "ui:battle/youjin_1.png"				
			elseif f == modGameProto.PINGHE_SHUANGYOU then
				image = "ui:battle/shuangyou_1.png"
			elseif f== modGameProto.PINGHE_SIYOU then
				image = "ui:battle/siyou_1.png"
			elseif f == modGameProto.PINGHE_BAYOU then
				image = "ui:battle/bayou_1.png"
			elseif f == modGameProto.PINGHE_HU then
				image = "ui:battle/hu.png"
			elseif f == modGameProto.PINGHE_ROBANGANG then
				image = "ui:battle/qiangangang.png"
			elseif f == -1 then
				image = "ui:battle/guo.png"
				width, height = 87 * scale, 84 * scale
			elseif flagValue then
				image = self:getFlagValueImage(flagValue, f) 
			end
			local btn = self:createButton(f, 0, 0, image, width, height)
			if RuleTypePH == 14 then
				btn:setOffsetX(x - 30)
			else 			
				btn:setOffsetX(x)
			end
			-- 缺flag
			if self:isQueFlag(f) then
				btn:setSize(146, 144)
				if curPriority and prioritysToIndex[curPriority] == index then
					local sp = pSprite()	
					sp:setTexture("effect:priority.fsi", 0)
					sp:setParent(btn)
					sp:setPosition(btn:getWidth()/2, btn:getHeight()/2)
					sp:setScale(4, 4)
					sp:setSpeed(5)
					sp:setZ(-1)
					sp:play(-1, true)					
				end
			end
			if f == modGameProto.TING then
				btn:setAlignY(ALIGN_MIDDLE)
				btn:setOffsetY(0)
			end			

			btn:addListener("ec_mouse_click", function()
				self:callRpc(index - 1, f)
			end)
			if distance then
				x = x - distance - width
			else
				--此处
				if RuleTypePH ~= 14 then
					x = x - width - 10
				end	
				if (RuleTypePH == 14) and (isPass == false) then									
					logv("info","guo",isPass)
					x = x - width - 30
					btn:setSize(149,131)			
					btn:setAlignX(ALIGN_CENTER)					
				end
				if (RuleTypePH == 14) and (isPass == true) then			
					x = x - width - 30
					btn:setSize(149,131)	
					btn:setAlignY(ALIGN_CENTER)
				end
			end
		end
	end
end

pFlagMenu.getSelfCardsPriority = function(self)
	if (not modBattleMgr.getCurBattle():getCurGame():isYunYangMj()) and (not modBattleMgr.getCurBattle():getCurGame():isXueZhanDaoDiMj()) then 
		return
	end
	if not modBattleMgr.getCurBattle():isPhaseDingQue() then
		return
	end
	local modPriority = import("logic/priority.lua")
	local player = modBattleMgr.getCurBattle():getCurGame():getCurPlayer()
	local cards = player:getAllCardsFromPool(T_POOL_HAND)
	local ids = {}
	for _, card in pairs(cards) do
		table.insert(ids, card:getId())
	end
	return modPriority.pPriority:instance():getQuePriority(ids)
end

pFlagMenu.isQueFlag = function(self, f)
	return f == modGameProto.YUNYANG_QUE_TONG or f == modGameProto.YUNYANG_QUE_SUO or f == modGameProto.YUNYANG_QUE_WAN
end

pFlagMenu.getFlagValueImage = function(self, flagValue, f)
	if self.piaoType then
		return "ui:battle/" .. self.piaoType .. "_" ..  flagValue .. ".png"
	else
		local names = {
			[modGameProto.PIAO_A] = "la",
			[modGameProto.PIAO_B] = "la",
			[modGameProto.PIAO_C] = "chuai",
			[modGameProto.PIAO_D] = "chuai",
			[modGameProto.YUNYANG_QUE_TONG] = "quetong",
			[modGameProto.YUNYANG_QUE_SUO] = "quesuo",
			[modGameProto.YUNYANG_QUE_WAN] = "quewan",
		}
		if not names[f] then return "" end
		return "ui:battle/" .. names[f] .. "_" .. flagValue .. ".png"
	end
end

pFlagMenu.callRpc = function(self, idx, sflag) 
	logv("warn","idx",idx,"sflag",sflag)
	modBattleRpc.answerChooseFlag(idx, function(success,reply)
		if success then
			modBattleMgr.getCurBattle():getBattleUI():clearFlagWnd()
		end
	end)	
end


pFlagMenu.createButton = function(self, name, x, y, image, width, height)
    local scale = scale
    local btnYQ = pButton():new()
    btnYQ:setName("btn_flag_" .. name)
    btnYQ:setParent(self)
    btnYQ:setAlignX(ALIGN_RIGHT)
    btnYQ:setAlignY(ALIGN_BOTTOM)
    btnYQ:setPosition(x,y)
    btnYQ:setImage(image)
    btnYQ:setSize(width,height)
    btnYQ:setColor(0xFFFFFFFF)
    self[btnYQ:getName()] = btnYQ
    table.insert(self.controls,btnYQ)
    return btnYQ
end

pFlagMenu.close = function(self)
	self.flags = {}
	self.wndParent = nil
	self:clearControls(self.controls)
	self:clearControls(self.dianControls)
	if self.dianEffect then 
		self.dianEffect:stop()
	end
	if self.effect then
		self.effect:stop()
	end
	if modGamePhase.pGamePhase:getInstance() then
		modGamePhase.pGamePhase:instance():close()
	end
	pFlagMenu:cleanInstance()
end

pFlagMenu.clearControls = function(self, controls)
	for _, wnd in pairs(controls) do
		wnd:setParent(nil)
	end	
	controls = nil
end
