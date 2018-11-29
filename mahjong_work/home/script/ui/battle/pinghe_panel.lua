local modMainPanel = import("ui/battle/main.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modEasing = import("common/easing.lua")
local mainPanelName = modMainPanel.pBattlePanel

pPinghePanel = pPinghePanel or class(modMainPanel.pBattlePanel)

pPinghePanel.init = function(self)
	logv("warn","pPingHePanel.init")
	modMainPanel.pBattlePanel.init(self)		
end

pPinghePanel.destroy = function(self)
	modMainPanel.pBattlePanel.destroy(self)
end

pPinghePanel.initCardSizes = function(self)
	self.handSizes = {
		[T_SEAT_MINE] = {100, 139},
		[T_SEAT_RIGHT] = {36 * 1.8, 72 * 1.8},
		[T_SEAT_OPP] = {100, 139},
		[T_SEAT_LEFT] = {36 * 1.8, 72 * 1.8},
	}
	self.showSizes = {
		[T_SEAT_MINE] = {100 * 0.90, 139 * 0.90},
		[T_SEAT_RIGHT] = {134 * 0.7, 104 * 0.7},
		[T_SEAT_OPP] = {100 * 0.9, 139 * 0.9},
		[T_SEAT_LEFT] = {134 * 0.7, 104 * 0.7},
	}
	self.DiscardSizes = {
		[T_SEAT_MINE] = {100 * 0.55, 139 * 0.55},
		[T_SEAT_RIGHT] = {134 * 0.43, 104 * 0.43},
		[T_SEAT_OPP] = {100 * 0.5, 139 * 0.5},
		[T_SEAT_LEFT] = {134 * 0.43, 104 * 0.43},
	}
end

pPinghePanel.setCardImage = function(self, card, cardSeat, id,testChangeCardList)
	local ruleStr = self:getRuleStr()																			
	if (string.find(ruleStr,"四金版") and not testChangeCardList ) then
		--平和 id为1时为圆筒，修改为白板			
		if id == 0 then				
			card:setImage(sf("ui:card/%d/show_%d.png", cardSeat, id + 33))
		else
			card:setImage(sf("ui:card/%d/show_%d.png", cardSeat, id - 1))
		end
	elseif (string.find(ruleStr,"三金版") and not testChangeCardList ) then
		card:setImage(sf("ui:card/%d/show_%d.png", cardSeat, id))	
	else		
		-- modMainPanel.pBattlePanel.setCardImage(self,card, cardSeat, id,testChangeCardList)
		card:setImage(sf("ui:card/%d/show_%d.png", cardSeat, id))		
	end		
end

pPinghePanel.setCardPosition = function ( self, card,cardX,width,cardSeat,id,testChangeCardList)
	-- if testChangeCardList then
	-- 	return	
	-- end
	if self:isMagicCard(id) and not testChangeCardList  then
		if (modBattleMgr.getCurBattle():isRelogin() == false ) then						
					card:setPosition(cardX-gGameWidth/2 + 75, gGameHeight/2 - 240)
					--card:setPosition(cardX - gGameWidth/2 - 550,10)
					setTimeout(30,function (  )
						runProcess(1,function()
							local fpx = -598
							local fpy = 144
							-- local tpx = -1210				
							-- local tpy = 10
							local tpx = 10
							local tpy = 10
							local du = 60
							for i = 0, du do 
								local x = modEasing.linear(i,fpx,tpx - fpx,du)
								local y = modEasing.linear(i,fpy,tpy - fpy,du)
								card:setPosition(x,y)
								yield()
							end
						end)
						setTimeout(80,function (  )
							card:setImage(sf("ui:card/%d/show_%d.png", cardSeat, id))					
						end)									
					end)				
				--平和麻将断线重连就不移动金，直接设置位置
		elseif	( modBattleMgr.getCurBattle():isRelogin() == true ) then		
			card:setPosition(cardX, 10)
			card:setImage(sf("ui:card/%d/show_%d.png", cardSeat, id))	
		end
	else
		modMainPanel.pBattlePanel.setCardPosition(self,card,cardX,width,cardSeat,id,testChangeCardList)
	end
	
end

pPinghePanel.hasFlowerCards = function(self)
	return modBattleMgr.getCurBattle():getCurGame():isPingHe()
end

pPinghePanel.getMaxWidthCount = function(self)
	return 4	
end
--添加不显示鬼牌提示
pPinghePanel.getIsShowDiscardMagic = function(self)
	return false
end

pPinghePanel.setGuiImage = function ( self,img )
	img:setImage("ui:calculate_gui_ph.png")
end

pPinghePanel.youjinHide = function ( self)
	logv("warn","youjinHide")	
	for i = 0,3 do
		local player = modBattleMgr.getCurBattle():getAllPlayers()[i] 
		local wnd = self[sf("wnd_piao_%d", i)]
		if modBattleMgr.getCurBattle():getCurGame():getSelfHasJin(player) then
			if wnd then
				logv("warn","wnd",wnd)
				wnd:show(false)			
				wnd = nil	
			end
		end
	end
end

pPinghePanel.askFlagShowPiaoWnds = function ( self,flags ,message)
	logv("warn","askFlagShowPiaoWnds")		
	if not flags or not message then return end 
	mainPanelName.askFlagShowPiaoWnds(self,flags,message)	
	-- self:youjinHide()
	self:showJinFlagWnds()
end

pPinghePanel.getIsCircle = function(self)
	return true
end

pPinghePanel.updateJinFlagWnds = function ( self,flag,player )
	logv("warn","pPinghePanel.updateJinFlagWnds")		
	if not player or not flag then return end	
	local wnd = self[sf("wnd_piao_%d", player:getSeat())]
	if not wnd then return end	
	self:setPiaoText(player:getSeat(),flag)
	wnd:show(true)
	if player:getSeat() == T_SEAT_MINE then
		self:setPiaoText(player:getSeat(), flag)
		wnd:show(true)
	end
end

pPinghePanel.showJinFlagWnds = function ( self )
	local players = modBattleMgr.getCurBattle():getAllPlayers()
	if not players then return end
	for _,player in pairs(players) do
		local wnd = self[sf("wnd_piao_%d", player:getSeat())]
		if not wnd then break end
		local fv = modBattleMgr.getCurBattle():getCurGame():getSelfHasJin(player)
		if fv then
			self:setPiaoText(player:getSeat(), fv)
			wnd:show(true)
			if player:getSeat() == T_SEAT_MINE then
				self:setPiaoText(player:getSeat(), fv)
				wnd:show(true)
			end
		end
	end
end

pPinghePanel.hideJinFlagWnds = function ( self,flag,player )	
	if not player or not flag then return end	
	local wnd = self[sf("wnd_piao_%d", player:getSeat())]
	if not wnd then return end		
	self:setPiaoText(player:getSeat(),flag)
	wnd:show(false)										
end

pPinghePanel.changeRuleText = function(self, roomInfo, rs)
	rs["number_of_game_times"] = {
		[1] = "1圈",
		[4] = "4圈",
		[8] = "8圈",
		[12] = "12圈",		
	}
end

pPinghePanel.getMaxHeightCount = function(self)
	return 3
end

pPinghePanel.getIsHideAnGang = function(self)
	return true
end
