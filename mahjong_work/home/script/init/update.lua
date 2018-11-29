local modLoadingPanel = import("ui/login/login_loading.lua")
local modUtil = import("util/util.lua")

local DEBUG = DEBUG or false
local updating = updating or false

local loginHint = modLoadingPanel.pLoginLoadingPanel:instance()
local agent = puppy.pUpdateAgent:instance()

local fixBugFiles = {
	["home/script/logic/fix_bug/prev_fix.lua"] = true,
	["home/script/logic/fix_bug/post_fix.lua"] = true,
}
local banFiles = {
	["home/script/import.lua"] = true,
	["home/script/common/init.lua"] = true,
	["home/script/init/start.lua"] = true,
	["home/script/init/gameinit.lua"] = true,
	["home/script/init/update.lua"] = true,
}

local isFileScript = function(file)
	return string.sub(file, -4, -1) == ".lua"
end

local getScriptRealPath = function(path)
	if string.find(path, "home/script") then
		return string.sub(path, 13, -1)
	else
		return path
	end
end
local updateFiles = function(fileList, callback)
	if not agent.updateFileListJson then
		return oldUpdateFiles(fileList, callback)
	end

	local toReadable = function(size)
		if size/1024/1024 > 1 then
			return sf("%.2f", size/1024/1024) .. "M"
		elseif size/1024 > 1 then
			return sf("%.2f", size/1024) .. "K"
		else
			return tostring(size)
		end
	end
	
	local updateLoginHint = function(download, total)
		local percent = download/total
		loginHint:setHint(sf(TEXT(164), 
				     math.floor(percent * 100),
				     toReadable(download), 
				     toReadable(total)))
		loginHint:setProgress(percent)
	end

	agent:updateFileList(fileList)

	agent.onGetPatchInfo = function(self, total)
		agent.updateTimer = setInterval(1, function()
			updateLoginHint(self:getDownloadSize(), self:getPatchSize())
		end)
	end

	agent.onPatchDone = function(self)
		updateLoginHint(self:getDownloadSize(), self:getPatchSize())
		agent:updateDone()
		local allScript = filter(isFileScript, fileList)
		setTimeout(30, function()
			callback(allScript)
			updating = false
		end)


		agent.updateTimer:stop()
		agent.updateTimer = nil
	end
end

setCurrentVersion = function()
	if agent then
		loginHint:setCurrentVersion(agent:getClientVersion())
	else
		loginHint:setCurrentVersion("")
	end
end

setNewestVersion = function(version)
	loginHint:setNewestVersion(version)
end

preAutoUpdate = function()
	loginHint:startAnimation()
	loginHint:setHint(TEXT(83))
	loginHint:setProgress(0)
	setCurrentVersion()
	setNewestVersion(nil)

	local modPreloadingPanel = import("ui/login/preloading_panel.lua")
	modPreloadingPanel.getPreloadPanel():open()
end

autoUpdate = function()
	if updating then
		return
	end
	local enterGame = function()
		updating = false

		setTimeout(10, function()
			loginHint:hide()
			-- 重置文本管理
			local modLocaleMgr = import("locale/main.lua")
			modLocaleMgr.pLocaleMgr:instance():resetTextLocaleData()
			local modPreloadingPanel = import("ui/login/preloading_panel.lua")
			modPreloadingPanel.getPreloadPanel():close()
			-- 登陆
			local modLoginMain = import("logic/login/main.lua")
			modLoginMain.pLoginMgr:instance():initLogin()
		end)
	end

	--local testUpdate = true
	if not testUpdate and app:getPlatform() == "macos" then
		enterGame()
		return
	else
		preAutoUpdate()
	end
	
	updating = true

	setTimeout(s2f(1), function()
		if agent then
			agent:checkUpdate(function(code)
				print(code)
				local err = false
				-- code: 
				-- 0: 没有更新
				-- 1: 需要更新
				-- 2: 检测失败
				-- 3: 引擎更新
				if code == 0 then
					loginHint:setHint(TEXT(53))
					enterGame()
				elseif code == 1 then
					setNewestVersion(agent:getNewestVersion())
					loginHint:setHint(TEXT(81))
					local updateInfo = agent:getExpireInfo()
					local pathes = updateInfo.files
					local num = table.size(pathes)
					logv("error", num)
					if not num or num <= 0 then
						-- etc/files跟本地一致，认为是最新
						loginHint:setHint(TEXT(53))
						agent:updateDone()
						enterGame()
					else
						local allFiles = {}
						for i = 1, num do
							table.insert(allFiles, pathes[i])
						end

						updateFiles(allFiles, function(allScript)
							-- 更新脚本
							_import(getScriptRealPath("home/script/logic/fix_bug/prev_fix.lua"))
							log("error", "prev fix bug")
							for _, path in ipairs(allScript) do
								if not fixBugFiles[path] then 
									if not banFiles[path] then
										_import(getScriptRealPath(path), true)
										log("error", "update script", path)
									else
										-- TODO need restart ? 
										log("error", "---------- update abandon --------", path)
									end
								end
							end
							_import(getScriptRealPath("home/script/logic/fix_bug/post_fix.lua"))
							log("error", "post fix bug")
							enterGame()
						end)
					end
				elseif code == 2 then
					loginHint:setHint(TEXT("检测更新失败，请检查网络。请点击屏幕重试。"), true)
					loginHint:setRetryFlag(true)
				elseif code == 3 then
					loginHint:setHint(TEXT(124), true)
					-- 提供链接、关闭游戏
					local modNaviUpdate = import("logic/navigate/update.lua")
					local link = modNaviUpdate.getPackageUpdateUrl()
					if puppy.sys.navigateUpdate and link then
						local modConfirmDialog = import("ui/common/confirm.lua")
						local dialog = modConfirmDialog.pConfirmDilog:instance()
						dialog:setZ(-1000000)
						dialog:setRenderLayer(3)
						dialog:open(TEXT(51), TEXT(123), function()
							puppy.sys.navigateUpdate(link)
						end, function()
							puppy.sys.closeGame()
						end)
					end
				else
					loginHint:setHint(TEXT(40), true)

					err = true
				end
				if err then
					-- TODO 弹出提示框，点击关闭游戏
				end
				updating = false
			end)
		else
			print("agent null!")
			loginHint:setHint(TEXT(40))
			-- TODO 弹出提示框，点击关闭游戏
		end
	end)

end
