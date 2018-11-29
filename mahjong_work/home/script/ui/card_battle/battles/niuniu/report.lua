local modTrigger = import("logic/trigger/mgr.lua")

pReportItem = pReportItem or class(pWindow)

pReportItem.init = function(self, info)
	local player = info.player
	if player:isMyself() then
		self:load("data/ui/card/niuniu_report_item_self.lua")
	else
		self:load("data/ui/card/niuniu_report_item_other.lua")
	end
	self.__name_hdr = player:bind("name", function(name)
		self.txt_name:setText(name)
	end, "")
	self.__avatar_hdr = player:bind("avatarurl", function(url)
		if not url or url == "" then
			url = "ui:image_default_female.png"
		end
		self.img_head:setImage(url)
	end)
	self.txt_id:setText(player:getUserId())
	self.score = info.score
	self.waterScore = info.waterScore or 0
	self.player = player
	if self.score > 0 then
		self.txt_score:setText("+"..self.score)
		self.txt_score:setTextColor(0xFFb13b22)
	else
		self.txt_score:setText(self.score)
		self.txt_score:setTextColor(0xFF168805)
	end
	if self.waterScore > 0 then
		self.txt_water_score:setText(sf("小费%d", self.waterScore))
		self.txt_water_score:setTextColor(0xFFb13b22)
	end
	self.img_big_win:show(false)
	self.wnd_fangzhu:show(player:getUserId() == player:getBattle():getOwnerId())
end

pReportItem.getScore = function(self)
	return self.score
end

pReportItem.setBigWinFlag = function(self)
	self.img_big_win:show(true)
end

pReportPanel = pReportPanel or class(pWindow, pSingleton)

pReportPanel.init = function(self)
	self:load("data/ui/card/niuniu_report.lua")
	self.btn_return:addListener("ec_mouse_click", function()
		self:close()
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
	self.playerInfoWnds = {}
	self:setParent(gWorld:getUIRoot())
	self:setRenderLayer(C_MAX_RL)
	self:setZ(C_MAX_Z)
end

--[[
playerInfo = {
	head_img = url,
	name = "姜小白",
	id = 1234567,
	score = 234,
	is_big_winner = true,
}
--]]
pReportPanel.setPlayerInfo = function(self, selfInfo, playerInfos)
	for _,wnd in ipairs(self.playerInfoWnds) do
		wnd:setParent(nil)
	end
	self.playerInfoWnds = {}
	local bigWinnerWnd = nil
	local wnd = pReportItem:new(selfInfo)
	wnd:setParent(self)
	table.push_back(self.playerInfoWnds, wnd)
	for _, info in ipairs(playerInfos) do
		local wnd = pReportItem:new(info)
		wnd:setParent(self)
		table.push_back(self.playerInfoWnds, wnd)
	end

	local bigScore = 0
	local bigWnd = nil
	for _, wnd in ipairs(self.playerInfoWnds) do
		if wnd:getScore() > bigScore then
			bigWnd = wnd
			bigScore = wnd:getScore()
		end
	end

	if #self.playerInfoWnds == 2 then
		self.playerInfoWnds[1]:setOffsetY(110)
		self.playerInfoWnds[2]:setOffsetY(-110)
	elseif #self.playerInfoWnds == 3 then
		self.playerInfoWnds[1]:setOffsetY(110)
		self.playerInfoWnds[2]:setOffsetY(-110)
		self.playerInfoWnds[2]:setOffsetX(-260)
		self.playerInfoWnds[3]:setOffsetY(-110)
		self.playerInfoWnds[3]:setOffsetX(260)
	elseif #self.playerInfoWnds == 4 then
		self.playerInfoWnds[1]:setOffsetY(150 + 20)
		self.playerInfoWnds[2]:setOffsetY(-60 + 40)
		self.playerInfoWnds[2]:setOffsetX(-260)
		self.playerInfoWnds[3]:setOffsetY(-60 + 40)
		self.playerInfoWnds[3]:setOffsetX(260)
		self.playerInfoWnds[4]:setOffsetY(-200)
	elseif #self.playerInfoWnds == 5 then
		self.playerInfoWnds[1]:setOffsetY(150 + 20)
		self.playerInfoWnds[2]:setOffsetY(-60 + 40)
		self.playerInfoWnds[2]:setOffsetX(-260)
		self.playerInfoWnds[3]:setOffsetY(-60 + 40)
		self.playerInfoWnds[3]:setOffsetX(260)
		self.playerInfoWnds[4]:setOffsetY(-200)
		self.playerInfoWnds[4]:setOffsetX(-260)
		self.playerInfoWnds[5]:setOffsetY(-200)
		self.playerInfoWnds[5]:setOffsetX(260)
	end

	if bigWnd then
		bigWnd:setBigWinFlag()
	end
end

pReportPanel.open = function(self, callback)
	self.callback = callback
	self:show(true)
end

pReportPanel.close = function(self)
	if self.callback then
		self.callback()
		self.callback = nil
	end
	pReportPanel:cleanInstance()
end

testReport = function()
	sTestReport = pReportPanel:new()
	sTestReport:setParent(gWorld:getUIRoot())
	sTestReport:show(true)
	sTestReport:setPlayerInfo(
		{
			head_img = url,
			name = "姜小白",
			id = 1234567,
			score = 234,
			is_big_winner = true,
		}, {
			{
				head_img = url,
				name = "小雪",
				id = 1234567,
				score = -100,
				is_big_winner = false,
			},
			{
				head_img = url,
				name = "小雪",
				id = 1234567,
				score = -100,
				is_big_winner = false,
			},
			{
				head_img = url,
				name = "小雪",
				id = 1234567,
				score = -100,
				is_big_winner = false,
			},
			{
				head_img = url,
				name = "小雪",
				id = 1234567,
				score = -100,
				is_big_winner = false,
			},

		})
end
