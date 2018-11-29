local modMsg = import("common/ui/msgbox.lua")
local modEditable = import("editable.lua")
local modMenu = import("tool/menu.lua")
local modSavePanel = import("tool/uieditor/savepanel.lua")
local modLoadPanel = import("tool/uieditor/loadpanel.lua")
local modFileList = import("common/ui/control/filelist.lua")
local modHistory = import("history.lua")

pUIEditor = pUIEditor or class(pWindow, pSingleton)

pUIEditor.init = function(self)
	self:setParent(gWorld:getUIRoot())
	self:setSize(gGameWidth, gGameHeight)
	self:setColor(0x00000000)
	self.mainPanel = nil
	self.selectWnd = nil
	self.selectWndList = {}
	self.path = "data/ui/blank.lua"

	self.menu = pWindow()
	self.menu:setParent(self)

	self.simulator = pWindow()
	self.simulator:setParent(self)
	self.simulator:load("tool/uieditor/template/iphone4.lua")

	self.hookKeyDown = gWorld:addHook("ec_key_down", function(e)
		-- log("info", "key down", e:key())
		local key = e:key()
		if key == 8 and e:isControlDown() then -- DELETE
			self.propPanel.btnDeleteFunc()	
		elseif key == 99 and e:isControlDown() then -- C-c
			self.propPanel.btnCopyFunc()
		elseif key == 118 and e:isControlDown() then -- C-v
			self.propPanel.btnPasteFunc()
		elseif key == 1073741904 then --left
			self:moveSelect(-1, 0)
		elseif key == 1073741903 then --right
			self:moveSelect(1, 0)
		elseif key == 1073741905 then --down
			self:moveSelect(0, 1)
		elseif key == 1073741906 then --up
			self:moveSelect(0, -1)
		end
	end)

	local x, y = self.simulator:getX(), self.simulator:getY()
	self.menu.editorMode = function(menu, btn, event)
		self.simulator:setScale(0.85, 0.85)
		self.simulator:setPosition(x, y)
	end

	self.device = "ipad"
	self.vertical = false

	self.doChangeMode = function(self, device, isVertical)
		local ver = isVertical and "_1" or ""
		local path = string.format("tool/uieditor/template/%s%s.lua", device, ver)
		self.simulator:clearNamedChild()
		self.simulator:load(path)
		if self.mainPanel then
			self.mainPanel:setParent(self.simulator.screen)
		end
		self.simulator:setScale(0.36, 0.36)
	end
	self.menu.onVertChange = function()
		self.vertical = not self.vertical
		self:doChangeMode(self.device, self.vertical)
	end

	self.menu.iphone4Mode = function(menu, btn, event)
		self.device = "iphone4"
		self:doChangeMode(self.device, self.vertical)
	end

	self.menu.iphone5Mode = function(menu, btn, event)
		self.device = "iphone5"
		self:doChangeMode(self.device, self.vertical)
	end

	self.menu.ipadMode = function(menu, btn, event)
		self.device = "ipad"
		self:doChangeMode(self.device, self.vertical)
	end

	self.menu:ipadMode()
	self.menu:editorMode()

	self.menu.onSave = function(menu, btn, event)
		local wndConf = self.mainPanel:toTable()
		modSavePanel.showSavePanel(wndConf, self.path, function(path)
			self.path = path
		end) 
	end

	self.menu.onNewBatchWindow = function(menu, btn, event)
		local wnd = self:createWnd(puppy.gui.pBatchWindow)
		wnd:setParent(self.simulator.screen)
		wnd:setPosition(gGameWidth/2 - 200, gGameHeight/2 - 150)
		wnd:setSize(400,300)
		if self.mainPanel then
			self.mainPanel:setParent(nil)
		end
		self.mainPanel = wnd
		wnd:setName("mainPanel")
		wnd:setRootNode("ui:ui_texture.png")
		self:makeEditable(wnd, true)
		self.controlListPanel:update()
	end

	self.menu.onNew = function(menu, btn, event)
		local wnd = self:createWnd(pWindow)
		wnd:setParent(self.simulator.screen)
		wnd:setPosition(gGameWidth/2 - 200, gGameHeight/2 - 150)
		wnd:setSize(400,300)
		if self.mainPanel then
			self.mainPanel:setParent(nil)
		end
		self.mainPanel = wnd
		wnd:setName("mainPanel")
		self:makeEditable(wnd, true)
		self.controlListPanel:update()
	end

	self.menu.onClose = function(menu, btn, event)
		self:close()
	end

	-- 删除无用技能和状态
	self.menu.onClean = function(menu, btn, event)
		local clean_dir = function(dir, ids, exclude)
			local files = io.scandir(dir)
			for _, file in pairs(files) do
				local id = string.sub(file, 1, -5)
				-- log("error", id)
				if not table.exist(ids, id) and not table.exist(exclude, id) then
					local path = dir .. file
					log("info", "delete "..path)
					os.remove(path)
				end
			end
		end

		local status_dir = "home/script/data/info/status/"
		local modAllStatus = import("data/info/status/all_status.lua")
		local allStatus = modAllStatus.getAllStatusIds()

		clean_dir(status_dir, allStatus, {"all_status"})

		local modAllSkill = import("data/info/skills/all_skill.lua")
		local allSkills = modAllSkill.getAllSkillIds()
		local skill_dir = "home/script/data/info/skills/"
		clean_dir(skill_dir, allSkills, {"all_skill"})
	end

	self.menu.onDelete = function(menu, btn, event)
		self.mainPanel:setParent(nil)
		os.remove("home/script/" .. self.loadPanel.editPath:getText())
		self.loadPanel.filelist:update(true)
		modHistory.remove(self.path)
	end

	self.menu.onPrev = function()
		modHistory.prev()
		self:loadFile(modHistory.get())
	end

	self.menu.onNext = function()
		modHistory.next()
		self:loadFile(modHistory.get())
	end

	self.menu:load("tool/uieditor/template/menu.lua")

	self.loadPanel = pWindow()
	self.loadPanel:setParent(self)
	self.loadPanel:load("tool/uieditor/template/load.lua")
	self.loadPanel.filelist = modFileList.pFileList()
	self.loadPanel.filelist:setParent(self.loadPanel)
	self.loadPanel.filelist:setSize(210,370)
	self.loadPanel.filelist:setPosition(0,50)

	local lang=gameconfig:getConfigStr("global", "locale","cn")
	if lang ~= "cn" then
		self.loadPanel.filelist:setRootDir(string.format("home/locale/%s/script", lang))
	else
		self.loadPanel.filelist:setRootDir("home/script")
	end
	self.loadPanel.filelist:setCurDir("data/ui/")  

	self.loadPanel.filelist.onFileSelect = function(fl,file)
		self.loadPanel.editPath:setText(fl:getSelectFile())
	end 

	self.loadPanel.filelist.onMouseClick = function(fl,file)
		self:loadFile(fl:getSelectFile())
		modHistory.push(fl:getSelectFile())
	end

	self.loadPanel.editSearch:addListener("ec_char", function()
		self.loadPanel.filelist:setFilter(self.loadPanel.editSearch:getText())
	end)

	self.loadPanel.editPath:setText(self.path)
	self.loadPanel.editPath:addListener("ec_enter",function()
		self:loadFile(self.loadPanel.editPath:getText())
		modHistory.push(fl:getSelectFile())
	end)
 
	local addControl = function(cls)
		if not self.mainPanel then
			modMsg.showMessage("请先新建或者加载")
			return
		end
		local wnd = self:createWnd(cls)
		wnd:setName(self:getNewName())
		self:makeEditable(wnd, true)
		self.controlListPanel:update(wnd)
		if cls == pSprite then
			wnd:setTexture("character:10001/stand.5.fsi", 0)
		end
		return wnd
	end

	self.controlsPanel = pWindow()
	self.controlsPanel:setParent(self)
	self.controlsPanel.onAddWindow = apply(addControl, pWindow)
	self.controlsPanel.onAddButton = apply(addControl, pButton)
	self.controlsPanel.onAddEdit = apply(addControl, pEdit)
	self.controlsPanel.onAddProgress = apply(addControl, pProgress)
	self.controlsPanel.onAddSprite = apply(addControl, pSprite)
	self.controlsPanel.onAddPanel = apply(addControl, pPanel)
	self.controlsPanel.onAddCheckButton = apply(addControl, pCheckButton)
	self.controlsPanel.onAddBatchWindow= apply(addControl, puppy.gui.pBatchWindow)
	self.controlsPanel:load("tool/uieditor/template/controls.lua")

	self.propPanel = pWindow()
	self.textPropPanel = pWindow()
	self.eventPropPanel = pWindow()
	self.imagePropPanel = pWindow()
	self.paramPropPanel = pWindow()

	local hideAllPropPanel = function()
		self.propPanel:close()
		self.textPropPanel:close()
		self.eventPropPanel:close()
		self.imagePropPanel:close()
		self.paramPropPanel:close()
	end

	self.allPropPanel = pWindow()
	self.allPropPanel:setParent(self)
	self.allPropPanel.showBaseProp = function()
		hideAllPropPanel()
		self.propPanel:open()
	end
	self.allPropPanel.showTextProp = function()
		hideAllPropPanel()
		self.textPropPanel:open()
	end

	self.allPropPanel.showEventProp = function()
		hideAllPropPanel()
		self.eventPropPanel:open()
	end
	
	self.allPropPanel.showImageProp = function()
		hideAllPropPanel()
		self.imagePropPanel:open()
	end
	
	self.allPropPanel.showParamProp = function()
		hideAllPropPanel()
		self.paramPropPanel:open()
	end

	self.allPropPanel:load("tool/uieditor/template/prop.lua")
	self.propPanel:setParent(self.allPropPanel)
	self.textPropPanel:setParent(self.allPropPanel)
	self.eventPropPanel:setParent(self.allPropPanel)
	self.imagePropPanel:setParent(self.allPropPanel)
	self.paramPropPanel:setParent(self.allPropPanel)
	self.allPropPanel.checkBase:setCheck(true, true)

	local toBool = function(txt)
		if txt == "yes" or txt == "true" then
			return true
		else
			return false
		end
	end

	local boolToText = function(val)
		if val then 
			return "yes"
		else 
			return "no" 
		end
	end

	local conf = {
		editPropName = function(wnd, txt)
			self.mainPanel[wnd:getName()] = nil
			wnd:setName(txt)
			self.mainPanel[txt] = wnd
		end, 
		editParent = function(wnd, txt)
			local parent = self.mainPanel[txt]
			if not parent then
				modMsg.showMessage("parent not find")
			else
				wnd:setParent(parent)
			end
		end,
		editDrag = function(wnd, txt)
			wnd:enableDrag(toBool(txt))
		end,
		btnDelete = function(wnd, txt)
			for control,_ in pairs(self.selectWndList) do
				self:deleteControl(control)
			end
			
			self.selectWnd = nil
		end,
		btnCopy = function(wnd, txt)
			self.copiedControl = wnd:toTable()
		end,
		btnPaste = function(wnd, txt)
			if not self.copiedControl then 
				modMsg.showMessage("no copied control")
			else
				local conf = table.clone(self.copiedControl)
				local control = addControl(getClass(conf.className))
				local newConf = control:toTable()
				control:fromTable(conf)
				control:setPosition(newConf.position[1], newConf.position[2])
				control:setName(newConf.name)
			end
		end,
		editX = function(wnd, txt)
			wnd:setPosition(tonumber(txt) or wnd:getX(), wnd:getY())
		end, 
		editRX = function(wnd, txt)
			wnd:setRX(tonumber(txt) or wnd:getRX())
		end, 
		editY = function(wnd, txt)
			wnd:setPosition(wnd:getX(), tonumber(txt) or wnd:getY())
		end,
		editRY = function(wnd, txt)
			wnd:setRY(tonumber(txt) or wnd:getRY())
		end,
		editOffsetX = function(wnd, txt)
			wnd:setOffsetX(tonumber(txt) or wnd:getOffsetX())
		end,
		editOffsetY = function(wnd, txt)
			wnd:setOffsetY(tonumber(txt) or wnd:getOffsetY())
		end,
		editZ = function(wnd, txt)
			wnd:setZ(tonumber(txt) or 0)
		end,
		editW = function(wnd, txt)
			wnd:setSize(tonumber(txt) or wnd:getWidth(), wnd:getHeight())
		end, 
		editH = function(wnd, txt)
			wnd:setSize(wnd:getWidth(), tonumber(txt) or wnd:getHeight())
		end,
		btnLeft = function(wnd, txt)
			if #table.keys(self.selectWndList) > 1 then
				local x = wnd:getX()
				for control,_ in pairs(self.selectWndList) do
					control:setPosition(x, control:getY())
				end
			else
				wnd:setAlignX(ALIGN_LEFT)
				self.propPanel:update(wnd)
			end
		end,
		btnCenter = function(wnd, txt)
			if #table.keys(self.selectWndList) > 1 then
				local x = wnd:getX() + wnd:getWidth()/2
				for control,_ in pairs(self.selectWndList) do
					control:setPosition(x - control:getWidth()/2, control:getY())
				end
			else
				wnd:setAlignX(ALIGN_CENTER)
				self.propPanel:update(wnd)
			end
		end,
		btnRight = function(wnd, txt)
			if #table.keys(self.selectWndList) > 1 then
				local x = wnd:getX() + wnd:getWidth()
				for control,_ in pairs(self.selectWndList) do
					control:setPosition(x - control:getWidth(), control:getY())
				end
			else
				wnd:setAlignX(ALIGN_RIGHT)
				self.propPanel:update(wnd)
			end
		end,
		btnLR = function(wnd, txt)
			wnd:setAlignX(ALIGN_LEFT_RIGHT)
			self.propPanel:update(wnd)
		end,
		btnTop = function(wnd, txt)
			if #table.keys(self.selectWndList) > 1 then
				local y = wnd:getY()
				for control,_ in pairs(self.selectWndList) do
					control:setPosition(control:getX(), y)
				end
			else
				wnd:setAlignY(ALIGN_TOP)
				self.propPanel:update(wnd)
			end
		end,
		btnMiddle = function(wnd, txt)
			if #table.keys(self.selectWndList) > 1 then
				local y = wnd:getY() + wnd:getHeight()/2
				for control,_ in pairs(self.selectWndList) do
					control:setPosition(control:getX(), y - control:getHeight()/2)
				end
			else
				wnd:setAlignY(ALIGN_MIDDLE)
				self.propPanel:update(wnd)
			end
		end,
		btnBottom = function(wnd, txt)
			if #table.keys(self.selectWndList) > 1 then
				local y = wnd:getY() + control:getHeight()
				for control,_ in pairs(self.selectWndList) do
					control:setPosition(control:getX(), y - control:getHeight())
				end
			else
				wnd:setAlignY(ALIGN_BOTTOM)
				self.propPanel:update(wnd)
			end
		end,
		btnTB = function(wnd, txt)
			wnd:setAlignY(ALIGN_TOP_BOTTOM)
			self.propPanel:update(wnd)
		end,
		btnImgWH = function (wnd, txt)
			local spt = pSprite:new()
			spt:setTexture(wnd:getTexturePath(), 0)
			
			local w = spt:getWidth()
			local h = spt:getHeight()
			local scale = self.propPanel.editScale:getText()
			try { function()
				scale = tonumber(scale) / 100
			end} catch { function()
				scale = 1.0 
			end} finally { function()

			end}
			wnd:setSize(w * scale, h * scale)
		end,
		btnEquiW = function(wnd, txt)
			if #table.keys(self.selectWndList) <= 2 then return end
			local minx, maxx, totalWidth = 2000, -1000, 0
			local maxControl = nil
			for control,_ in pairs(self.selectWndList) do
				local x = control:getX()
				local w = control:getWidth()
				if x < minx then minx = x end
				if x > maxx then 
					maxx = x 
					maxControl = control
				end
				totalWidth = totalWidth + w
			end
			totalWidth = totalWidth - maxControl:getWidth()
			
			local controls = table.keys(self.selectWndList)
			table.sort(controls, function(a,b)
				return a:getX() < b:getX()
			end)
			local currentX = minx
			local space = (maxx - minx - totalWidth) / (#controls - 1)
			for _,control in pairs(controls) do
				control:setPosition(currentX, control:getY())
				currentX = currentX + control:getWidth() + space
			end
		end,
		btnEquiH = function(wnd, txt)
			if #table.keys(self.selectWndList) <= 2 then return end
			log("info", "equi height")
			local miny, maxy, totalHeight = 2000, -1000, 0
			local maxControl = nil
			for control,_ in pairs(self.selectWndList) do
				local y = control:getY()
				local h = control:getHeight()
				if y < miny then miny = y end
				if y > maxy then 
					maxy = y 
					maxControl = control
				end
				totalHeight = totalHeight + h
			end
			totalHeight = totalHeight - maxControl:getHeight()
			
			local controls = table.keys(self.selectWndList)
			table.sort(controls, function(a,b)
				return a:getY() < b:getY()
			end)
			local currentY = miny
			local space = (maxy - miny - totalHeight) / (#controls - 1)
			for _,control in pairs(controls) do
				log("info", "control", currentY, control:getHeight(), space)
				control:setPosition(control:getX(), currentY)
				currentY = currentY + control:getHeight() + space
			end
		end,

		editShowSelf = function(wnd, txt)
			wnd:showSelf(toBool(txt))
		end,
		editShowChild = function(wnd, txt)
			wnd:showChild(toBool(txt))
		end,

		editRotX = function(wnd, txt)
			-- TODO
		end,

		editRotY = function(wnd, txt)
			-- TODO
		end,

		editRotZ = function(wnd, txt)
			local rz = tonumber(txt)
			log("error", txt, rz, wnd)
			if rz then
				wnd:setRot(0, 0, rz)
			end
		end
	}

	for k,v in pairs(conf) do
		self.propPanel[k.."Func"] = function()
			if not self.selectWnd then return end
			v(self.selectWnd, self.propPanel[k]:getText())
		end
	end

	local makeSameFunc = function(editName)
		return function()
			for control,_ in pairs(self.selectWndList) do
				conf[editName](control, self.propPanel[editName]:getText())
			end
		end
	end


	self.propPanel.sameParent	= makeSameFunc("editParent")
	self.propPanel.sameDrag		= makeSameFunc("editDrag")
	self.propPanel.sameX		= makeSameFunc("editX")
	self.propPanel.sameRX		= makeSameFunc("editRX")
	self.propPanel.sameY		= makeSameFunc("editY")
	self.propPanel.sameRY		= makeSameFunc("editRY")
	self.propPanel.sameZ		= makeSameFunc("editZ")
	self.propPanel.sameW		= makeSameFunc("editW")
	self.propPanel.sameH		= makeSameFunc("editH")
	self.propPanel.sameShowSelf 	= makeSameFunc("editShowSelf")
	self.propPanel.sameShowChild 	= makeSameFunc("editShowChild")

	self.propPanel:load("tool/uieditor/template/baseprop.lua")

	local conf = {
		editText = function(wnd, txt)
			wnd:setText(txt)
		end,
		editTextColor = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setColor(tonumber(txt))
			end
		end,
		editAutoLine = function(wnd, txt)
			if wnd.getTextControl then
				pText.setAutoBreakLine(wnd:getTextControl(), toBool(txt))
			end
		end,
		editEdgeDistance = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setEdgeDistance(tonumber(txt) or 0)
			end
		end,
		editShadowColor = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setShadowColor(tonumber(txt) or 0)
			end
		end,
		editStrokeColor = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setStrokeColor(tonumber(txt) or 0)
			end
		end, 
		editFontSize = function(wnd, txt)
			if wnd.getTextControl then
				self.fontSize = tonumber(txt)
				wnd:getTextControl():setFontSize(tonumber(txt) or wnd:getTextControl():getFontSize())
			end
		end,
		editFontBold = function(wnd, txt)
			if wnd.getTextControl then
				self.fontBold = tonumber(txt)
				wnd:getTextControl():setFontBold(tonumber(txt) or wnd:getTextControl():getFontBold())
			end
		end,
		editFontType = function(wnd, txt)
			log("error",txt)
			if wnd.getTextControl then
				log("error","font type", txt)
				wnd:getTextControl():setFont(txt, wnd:getTextControl():getFontSize(), 0)
			end
		end,
		checkLeft = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setAlignX(ALIGN_LEFT)
			end
		end,
		checkCenter = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setAlignX(ALIGN_CENTER)
			end
		end,
		checkRight = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setAlignX(ALIGN_RIGHT)
			end
		end, 
		checkTop = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setAlignY(ALIGN_TOP)
			end
		end,
		checkMiddle = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setAlignY(ALIGN_MIDDLE)
			end
		end, 
		checkBottom = function(wnd, txt)
			if wnd.getTextControl then
				wnd:getTextControl():setAlignY(ALIGN_BOTTOM)
			end
		end,
	}

	for k,v in pairs(conf) do
		--log("error",k)
		self.textPropPanel[k.."Func"] = function()
			if not self.selectWnd then return end
			--log("error",self.textPropPanel[k]:getText())
			v(self.selectWnd, self.textPropPanel[k]:getText())
		end
	end

	local makeSameFunc = function(editName)
		return function()
			for control,_ in pairs(self.selectWndList) do
				conf[editName](control, self.textPropPanel[editName]:getText())
			end
		end
	end

	self.textPropPanel.sameText = makeSameFunc("editText")
	self.textPropPanel.sameTextColor = makeSameFunc("editTextColor")
	self.textPropPanel.sameAutoLine = makeSameFunc("editAutoLine")
	self.textPropPanel.sameEdgeDistance = makeSameFunc("editEdgeDistance")
	self.textPropPanel.sameShadowColor = makeSameFunc("editShadowColor")
	self.textPropPanel.sameStrokeColor = makeSameFunc("editStrokeColor")
	self.textPropPanel.sameFontSize = makeSameFunc("editFontSize")
	self.textPropPanel.sameFontType = makeSameFunc("editFontType")
	self.textPropPanel.sameFontBold = makeSameFunc("editFontBold")
	self.textPropPanel:load("tool/uieditor/template/textprop.lua")

	local changeEnableEvent = function(wnd, txt)
		wnd:enableEvent(toBool(txt))
	end
	local makeEventFunc = function(func)
		return function(panel, edit, event)
			if not self.selectWnd then return end
			func(self.selectWnd, edit:getText())
		end
	end
	local makeSameFunc = function(func, editName)
		return function()
			for control,_ in pairs(self.selectWndList) do
				func(control, self.eventPropPanel[editName]:getText())
			end
		end
	end

	local getEventFunc = function(eventName)
		return function()
			if not self.selectWnd then return end
			self.selectWnd.eventMap = self.selectWnd.eventMap or {}
			self.selectWnd.eventMap[eventName] = self.eventPropPanel["edit_"..eventName]:getText()
		end
	end

	self.eventPropPanel.ec_mouse_left_down_func = getEventFunc("ec_mouse_left_down")
	self.eventPropPanel.ec_mouse_click_func = getEventFunc("ec_mouse_click")
	self.eventPropPanel.ec_mouse_drag_func = getEventFunc("ec_mouse_drag")
	self.eventPropPanel.ec_key_up_func = getEventFunc("ec_key_up")
	self.eventPropPanel.ec_inactive_func = getEventFunc("ec_inactive")
	self.eventPropPanel.ec_checked_func = getEventFunc("ec_checked")
	self.eventPropPanel.changeEnableEvent = makeEventFunc(changeEnableEvent)
	self.eventPropPanel.sameEnableEvent = makeSameFunc(changeEnableEvent, "editEnableEvent")
	self.eventPropPanel:load("tool/uieditor/template/eventprop.lua")

	local conf = {
		editColor = function(wnd, txt)
			wnd:setColor(tonumber(txt))
		end,
		editImagePath = function(wnd, txt)
			wnd:setImage(txt)
		end,
		editDownImage = function(wnd, txt)
			if wnd.setClickDownImage then
				wnd:setClickDownImage(txt)
			end
		end,
		editDisableImage = function(wnd, txt)
			if wnd.setDisableImage then
				wnd:setDisableImage(txt)
			end
		end,
		editTemplate = function(wnd, txt)
			local x, y = wnd:getX(), wnd:getY()
			if wnd:className() == "pPanel" then
				wnd:load(txt)
				wnd:setPosition(x,y)
			end
		end,
		editCheckedImage = function(wnd, txt)
			if wnd.setCheckedImage then
				wnd:setCheckedImage(txt)
			end
		end,

		editGroup = function(wnd, txt)
			if wnd.setGroup then
				wnd:setGroup(tonumber(txt))
			end
		end,

		btnHorn = function(wnd, txt)
			wnd:setXSplit(self.imagePropPanel.btnHorn:isChecked())
		end,

		btnVert = function(wnd, txt)
			wnd:setYSplit(self.imagePropPanel.btnVert:isChecked())
		end,
		btnButtonText = function(wnd,txt)
			if self.imagePropPanel.btnButtonText:isChecked() then
				wnd:bindWithParent()
			else
				wnd:unbindWithParent()
			end
		end,
		editSplitSize = function(wnd, txt)
			wnd:setSplitSize(tonumber(txt))
		end,
		editStyle = function(wnd, txt)
			wnd:setStyle(txt)
			self:makeEditable(wnd)
		end,
		editFillImage = function(wnd, txt)
			if wnd.getFillPicture then
				wnd:getFillPicture():setTexturePath(txt)
			end
		end,
		editOverImage = function(wnd, txt)
			if wnd.getOverPicture then
				wnd:getOverPicture():setTexturePath(txt)
			end
		end,
		editSound = function(wnd, txt)
			if wnd.setSound then
				wnd:setSound(txt)
			end
		end
	}

	for k,v in pairs(conf) do
		self.imagePropPanel[k.."Func"] = function()
			if not self.selectWnd then return end
			v(self.selectWnd, self.imagePropPanel[k]:getText())
		end
	end

	local makeSameFunc = function(editName)
		return function()
			for control,_ in pairs(self.selectWndList) do
				conf[editName](control, self.imagePropPanel[editName]:getText())
			end
		end
	end

	local sameSplit = function(panel, wnd, event)
		for control,_ in pairs(self.selectWndList) do
			control:setXSplit(self.imagePropPanel.btnHorn:isChecked())
			control:setYSplit(self.imagePropPanel.btnVert:isChecked())
			control:setSplitSize(tonumber(self.imagePropPanel.editSplitSize:getText()))
		end
	end

	self.imagePropPanel.sameColor		= makeSameFunc("editColor")
	self.imagePropPanel.sameImagePath	= makeSameFunc("editImagePath")
	self.imagePropPanel.sameDownImage	= makeSameFunc("editDownImage")
	self.imagePropPanel.sameDisableImage	= makeSameFunc("editDisableImage")
	self.imagePropPanel.sameTemplate	= makeSameFunc("editTemplate")
	self.imagePropPanel.sameCheckedImage	= makeSameFunc("editCheckedImage")
	self.imagePropPanel.sameGroup		= makeSameFunc("editGroup")
	self.imagePropPanel.sameStyle		= makeSameFunc("editStyle")
	self.imagePropPanel.sameFillImage 	= makeSameFunc("editFillImage")
	self.imagePropPanel.sameOverImage 	= makeSameFunc("editOverImage")
	self.imagePropPanel.sameSound		= makeSameFunc("editSound")
	self.imagePropPanel.sameSplit 		= sameSplit

	self.imagePropPanel:load("tool/uieditor/template/imageprop.lua")

	self.paramPropPanel:load("tool/uieditor/template/paramprop.lua")

	self.imagePropPanel.update = function(panel, control)
		panel.editColor:setText(string.format("0x%X", control:getColor()))
		panel.editImagePath:setText(control:getTexturePath())
		
		if isA(control, pWindow) then
			panel.btnHorn:setCheck(control:getPictureControl():isXSplit(), false)
			panel.btnVert:setCheck(control:getPictureControl():isYSplit(), false)
			panel.editSplitSize:setText(control:getPictureControl():getSplitSize())
		end

		-- panel.btnButtonText:setCheck(false, false)
		panel.editStyle:setText(control:getStyle())
		if control.getClickDownImage then
			panel.editDownImage:setText(control:getClickDownImage())
		else
			panel.editDownImage:setText("")
		end

		if control.getDisableImage then
			panel.editDisableImage:setText(control:getDisableImage())
		else
			panel.editDisableImage:setText("")
		end

		if control:className() == "pPanel" then
			panel.editTemplate:setText(control:getPath())
		else
			panel.editTemplate:setText("")
		end

		if control.getSound then
			panel.editSound:setText(control:getSound())
		end

		if control:className() == "pButton" then
			panel.btnButtonText:setCheck(control:isBindWithParent())
		end

		if control:className() == "pCheckButton" then
			panel.editCheckedImage:setText(control:getCheckedImage())
			panel.editGroup:setText(control:getGroup())
			panel.btnButtonText:setCheck(control:isBindWithParent())
		else
			panel.editCheckedImage:setText("")
			panel.editGroup:setText("")
		end

		if control:className() == "pEdit" then
			panel.editCheckedImage:setText(control:getFocusImage())
		end

		if control:className() == "pProgress" then
			panel.editFillImage:setText(control:getFillPicture():getTexturePath())
			panel.editOverImage:setText(control:getOverPicture():getTexturePath())
		end
	end

	self.paramPropPanel.update = function(panel, control)
		local paramMap = control.paramMap or {}
		panel.paramMap = panel.paramMap or {}
		local needUpdate = false
		for k,v in pairs(panel.paramMap or {}) do
			if paramMap[k] ~= v then
				needUpdate = true
			end
		end
		for k,v in pairs(paramMap) do
			if panel.paramMap[k] ~= v then
				needUpdate = true
			end
		end

		if not needUpdate then return end
		
		panel:clearChild()
		local x1, x2, x3, y = 10, 110, 210, 10
		local createParamWnd = function(y)
			local nameEdit = pEdit()
			nameEdit:setParent(panel)
			nameEdit:setImage("ui:input.png")
			nameEdit:setSize(90, 20)
			nameEdit:setPosition(x1, y)
			nameEdit:getTextControl():setFontSize(14)
			nameEdit:getTextControl():setAutoBreakLine(false)

			local valueEdit = pEdit()
			valueEdit:setParent(panel)
			valueEdit:setImage("ui:input.png")
			valueEdit:setSize(90, 20)
			valueEdit:setPosition(x2, y)
			valueEdit:getTextControl():setFontSize(14)
			valueEdit:getTextControl():setAutoBreakLine(false)

			local typeEdit = pEdit()
			typeEdit:setParent(panel)
			typeEdit:setImage("ui:input.png")
			typeEdit:setSize(50, 20)
			typeEdit:setPosition(x3, y)
			typeEdit:getTextControl():setFontSize(14)
			typeEdit:getTextControl():setAutoBreakLine(false)
			return nameEdit,valueEdit,typeEdit
		end

		local nameEdit,valueEdit,typeEdit = createParamWnd(y)
		
		y = y + 35
		local addBtn = pButton()
		addBtn:setParent(panel)
		addBtn:setPosition(0,y)
		addBtn:setAlignX(ALIGN_CENTER)
		addBtn:setSize(70, 30)
		addBtn:setText("Add")
		addBtn:setImage("ui:button.png")
		addBtn:getTextControl():setColor(0xFFFFFFFF)
		addBtn:addListener("ec_mouse_click", function()
			local name = nameEdit:getText()
			local value = valueEdit:getText()
			local type = typeEdit:getText()
			local typeFunc = {
				int = tonumber,
				float = tonumber,
				string = id,
			}
			local func = typeFunc[type] or id
			control:setParam(name, func(value))
			panel:update(control)
		end)
		panel.addBtn = addBtn

		panel.edits = {}
		panel.paramMap = {}
		for n,v in pairs(control.paramMap or {}) do
			panel.paramMap[n] = v
			y = y + 35
			local nameEdit,valueEdit,typeEdit = createParamWnd(y)
			nameEdit:setText(n)
			if is_number(v) then
				valueEdit:setText(string.format("%.2f", v))
				typeEdit:setText("float")
			else
				valueEdit:setText(v)
				typeEdit:setText("string")
			end
			local updateParam = function()
				local name = nameEdit:getText()
				local value = valueEdit:getText()
				local type = typeEdit:getText()
				local typeFunc = {
					int = tonumber,
					float = tonumber,
					string = id,
				}
				local func = typeFunc[type] or id
				control.paramMap[n] = nil
				if name and name ~= "" then
					control:setParam(name, func(value))
				end
				panel:update(control)
			end

			nameEdit:addListener("ec_inactive", updateParam)
			valueEdit:addListener("ec_inactive", updateParam)
			typeEdit:addListener("ec_inactive", updateParam)
			table.insert(panel.edits, {nameEdit, valueEdit, typeEdit})
		end
	end

	self.eventPropPanel.update = function(panel, control)
		panel.editEnableEvent:setText(boolToText(control:isEnableEvent()))

		for _,child in ipairs(panel:children()) do
			if child:className() == "pEdit" and string.find(child:getName(), "edit_ec") then
				child:setText("")
			end
		end
		for k,v in pairs(control.eventMap or {}) do
			log("info", k, v)
			panel["edit_"..k]:setText(v)
		end

	end

	self.textPropPanel.update = function(panel, control)
		panel.editText:setText(control:getText() or "")
		if control.getTextControl then
			panel.editTextColor:setText(string.format("0x%X", control:getTextControl():getColor()))
			panel.editShadowColor:setText(string.format("0x%X", control:getTextControl():getShadowColor()))
			panel.editStrokeColor:setText(string.format("0x%X", control:getTextControl():getStrokeColor()))
			panel.editAutoLine:setText(boolToText(pText.isAutoBreakLine(control:getTextControl())))
			panel.editEdgeDistance:setText(string.format("%.0f", control:getTextControl():getEdgeDistance()))
			panel.editFontSize:setText(string.format("%d", control:getTextControl():getFontSize()))
			log("error",control:getTextControl():getFontType())
			log("error",control:getTextControl():getFontSize())
			panel.editFontType:setText(control:getTextControl():getFontType())
			panel.editFontBold:setText(control:getTextControl():getFontBold())
			local ax = control:getTextControl():getAlignX()
			local ay = control:getTextControl():getAlignY()
			if ax == ALIGN_LEFT then panel.checkLeft:setCheck(true, true) 
			elseif ax == ALIGN_CENTER then panel.checkCenter:setCheck(true, true) 
			elseif ax == ALIGN_RIGHT then panel.checkRight:setCheck(true, true) end
			--elseif ax == ALIGN_LEFT_RIGHT then panel.checkLR:setCheck(true, true) end
			
			if ay == ALIGN_TOP then panel.checkTop:setCheck(true, true)
			elseif ay == ALIGN_MIDDLE then panel.checkMiddle:setCheck(true, true)
			elseif ay == ALIGN_BOTTOM then panel.checkBottom:setCheck(true, true) end
			--elseif ay == ALIGN_TOP_BOTTOM then panel.checkTB:setCheck(true, true) end

		end
	end

	self.propPanel.update = function(panel, control)
		self.eventPropPanel:update(control)
		self.textPropPanel:update(control)
		self.imagePropPanel:update(control)
		self.paramPropPanel:update(control)

		panel.editPropName:setText(control:getName())
		panel.editType:setText(control:className())
		panel.editDrag:setText(boolToText(control:canDrag()))

		panel.editX:setText(string.format("%.0f", control:getX()))
		panel.editOffsetX:setText(string.format("%.0f", control:getOffsetX()))
		panel.editRX:setText(string.format("%.0f", control:getRX()))
		panel.editY:setText(string.format("%.0f", control:getY()))
		panel.editOffsetY:setText(string.format("%.0f", control:getOffsetY()))
		panel.editRY:setText(string.format("%.0f", control:getRY()))
		panel.editZ:setText(string.format("%.0f", control:getZ()))

		panel.editW:setText(string.format("%.0f", control:getWidth()))
		panel.editH:setText(string.format("%.0f", control:getHeight()))

		panel.editShowSelf:setText(boolToText(control:isSelfShow()))
		panel.editShowChild:setText(boolToText(control:isChildShow()))

		panel.editRotX:setText("")
		panel.editRotY:setText("")
		panel.editRotZ:setText(string.format("%.2f", control:getRot()))


		local ax = control:getAlignX()
		local ay = control:getAlignY()
		if ax == ALIGN_LEFT then panel.btnLeft:setCheck(true, true) 
		elseif ax == ALIGN_CENTER then panel.btnCenter:setCheck(true, true) 
		elseif ax == ALIGN_RIGHT then panel.btnRight:setCheck(true, true) 
		elseif ax == ALIGN_LEFT_RIGHT then panel.btnLR:setCheck(true, true) end
		
		if ay == ALIGN_TOP then panel.btnTop:setCheck(true, true)
		elseif ay == ALIGN_MIDDLE then panel.btnMiddle:setCheck(true, true)
		elseif ay == ALIGN_BOTTOM then panel.btnBottom:setCheck(true, true) 
		elseif ay == ALIGN_TOP_BOTTOM then panel.btnTB:setCheck(true, true) end
		
		panel.editParent:setText(control:getParent():getName())
	end

	self.controlListPanel = pWindow()
	self.controlListPanel:enableDrag(true)
	self.controlListPanel:setParent(self)
	self.controlListPanel:load("tool/uieditor/template/control_list.lua")
	self.controlListPanel.wnd_list:setClipDraw(true)

	self.listPanel = pWindow()
	self.listPanel:setParent(nil)
	self.listPanel:addListener("ec_mouse_drag", function(e)
                self.listPanel:move(0, e:dy())
		local y = self.listPanel:getY()
		if y + self.listPanel:getHeight()<self.controlListPanel:getHeight() then
			y = -self.listPanel:getHeight()+self.controlListPanel:getHeight()
		end
		if  y > 0 then y = 0 end
		self.listPanel:setPosition(0,y)
	end)

	self.controlListPanel.search_edit:addListener("ec_char", function()
		self.controlListPanel:update(self.controlListPanel.control, self.controlListPanel.search_edit:getText())
	end)
	
	self.controlListPanel.update = function(panel, control, filterName)
		self.controlListPanel.control = control
		self.listPanel:setPosition(0,0)
		self.listPanel:clearChild()
		self.listPanel:setParent(self.controlListPanel.wnd_list)
		local startX,startY,span,w,h = 
		panel:getParam("startX"),
		panel:getParam("startY"),
		panel:getParam("span"),
		panel:getParam("w"),
		panel:getParam("h")
		panel.wnds = {}
		for k,v in pairs(self.mainPanel) do
			if isA(v, pObject) and v:getName() and (not filterName or string.find(k, filterName)) then
				local wnd = pCheckButton()
				--wnd:setParent(panel)
				wnd:setParent(self.listPanel)
				wnd:setSize(w,h)
				wnd:setImage("ui:button.png")
				wnd:setCheckedImage("ui:button_selected.png")
				wnd:setGroup(1)
				wnd:setPosition(startX, startY)
				wnd:setText(k)
				wnd:getTextControl():setFontSize(14)
				wnd:getTextControl():setAutoBreakLine(false)
				wnd:getTextControl():setColor(0xFFFFFFFF)
				wnd:addListener("ec_checked", function()
					v:fireEvent("ec_mouse_click")
				end)

				if v == control then
					wnd:setCheck(true, false)
				end
				table.insert(panel.wnds, wnd)
				
				startY = startY + span

			end
		end

		if startY>200 then

			self.listPanel:setSize(150,startY)
		else
			self.listPanel:setSize(150,280)
		end

		self.listPanel:setColor(0x770000FF)
	end
end

pUIEditor.loadFile =  function(self, path)
	self.path = path 
	if self.mainPanel then 
		self.mainPanel:setParent(nil)
		self.mainPanel = nil
	end
	log("info", path)
	local data = _import(path)
	local wnd = pWindow()
	wnd:fromTable(data.data)
	wnd:setParent(self.simulator.screen)
	self.mainPanel = wnd
	self:makeEditable(wnd,true) 
	self.controlListPanel:update()
	modMsg.showMessage(string.format("%s加载成功",self.path))
end

pUIEditor.moveSelect = function(self, dx, dy)
	for control,_ in pairs(self.selectWndList) do
		control:move(dx, dy)
	end
	self:updatePropWnd(self.selectWnd)	
end

pUIEditor.makeEditable = function(self, wnd, recurse)
	if not wnd:getName() then return end
	self.mainPanel[wnd:getName()] = wnd

	modEditable.addEditWnd(wnd)

	wnd:addListener("ec_mouse_click",function(event)
		if event and bit.band(event:ck_status(), puppy.ecks_ctrl) ~= 0 then
			if self.selectWndList[wnd] then
				self.selectWndList[wnd] = nil
				wnd:makeCurrent(false)
			else
				self.selectWndList[wnd] = true
				wnd:makeCurrent(true)
				
				if not self.selectWnd then
					self:setSelectWnd(wnd)
				end
			end
		else
			for c,_ in pairs(self.selectWndList) do
				c:makeCurrent(false)
			end
			self.selectWndList = {}
			self.selectWndList[wnd] = true
			self:setSelectWnd(wnd)
		end
	end)

	wnd:addListener("ec_mouse_drag", function(event)
		self:updatePropWnd(wnd)
		for control,_ in pairs(self.selectWndList) do
			if control ~= wnd then
				control:move(event:dx(), event:dy())
			end
		end
	end)

	wnd.setPosition = function(_, x, y)
		getClass(wnd:className()).setPosition(wnd, x,y)
		self:updatePropWnd(wnd)
	end

	wnd.setSize = function(_, w, h)
		getClass(wnd:className()).setSize(wnd, w, h)
		wnd:onSetSize(w, h)
		self:updatePropWnd(wnd)
	end

	if recurse then
		for _, child in ipairs(wnd:children()) do
			self:makeEditable(child, recurse)
		end
	end
end

pUIEditor.deleteControl = function(self, wnd)
	wnd:setParent(nil)
	self.mainPanel[wnd:getName()] = nil
	self.controlListPanel:update(self.selectWnd)
end

pUIEditor.createWnd = function(self, cls)
	local wnd = cls:new()
	wnd:setParent(self.mainPanel)
	wnd:setColor(0x770000FF)
	wnd:setPosition(50, 50)
	wnd:setSize(100,100)
	return wnd
end

pUIEditor.setSelectWnd = function(self, wnd)
	if self.selectWnd then
		self.selectWnd:makeCurrent(false)
	end
	self.selectWnd = wnd
	if self.selectWnd then
		self.selectWnd:makeCurrent(true)
		self.selectWnd:bringTop()
	end
	self:updatePropWnd(wnd)
end

pUIEditor.updatePropWnd = function(self, wnd)
	if wnd ~= self.selectWnd then return end
	self.propPanel:update(wnd)
	--self.controlListPanel:update(wnd)
	--self.eventPanel:update(wnd)
end

pUIEditor.getNewName = function(self)
	for i=1,1000 do
		if not self.mainPanel["control"..i] then
			return "control"..i
		end
	end
	return "control"..0
end

pUIEditor.close = function(self)
	pWindow.close(self)
	modMenu.showMenu()
end

showUIEditor = function()
	pUIEditor:instance():open()
end

hideUIEditor = function()
	pUIEditor:instance():close()
end
