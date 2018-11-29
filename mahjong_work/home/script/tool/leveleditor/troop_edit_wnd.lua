local modLevelEditor = import("tool/leveleditor/main.lua")

pTroopEditWnd = pTroopEditWnd or class(pWindow)


local loopSelectTroop = function(func)
	return function(self)
		local troops = modLevelEditor.pLevelEditor:instance():getSelectTroops()
		for _,troop in ipairs(troops) do
			func(self, troop)
		end
	end
end

pTroopEditWnd.init = function(self, parent, editor)
	self:load("tool/leveleditor/template/troop_edit_wnd.lua")
	self:setParent(parent)
	self:show(false)

	self.copyBtn:addListener("ec_mouse_click", function(e)
		self.editor.copyData = self.hostTroop.data
	end)

	self.delBtn:addListener("ec_mouse_click", function(e)
		loopSelectTroop(function(_, troop)
			troop:setParent(nil)
			self.editor.allTroopsObjs[troop] = nil
			self.hostTroop = nil
		end)()
	end)

	self.MAX_TROOP_LEVEL = 6

	self.editor = editor
end

local getEditContent = function(wnd)
	local num = wnd:getText()
	num = tonumber(num)
	if not num then
		infoMessage("请填写数字！")
	end
	return num
end

local parseSkills = function(skillsStr)
	if not skillsStr then return {} end

	local t = string.split(skillsStr, ",")
	return t
end

pTroopEditWnd.saveTroopAttr = function(self)


	local troop = self.hostTroop
	local x, y = troop:getX(), troop:getY()

	local level = getEditContent(self.editLevel)
	local type = getEditContent(self.editType)
	local resid = getEditContent(self.editResid)
	local dir = getEditContent(self.editDir)
	local ai = self.editAiPath:getText()

	local hp = getEditContent(self.editHp)
	local att = getEditContent(self.editAtt)
	local armor = getEditContent(self.editArmor)
	local attSpeed = getEditContent(self.editAttSpeed)
	local attScope = getEditContent(self.editAttScope)
	local moveSpeed = getEditContent(self.editMoveSpeed)

	-- TODO 暂时不支持部队加技能
	--local skills = parseSkills(self.editSkills:getText())

	troop.data.lv = level
	troop.data.resid = resid
	troop.data.type = type
	troop.data.ai = ai
	troop.data.config.x = x
	troop.data.config.y = y
	troop.data.dir = dir

	troop.data.mathprop.baseHp = hp
	troop.data.mathprop.baseAtt = att
	troop.data.mathprop.baseArmor = armor
	troop.data.mathprop.attSpeed = attSpeed
	troop.data.mathprop.attScope = attScope
	troop.data.mathprop.moveSpeed = moveSpeed

	troop:setResid(resid)
	troop:setDirIndex(dir)

	self:refresh()
end

pTroopEditWnd.sameResid = loopSelectTroop(function(self, troop) 
	local resid = getEditContent(self.editResid)
	troop:setResid(resid)
	troop.data.resid = resid
end)

pTroopEditWnd.sameDir = loopSelectTroop(function(self, troop)
	local dir = getEditContent(self.editDir)
	troop:setDirIndex(dir)
	troop.data.dir = dir
end)

pTroopEditWnd.sameType = loopSelectTroop(function(self, troop)
	local type = getEditContent(self.editType)
	troop.data.type = type
end)

pTroopEditWnd.sameAI = loopSelectTroop(function(self, troop)
	local ai = self.editAiPath:getText()
	troop.data.ai = ai
end)

pTroopEditWnd.sameLevel = loopSelectTroop(function(self, troop)
	local level = getEditContent(self.editLevel)	
	troop.data.lv = level
end)

pTroopEditWnd.sameAttack = loopSelectTroop(function(self, troop)
	local att = getEditContent(self.editAtt)
	troop.data.mathprop.baseAtt = att
end)

pTroopEditWnd.sameAttackScope = loopSelectTroop(function(self, troop)
	local attScope = getEditContent(self.editAttScope)
	troop.data.mathprop.attScope = attScope
end)

pTroopEditWnd.sameMoveSpeed = loopSelectTroop(function(self, troop)
	local moveSpeed = getEditContent(self.editMoveSpeed)
	troop.data.mathprop.baseMoveSpeed = moveSpeed
end)

pTroopEditWnd.sameHP = loopSelectTroop(function(self, troop)
	local hp = getEditContent(self.editHp)
	troop.data.mathprop.baseHp = hp
end)

pTroopEditWnd.sameArmor = loopSelectTroop(function(self, troop)
	local armor = getEditContent(self.editArmor)
	troop.data.mathprop.baseArmor = armor
end)

pTroopEditWnd.sameAttSpeed = loopSelectTroop(function(self, troop)
	local attSpeed = getEditContent(self.editAttSpeed)
	troop.data.mathprop.attSpeed = attSpeed
end)

pTroopEditWnd.open = function(self, troop)
	self.hostTroop = troop 
		
	self:show(true)

	self:refresh()
end

pTroopEditWnd.close = function(self)
	self:show(false)
end

pTroopEditWnd.refresh = function(self)
	local troop = self.hostTroop
	local data = troop.data

	local setText = function(wnd, numInfo)
		if wnd == self.editAttSpeed then
			wnd:setText(string.format("%f", numInfo))
		else
			wnd:setText(string.format("%d", numInfo))
		end
	end

	-- 等级
	local lv = data["lv"]
	setText(self.editLevel, lv)
	-- 资源id
	local resid = data["resid"]
	setText(self.editResid, resid)
	-- 类型
	local type = data["type"]
	setText(self.editType, type)
	-- ai
	local ai = data["ai"]
	self.editAiPath:setText(ai)
	
	local dir = data.dir or 2
	self.editDir:setText(dir)
	-- 气血
	local hp = data["mathprop"]["baseHp"]
	setText(self.editHp, hp)
	-- 攻击
	local att = data["mathprop"]["baseAtt"]
	setText(self.editAtt, att)
	-- 防御
	local armor = data["mathprop"]["baseArmor"]
	setText(self.editArmor, armor)
	-- 攻速
	local attSpeed = data["mathprop"]["attSpeed"]
	setText(self.editAttSpeed, attSpeed)
	-- 攻击范围
	local attScope = data["mathprop"]["attScope"]
	setText(self.editAttScope, attScope)
	-- 移动速度
	local moveSpeed = data["mathprop"]["baseMoveSpeed"]
	setText(self.editMoveSpeed, moveSpeed)

	if self.sprite then
		self.sprite:setParent(nil)
	end

	self.sprite = pCharacter()
	self.sprite:setResid(resid)
	self.sprite:setDirIndex(dir)
	self.sprite:setParent(self.resWnd)
	local w, h = self.resWnd:getWidth(), self.resWnd:getHeight()
	self.sprite:setPosition(w/2, h)
end

