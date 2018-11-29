local modTroopConf = import("td/cultivate/config.lua")
local modUtil = import("td/util.lua")

pCellTroopWnd = pCellTroopWnd or class(pWindow)

pCellTroopWnd.init = function(self)
	self.onResIdChange = function(self, btn, e)
		local resid = self.editResId:getText()
		if not self.resWnd.char then
			self.resWnd.char = pCharacter:new()
			self.resWnd.char:setParent(self.resWnd)
			self.resWnd.char:setPosition(self.resWnd:getWidth()/2, self.resWnd:getHeight()*2/3)
		end
		self.resWnd.char:setResid(resid)
		self:onConfirm()
	end
	self.onConfirm = function(self, btn, e)
		if self.hostCell then
			local num = self.editNum:getText()
			num = tonumber(num)
			local resid = self.editResId:getText()
			resid = tostring(resid)
			local troopType = self.editType:getText()
			troopType = tostring(troopType)
			local mathprop = self:getTroopMathPropData()
			local ai = self.editAiPath:getText()
			local sx, sy = self.editSX:getText(), self.editSY:getText()
			if not mathprop then
				infoMessage(TEXT("请正确输入属性！"))
				return
			end
			if not num or num < 0 then
				infoMessage(TEXT("请正确输入数量！"))
				return
			end
			if not resid or resid == "" then
				infoMessage(TEXT("请正确输入造型！"))
				return
			end
			if not troopType or troopType == "" then
				infoMessage(TEXT("请正确输入类型！"))
				return
			end

			local data = {}
			data["resid"] = resid
			data["lv"] = 1
			data["type"] = troopType
			data["mathprop"] = mathprop
			data["ai"] = ai
			data.sx = sx or 1
			data.sy = sy or 1

			self.hostCell:layoutTroopsFromData(data, num)
		end
	end
	self.onClose = function(self, btn, e)
		self:close()
	end
	self:load("tool/leveleditor/template/cell_troop_wnd.lua")
	self:setParent(parent)
	-- modUtil.makeModelWindow(self)
	self:show(false)
end

pCellTroopWnd.getTroopMathPropData = function(self)
	local baseHp = self.editHp:getText()
	baseHp = tonumber(baseHp)
	local baseAtt = self.editAtt:getText()
	baseAtt = tonumber(baseAtt)
	local baseArmor = self.editArmor:getText()
	baseArmor = tonumber(baseArmor)
	local attSpeed = self.editAttSpeed:getText()
	attSpeed = tonumber(attSpeed)
	local attScope = self.editAttScope:getText()
	attScope = tonumber(attScope)
	local moveSpeed = self.editMoveSpeed:getText()
	moveSpeed = tonumber(moveSpeed)
	if baseHp and baseArmor and baseAtt and attScope and 
		attSpeed and moveSpeed then
		return {
			baseHp = baseHp,
			baseAtt = baseAtt,
			baseArmor = baseArmor,
			baseAttSpeed = attSpeed,
			attScope = attScope,
			baseMoveSpeed = moveSpeed
		}
	else
		return nil
	end
end

local setNumEdit = function(wnd, num)
	wnd:setText(string.format("%d", num))
end

local setFloatEdit = function(wnd, fl)
	wnd:setText(string.format("%.2f", fl))
end

local setStrEdit = function(wnd, str)
	wnd:setText(str)
end

pCellTroopWnd.setTroopMathPropData = function(self, mathprop)
	setNumEdit(self.editHp, mathprop.baseHp)
	setNumEdit(self.editAtt, mathprop.baseAtt)
	setNumEdit(self.editArmor, mathprop.baseArmor)
	setFloatEdit(self.editAttSpeed, mathprop.baseAttSpeed)
	setNumEdit(self.editAttScope, mathprop.attScope)
	setNumEdit(self.editMoveSpeed, mathprop.baseMoveSpeed)
end

pCellTroopWnd.onScaleChange = function(self)
	local sx,sy = self.editSX:getText(), self.editSY:getText()
	if self.resWnd.char then
		self.resWnd.char:setScale(sx, sy)
	end
	self:onConfirm()
end

pCellTroopWnd.refresh = function(self)
	if self.hostCell and self.hostCell:isTroopCell() then
		local data = self.hostCell:getTroopsData()
		local num = self.hostCell:getTroopNum()
		local resid = data["resid"]
		local sx,sy = data.sx or 1, data.sy or 1
		local troopType = data["type"]
		local ai = data["ai"]
		setFloatEdit(self.editSX, sx)
		setFloatEdit(self.editSY, sy)
		setStrEdit(self.editResId, resid)
		setStrEdit(self.editType, troopType)
		setNumEdit(self.editNum, num)
		setStrEdit(self.editAiPath, ai)

		local mathprop = data["mathprop"]
		logv("info", mathprop)
		self:setTroopMathPropData(mathprop)

		self:onResIdChange()
		self:onScaleChange()
	end
end

pCellTroopWnd.open = function(self, hostCell)
	self:show(true)
	self.hostCell = hostCell
	self:refresh()
end

pCellTroopWnd.close = function(self)
	if self.hostCell then
		self.hostCell:onCloseMenu()
		self.hostCell = nil
	end
	self:show(false)
end

gCellTroopWnd = nil

getCellTroopWnd = function()
	if not gCellTroopWnd then
		gCellTroopWnd = pCellTroopWnd:new()
		gCellTroopWnd:setParent(gWorld:getUIRoot())
	end
	return gCellTroopWnd
end

open = function(cell)
	local wnd = getCellTroopWnd()
	wnd:open(cell)
end

close = function()
	local wnd = getCellTroopWnd()
	wnd:close()
end

