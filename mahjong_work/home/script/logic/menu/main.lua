local modUtil = import("util/util.lua")

pMenuMgr = pMenuMgr or class(pSingleton)

pMenuMgr.init = function(self)
end

pMenuMgr.getCurMenuPanel = function(self)
	if not self.menuPanel then
		self:initMainMenu()
	end
	return self.menuPanel
end

pMenuMgr.initMainMenu = function(self)
	local channelId = modUtil.getOpChannel()
	logv("warn",channelId)
	local modMenuMain = import("ui/menu/" .. channelId .. ".lua")
	local channelToName = {
		["openew"] = modMenuMain.pMainOpenew,
		["ds_queyue"] = modMenuMain.pMainDsqueyue,
		["tj_lexian"] = modMenuMain.pMainTjlexian,
		["ly_youwen"] = modMenuMain.pMainLyyouwen,
		["jz_laiba"] = modMenuMain.pMainJzlaiba,
		["rc_xianle"] = modMenuMain.pMainRcxianle,
		["test"] = modMenuMain.pMainTest,		
		["xy_hanshui"] = modMenuMain.pMainXyhanshui,
		["yy_doudou"] = modMenuMain.pMainYydoudou,
		["nc_tianjiuwang"] = modMenuMain.pMainNcTianjiuwang,
		["za_queyue"] = modMenuMain.pMainZaqueyue,
		["qs_pinghe"] = modMenuMain.pMainQspinghe,
	}
	self.menuPanel = channelToName[channelId]:new()
end

pMenuMgr.close = function(self)
	self.menuPanel:close()
	self.menuPanel = nil
	pMenuMgr:cleanInstance()
end


