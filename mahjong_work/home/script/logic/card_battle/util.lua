local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modPaijiuProto = import("data/proto/rpc_pb2/pokers/paijiu_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")

local niuTypeInfo = {
	[modNiuniuProto.T_NN_NONE] = {img="0.fsi", name=TEXT("没牛"), sound=100},
	[modNiuniuProto.T_NN_1] = {img="1.fsi", name=TEXT("牛一"), sound=101},
	[modNiuniuProto.T_NN_2] = {img="2.fsi", name=TEXT("牛二"), sound=102},
	[modNiuniuProto.T_NN_3] = {img="3.fsi", name=TEXT("牛三"), sound=103},
	[modNiuniuProto.T_NN_4] = {img="4.fsi", name=TEXT("牛四"), sound=104},
	[modNiuniuProto.T_NN_5] = {img="5.fsi", name=TEXT("牛五"), sound=105},
	[modNiuniuProto.T_NN_6] = {img="6.fsi", name=TEXT("牛六"), sound=106},
	[modNiuniuProto.T_NN_7] = {img="7.fsi", name=TEXT("牛七"), sound=207},
	[modNiuniuProto.T_NN_8] = {img="8.fsi", name=TEXT("牛八"), sound=208},
	[modNiuniuProto.T_NN_9] = {img="9.fsi", name=TEXT("牛九"), sound=209},
	[modNiuniuProto.T_NN_10] = {img="10.fsi", name=TEXT("牛牛"), sound=310},
	[modNiuniuProto.T_NN_WUHUANIU] = {img="11.fsi", name=TEXT("五花牛"), sound=411},
	[modNiuniuProto.T_NN_WUXIAONIU] = {img="12.fsi", name=TEXT("五小牛"), sound=412},
	[modNiuniuProto.T_NN_SHUNZI] = {img="13.fsi", name=TEXT("顺子"), sound=413},
	[modNiuniuProto.T_NN_TONGHUA] = {img="14.fsi", name=TEXT("同花"), sound=414},
	[modNiuniuProto.T_NN_HULU] = {img="15.fsi", name=TEXT("葫芦"), sound=415},
	[modNiuniuProto.T_NN_ZHADAN] = {img="16.fsi", name=TEXT("炸弹"), sound=416},
	[modNiuniuProto.T_NN_TONGHUASHUN] = {img="17.fsi", name=TEXT("同花顺"), sound=417},
}

getNiuImageByType = function(niuType)
	return sf("effect:card_game/niuniu/%s", niuTypeInfo[niuType].img)
end

getNiuSoundID = function(niuType)
	return niuTypeInfo[niuType].sound
end

getNiuNameByType = function(niuType)
	return niuTypeInfo[niuType].name
end

local huaToPrefix = {
	[1] = "d",
	[2] = "c",
	[3] = "h",
	[4] = "s",
}

getPokerCardImage = function(cardId)
	local path = "ui:card_game/poker_cards/"
	if cardId == 598 then
		return sf("%sjoker1.png", path)
	elseif cardId == 599 then
		return sf("%sjoker2.png", path)
	else
		local hua = math.floor(cardId / 100)
		local num = cardId % 100
		local prefix = huaToPrefix[hua]
		local surfix = ""
		if num == 1 then
			surfix = "a"
		elseif num == 11 then
			surfix = "j"
		elseif num == 12 then
			surfix = "q"
		elseif num == 13 then
			surfix = "k"
		else
			surfix = sf("%d", num)
		end
		return sf("%s%s%s.png", path, prefix, surfix)
	end
end

getPaijiuCardImage = function(cardId)
	return sf("ui:card_game/paijiu/cards/%d.png", cardId)
end

getPokerCardImageById = function(cardId, pokerType)
	pokerType = pokerType or modLobbyProto.NIUNIU
	if pokerType == modLobbyProto.NIUNIU then
		return getPokerCardImage(cardId)
	elseif pokerType == modLobbyProto.PAIJIU then
		return getPaijiuCardImage(cardId)
	end
end

getPokerCardBgImage = function(pokerType)
	pokerType = pokerType or modLobbyProto.NIUNIU
	if pokerType == modLobbyProto.NIUNIU then
		return "ui:card_game/poker_cards/bg.png"
	elseif pokerType == modLobbyProto.PAIJIU then
		return "ui:card_game/paijiu/cards/back.png"
	end
end

local handCardTypeSoundInfoFunc = {
	[modLobbyProto.NIUNIU] = {
		[T_GENDER_FEMALE] = function(t)
			return sf("sound:card_game/niuniu/niu_1_%03d.mp3", getNiuSoundID(t))
		end,
		[T_GENDER_MALE] = function(t)
			return sf("sound:card_game/niuniu/niu_2_%03d.mp3", getNiuSoundID(t))
		end,
	}
}

getHandCardTypeSoundPath = function(pokerType, t, gender)
	if not gender or gender == T_GENDER_UNKOW then
		gender = T_GENDER_FEMALE
	end
	if handCardTypeSoundInfoFunc[pokerType] then
		return handCardTypeSoundInfoFunc[pokerType][gender](t)
	else
		return nil
	end
end

getCountdownSound = function(pokerType, second)
	if second <= 0 then
		return "sound:card_game/schtime2.mp3"
	else
		return "sound:card_game/schtime1.mp3"
	end
end

local pjTypeToName = {
	[modPaijiuProto.T_PJ_0] = TEXT("没点"),
	[modPaijiuProto.T_PJ_1] = TEXT("一"),
	[modPaijiuProto.T_PJ_2] = TEXT("二"),
	[modPaijiuProto.T_PJ_3] = TEXT("三"),
	[modPaijiuProto.T_PJ_4] = TEXT("四"),
	[modPaijiuProto.T_PJ_5] = TEXT("五"),
	[modPaijiuProto.T_PJ_6] = TEXT("六"),
	[modPaijiuProto.T_PJ_7] = TEXT("七"),
	[modPaijiuProto.T_PJ_8] = TEXT("八"),
	[modPaijiuProto.T_PJ_9] = TEXT("九"),
	[modPaijiuProto.T_PJ_DIGANG] = TEXT("地杠"),
	[modPaijiuProto.T_PJ_TIANGANG] = TEXT("天杠"),
	[modPaijiuProto.T_PJ_TIANJIUWANG] = TEXT("天九王"),
	[modPaijiuProto.T_PJ_D_5] = TEXT("对五"),
	[modPaijiuProto.T_PJ_D_7] = TEXT("对七"),
	[modPaijiuProto.T_PJ_D_8] = TEXT("对八"),
	[modPaijiuProto.T_PJ_D_9] = TEXT("对九"),
	[modPaijiuProto.T_PJ_D_YAOWU] = TEXT("对低脚"),
	[modPaijiuProto.T_PJ_D_YAOLIU] = TEXT("对高脚"),
	[modPaijiuProto.T_PJ_D_SILIU] = TEXT("对红头"),
	[modPaijiuProto.T_PJ_D_FUTOU] = TEXT("对斧"),
	[modPaijiuProto.T_PJ_D_BAN] = TEXT("对板"),
	[modPaijiuProto.T_PJ_D_CHANG] = TEXT("对长"),
	[modPaijiuProto.T_PJ_D_MEI] = TEXT("对梅"),
	[modPaijiuProto.T_PJ_D_HE] = TEXT("对和"),
	[modPaijiuProto.T_PJ_D_REN] = TEXT("对人"),
	[modPaijiuProto.T_PJ_D_DI] = TEXT("对地"),
	[modPaijiuProto.T_PJ_D_TIAN] = TEXT("对天"),
	[modPaijiuProto.T_PJ_DUI_XIANG] = TEXT("对响"),
}

local famousCardIdToName = {
	[44012] = TEXT("天字"),
	[43002] = TEXT("地字"),
	[42008] = TEXT("人"),
	[41004] = TEXT("和"),
	[33010] = TEXT("梅"),
	[32006] = TEXT("长"),
	[31004] = TEXT("板"),
	[24011] = TEXT("斧"),
	[23010] = TEXT("红头"),
	[22007] = TEXT("高脚"),
	[21006] = TEXT("低脚"),
}
local pjTypeToSound = {
	[modPaijiuProto.T_PJ_0] = "meidian",
	[modPaijiuProto.T_PJ_1] = "1",
	[modPaijiuProto.T_PJ_2] = "2",
	[modPaijiuProto.T_PJ_3] = "3",
	[modPaijiuProto.T_PJ_4] = "4",
	[modPaijiuProto.T_PJ_5] = "5",
	[modPaijiuProto.T_PJ_6] = "6",
	[modPaijiuProto.T_PJ_7] = "7",
	[modPaijiuProto.T_PJ_8] = "8",
	[modPaijiuProto.T_PJ_9] = "9",
	[modPaijiuProto.T_PJ_DIGANG] = "di_gang",
	[modPaijiuProto.T_PJ_TIANGANG] = "tian_gang",
	[modPaijiuProto.T_PJ_TIANJIUWANG] = "tianjiuwang",
	[modPaijiuProto.T_PJ_D_5] = "dui_5",
	[modPaijiuProto.T_PJ_D_7] = "dui_7",
	[modPaijiuProto.T_PJ_D_8] = "dui_8",
	[modPaijiuProto.T_PJ_D_9] = "dui_9",
	[modPaijiuProto.T_PJ_D_YAOWU] = "dui_dj",
	[modPaijiuProto.T_PJ_D_YAOLIU] = "dui_gj",
	[modPaijiuProto.T_PJ_D_SILIU] = "dui_ht",
	[modPaijiuProto.T_PJ_D_FUTOU] = "dui_fu",
	[modPaijiuProto.T_PJ_D_BAN] = "dui_ban",
	[modPaijiuProto.T_PJ_D_CHANG] = "dui_chang",
	[modPaijiuProto.T_PJ_D_MEI] = "dui_mei",
	[modPaijiuProto.T_PJ_D_HE] = "dui_he",
	[modPaijiuProto.T_PJ_D_REN] = "dui_ren",
	[modPaijiuProto.T_PJ_D_DI] = "dui_di",
	[modPaijiuProto.T_PJ_D_TIAN] = "dui_tian",
	[modPaijiuProto.T_PJ_DUI_XIANG] = "dui_xiang",
}

local famousCardIdToSound = {
	[44012] = "tian",
	[43002] = "di",
	[42008] = "ren",
	[41004] = "he",
	[33010] = "mei",
	[32006] = "chang",
	[31004] = "ban",
	[24011] = "fu",
	[23010] = "ht",
	[22007] = "gj",
	[21006] = "dj",
}

getPaijiuSoundPath = function(pjType, cardIds, sex)
	local name = getPaijiuSoundName(pjType, cardIds)
	if sex == T_GENDER_MALE then
		return "sound:card_game/paijiu/male/"..name .. ".mp3"
	else
		return "sound:card_game/paijiu/female/"..name .. ".mp3"
	end
end
getPaijiuSoundName = function(pjType, cardIds)
	if pjType <= modPaijiuProto.T_PJ_9 then
		local suffix = pjTypeToSound[pjType]
		if pjType == modPaijiuProto.T_PJ_0 then
			return suffix
		else
			local bigCardId = math.max(cardIds[1], cardIds[2])
			local prefix = famousCardIdToSound[bigCardId]
			if not prefix then
				prefix = "za"
			end
			return sf("%s_%s", prefix, suffix)
		end
	else
		return pjTypeToSound[pjType]
	end

end

getPaijiuHandTypeName = function(pjType, cardIds)
	if pjType <= modPaijiuProto.T_PJ_9 then
		local suffix = pjTypeToName[pjType]
		if pjType == modPaijiuProto.T_PJ_0 then
			return suffix
		else
			if not cardIds[1] or not cardIds[2] then
				return ""
			end
			local bigCardId = math.max(cardIds[1], cardIds[2])
			local prefix = famousCardIdToName[bigCardId]
			if not prefix then
				prefix = TEXT("杂")
			end
			return sf("%s%s", prefix, suffix)
		end
	else
		return pjTypeToName[pjType]
	end
end
