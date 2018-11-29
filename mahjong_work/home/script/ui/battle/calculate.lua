local modBattleRpc = import("logic/battle/rpc.lua")
local modUtil = import("util/util.lua")
local modPlayer = import("logic/battle/player.lua")
local modCardPool = import("logic/battle/pool.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modFunctionManager = import("ui/common/uifunctionmanager.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modSound = import("logic/sound/main.lua")
local modEvent = import("common/event.lua")
local modTrigger = import("logic/trigger/mgr.lua")

pCalculatePanel = pCalculatePanel or class(pWindow, pSingleton)

local huTypeString = modGameProto.AskCheckGameOverRequest.PlayerStatistic

local pidToColors = {
	[0] = 0xFFFF33FF,
	[1] = 0xFFFF6666,
	[2] = 0xFF66FFFF,
	[3] = 0xFF66B2FF,
}

local colorToImgs = {
	[0xFFFF33FF] = "ui:calculate_img_r.png",
	[0xFFFF6666] = "ui:calculate_img_o.png",
	[0xFF66FFFF] = "ui:calculate_img_g.png",
	[0xFF66B2FF] = "ui:calculate_img_b.png",
}

pCalculatePanel.init = function(self)
	self:load("data/ui/calculate.lua")
	self.btn_exit:show(false)
---	self.btn_exit:setText("退出游戏")
	self.btn_start:addListener("ec_mouse_click", function()
		if modBattleMgr.getCurBattle():getIsVideoState() then
			modBattleMgr.pBattleMgr:instance():battleDestroy()
		else
			if self.isAnswer then
				modBattleRpc.confirmCalcResult(function(success, reason)
					if success then
						-- 结束处理
						modBattleMgr.getCurBattle():getBattleUI():clearAllPlayerCards()
						modBattleMgr.getCurBattle():getBattleUI():initIconPos()
						if self.message.winner_id then
							modBattleMgr.getCurBattle():getBattleUI():hostMark(self.message.winner_id)
						end
						modFunctionManager.pUIFunctionManager:instance():stopFunction()
						modBattleMgr.getCurBattle():getBattleUI():clearCalculate()
					end
				end)
			else
				local roomInfo = modBattleMgr.getCurBattle():getRoomInfo()
				local clubId = roomInfo.club_context.club_id
				local groundId = roomInfo.club_context.club_ground_id
				local roomType = roomInfo.room_type
				if not self:isClubRoom() then
					self:noAnswer()
				end
				self:clubRoomMatch(clubId, groundId, roomType)
			end
		end
	end)
	local modUIUtil = import("ui/common/util.lua")
	modUIUtil.adjustSize(self, gGameWidth, gGameHeight)
	modUIUtil.makeModelWindow(self, false, true)
--	self.wnd_cal:setSize(self.wnd_cal:getWidth(), self.wnd_cal:getHeight() + (self.wnd_bg:getHeight() - self.wnd_cal:getHeight()) / 4)
	self:setParent(modBattleMgr.getCurBattle():getBattleUI())
	self:setRenderLayer(C_BATTLE_UI_RL)
	self:setZ(C_BATTLE_WIDGET)
--	self:setParent(gWorld:getUIRoot())
	self.btn_share:setOffsetX( - self.wnd_cal:getWidth() * 0.01)
	self.btn_start:setOffsetX( - self.wnd_cal:getWidth() * 0.01)
	self.btn_start:setOffsetY( - self.wnd_cal:getHeight() * 0.02)
	self.btn_exit:setOffsetX( - self.wnd_cal:getWidth() * 0.01)
	self.btn_exit:setOffsetY( - self.wnd_cal:getHeight() * 0.02)
	self.btn_share:setOffsetY( - self.wnd_cal:getHeight() * 0.02)
	self.btn_exit:addListener("ec_mouse_click", function()
		if self:isClubRoom() and (not self.isAnswer) and not modBattleMgr.getCurBattle():getIsVideoState() then
			self:noAnswer()
			return
		end
	end)
	self.btn_share:addListener("ec_mouse_click", function()
		if self.btn_share.__wait_exec_flag then
			return
		end
		if self.btn_share.__wait_exec_hdr then
			self.btn_share.__wait_exec_hdr:stop()
		end
		self.btn_share.__wait_exec_flag = true
		modTrigger.regTriggerOnce(EV_AFTER_DRAW, function()
			if self.btn_share.__wait_exec_hdr then
				self.btn_share.__wait_exec_hdr:stop()
				self.btn_share.__wait_exec_hdr = nil
			end
			self.btn_share.__wait_exec_flag = false
			puppy.sys.shareWeChatWithScreenCapture(2)
		end)
		self.btn_share.__wait_exec_hdr = setTimeout(10, function()
			if self.btn_share.__wait_exec_flag then
				puppy.sys.shareWeChatWithScreenCapture(2)
				self.btn_share.__wait_exec_hdr = nil
				self.btn_share.__wait_exec_flag = false
			end
		end)
	end)
	self.controls = {}
	self.pidToWnds = {}
end

pCalculatePanel.noAnswer = function(self)
	if self.isAnswer then return end
	modBattleMgr.getCurBattle():getBattleUI():clearAllPlayerCards()
	if self.message.winner_id then
		modBattleMgr.getCurBattle():getBattleUI():hostMark(self.message.winner_id)
	end
	modBattleMgr.getCurBattle():getBattleUI():clearCalculate()
	modFunctionManager.pUIFunctionManager:instance():stopFunction()
end

pCalculatePanel.clubRoomMatch = function(self, clubId, groundId, roomType)
	if roomType ~= modLobbyProto.CreateRoomRequest.CLUB_SHARED then return end
	self:clubJoinMatch(clubId, groundId)
end

pCalculatePanel.clubJoinMatch = function(self, clubId, groundId)
	if not clubId or clubId == -1 or not groundId then return end
	local modClubMgr = import("logic/club/main.lua")
	local modClubImplProto = import("data/proto/rpc_pb2/club_impl_pb.lua")
	local modUserData = import("logic/userdata.lua")
	modClubMgr.getCurClub():clubJoinMatch(clubId, groundId, modUserData.getUID(), true, function(success, reply)
		if not success then
			if modBattleMgr.getCurBattle() then
				modBattleMgr.pBattleMgr:instance():battleDestroy()
			end
			return
		end
		local room = reply.room
		modBattleMgr.pBattleMgr:instance():enterBattle(room.id, room.host, room.port, function(success)
			if not success	then
				if modBattleMgr.getCurBattle() then
					modBattleMgr.pBattleMgr:instance():battleDestroy()
				end
			end
		end)
	end)
end

pCalculatePanel.regEvent = function(self)
	self.__update_user_prop = modEvent.handleEvent(EV_UPDATE_USER_PROP,function(seatId, name, avatarUrl, ip, pid)
		if not self.pidToWnds or not self.pidToWnds[pid] then
			return
		end
		self.pidToWnds[pid]["name"]:setText(name)
		self.pidToWnds[pid]["img"]:setImage(avatarUrl)
	end)
end

pCalculatePanel.open = function(self, message, ruleStr)		
	self.message = message
	self.isAnswer = not self.message.do_not_answer
	self.ruleStr = ruleStr
	-- 自己结算信息
	self:signleShow(message.game_is_drawn)

	-- 本局所有信息
	self:infoShow()
	self:regEvent()
end

pCalculatePanel.showCards = function(self, wndParent, currentPlayer, playerId, posX)	
	local players = modBattleMgr.getCurBattle():getAllPlayersByPid()
	local player = modBattleMgr.getCurBattle():getPlayerByPlayerId(playerId)
	local showPool = player:getShowPool()
	local handPool = player:getHandPool()
	local combs = showPool:getCombinations()
	local huCard = currentPlayer.hu_card_id
	local huType = currentPlayer.hu_type
	local x = 0
	local y = 0
	local initY = 0
	local scale = 2.1
	local curScale = 2.4
	local width = 100
	local height = 139
	local cardDistance = 3
	local pcolor = pidToColors[playerId]
	local huCardTriggerPid = nil
	if posX then
		x = posX
		y = 0
		initY = y
	end

	-- 东山
	if self:isDongShanQueYue() or
		self:isZhaoAnQueYue() or self:isPingHeMJ() then
		scale = 2.4
		curScale = 2.7
		cardDistance = 2
	end	
		
	for k,comb in pairs(combs) do				
		-- 出发牌PID
		local triggerPid = comb:getTriggerPid()		
		local triggerColor = pidToColors[triggerPid]
		if triggerPid == playerId then
			triggerColor = 0xFFFFFFFF
		end		
		-- 胡牌排序
		if comb.t == modGameProto.HU then						
			comb:huAndZimoSort()
			huCardTriggerPid = comb:getTriggerPid()			
		end
		-- comb 牌			
		local combCards = comb:getCards()
			
		-- 杠
		if modBattleMgr.getCurBattle():getCurGame():isGang(comb.t) then
			local cardX = x
			local curCardX = x
			y = initY + ((height / scale) - (height / curScale))
			for idx,card in pairs(combCards) do
				local cardId = card:getId()
				local image = "ui:card/2/show_" .. cardId .. ".png"
				if comb.t ==  modGameProto.ANGANG and idx ~= table.getn(combCards) then
					image = "ui:card/2/show_hide.png"
				end
				local cardWnd = self:createWnd("card" .. idx .. cardId,curCardX,y,image,width / curScale, height / curScale,nil,cardId,scale)
				cardWnd:setParent(wndParent)
				cardWnd:setAlignY(ALIGN_BOTTOM)
				-- 设置自己颜色
--				cardWnd:setColor(pcolor)
				if idx == table.getn(combCards) then
					cardWnd:setPosition(cardWnd:getX() - 2 *(width / curScale) + cardDistance + 2,cardWnd:getY() - cardWnd:getY() / 6)
					cardWnd:setOffsetY(-cardWnd:getHeight() / 6 - 5)
					-- 触发牌设置对应玩家颜色
					cardWnd:setColor(triggerColor)
				else
					cardX = cardX + width / scale - cardDistance
					curCardX = curCardX + width / curScale - cardDistance
				end
			end
			x = cardX
		else
			-- 胡牌缩放比例
			if comb.t == modGameProto.HU then
				curScale = scale
			else
				curScale = 2.3
				if self:isDongShanQueYue() or
					self:isZhaoAnQueYue() or self:isPingHeMJ() then
					curScale = 2.7
				end
			end
			y = initY +  ((height / scale) - (height / curScale))
			local cardX = x
			local curCardX = x
			for index, card in pairs(combCards) do
				local cardId = card:getId()
				if comb.t ~= modGameProto.HU or -- 不是胡的comb直接画
					cardId ~= huCard or -- 不是胡的那张牌直接画
					(comb.t == modGameProto.HU and index ~= table.getn(combCards) and cardId == huCard) -- 胡comb 排序后 最后一张同触发牌一样id的牌不画
					then
					logv("error","cardId",cardId)
					local image = "ui:card/2/show_" .. cardId .. ".png"
					local cardWnd = self:createWnd("card" .. playerId .. cardId .. index,curCardX,y,image,width / curScale, height / curScale,nil,cardId,curScale)
					cardWnd:setParent(wndParent)
					cardWnd:setAlignY(ALIGN_BOTTOM)
					cardWnd:setOffsetY(-5)
--					cardWnd:setColor(pcolor)
					-- 吃碰中间那张触发牌设置对应玩家颜色
					if comb.t ~= modGameProto.HU then
						if index == 2 then
							cardWnd:setColor(triggerColor)
						end
					end
					cardX = cardX + width / scale - cardDistance
					curCardX = curCardX + width / curScale - cardDistance
				end
			end
			x = cardX
		end
	end
	-- 没胡的描画手牌
	local handCards = handPool:getCards(true)
	y = initY	
	if handCards then		
		local cardX = x		
		for _,card in pairs(handCards) do						
			local cardId = card:getId()			
			local image = "ui:card/2/show_" .. cardId .. ".png"
			local cardWnd = self:createWnd("card" .. playerId .. cardId,cardX,y,image,width / scale, height / scale,nil,cardId,scale)
			cardWnd:setParent(wndParent)
			cardWnd:setAlignY(ALIGN_BOTTOM)
			cardWnd:setOffsetY(-5)
--			cardWnd:setColor(pcolor)
			cardX = cardX + width / scale - cardDistance
		end
		x = cardX
	end
	-- 描画胡牌
	x = x + 10
	if huCard >= 0 and huType ~= huTypeString.FANGPAO and huType ~= huTypeString.GANG_FANGPAO then		
		local image = "ui:card/2/show_" .. huCard .. ".png"
		local huWnd = self:createWnd("card" .. playerId .. huCard,x,y,image,width / scale, height / scale,nil,huCard,scale)
		huWnd:setParent(wndParent)
		huWnd:setAlignY(ALIGN_BOTTOM)
		huWnd:setOffsetY(-5)
		if huCardTriggerPid then
			if huCardTriggerPid == playerId then
				huWnd:setColor(0xFFFFFFFF)
			else
				huWnd:setColor(pidToColors[huCardTriggerPid])
			end
		end
	end

end

-- 全局信息
pCalculatePanel.infoShow = function(self)
	if self.message and modBattleMgr.getCurBattle() then
		local playerInfo = {}
--		local winnerId = self.message.winner_id
		local winnerId = modBattleMgr.getCurBattle():getCurGame():getBankerId()
		local y = self["wnd_calculate_result_tile"]:getHeight() / 5 + 20
		local isShowCard = false
		local players = modBattleMgr.getCurBattle():getAllPlayersByPid()

		for k,v in ipairs(self.message.player_statistics) do
--			if type(k) == "number" then
				table.insert(playerInfo,v)
--			end
		end		
		for idx, currentPlayer in pairs(playerInfo) do
			local huType = currentPlayer.hu_type
			local player = players[idx - 1]
			-- 描画item
			local itemWnd = self:createWnd("item_" .. idx, 0, y, "ui:bottom_info.png",self.wnd_bg:getWidth() * 0.9, 110)
				itemWnd:setAlignX(ALIGN_CENTER)
				itemWnd:setColor(0xFFFFFFFF)
				itemWnd:setXSplit(10)
				itemWnd:setYSplit(10)



			-- 描画头像
			local modUIUtil = import("ui/common/util.lua")
			local img = player:getAvatarUrl() or modUIUtil.getDefaultImage(2)
			local imageBg = self:createWnd("image_" .. idx, self.wnd_bg:getWidth() * 0.01, 0, img, 80, 80)
			imageBg:setParent(itemWnd)
			imageBg:setAlignY(ALIGN_CENTER)
--			imageBg:addListener("ec_mouse_click", function()
--				local uid = player:getUid()
--				local modPlayerInfo = import("logic/menu/player_info_mgr.lua")
--				modPlayerInfo.newMgr(uid, T_MAHJONG_ROOM)
--			end)

			-- 描画头像框
			local imageFront = self:createWnd("image_front" .. idx,0, 0, "ui:bg_top_mini.png", imageBg:getWidth() * 1.1, imageBg:getHeight() * 1.1)
			local imgColor = pidToColors[idx - 1]
			imageFront:setImage(colorToImgs[imgColor])
			imageFront:setParent(imageBg)
			imageFront:setAlignY(ALIGN_CENTER)
			imageFront:setAlignX(ALIGN_CENTER)

			-- 描画name
			local name = player:getName() or "???"
			if modUIUtil.utf8len(name) > 6 then
				name = modUIUtil.getMaxLenString(name, 6)
			end
			local nameWnd = self:createWnd("name_" .. idx, 0, 0, nil, 100, 50, name)
			nameWnd:setPosition(100, 0)
			nameWnd:setParent(itemWnd)
			nameWnd:setAlignY(ALIGN_CENTER)
			nameWnd:getTextControl():setAlignX(ALIGN_LEFT)
			nameWnd:getTextControl():setAlignY(ALIGN_MIDDLE)
			nameWnd:getTextControl():setFontSize(26)
			if not self.pidToWnds[player:getPlayerId()] then
				self.pidToWnds[player:getPlayerId()] = {}
			end
			self.pidToWnds[player:getPlayerId()]["name"] = nameWnd
			self.pidToWnds[player:getPlayerId()]["img"] = imageBg

			-- 描画庄
			local bankerZhuangCount = nil
			if idx - 1 == winnerId and not modBattleMgr.getCurBattle():getCurGame():isDongShan() or not modBattleMgr.getCurBattle():getCurGame():isPingHe() then
				if modBattleMgr.getCurBattle():getCurGame():isZhaoAn() then
					bankerZhuangCount = modBattleMgr.getCurBattle():getCurGame():getBankerZhuangCount()
				end
				local hostWnd =self:createWnd("host_" .. idx,0,0,"ui:calculate_host.png",41 * 0.8, 41 * 0.8)
				hostWnd:setParent(imageFront)
				hostWnd:setAlignX(ALIGN_BOTTOM)
				hostWnd:setAlignY(ALIGN_BOTTOM)
				hostWnd:setOffsetX(hostWnd:getWidth() / 5)
				hostWnd:setOffsetY(hostWnd:getHeight() / 5)
			end

			if modBattleMgr.getCurBattle():getCurGame():isDongShan() or modBattleMgr.getCurBattle():getCurGame():isPingHe() then
				local hostWnd =self:createWnd("host_" .. idx,0,0,"ui:calculate_host.png",41 * 0.8, 41 * 0.8)
				hostWnd:setParent(imageFront)
				local seatToDir = modBattleMgr.getCurBattle():getSeatToDir()
				local image = sf("ui:calculate_dir_%d.png", seatToDir[player:getSeat()])
				hostWnd:setImage(image)
			end

			-- 描画胡
			local fanCount =  nil
			local piaoCount = nil
			if huType ~= huTypeString.NONE and huType ~= huTypeString.FANGPAO and huType ~= huTypeString.GANG_FANGPAO then
				local huWnd = self:createWnd("hu_" .. idx,0, 0,"ui:calculate_hu.png",
					150,129)
				huWnd:setParent(itemWnd)
				huWnd:setAlignY(ALIGN_CENTER)
				huWnd:setAlignX(ALIGN_RIGHT)
				huWnd:setOffsetX(0)
			end

			-- 分数
			local score = 0
			local scoresFromPlayers = currentPlayer.scores_from_players
			for pid, sc in ipairs(scoresFromPlayers) do
				if pid - 1 == player:getPlayerId() then
					score = sc
					break
				end
			end
			if score >= 0 then
				score = "+" .. score
			end
			local waterScore = currentPlayer.water_score
			local scoreWnd = self:createWnd("score_" .. idx, 0, 37, nil, 100, 70, score)
			scoreWnd:setParent(itemWnd)
			scoreWnd:setAlignX(ALIGN_RIGHT)
			scoreWnd:setAlignY(ALIGN_CENTER)
			scoreWnd:setOffsetX(- itemWnd:getWidth() * 0.15)
			scoreWnd:getTextControl():setFontSize(40)
			scoreWnd:getTextControl():setAlignX(ALIGN_CENTER)
			scoreWnd:getTextControl():setAlignY(ALIGN_CENTER)
			if waterScore > 0 then
				scoreWnd:setText(score .. sf("\n(小费-%d)", waterScore))
			end

			if self:getPlayerIsPochan(player) then
				local waterWnd = self:createWnd("water_" .. idx, 0, 37, nil, 50, 70)
				waterWnd:setParent(itemWnd)
				waterWnd:setAlignX(ALIGN_RIGHT)
				waterWnd:setAlignY(ALIGN_CENTER)
				waterWnd:setImage("ui:icon_pochan.png")
				waterWnd:setSize(95, 83)
				waterWnd:setColor(0xFFFFFFFF)
			end

			local flowerCards = player:getAllCardsFromPool(T_POOL_FLOWER)
			local textX = nameWnd:getX() + nameWnd:getWidth() + itemWnd:getWidth() * 0.02
			if table.getn(flowerCards) > 0 then
				local width, height = 100, 139
				local x, y = textX, 0
				for n, card in pairs(flowerCards) do
					local cardId = card:getId()
					local image = sf("ui:card/2/show_%d.png", cardId)
					local flowerWnd = self:createWnd("flower_" .. n, x, y, image, width * 0.31, height * 0.31)
					flowerWnd:setParent(itemWnd)
					x = x + flowerWnd:getWidth() - 1
					textX = x
				end
				textX = textX + 10
			end

			-- 描画combtext
			local fans = currentPlayer.fan_types			
			local fanCnt = currentPlayer.fan_count
			local currType = modBattleMgr.getCurBattle():getCurGame():getCurrMJType()
			local fansStr = modUIUtil.getFan(currType)						
			local addStr = "番"
			local combTexts = {}
			if modBattleMgr.getCurBattle():getCurGame():isDongShan() or modBattleMgr.getCurBattle():getCurGame():isZhaoAn() then
				addStr = "台"
			end
			if  modBattleMgr.getCurBattle():getCurGame():isPingHe() then
				addStr = "分"
			end
			if bankerZhuangCount and bankerZhuangCount > 0 then
				table.insert(combTexts, "连庄" .. bankerZhuangCount .. "次")
			end
			if currentPlayer.angang_count > 0 then
				table.insert(combTexts,"暗杠x" .. currentPlayer.angang_count)
			end
			if currentPlayer.xiaominggang_count > 0 then
				local s = "加杠x"
				if modBattleMgr.getCurBattle():getCurGame():isDongShan() or modBattleMgr.getCurBattle():getCurGame():isPingHe() or modBattleMgr.getCurBattle():getCurGame():isZhaoAn() then
					s = "明杠x"
				end
				table.insert(combTexts, s .. currentPlayer.xiaominggang_count)
			end
			if currentPlayer.fanggang_count > 0 then
				local s = "明杠(放杠)x"
				if modBattleMgr.getCurBattle():getCurGame():isDongShan() or modBattleMgr.getCurBattle():getCurGame():isPingHe() or modBattleMgr.getCurBattle():getCurGame():isZhaoAn() then
					s = "放杠x"
				end
				table.insert(combTexts,s .. currentPlayer.fanggang_count)
			end
			if currentPlayer.jiegang_count > 0 then
				local s = "明杠(接杠)x"
				if modBattleMgr.getCurBattle():getCurGame():isDongShan() or modBattleMgr.getCurBattle():getCurGame():isPingHe() or modBattleMgr.getCurBattle():getCurGame():isZhaoAn() then
					s = "明杠x"
				end
				table.insert(combTexts, s .. currentPlayer.jiegang_count)
			end
			if currentPlayer.valid_niao_card_count > 0 then
				if modBattleMgr.getCurBattle():getCurGame():isYunYangMj() or modBattleMgr.getCurBattle():getCurGame():isXueZhanDaoDiMj() then
					table.insert(combTexts,"花猪x" .. currentPlayer.valid_niao_card_count)
				else
					table.insert(combTexts,"中" .. currentPlayer.valid_niao_card_count .. "鸟")
				end
			end
			if huType == huTypeString.ZIMO then
				--平和麻将不要加自摸
				if not modBattleMgr.getCurBattle():getCurGame():isPingHe() then
					table.insert(combTexts,"自摸")
				end		
			elseif huType == huTypeString.FANGPAO then
				table.insert(combTexts,"放炮")
			elseif huType == huTypeString.JIEPAO then
				table.insert(combTexts,"接炮")
			elseif huType == huTypeString.GANG_FANGPAO then
				local s = "杠上放炮"
				if modBattleMgr.getCurBattle():getCurGame():isDongShan() or modBattleMgr.getCurBattle():getCurGame():isPingHe() or modBattleMgr.getCurBattle():getCurGame():isZhaoAn() then
					s = "放炮"
				end
				table.insert(combTexts, s)
			elseif huType == huTypeString.GANG_JIEPAO then
				local s = "杠上接炮"
				if modBattleMgr.getCurBattle():getCurGame():isDongShan() or modBattleMgr.getCurBattle():getCurGame():isPingHe() or modBattleMgr.getCurBattle():getCurGame():isZhaoAn() then
					s = "接炮"
				end
				table.insert(combTexts, s)
			end
			if currentPlayer.fan_count > 0 and
				currType ~= modLobbyProto.CreateRoomRequest.ZHUANZHUAN
				and currType ~= modLobbyProto.CreateRoomRequest.HONGZHONG
				and currType ~= modLobbyProto.CreateRoomRequest.XIANGYANG
				and currType ~= modLobbyProto.CreateRoomRequest.XIANGYANG_BAIHE
				then
				fanCount = currentPlayer.fan_count .. addStr
			end
			if currentPlayer.piao_count > 0 then
				local piaoTexts = {
					["dama"] = "搭%d马",
					["piaofen"] = "飘%d分",
					["chatai"] = "插%d台"
				}
				local piaot = modBattleMgr.getCurBattle():getBattleUI():getPiaoType()
				if piaoTexts[piaot] then
					piaoCount = sf(piaoTexts[piaot], currentPlayer.piao_count)
				end
				if modBattleMgr.getCurBattle():getCurGame():isTianJinMJ() then
					local isChuai = self:isLaOrChuai(player)
					if isChuai then piaoCount = "踹"
					else
						piaoCount = "拉"
					end

				end
			end			
			for _, fan in pairs(fans) do			
				if fansStr and fansStr[fan] then					
					table.insert(combTexts, fansStr[fan])
				end
			end

			if fanCount then
				table.insert(combTexts, fanCount)
			end

			if piaoCount then
				table.insert(combTexts, piaoCount)
			end


			local textY = 0
			for k,text in pairs(combTexts) do
				local textWnd = self:createWnd("text_" .. k .. idx,textX,textY,nil,50,50,text)
				textWnd:setParent(itemWnd)
				textWnd:getTextControl():setFontSize(25)
				textWnd:getTextControl():setFontBold(1)
				textWnd:getTextControl():setAlignX(ALIGN_LEFT)
				textWnd:getTextControl():setAlignY(ALIGN_TOP)
				textX = textX + textWnd:getTextControl():getWidth() + 15
				if k == idx then
					textWndCopy = textWnd
				end
			end

			-- 描画牌
			local posX = nameWnd:getX() + nameWnd:getWidth() + itemWnd:getWidth() * 0.02
			self:showCards(itemWnd, currentPlayer, idx - 1, posX)

			y = y + itemWnd:getHeight() + itemWnd:getHeight() * 0.05
		end
	end
end

pCalculatePanel.getPlayerIsPochan = function(self, player)
	if not player then return end
	if not modBattleMgr.getCurBattle():getCurGame():isClubRoom()	then
		return false
	end
	return player:getScore() <= 0
end

pCalculatePanel.isLaOrChuai = function(self, player)
	local hostId = modBattleMgr.getCurBattle():getCurGame():getBankerId()
	local pid = player:getPlayerId()
	return hostId == pid
end

pCalculatePanel.isClubRoom = function(self)
	local roomInfo = modBattleMgr.getCurBattle():getRoomInfo()
	if not roomInfo then return end
	return roomInfo.room_type == modLobbyProto.CreateRoomRequest.CLUB_SHARED
end

-- 个人信息
pCalculatePanel.signleShow = function(self, isGameDrawn)
	if not self.isAnswer and (not self:isClubRoom()) and not modBattleMgr:getCurBattle():getIsVideoState() then
		self.wnd_start:setImage("ui:calculate_game_over.png")
	end
	if self:isClubRoom() and (not self.isAnswer) and not modBattleMgr.getCurBattle():getIsVideoState() then
		self.wnd_share:setImage("ui:calculate_game_over.png")
		self.btn_share:setImage("ui:btn8.png")
		self.btn_share:show(false)
		self.btn_exit:show(true)
	end

	local myPlayerId = modBattleMgr.getCurBattle():getMyPlayerId()
	local myInfo = self.message.player_statistics[myPlayerId + 1]
	local myHuType = myInfo.hu_type

	-- 音效
	local score = 0
	local scoresFromPlayers = myInfo.scores_from_players
	for pid, sc in ipairs(scoresFromPlayers) do
		if pid - 1 == myPlayerId then
			score = sc
			break
		end
	end
	if isGameDrawn then
		modSound.getCurSound():playSound("sound:chengju.mp3")
	elseif score >= 0 then
		modSound.getCurSound():playSound("sound:win.mp3")
	else
		modSound.getCurSound():playSound("sound:lose.mp3")
	end

	-- 描画是否胜利
	local width = 178
	local height = 114
	local resultBg = self:createWnd("result_tile", 0, 0,"ui:calculate_win_title.png", 721, 283)
	resultBg:setAlignX(ALIGN_CENTER)
	resultBg:setAlignY(ALIGN_TOP)
	resultBg:setPosition(0, - resultBg:getHeight() / 2)
	resultBg:setParent(self.wnd_cal)


	local resultWnd = self:createWnd("result", 0, 0, "ui:calculate_win.png",width,height)
	resultWnd:setAlignX(ALIGN_CENTER)
	resultWnd:setAlignY(ALIGN_CENTER)
	resultWnd:setParent(resultBg)
		-- 失败
	if score < 0 then
		resultWnd:setImage("ui:calculate_lose.png")
		resultBg:setImage("ui:calculate_lose_title.png")
	end

		-- 陪打
	if score == 0 then
		resultWnd:setImage("ui:calculate_peida.png")
		resultWnd:setSize(372, 114)
	else
		resultWnd:setSize(width, height)
	end

		-- 流局
	local isLiuJu = isGameDrawn
	if isLiuJu then
		resultWnd:setImage("ui:calculate_liuju.png")
		resultWnd:setSize(186, 111)
		resultBg:setImage("ui:calculate_lose_title.png")
	end
	-- 描画鸟牌
	if modBattleMgr.getCurBattle():getRoomInfo()["zhuaniao_count"] ~= 0 and
		table.getn(self.message.niao_card_ids) > 0
		then
		-- 描画字体
		local niaoBg = self:createWnd("niao_bg", 80, 0, nil, 50, 50, "抓鸟:")
		niaoBg:setParent(self.wnd_cal)
		niaoBg:setAlignY(ALIGN_BOTTOM)
		niaoBg:setOffsetY(-60)
		niaoBg:getTextControl():setFontSize(30)
		niaoBg:getTextControl():setAlignY(ALIGN_CENTER)
		self.wnd_niaocard_bg:setParent(niaoBg)
		self.wnd_niaocard_bg:setAlignY(ALIGN_CENTER)
		self.wnd_niaocard_bg:setPosition(niaoBg:getWidth(), 0)

		-- 描画牌
		self:showNiaoCard()
	end

	-- 麻将规则
	local ruleBg = self:createWnd("rule_bg", 10, 0, nil, 50, 50, " ")
	ruleBg:setParent(self.wnd_cal)
	ruleBg:setAlignY(ALIGN_BOTTOM)
	ruleBg:setOffsetY(ruleBg:getTextControl():getHeight() + 10)
	ruleBg:getTextControl():setFontSize(30)
	ruleBg:getTextControl():setAlignX(ALIGN_LEFT)
	ruleBg:getTextControl():setAlignY(ALIGN_CENTER)

	local ruleWnd = self:createWnd("rule", 0, 0, nil, 50, 50, self.ruleStr)
	ruleWnd:setParent(ruleBg)
	ruleWnd:setAlignY(ALIGN_CENTER)
	ruleWnd:getTextControl():setFontSize(24)
	ruleWnd:getTextControl():setAlignY(ALIGN_CENTER)
	ruleWnd:getTextControl():setAlignX(ALIGN_LEFT)
	-- 描画时间
	local t = os.time()
	if modBattleMgr.getCurBattle():getIsVideoState() then
		if modBattleMgr.getCurBattle():getVideoTime() then
			t = modBattleMgr.getCurBattle():getVideoTime()
		end
	end
	local time = os.date("%Y.%m.%d   %H:%M:%S", t)
	local timeWnd = self:createWnd("time", 0, 0, nil, 50, 50, time)
	timeWnd:setParent(self.wnd_cal)
	timeWnd:setAlignX(ALIGN_RIGHT)
	timeWnd:setOffsetX(self.btn_share:getOffsetX())
	timeWnd:setAlignY(ALIGN_BOTTOM)
	timeWnd:setOffsetY(ruleBg:getOffsetY() * 1.8)
	timeWnd:getTextControl():setAlignX(ALIGN_LEFT)
	timeWnd:getTextControl():setAlignY(ALIGN_CENTER)
	timeWnd:getTextControl():setFontSize(24)
	timeWnd:getTextControl():setFontBold(0)

	-- 回访码
	local code = self.message.record_id
	if not code or code == -1 then return end
	local codeWnd = self:createWnd("code", 10, 0, nil, 50, 50, "回放码:" .. sf("%08d", code))
	codeWnd:setParent(self.wnd_cal)
	codeWnd:setAlignY(ALIGN_BOTTOM)
	codeWnd:setOffsetY(ruleBg:getOffsetY() * 1.8)
	codeWnd:getTextControl():setFontSize(24)
	codeWnd:getTextControl():setAlignX(ALIGN_LEFT)
end

-- 鸟牌
pCalculatePanel.showNiaoCard = function(self)
	local cards = {}
	local validCards = {}
	local niaoCards = self.message.niao_card_ids
	local niaoValids = self.message.valid_niao_card_ids
	local scale = 0.8
	local width = 89 * scale
	local height = 135 * scale
	local x = scale * width

	-- 赋值
	for k,cardId in ipairs(niaoCards) do
		table.insert(cards,cardId)
	end
	for k,cardId in ipairs(niaoValids) do
		table.insert(validCards,cardId)
	end
	-- 初始位置
	if table.getn(cards) > 2 then
		x = x - self:getInt((table.getn(cards) - 1) / 2) * width
		self.wnd_niaocard_bg:setPosition(self.wnd_niaocard_bg:getX() + self:getInt((table.getn(cards) - 1) / 2) * width, 0)
	end

	-- 描画
	for k,cardId in pairs(cards) do
		logv("error",cardId)
		local image = "ui:card/2/show_" .. cardId .. ".png"
		local cardWnd = self:createWnd("card_" .. k,x,0,image,width,height,nil,cardId)
		cardWnd:setParent(self.wnd_niaocard_bg)
		cardWnd:setSize(cardWnd:getWidth() * scale,cardWnd:getHeight() * scale)
		local gui = self["wnd_calculate_gui_card_" .. k]
		if gui then
			gui:setSize(gui:getWidth() * scale * 0.8,gui:getHeight() * scale * 0.8)
			gui:setPosition(gui:getX() - 1, 0)
			gui:setAlignY(ALIGN_BOTTOM)
		end
		local di = self["wnd_calculate_di_card_" .. k]
		if di then
			di:setSize(di:getWidth() * scale - 2, di:getHeight() * scale - 6)
			di:setPosition(di:getX() - 1, di:getHeight() * 0.1 - 1)
		end
		cardWnd:setAlignY(ALIGN_CENTER)
		-- 选中
		for _,valid in pairs(validCards) do
			if cardId == valid  then
				cardWnd:setColor(0xFFEEEE00)
				break
			end
		end
		x = x + width * scale - 3.5 * scale
	end
end



pCalculatePanel.createWnd = function(self,wndName,x,y,image_path,width,height,text,cardId,scale)
	local wnd = pWindow():new()
	wnd:setName("wnd_calculate_" .. wndName)
	wnd:setParent(self.wnd_cal)
	wnd:setPosition(x,y)
	wnd:setAlignX(ALIGN_LEFT)
	wnd:setAlignY(ALIGN_TOP)
	if text then
		wnd:setText(text)
	end
	wnd:getTextControl():setFontSize(30)
	wnd:getTextControl():setAlignX(ALIGN_RIGHT)
	wnd:getTextControl():setAlignY(ALIGN_CENTER)
	wnd:getTextControl():setAutoBreakLine(false)
	wnd:getTextControl():setColor(0xFF352114)
	if image_path then
		wnd:setColor(0xFFFFFFFF)
		wnd:setImage(image_path)
	else
		wnd:setColor(0)
	end
	wnd:setSize(width,height)
	wnd:setZ(-1)
	self[wnd:getName()] = wnd
	table.insert(self.controls,self[wnd:getName()])
	if cardId then
		if self:isMagicCard(cardId)  then
			-- 鬼牌
			--平和鬼牌标志
			-- local gui = self:createWnd("gui_" .. wndName,-1,34,"ui:calculate_gui.png",81 * 0.8,110 * 0.8)
			local gui
			if (modBattleMgr.getCurBattle():getCurGame():getRuleType() == 14) then
				gui = self:createWnd("gui_" .. wndName,-1,34,"ui:calculate_gui_ph.png",81 * 0.8,110 * 0.8)
			else
				gui = self:createWnd("gui_" .. wndName,-1,34,"ui:calculate_gui.png",81 * 0.8,110 * 0.8)
			end			
			gui:setParent(self[wnd:getName()])
			gui:setZ(wnd:getZ())
			gui:setAlignY(ALIGN_BOTTOM)
			gui:setColor(0xFFEEEE00)
			if scale then
				gui:setSize(gui:getWidth()/scale,gui:getHeight()/scale)
				gui:setPosition(gui:getX(),gui:getY() / scale)
			end
			table.insert(self.controls,gui)
--[[		elseif cardId == modBattleMgr.getCurBattle():getDiCardId() then
			-- 地牌
			local di = self:createWnd("di_" .. wndName, -1, 0, "ui:calculate_di.png", 81 * 0.8, 100 * 0.8)
			di:setParent(self[wnd:getName()])
			di:setZ(wnd:getZ())
			di:setAlignY(ALIGN_BOTTOM)
			if scale then
				di:setSize(di:getWidth()/scale, di:getHeight()/scale)
				di:setPosition(di:getX(), di:getY() / scale)
			end
			table.insert(self.controls,di)]]--
		end
	end
	return self[wnd:getName()]
end

pCalculatePanel.close = function(self)
	if self.controls then
		for k,v in pairs(self.controls) do
			v:setParent(nil)
		end
		self.controls = nil
	end
--	modBattleMgr.pBattleMgr:instance():battleDestroy()
	self.message = nil
	self.ruleStr = nil
	self.isAnswer = nil
	if self.__update_user_prop then
		modEvent.removeListener(self.__update_user_prop)
		self.__update_user_prop = nil
	end
	self:showClubUI()
	pCalculatePanel:cleanInstance()
end

pCalculatePanel.showClubUI = function(self)
	modEvent.fireEvent(EV_BATTLE_END)
end

-- 取整
pCalculatePanel.getInt = function(self,x)
	if x <= 0 then
		return math.ceil(x)
	end

	if math.ceil(x) == x then
		x = math.ceil(x)
	else
		x = math.ceil(x) - 1
	end
	return x
end

pCalculatePanel.show = function(self,isShow)
	self:showSelf(isShow)
end

pCalculatePanel.isDongShanQueYue = function(self)
--	return modUtil.getOpChannel() == "ds_queyue"
	return modBattleMgr.getCurBattle():getCurGame():isDongShan()
end
pCalculatePanel.isPingHeMJ = function ( self )
	return modBattleMgr.getCurBattle():getCurGame():isPingHe()
end

pCalculatePanel.isZhaoAnQueYue = function(self)
	return modBattleMgr.getCurBattle():getCurGame():isZhaoAn()
end

pCalculatePanel.isMagicCard = function(self, id)
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

