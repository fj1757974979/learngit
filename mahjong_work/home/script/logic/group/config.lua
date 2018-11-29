local modData = import("data/info/info_group_config.lua")
local modUtil = import("util/util.lua")

getConfigData = function()
	local channelId = modUtil.getOpChannel()
	local data = modData.data
	return data[channelId]
end

getCreateCost = function()
	local config = getConfigData()
	return config["room_card_cost"]
end

isGroupOpen = function()
	return getConfigData() ~= nil
end
