local modUtil = import("util/util.lua")
local modEvent = import("common/event.lua")
local modBattleRpc = import("logic/battle/rpc.lua")
local modUserData = import("logic/userdata.lua")
local modUIUtil = import("ui/common/util.lua")
local modBattleMgr = import("logic/battle/main.lua")
local modEndPlayerInfo = import("ui/battle/endplayerinfo.lua")			

pEndPlayer = pEndPlayer or class(pWindow)

pEndPlayer.init = function(self, statistic, index, pid, userId, allPlayers, winners, paoshous, isVideo, ownerUid, playerCount, host)
	self.host = host
	-- 不是自己
	if index > 0 then
		self:load("data/ui/endcalculateinfos.lua")
		self:setSize(474, 206)
		self.wnd_score:setFont("end_lose_number", 40, 1)
		self.wnd_score:setScale(2.5, 2.5)
	else
		self:load("data/ui/endcalculateplayer.lua")
		self.wnd_score:setFont("end_lose_number", 40, 1)
		self.wnd_score:setScale(2.5, 2.5)
		self:setSize(700, 206)
	end
	self.wnd_win:show(false)
	self:setAlignX(ALIGN_CENTER)
	self:setAlignY(ALIGN_TOP)
	self.wnd_pao_shou:show(false)
	self:setZ(C_BATTLE_UI_Z)

	if isVideo and not players and userId then
		modBattleRpc.updateUserProps(userId, function(success, reply) 
			if success then
				local image = reply.avatar_url
				local name = reply.nickname
				if modUIUtil.utf8len(name) > 6 then
					name = modUIUtil.getMaxLenString(name, 6)
				end
				self.wnd_name:setText(name)
				self.wnd_image:setImage(image)
				self.wnd_image:setColor(0xFFFFFFFF)
				self.wnd_uid:setText(userId)
			end
		end)	

	elseif allPlayers then
		local player = allPlayers[pid]
		local image = player:getAvatarUrl()
		local name = player:getName()
		local uid = player:getUid()
		userId = uid
		if modUIUtil.utf8len(name) > 6 then
			name = modUIUtil.getMaxLenString(name, 6)
		end
		self.wnd_name:setText(name)
		self.wnd_image:setImage(image)
		self.wnd_image:setColor(0xFFFFFFFF)
		self.wnd_uid:setText(uid)
	end
	self.wnd_uid:setFont("end_number", 35, 1)

	if userId == ownerUid then
		self.wnd_owner:show(true)
	else
		self.wnd_owner:show(false)
	end
	-- 分数
	local score = 0
	local scoresFromPlayers = statistic.scores_from_players
	for spid, sc in ipairs(scoresFromPlayers) do
		if pid == spid - 1 then
			score = sc
			break
		end
	end
	self.wnd_score:setText(score)
	if score < 0 then
		--if index > 0 then
			--self.wnd_mark:setImage("ui:end_calculate_mine_p.png")
			--self.wnd_mark:setOffsetX(self.wnd_mark:getOffsetX() + 5)
		--else
			--self.wnd_mark:setImage("ui:end_calculate_mine_m.png")
			--self.wnd_mark:setOffsetX(self.wnd_mark:getOffsetX() + 15)
		--end
		self.wnd_mark:setImage("ui:end_calculate_m.png")
	elseif score == 0 then
		self.wnd_mark:show(false)
	elseif score > 0 then
		--if index > 0 then
			--self.wnd_mark:setOffsetX(self.wnd_mark:getOffsetX() -  15)
		--end
		self.wnd_mark:setImage("ui:end_calculate_mine_p.png")
		self.wnd_score:setFont("end_win_number", 40, 1)
	end
	
	-- 大赢家
	for _, p in ipairs(winners) do
		if p == pid then
			self.wnd_win:show(true)
			break
		end
	end
    -- 最佳炮手
	for _, p in ipairs(paoshous) do
		if p == pid then
			self.wnd_pao_shou:show(true)
			break
		end
	end
	self.userId = userId
	self.statistic = statistic
	self.idx = index
	self.playerCount = playerCount
	self:regEvent()
end

pEndPlayer.regEvent = function(self)
	self:addListener("ec_mouse_click", function()
		self.host:onChoosePlayerWindow(self)
	end)
end

pEndPlayer.getUserName = function(self)
	return self.wnd_name:getText() or ""
end

pEndPlayer.getTexturePath = function(self)
	return self.wnd_image:getTexturePath()
end

pEndPlayer.setPos = function(self, x, y)
	self:setPosition(0, y)
	self:setOffsetX(x)
end

pEndPlayer.showPlayerInfoWnd = function(self, flag)
	if not flag then
		if self.showInfoWnd then
			self.showInfoWnd:setParent(nil)
			self.showInfoWnd = nil
		end
	else
		if not self.showInfoWnd then
			self.showInfoWnd = modEndPlayerInfo.pEndPlayerInfo:new(self, self:getUserName(), self:getTexturePath(), self.userId, self.statistic, self.idx, self.playerCount)
		end
	end
end

pEndPlayer.destroy = function(self)
	if self.showInfoWnd then
		self.showInfoWnd:setParent(nil)
		self.showInfoWnd = nil
	end
	self:setParent(nil)
end
