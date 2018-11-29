local modTroopConf = import("td/cultivate/config.lua")
local modUtil = import("td/util.lua")
local modGeneralMgr = import("td/general/main.lua")
local modGeneralConf = import("td/general/config.lua")
local modGeneral = import("td/general/general.lua")

pCellGeneralWnd = pCellGeneralWnd or class(pWindow)

pCellGeneralWnd.init = function(self)
	self.onResIdChange = function(self, btn, e)
		local gtype = self.editType:getText()
		if not self.resWnd.char then
			self.resWnd.char = pCharacter:new()
			self.resWnd.char:setParent(self.resWnd)
			self.resWnd.char:setPosition(self.resWnd:getWidth()/2, self.resWnd:getHeight()*2/3)
		end
		local conf = modGeneralConf.getGeneralDataByType(gtype)
		if conf then
			local resid = conf["resId"]
			self.resWnd.char:setResid(resid)
		else 
			log("error", "general not find", gtype)
		end
		
		if btn then
			self:onConfirm()
		end

		--[[
		--]]
	end
	self.onConfirm = function(self, btn, e)
		log("error", self.hostCell)
		if self.hostCell then
			local gtype = self.editType:getText()
			if not gtype then
				self.hostCell:layoutGeneralFromData(nil, {})
				-- self:close()
				return
			end
			local level = self.editLevel:getText()
			level = tonumber(level)

			local skillInfos = {}
			local skills = self.editSkills:getText()
			if skills then
				local arrSkill = string.split(skills, ",")
				logv("info", arrSkill)
				for _, skillId in pairs(arrSkill) do
					skillInfos[skillId] = {skillId=skillId, level=1}
				end
			end

			local mathprop = self:getTroopMathPropData()
			logv("info", mathprop)
			local ai = self.editAiPath:getText()
			if not mathprop then
				infoMessage("请正确输入属性！")
				return
			end

			local sx,sy = self.editSX:getText(), self.editSY:getText()
			local reward = self.editReward:getText()
			local data = {}
			data["lv"] = level
			data["mathprop"] = mathprop
			data["ai"] = ai
			data["skillInfos"] = skillInfos
			data["gtype"] = gtype
			data.reward = reward
			data.sx = sx or 1
			data.sy = sy or 1

			self.hostCell:layoutGeneralFromData(gtype, data)
			-- self:close()
		end
	end
	self.onClose = function(self, btn, e)
		self:close()
	end
	self:load("tool/leveleditor/template/cell_general_wnd.lua")
	self:setParent(parent)
	-- modUtil.makeModelWindow(self)
	self:show(false)
end

pCellGeneralWnd.getTroopMathPropData = function(self)
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
	wnd:setText(string.format("%d", num or 0))
end

local setFloatEdit = function(wnd, fl)
	wnd:setText(string.format("%.2f", fl or 0))
end

local setStrEdit = function(wnd, str)
	wnd:setText(str or "")
end

pCellGeneralWnd.setTroopMathPropData = function(self, mathprop)
	logv("info", mathprop)
	--[[
	setNumEdit(self.editHp, mathprop.baseHp)
	setNumEdit(self.editAtt, mathprop.baseAtt)
	setNumEdit(self.editArmor, mathprop.baseArmor)
	setFloatEdit(self.editAttSpeed, mathprop.baseAttSpeed)
	setNumEdit(self.editAttScope, mathprop.attScope)
	setNumEdit(self.editMoveSpeed, mathprop.baseMoveSpeed)
	--]]

	setNumEdit(self.editHp, mathprop.maxHP or mathprop.baseHp)
	setNumEdit(self.editAtt, mathprop.attack or mathprop.baseAtt)
	setNumEdit(self.editArmor, mathprop.armor or mathprop.baseArmor)
	setFloatEdit(self.editAttSpeed, mathprop.attSpeed or mathprop.baseAttSpeed)
	setNumEdit(self.editAttScope, mathprop.attScope)
	setNumEdit(self.editMoveSpeed, mathprop.moveSpeed or mathprop.baseMoveSpeed)

	if mathprop.maxHP then
		setNumEdit(self.txtHp, mathprop.maxHP)
		setNumEdit(self.txtAttack, mathprop.attack)
		setNumEdit(self.txtArmor, mathprop.armor)
		setFloatEdit(self.txtAttSpeed, mathprop.attSpeed)
		setNumEdit(self.txtAttScope, mathprop.attScope)
		setNumEdit(self.txtMoveSpeed, mathprop.moveSpeed)
	end
end

pCellGeneralWnd.onScaleChange = function(self)
	local sx,sy = self.editSX:getText(), self.editSY:getText()
	if self.resWnd.char then
		self.resWnd.char:setScale(sx, sy)
	end
	self:onConfirm()
end

pCellGeneralWnd.onReset = function(self)
	local level = tonumber(self.editLevel:getText())
	if self.hostCell and self.hostCell:getGeneralType() then
		local gtype = self.hostCell:getGeneralType()
		local gmgr = modGeneralMgr:getGeneralMgr()
		local general = gmgr:newFakeGeneral(self.editType:getText(), level, modGeneral.getGeneralInitData())
		
		local prop = general:getMathProperty()
		logv("error", prop)
		self:setTroopMathPropData(prop)
	end
end

pCellGeneralWnd.onResetSkill = function(self)
	local gtype = self.editType:getText()
	local conf = modGeneralConf.getGeneralDataByType(gtype)
	if conf then
		-- reset skill
		local skills = conf["bornSkills"]
		local skillInfos = {}
		for _, skillId in pairs(skills) do
			skillInfos[skillId] = {skillId=skillId, level=1}
		end
		
		local data = self.hostCell:getGeneralData()
		data.skillInfos = skillInfos

		local skillStr = ""
		for skillId, info in pairs(skillInfos) do
			skillStr = string.format("%s,%s", skillId, skillStr)
		end
		skillStr = string.sub(skillStr, 1, -2)
		self.editSkills:setText(skillStr)
	end
end

pCellGeneralWnd.refresh = function(self)
	if self.hostCell and self.hostCell:getGeneralType() then
		local data = self.hostCell:getGeneralData()
		local ai = data["ai"]
		local level = data["lv"]
		local skillInfos = data["skillInfos"]
		local gtype = data["gtype"]
		local sx,sy = data.sx or 1, data.sy or 1
		local reward = data["reward"]
		setStrEdit(self.editLevel, level)
		setStrEdit(self.editType, gtype)
		setStrEdit(self.editAiPath, ai)
		setFloatEdit(self.editSX, sx)
		setFloatEdit(self.editSY, sy)
		setStrEdit(self.editReward, reward)

		local skillStr = ""
		for skillId, info in pairs(skillInfos) do
			skillStr = string.format("%s,%s", skillId, skillStr)
		end
		skillStr = string.sub(skillStr, 1, -2)
		setStrEdit(self.editSkills, skillStr)

		local mathprop = data["mathprop"]
		self:setTroopMathPropData(mathprop)

		self:onResIdChange()
		self:onScaleChange()
	else
		setStrEdit(self.editLevel, "")
		setStrEdit(self.editType, "")
		setStrEdit(self.editAiPath, "")
		self:setTroopMathPropData({})
		setStrEdit(self.editSkills, "")
		setFloatEdit(self.editSX, 0)
		setFloatEdit(self.editSY, 0)
		setStrEdit(self.editReward, "")
	end
end

pCellGeneralWnd.open = function(self, hostCell)
	self:show(true)
	self.hostCell = hostCell
	self:refresh()
end

pCellGeneralWnd.close = function(self)
	if self.hostCell then
		self.hostCell:onCloseMenu()
		self.hostCell = nil
	end
	self:show(false)
end

gCellGeneralWnd = nil

getCellGeneralWnd = function()
	if not gCellGeneralWnd then
		gCellGeneralWnd = pCellGeneralWnd:new()
		gCellGeneralWnd:setParent(gWorld:getUIRoot())
	end
	return gCellGeneralWnd
end

open = function(cell)
	local wnd = getCellGeneralWnd()
	wnd:open(cell)
end

close = function()
	local wnd = getCellGeneralWnd()
	wnd:close()
end

