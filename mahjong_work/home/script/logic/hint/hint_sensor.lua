local modHintMgr = import("logic/hint/mgr.lua")
local modEvent = import("common/event.lua")
import("logic/hint/macros.lua")

local hintTypeToImg = {
	[T_HINT_RED_POINT] = "ui:hint_red_point.png",
}

pHintSensorBase = pHintSensorBase or class()

pHintSensorBase.init = function(self)
	self.allConcernHints = self:getConcernHints()
	self.__hint_hdr = modHintMgr.pHintMgr:instance():handleHints(self.allConcernHints, function(hintName, isShow)
		--log("info", "[pHintSensorBase.handleHint callback]", hintName, isShow)
		self:handleHintByType(hintName, isShow)
		return self:bubbleHint()
	end)
	self.__redo_hdr = modEvent.handleEvent("REDO_PREFIX_HINT", function(hintName)
		self:redoPrefixHint(hintName)
	end)
	self.__destroy_hdr = modEvent.handleEvent("DESTROY_GAME", function()
		if self.__hint_hdr then
			modHintMgr.pHintMgr:instance():unhandleHints(self.__hint_hdr)
			self.__hint_hdr = nil
		end
	end)
end

pHintSensorBase.handleHintByType = function(self, hintName, isShow)
	local wnd = self:getWndByHintName(hintName)
	--log("info", "[pHintSensorBase.handleHintByType]", hintName, isShow)
	if not wnd then
		log("error", "can't find wnd to handle ", hintName, isShow)
		return
	end
	if isShow then
		local hintType = self:getHintTypeByName(hintName)
		if hintType then
			self:assembleHint(wnd, hintName, hintType)
		end
	else
		self:disassembleHint(wnd, hintName)
	end
end

pHintSensorBase.updateSelfHints = function(self)
	self:resetHintWnds()
	self.allConcernHints = self.allConcernHints or self:getConcernHints()
	modHintMgr.pHintMgr:instance():updateHints(self.allConcernHints, self.__hint_hdr)
end

pHintSensorBase.resetHintWnds = function(self)
	self.allConcernHints = self.allConcernHints or self:getConcernHints()
	for _, hintName in ipairs(self.allConcernHints) do
		local wnd = self:getWndByHintName(hintName)
		if wnd then
			self:disassembleHint(wnd, hintName, true)
		end
	end
end

pHintSensorBase.getConcernHints = function(self)
	-- to be implement
	return {}
end

pHintSensorBase.getHintTypeByName = function(self, hintName)
	-- to be implement
	return T_HINT_RED_POINT
end

pHintSensorBase.getWndByHintName = function(self, hintName)
	-- to be implement
	return nil
end

pHintSensorBase.bubbleHint = function(self)
	return true
end

pHintSensorBase.redoPrefixHint = function(self, hintName)
	-- to be implement
	return
end

pHintSensorBase.assembleHint = function(self, wnd, hintName, hintType)
	wnd.__hint_info__ = wnd.__hint_info__ or {}
	if wnd.__hint__ then
		if wnd.__hint_info__[hintName] == hintType then
			return
		else
			wnd.__hint__:setParent(nil)
		end
	end
	wnd.__hint_info__[hintName] = hintType
	--[[
	if hintType == T_HINT_LIGHT_RING then
		local hint = pSprite()
		hint:setTexture("effect:ui/red_dot.fsi", 0)
		hint:setParent(wnd)
		local w, h = wnd:getWidth(), wnd:getHeight()
		local _w, _h = 85, 85 
		hint:setScale(w/_w, h/_h)
		hint:setPosition(w/2, h/2)
		hint:enableEvent(false)
		wnd.__hint__ = hint
		return
	end
	if hintType == T_HINT_LIGHT_ROUND then
		local hint = pSprite()
		hint:setTexture("effect:ui/long_frame.fsi", 0)
		hint:setParent(wnd)
		local w, h = wnd:getWidth(), wnd:getHeight()
		local _w, _h = 275, 70
		hint:setScale(w/_w, h/_h)
		hint:setPosition(w/2, h/2)
		hint:enableEvent(false)
		wnd.__hint__ = hint
		return
	end
	]]--

	local img = hintTypeToImg[hintType]
	if not img then
		log("error", "can't find hint resource")
		return
	end
	local hint = pWindow()
	hint:setImage(img)
	hint:setParent(wnd)
	hint:setZ(-10)
	hint:enableEvent(false)
	hint:setToImgHW(function()
		local w, h = hint:getWidth(), hint:getHeight()
		hint:setKeyPoint(w/2, h/2)
	end)
	local w, h = wnd:getWidth(), wnd:getHeight()
	if hintType == T_HINT_RED_POINT then
		hint:setPosition(w, 0)
	--[[
	elseif hintType == T_HINT_PLUS then
		hint:setPosition(w/2, h/2)
		hint:setScale(0.5, 0.5)
	elseif hintType == T_HINT_FULL then
		hint:setPosition(w, 0)
	elseif hintType == T_HINT_NEW then
		hint:setPosition(w, 0)
		--hint:setPosition(w + hint:getWidth()/2, -hint:getHeight()/2)
		--hint:setScale(0.8, 0.8)
	]]--
	end
	wnd.__hint__ = hint
end

pHintSensorBase.disassembleHint = function(self, wnd, hintName, all)
	if all then
		if wnd.__hint__ then
			wnd.__hint__:setParent(nil)
			wnd.__hint__ = nil
		end
		wnd.__hint_info__ = {}
	else
		wnd.__hint_info__ = wnd.__hint_info__ or {}
		wnd.__hint_info__[hintName] = nil
		if table.size(wnd.__hint_info__) <= 0 then
			if wnd.__hint__ then
				wnd.__hint__:setParent(nil)
				wnd.__hint__ = nil
			end
			wnd.__hint_info__ = {}
		end
	end
end

pHintSensorBase.destroy = function(self)
	if self.__hint_hdr then
		modHintMgr.pHintMgr:instance():unhandleHints(self.__hint_hdr)
		self.__hint_hdr = nil
	end
end
