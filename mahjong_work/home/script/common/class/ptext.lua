gAllImgFaceName = {}

puppy.render.pFontMgr.addImgFont = function(self, name, path, gw, gh)
	gAllImgFaceName[name] = true
	gw = gw or 16
	gh = gh or 23
	puppy.render.pFontMgr.addImgFace(self, name, path, 24, gw, gh)
end

puppy.render.pFontMgr.addBmpFont = function(self, name, path, config, size)
	--gAllImgFaceName[name] = true
	puppy.render.pFontMgr.addBmpFace(self, name, path, config, size)
end

puppy.world.pText.realSetFont = puppy.world.pText.realSetFont or puppy.world.pText.setFont

puppy.world.pText.setFont = function(self, name, size, bold)
	if gAllImgFaceName[name] then
		size = 24
		bold = 0
	end
	puppy.world.pText.realSetFont(self, name, size, bold)
end

puppy.world.pText.enable = function(self, flg)
	if flg then
		if self.__originColor then
			self:setColor(self.__originColor)
			self.__originColor = nil
		end
	else
		if not self.__originColor then
			self.__originColor = self:getColor()
		end
		self:setColor(0xff777777)
	end
end
