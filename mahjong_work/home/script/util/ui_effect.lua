
gMutextChooseGroupTb = gMutextChooseGroupTb or {}
gGroupIdxToImg = new_weak_table()
gGroupIdxToNotSplit = new_weak_table()

gGroupIdx = gGroupIdx or 0

genChooseGroup = function(chooseImg, notSplit)
	chooseImg = chooseImg or "ui:gj_common_effects3.png"
	gGroupIdx = gGroupIdx + 1
	gMutextChooseGroupTb[gGroupIdx] = new_weak_table()
	gGroupIdxToImg[gGroupIdx] = chooseImg
	notSplit = notSplit or false
	gGroupIdxToNotSplit[gGroupIdx] = notSplit
	return gGroupIdx
end

delChooseGroup = function(groupIdx)
	if not gMutextChooseGroupTb[groupIdx] then
		return false
	end
	local mutex = gMutextChooseGroupTb[groupIdx]
	for _, w in ipairs(mutex) do
		w.__mc_group_idx = nil
		w.__mc_chosen = nil
		if w.__mc_click_hdr then
			w:removeListener(w.__mc_click_hdr)
			w.__mc_click_hdr = nil
		end
		if w.__mc_chosen_wnd then
			w.__mc_chosen_wnd:setParent(nil)
			w.__mc_chosen_wnd = nil
		end
	end
	gMutextChooseGroupTb[groupIdx] = nil
	gGroupIdxToImg[groupIdx] = nil
	gGroupIdxToImg[groupIdx] = nil
end

addMutexChooseWnd = function(groupIdx, wnd)
	if not gMutextChooseGroupTb[groupIdx] then
		return false
	end
	for _, w in ipairs(gMutextChooseGroupTb[groupIdx]) do
		if w == wnd then
			return true
		end
	end
	table.insert(gMutextChooseGroupTb[groupIdx], wnd)
	wnd.__mc_group_idx = groupIdx
	wnd.__mc_chosen = function(self, flag)
		local w, h = self:getWidth(), self:getHeight()
		if flag then
			if not self.__mc_chosen_wnd then
				self.__mc_chosen_wnd = pWindow()
				self.__mc_chosen_wnd:setImage(gGroupIdxToImg[groupIdx])
				self.__mc_chosen_wnd:enableEvent(false)
				self.__mc_chosen_wnd:setAlignX(ALIGN_CENTER)
				self.__mc_chosen_wnd:setAlignY(ALIGN_MIDDLE)
				self.__mc_chosen_wnd:setParent(self)
				self.__mc_chosen_wnd:setSize(w + 15, h + 15)
				local notSplit = gGroupIdxToNotSplit[groupIdx] or false
				if not notSplit then
					self.__mc_chosen_wnd:setXSplit(true)
					self.__mc_chosen_wnd:setYSplit(true)
					self.__mc_chosen_wnd:setSplitSize(30)
				end
				self.__mc_chosen_wnd:setZ(-1)
			end
		else
			if self.__mc_chosen_wnd then
				self.__mc_chosen_wnd:setParent(nil)
				self.__mc_chosen_wnd = nil
			end
		end
	end
	wnd.__mc_click_hdr = wnd:addListener("ec_mouse_click", function(e)
		local gid = wnd.__mc_group_idx
		local mutex = gMutextChooseGroupTb[gid]
		if mutex then
			for _, w in ipairs(mutex) do
				if w ~= wnd then
					w:__mc_chosen(false)
				end
			end
			wnd:__mc_chosen(true)
		end
		if e then
			e:bubble(true)
		end
	end)
end

delMutexChooseWnd = function(groupIdx, wnd)
	if not gMutextChooseGroupTb[groupIdx] then
		return false
	end
	local mutex = gMutextChooseGroupTb[groupIdx]
	local i = -1
	for idx, w in ipairs(mutex) do
		if w == wnd then
			i = idx
			break
		end
	end
	if i > 0 then
		wnd.__mc_group_idx = nil
		wnd.__mc_chosen = nil
		if wnd.__mc_click_hdr then
			wnd:removeListener(w.__mc_click_hdr)
			wnd.__mc_click_hdr = nil
		end
		if wnd.__mc_chosen_wnd then
			wnd.__mc_chosen_wnd:setParent(nil)
			wnd.__mc_chosen_wnd = nil
		end
		table.remove(mutex, i)
		return true
	end
	return false
end

-----------------------------------------------------------
