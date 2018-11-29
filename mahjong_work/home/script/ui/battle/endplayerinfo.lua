local modUIUtil = import("ui/common/util.lua")


pEndPlayerInfo = pEndPlayerInfo or class(pWindow)

pEndPlayerInfo.init = function(self, parentWnd, name, image, uid, statics, index, playerCount)
	self:load("data/ui/endplayerinfo.lua")
	self.wnd_uid:setFont("end_number", 35, 1)
	self.wnd_zimo:setText("自摸次数：")
	self.wnd_dianpao:setText("点炮次数：")
	self.wnd_jiepao:setText("接炮次数：")
	self.wnd_minggang:setText("明杠次数：")
	self.wnd_angang:setText("暗杠次数：")
	self.wnd_zimo_value:setText("x" .. statics.zimo_count)
	self.wnd_jiepao_value:setText("x" .. (statics.jiepao_count + statics.gang_jiepao_count))
	self.wnd_dianpao_value:setText("x" .. (statics.fangpao_count + statics.gang_fangpao_count))
	self.wnd_minggang_value:setText("x" .. (statics.xiaominggang_count + statics.jiegang_count))
	self.wnd_angang_value:setText("x" .. statics.angang_count)

	self:setAlignY(ALIGN_TOP)
	self:setZ(C_BATTLE_UI_Z)

	self:setParent(parentWnd)
	self.wnd_name:setText(name)
	self.wnd_image:setImage(image)
	self.wnd_image:setColor(0xFFFFFFFF)
	self.wnd_uid:setText(uid)	
	if index == 0 then
		self:setPos(633 / 2 + 10, 0) --gGameHeight * 0.43)
	else
		self:setPos(100, 0)
	end
end

pEndPlayerInfo.setPos = function(self, x, y)
	self:setOffsetX(x)
	self:setPosition(0, y)
end

