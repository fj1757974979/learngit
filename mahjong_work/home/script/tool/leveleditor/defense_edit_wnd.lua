
pDefenseEditWnd = pDefenseEditWnd or class(pWindow)

pDefenseEditWnd.init = function(self, parent)
	self:load("data/ui/building_edit_wnd.lua")
	self:setParent(parent)
	self:show(false)

	self.saveBtn:addListener("ec_mouse_click", function(e)
		self:saveBuildAttr()
	end)

	self.MAX_BUILDING_LEVEL = 6
end

pDefenseEditWnd.saveBuildAttr = function(self)
	local hostBuild = self.hostBuild

	local getEditContent = function(wnd)
		local num = wnd:getText()
		num = tonumber(num)
		if not num then
			infoMessage("请填写数字！")
		end
		return num
	end

	local level = getEditContent(self.editLevel)
	if not level then return end

	if hostBuild:getProp("level") ~= level then
		if level > self.MAX_BUILDING_LEVEL then
			infoMessage("超出最大等级！")
			return
		end
		-- 等级不一样，按照等级来填写
		hostBuild:setLinkedProp("level", level)
		hostBuild:upGradeAttr()
		self:refresh()
	else
		local hp = getEditContent(self.editHp)
		local att = getEditContent(self.editAtt)
		local armor = getEditContent(self.editArmor)
		local attSpeed = getEditContent(self.editAttSpeed)
		local attScope = getEditContent(self.editAttScope)

		if hp and att and armor and attSpeed and attScope then
			hostBuild:setLinkedProp("baseHp", hp)
			hostBuild:setLinkedProp("baseAtt", att)
			hostBuild:setLinkedProp("baseArmor", armor)
			hostBuild:setLinkedProp("baseAttSpeed", attSpeed)
			hostBuild:setLinkedProp("attScope", attScope)
			self:refresh()
		else
			infoMessage("填写不正确！")
		end
	end
end

pDefenseEditWnd.open = function(self, hostBuild)
	if not self.hostBuild then
		self.hostBuild = hostBuild
	end
	self:show(true)

	self:refresh()
end

pDefenseEditWnd.close = function(self)
	self:show(false)
end

pDefenseEditWnd.onTemplateChange = function(self)
	local templateId = self.editTemplate:getText()
	if self.hostBuild then
		self.hostBuild.sprite:clear()
		self.hostBuild.sprite:load(templateId)
		self.hostBuild:getConf().templateId = templateId
	end
end

pDefenseEditWnd.refresh = function(self)
	local setText = function(wnd, numInfo)
		if wnd == self.editAttSpeed then
			wnd:setText(string.format("%f", numInfo))
		else
			wnd:setText(string.format("%d", numInfo))
		end
	end
	local hostBuild = self.hostBuild
	local conf = hostBuild:getConf()
	self.txtName:setText(conf["name"])
	-- 等级
	local lv = hostBuild:getProp("level")
	setText(self.editLevel, lv)

	local templateId = conf["templateId"]
	self.editTemplate:setText(templateId)
	-- 气血
	local hp = hostBuild:getProp("maxHP")
	setText(self.editHp, hp)
	-- 攻击
	local att = hostBuild:getProp("attack")
	setText(self.editAtt, att)
	-- 防御
	local armor = hostBuild:getProp("armor")
	setText(self.editArmor, armor)
	-- 攻速
	local attSpeed = hostBuild:getProp("attSpeed")
	setText(self.editAttSpeed, attSpeed)
	-- 攻击范围
	local attScope = hostBuild:getProp("attScope")
	setText(self.editAttScope, attScope)
end

