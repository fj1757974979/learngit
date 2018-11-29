local modClubRpc = import("logic/club/rpc.lua")
local modUIUtil = import("ui/common/util.lua")

pJoinApply = pJoinApply or class(pWindow, pSingleton)

pJoinApply.init = function(self)
	self:load("data/ui/club_join_apply.lua")
	self:setParent(gWorld:getUIRoot())
	self.wnd_text:setText("点击输入留言")
	self:regEvent()
	modUIUtil.makeModelWindow(self, false, false)
end

pJoinApply.initUI = function(self)
	self.wnd_title:setText("请输入留言并确认是否加入\n#cr" .. self.clubInfo.name .. "#n" .. "俱乐部")
end

pJoinApply.regEvent = function(self)
	self.btn_send:addListener("ec_mouse_click", function() 
		self:sendRequst()	
	end)

	self.edit_text:addListener("ec_focus", function() 
		self.wnd_text:setText("")
	end)

	self.btn_close:addListener("ec_mouse_click", function() 
		self:close()
	end)

	self.edit_text:addListener("ec_unfocus", function() 
		local text = self.edit_text:getText()
		if not text or text == "" then
			self.wnd_text:setText("点击输入留言")
		end
	end)
end

pJoinApply.sendRequst = function(self)
	local text = self.edit_text:getText()
	if not text or text == "" or text == "" then
		text = "这家伙很懒，什么都没留下"
	end
	modClubRpc.sendJoinRequest(self.clubInfo.id, text, function(success, reason, reply)
		if success then
			infoMessage("申请成功, 请等待管理员确认")
			self:close()
		else
			infoMessage(reason)
		end
	end)
end

pJoinApply.open = function(self, clubInfo, isMyClub)
	self.clubInfo = clubInfo
	self.isMyClub = isMyClub
	self:initUI()
end

pJoinApply.close = function(self)
	self.isMyClub = false
	pJoinApply:cleanInstance()
end
