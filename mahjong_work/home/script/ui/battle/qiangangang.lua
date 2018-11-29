local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modEasing = import("common/easing.lua")
local modUserPropCache = import("logic/userpropcache.lua")

pAnGang = pAnGang or class(pWindow, pSingleton)

pAnGang.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:setZ(-10000)
	-- self:setAlignX(ALIGN_CENTER)
	-- self:setAlignY(ALIGN_CENTER)
	-- self:setOffsetX(-gGameWidth * 0.1)
	-- self:setOffsetY(-15)	
	self:setPosition(-890,-470)
	self:setImage("ui:angangzhong_bg.png")
	self:setSize(1152, 595)	
	self.controls = {}
	self.propData = {}		
end

pAnGang.open = function(self, message, wndParent)
	self.player_to_angang = message.player_to_angang		
	self:setParent(wndParent)
	self.wndParent = wndParent		
	self.keyCards = {}	
	self:drawMaJiangBtn()		
end

pAnGang.drawMaJiangBtn = function(self)
	self.btnControl = {}
	local angangWidth, angangHeight = 192, 114
	local angangImage = "ui:majiangdui.png"	
	local px,py = 200, 140
	local y = 120

	--获取头像框
	-- local headX,headY = 80, 80
	local headPosX = -188
	local plid
	for i,pta in ipairs(self.player_to_angang) do
		logv("warn","pta",pta.angang_id,pta.player_id)
		plid = pta.player_id
		local x = -80								
		for j,id in ipairs (pta.angang_id) do
			if pta.angang_id then
				x = x + px
			end
			logv("warn","id",id)
			local btn = self:createButton(sf("angang%d%d", i, j), x, y, angangImage, angangWidth, angangHeight)			
			btn:addListener("ec_mouse_click", function()
				logv("warn","id",id,"plid",plid)				 						
				self:clickMaJiangDui(id,plid)
				btn.player_id = plid
				btn.angang_id = id			
			end)
		end
		self:createHeadImage(plid,y)		
		-- logv("warn",plid)
		-- local seatIdByPlayerId = modBattleMgr.getCurBattle():getSeatIdByPlayerId(plid)
		-- logv("warn",seatIdByPlayerId)
		-- local seatToUid = modBattleMgr.getCurBattle():getSeatToUid()		
		-- logv("warn",seatToUid[seatIdByPlayerId])
		-- local prop = modUserPropCache.getCurPropCache():getProp(seatToUid[seatIdByPlayerId])		
		-- if prop then			
		-- 	logv("warn",prop["avatarUrl"],"opop")		
		-- 	if prop["avatarUrl"] then										
		-- 		local haedImageWnd = self:createWnd(sf("player_%d",plid),30,y+15,"ui:battle_image_bg.png",headX,headY)
		-- 		local headImage = self:createWnd(sf("player_image%d",plid),30,y + 15,prop["avatarUrl"],headX - 5,headY - 5)
		-- 		headImage:setParent(haedImageWnd)
		-- 		headImage:setAlignX(ALIGN_CENTER)
		-- 		headImage:setAlignY(ALIGN_CENTER)
		-- 	end		
		-- end	
		if pta.angang_id then
			y = y + py
		end			
	end	
end

pAnGang.createHeadImage = function (self,plid,y)
	local headX,headY = 80, 80	
	local seatIdByPlayerId = modBattleMgr.getCurBattle():getSeatIdByPlayerId(plid)
	logv("warn",seatIdByPlayerId)
	local seatToUid = modBattleMgr.getCurBattle():getSeatToUid()		
	logv("warn",seatToUid[seatIdByPlayerId])
	--判断是否是断线重连
	--[[
	local prop 
	if modBattleMgr.getCurBattle():isReconnect() == false then
		prop = modUserPropCache.getCurPropCache():getProp(seatToUid[seatIdByPlayerId])
		logv("warn","true")
		if not self.propData[plid] then
			table.insert(self.propData,plid,prop)
			logv("warn",self.propData[plid])
			logv("warn",self.propData[1])			
		end		
	elseif modBattleMgr.getCurBattle():isReconnect() == true then
		logv("warn","false")
		logv("warn",self.propData[1])
		logv("warn",self.propData[plid])
		if self.propData[plid] then
			prop = self.propData[plid]
		end
	end
		logv("warn",prop,"prop")		
	if prop then		
		if prop["avatarUrl"] then						
			local haedImageWnd = self:createWnd(sf("player_%d",plid),30,y,"ui:battle_image_bg.png",headX,headY)
			local headImage = self:createWnd(sf("player_image%d",plid),30,y,prop["avatarUrl"],headX - 5,headY - 5)
			headImage:setParent(haedImageWnd)
			headImage:setAlignX(ALIGN_CENTER)
			headImage:setAlignY(ALIGN_CENTER)
		end
		local nameWnd = self:createWnd(sf("wnd_role_%d",plid),30,y + 80,"ui:angang_username_bg.png",80,30)	
		if nameWnd and prop["userName"]	then		
			nameWnd:setText(prop["userName"])
		end
	end	
	]]--
	
	local player = modBattleMgr.getCurBattle():getPlayerByPlayerId(plid)
	player:bind("avatarUrl", function(avatarUrl)
		local haedImageWnd = self:createWnd(sf("player_%d",plid),30,y,"ui:battle_image_bg.png",headX,headY)
		local headImage = self:createWnd(sf("player_image%d",plid),30,y,player:getAvatarUrl(),headX - 5,headY - 5)
		headImage:setParent(haedImageWnd)
		headImage:setAlignX(ALIGN_CENTER)
		headImage:setAlignY(ALIGN_CENTER)
	end)
	player:bind("nickName", function(nickName)
		local nameWnd = self:createWnd(sf("wnd_role_%d",plid),20,y + 80,"ui:angang_username_bg.png",100,30)	
		nameWnd:setText(player:getName())
	end)
end

pAnGang.dealAngangData = function ( self, message )
	logv("warn",message.card_id)
	logv("warn",message.is_hu)
	logv("warn",message.player_id)
	logv("warn",message.angang_id)
	--根据id翻牌，显示翻开的麻将
	-- 根据message里的playerid和暗杠id找到btn
	-- 便利self.btnControl
	-- btn.player_id == playerid && btn.angangid == angengid
	-- btn = btn	 
	for _,btn in ipairs(self.controls) do
		logv("warn",btn.player_id,btn.angang_id)
		if(btn.player_id == message.player_id and btn.angang_id == message.angang_id) then			
			local angangcard = self:createWnd("angangcard",0,0,sf("ui:card/2/show_%d.png", message.card_id),43,66)
			angangcard:setParent(btn)
			angangcard:setAlignX(ALIGN_CENTER)
			angangcard:setAlignY(ALIGN_CENTER)
			angangcard:setOffsetY(-12)
		end
	end
	setTimeout(30,function (  )
		if message.is_hu then
			--提示抢杠成功
			local qianggang_successTip = self:createWnd("successTip",0,0,"ui:qianggang_success.png",249,141)			
			qianggang_successTip:setAlignY(ALIGN_CENTER)
			qianggang_successTip:setAlignX(ALIGN_CENTER)
			-- self:moveTip(qianggang_successTip)
		else
			--提示抢杠失败
			local qianggang_failTip = self:createWnd("successTip",0,0,"ui:qianggang_fail.png",249,141)			
			qianggang_failTip:setAlignY(ALIGN_CENTER)
			qianggang_failTip:setAlignX(ALIGN_CENTER)
			-- self:moveTip(qianggang_failTip)
		end
		setTimeout(30,function ( )
			self:close()
		end)
	end)	
end

--移动提示语
pAnGang.moveTip = function ( self, createWnd)
	logv("warn",createWnd:getX())
	logv("warn",createWnd:getY())
	logv("warn","pMenu.moveTip")
	runProcess(1,function()
		local fpx = 0
		local fpy = 0	
		local tpx = 0
		local tpy = -500
		local du = 60
		for i = 0, du do 
			local x = modEasing.linear(i,fpx,tpx - fpx,du)
			local y = modEasing.linear(i,fpy,tpy - fpy,du)
			createWnd:setPosition(x,y)
			yield()
		end
	end)
end

pAnGang.clickMaJiangDui = function (self,angang_id,player_id )
	logv("warn",angang_id,player_id)
	self:rpcChooseAnGang(angang_id,player_id)
end

pAnGang.isInsert = function(self, t, id)
	for _, i in pairs(self.keyCards[t]) do
		if i == id then
			return false
		end
	end
	return true
end

pAnGang.callRpc = function(self, idx, comb)
	self:getCurBattle():getBattleUI():combOnChoose(idx, comb, self)
end

pAnGang.rpcChooseAnGang = function(self, agidx,plid)
	logv("warn","pMenu.rpcChooseAnGang",agidx,plid)
	self:getCurGame():rpcChooseAngang(agidx, plid)
	-- self:close()
end

pAnGang.close = function(self)	
	for k,v in pairs(self.controls) do
		v:setParent(nil)
	end	
	self.controls = {}
	self.wndParent = nil			
	pAnGang:cleanInstance()
end

pAnGang.createButton = function(self, name, x, y, image, width, height)
    local scale = scale
    local btnYQ = pButton():new()
    btnYQ:setName("btn_" .. name)
    btnYQ:setParent(self)
    -- btnYQ:setAlignX(ALIGN_RIGHT)
    -- btnYQ:setAlignY(ALIGN_CENTER)
    btnYQ:setPosition(x, y)
    btnYQ:setImage(image)
    btnYQ:setSize(width, height)
    btnYQ:setColor(0xFFFFFFFF)
    self[btnYQ:getName()] = btnYQ
    table.insert(self.controls, btnYQ)
    return btnYQ
end

pAnGang.createWnd = function(self, name, x, y, image, width, height)
	local wnd = pWindow:new()
	wnd:setName("wnd_key_" .. name)
	wnd:setParent(self)
	-- wnd:setAlignX(ALIGN_RIGHT)
	-- wnd:setAlignY(ALIGN_CENTER)
	wnd:setPosition(x or 0, y or 0)
	wnd:setImage(image)
	wnd:setSize(width or 50, height or 50)
	wnd:setColor(0xFFFFFFFF)
	self[wnd:getName()] = wnd
	table.insert(self.controls, wnd)
	return wnd
end

pAnGang.getCurBattle = function(self)
	return modBattleMgr.getCurBattle()
end

pAnGang.getCurGame = function(self)
	return modBattleMgr.getCurBattle():getCurGame()
end
