local modUtil = import("util/util.lua")

local packageUpdateUrl = {
	ios = {
		--tj_lexian = "https://itunes.apple.com/cn/app/id1269449680?mt=8",
		--openew = "https://itunes.apple.com/cn/app/id1274334913?mt=8",
		tj_lexian = "https://fir.im/hntjmj",
		openew = "https://fir.im/openewqp",
		--ds_queyue = "https://fir.im/fjdsmj",
		ds_queyue = "https://itunes.apple.com/us/app/id1288355682?mt=8",
	},
	android = {
		tj_lexian = "https://fir.im/hntjmj",
		openew = "https://fir.im/openewqp",
		ds_queyue = "https://fir.im/fjdsmj",
	},
}

getPackageUpdateUrl = function()
	local platform = app:getPlatform()
	local opChannel = modUtil.getOpChannel()
	local conf = packageUpdateUrl[platform]
	if conf then
		return conf[opChannel]
	else
		return nil
	end
end
