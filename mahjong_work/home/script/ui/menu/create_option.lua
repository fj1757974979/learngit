local modDataCreateOption = import("data/info/info_create_option.lua")
local modBattleRpc = import("logic/battle/rpc.lua")

local optionTitleConfig = {
	["局数"] = "ui:create_round_count.png",
	["圈数"] = "ui:create_circle_count.png",
	["人数"] = "ui:create_player_count.png",
	["金牌"] = "ui:create_gold.png",
	["玩法"] = "ui:create_rule.png",
	["可选"] = "ui:create_select.png",
	["模式"] = "ui:create_mode.png",
	["癞子"] = "ui:create_wang.png",
	["坐庄"] = "ui:create_zhuang.png",
	["明牌抢庄"] = "ui:create_mode.png",
	["开庄玩法"] = "ui:create_mode.png",
	["抢庄"] = "ui:create_qiangzhuang.png",
	["压分"] = "ui:create_yafen.png",
	["推注"] = "ui:create_tuizhu.png",
	["翻倍"] = "ui:create_double.png",
	["分数"] = "ui:create_score.png",
}

function getOptionTitleRes(title)
	return optionTitleConfig[title]
end

function getConfig(gameType)
	for _, config in pairs(modDataCreateOption.data) do
		if config.gameType == gameType then
			return config
		end
	end
	return nil
end

function getData()
	return modDataCreateOption.data
end

function isPoker(gameType)
	local config = getConfig(gameType)
	return config.gameStyle == 2
end

function isMahjong(gameType)
	local config = getConfig(gameType)
	return config.gameStyle == 1
end

function getGameStyle(gameType)
	local config = getConfig(gameType)
	return config.gameStyle
end

function getGameRealType(gameType)
	local conf = getConfig(gameType)
	local realGameType = conf.realGameType
	if not realGameType or realGameType == "" then
		return gameType
	else
		return realGameType
	end
end

function getCreateRoomRpc(gameType)
	logv("warn","getCreateRoomRpc")
	if isPoker(gameType) then
		return modBattleRpc.createPokerRoom
	elseif isMahjong(gameType) then
		return modBattleRpc.createRoom
	else
		return modBattleRpc.createRoom
	end
end
