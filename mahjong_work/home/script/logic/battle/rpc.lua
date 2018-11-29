local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modNiuniuProto = import("data/proto/rpc_pb2/pokers/niuniu_pb.lua")
local modUserData = import("logic/userdata.lua")
local modUIAllFunction = import("ui/common/uiallfunction.lua")
local modUserPropCache = import("logic/userpropcache.lua")
local modChatProto = import("data/proto/rpc_pb2/chat_pb.lua")
local modCardBattleCreate = import("logic/card_battle/create.lua")

doEnterRoom = function(roomId)
	lookupRoom(roomId, function(success, reason, roomId, roomHost, roomPort)
		if success then
			local modBattleMgr = import("logic/battle/main.lua")
			modBattleMgr.pBattleMgr:instance():enterBattle(roomId, roomHost, roomPort, function(success)
				if success then
				end
			end)
		else
			infoMessage(reason)
		end
	end)
end

roomcardText = function()
	local modChannelMgr = import("logic/channels/main.lua")
	return modChannelMgr.getCurChannel():getRoomcardText() or "钻石"
end

lookupRoom = function(roomId, callback)
	log("info", roomId, type(roomId))
	local request = modLobbyProto.LookupRoomRequest()
	request.room_id = roomId
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.LOOKUP_ROOM, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.LookupRoomReply()
			reply:ParseFromString(ret)
			if reply.error_code == modLobbyProto.LookupRoomReply.SUCCESS then
				local roomId = reply.room.id
				if roomId < 0 then
					callback(false, TEXT("没有找到该房间,可能房主已经退出。"))
				else
					callback(true, "", roomId, reply.room.host, reply.room.port, reply.room.game_type)
				end
			else
				callback(false, TEXT("查找失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

publickCreateList = function(valueList, request, ruleType)
	if valueList["player"] ~= nil then
		request.max_number_of_users = valueList["player"]end
	if valueList["round"] ~= nil then
		request.number_of_game_times = valueList["round"]end
	if valueList["auto_time"] ~= nil then
		request.auo_timeout = valueList["auto_time"]
	end
	if valueList["dibei"] ~= nil then
		request.dibei = valueList["dibei"]end

end

createList = function(valueList, request, ruleType)
	logv("info", "createList valueList: ", valueList, ruleType)
	publickCreateList(valueList, request, ruleType)
	if valueList["ruleType"] ~= nil then
		request.rule_type = valueList["ruleType"] end
	if valueList["hostmode"] ~= nil then
		request.allow_zhuangxian = valueList["hostmode"]end
	if valueList["jiepao"] ~= nil then
		request.allow_dianpao = valueList["jiepao"]end
	if valueList["tongpao"] ~= nil then
		request.allow_yipaoduoxiang = valueList["tongpao"] end
	if valueList["qianggang"] ~= nil then
		request.allow_qianggang = valueList["qianggang"] end
	if valueList["kechi"] ~= nil then
		request.allow_chi = valueList["kechi"]end
	if valueList["hongzhong"] ~= nil then
		request.allow_magic_cards = valueList["hongzhong"]end
	if valueList["bird"] ~= nil then
		request.zhuaniao_count = valueList["bird"]end
	if valueList["159zhuaniao"] ~= nil then
		request.zhongniao_rule = valueList["159zhuaniao"]end
	if valueList["liujuzhuang"] ~= nil then
		request.liujuzhuang = valueList["liujuzhuang"]end
	if valueList["room"] ~= nil then
		request.room_type = valueList["room"]end
	if valueList["dama"] ~= nil then
		request.allow_piao = valueList["dama"]end
	if valueList["baxiaodui"] ~= nil then
		request.allow_dui_hu = valueList["baxiaodui"]end
	if valueList["koupaimode"] ~= nil then
		request.conceal_discarded_cards = valueList["koupaimode"] end

	if ruleType == "mmmj" then
		if valueList["maima"] ~= nil then
			request.zhuaniao_count = valueList["maima"] end
		maomingCreateList(valueList, request.maoming_extras)
	elseif ruleType == "tjtjmj" then
		tianjingCreateList(valueList, request.tianjin_extras)
	elseif ruleType == "dsmj" then
		dongshanCreateList(valueList, request.dongshan_extras)
	elseif ruleType == "phmj" then		
		pingheCreateList(valueList, request.pinghe_extras)
	elseif ruleType == "yyhsz" then
		yunyangHuanSanZhangCreateList(valueList, request.yunyang_extras)
	elseif ruleType == "kawuxing" or ruleType == "baihekawuxing" then
		kawuxingCreateList(valueList, request.xiangyang_extras)
		if valueList["maima"] ~= nil then
			request.zhuaniao_count = valueList["maima"]
		end
	elseif ruleType == "cqddh" then
		cqddhCreateList(valueList, request.daodao_extras)
	elseif ruleType == "sdrcmj" then
		sdrcmjCreateList(valueList, request.rongcheng_extras)
	elseif ruleType == "xzdd" then
		xzddCreateList(valueList, request.chengdu_extras)
	elseif ruleType == "sdjnmj" then
		sdjnCreateList(valueList, request.jining_extras)
	end

	local x = valueList["cards"]
	for _,id in pairs(x) do
		request.preset_undealt_card_ids:append(tonumber(id))
	end
	request.group_id = valueList["grpId"] or -1
	return request
end

sdjnCreateList = function(valueList, extras)
	if valueList["genzhuang"] ~= nil then
		extras.genzhuang = valueList["genzhuang"]
	end

	if valueList["sankoubaohu"] ~= nil then
		extras.sankoubaohu = valueList["sankoubaohu"]
	end
end

xzddCreateList = function(valueList, extras)
	if valueList["huansanzhang"] ~= nil then
		extras.huansanzhang = valueList["huansanzhang"]
	end
	if valueList["dingque"] ~= nil then
		extras.dingque = valueList["dingque"]
	end
	if valueList["dianganghua"] ~= nil then
		extras.dianganghua = valueList["dianganghua"]
	end
	if valueList["hujiaozhuanyi"] ~= nil then
		extras.hujiaozhuanyi = valueList["hujiaozhuanyi"]
	end
	if valueList["zimojiadi"] ~= nil then
		extras.zimojiadi = valueList["zimojiadi"]
	end
	if valueList["zimojiafan"] ~= nil then
		extras.zimojiafan = valueList["zimojiafan"]
	end
	if valueList["jingoudiao"] ~= nil then
		extras.allow_jingoudiao = valueList["jingoudiao"]
	end
	if valueList["tiandihu"] ~= nil then
		extras.allow_tiandihu = valueList["tiandihu"]
	end

	if valueList["daiyaojiujiangdui"] ~= nil then
		extras.allow_yaojiujiangdui = valueList["daiyaojiujiangdui"]
	end
	if valueList["yitiaolong"] ~= nil then
		extras.allow_yitiaolong = valueList["yitiaolong"]
	end
	if valueList["menqingzhongzhang"] ~= nil then
		extras.allow_menqing = valueList["menqingzhongzhang"]
	end
	if valueList["fengding"] ~= nil then
		extras.max_fan_count = valueList["fengding"]
	end
	if valueList["fanqihu"] ~= nil then
		extras.min_fan_count = valueList["fanqihu"]
	end
end

cqddhCreateList = function(valueList, extras)
	if valueList["tuo"] ~= nil then
		extras.xy_scores = valueList["tuo"]
	end
end

sdrcmjCreateList = function(valueList, extras)
	if valueList["erwubazhang"] ~= nil then
		extras.erwubazhang = valueList["erwubazhang"]
	end
	if valueList["qiluo"] ~= nil then
		extras.qiluo = valueList["qiluo"]
	end
	if valueList["minglou"] ~= nil then
		extras.allow_minglou = valueList["minglou"]
	end
	if valueList["shuaiquan"] ~= nil then
		extras.allow_shuaiquan = valueList["shuaiquan"]
	end
	if valueList["daifengpai"] ~= nil then
		extras.allow_word_cards = valueList["daifengpai"]
	end
end

yunyangHuanSanZhangCreateList = function(valueList, extras)
	if valueList["dingque"] ~= nil then
		extras.dingque = valueList["dingque"]
	end
	if valueList["qiansihousi"] ~= nil then
		extras.allow_qiansi = valueList["qiansihousi"]
		extras.allow_housi = valueList["qiansihousi"]
	end
	if valueList["zhuangsanda"] ~= nil then
		extras.allow_zhuangsanda = valueList["zhuangsanda"]
	end
	if valueList["jingoudiao"] ~= nil then
		extras.allow_jingoudiao = valueList["jingoudiao"]
	end
	if (not valueList["dingque"]) and valueList["huazhu"] ~= nil then
		extras.huazhu_score = valueList["huazhu"]
	end
	if valueList["fengding"] ~= nil then
		extras.max_fan_count = valueList["fengding"]
	end
	log("info", "dingque:", valueList["dingque"], "qiansihousi:", valueList["qiansihousi"], "zhuangsanda:", valueList["zhuangsanda"], "jingoudiao", valueList["jingoudiao"], "huazhu:", valueList["huazhu"])
end

dongshanCreateList = function(valueList, extras)
	if valueList["fgsjkf"] ~= nil then
		extras.fgsjkf = valueList["fgsjkf"]
	end
end

pingheCreateList = function (valueList, extras)	
	if valueList["sijinban"] ~= nil then
		extras.sijinban = valueList["sijinban"]
	end
	if valueList["sanjindao_or_sijindao"] ~= nil then
		extras.sanjindao_or_sijindao = valueList["sanjindao_or_sijindao"]
	end
	if valueList["shuangyou_can_hu"] ~= nil then
		extras.shuangyou_can_hu = valueList["shuangyou_can_hu"]
	end
end


tianjingCreateList = function(valueList, extras)
	if valueList["jingang"] ~= nil then
		extras.allow_jingang = valueList["jingang"]		end
		if (not valueList["koupaimode"]) and valueList["chan"] ~= nil then
			extras.allow_chan = valueList["chan"]
		end
		if valueList["la"] ~= nil then
			extras.allow_la = valueList["la"]
		end
		if valueList["chuai"] ~= nil then
			extras.allow_chuai = valueList["chuai"]
		end
	end

maomingCreateList = function(valueList, extras, isMaoming)
	if valueList["fengtoupai"] ~= nil then
		extras.allow_word_cards = valueList["fengtoupai"] end
	if valueList["keqiangangang"] ~= nil then
		if valueList["fengtoupai"] then
			extras.allow_qiangangang = valueList["keqiangangang"] end
		end
	if valueList["sidajingang"] ~= nil then
		if valueList["dingguipai"] then
			extras.allow_sidajingang = valueList["sidajingang"] end
		end
	if valueList["gangbaochengbao"] ~= nil then
		extras.gangbao_chengbao = valueList["gangbaochengbao"] end
	if valueList["12zhangluodi"] ~= nil then
		extras.shierzhangluodi_chengbao = valueList["12zhangluodi"] end
	if valueList["qianggangchengbao"] ~= nil then
		if valueList["qianggang"] then
			extras.qianggang_chengbao = valueList["qianggangchengbao"] end
		end
	if valueList["fenzhurou"] ~= nil then
		extras.fenzhurou = valueList["fenzhurou"] end
	if valueList["wuguix2"] ~= nil then
		if valueList["dingguipai"] then
			extras.wugui_x2 = valueList["wuguix2"] end
		end
	if valueList["qianggangbeishu"] ~= nil then
		if valueList["qianggang"] then
			extras.qianggang_x2 = valueList["qianggangbeishu"] end
		end
	if valueList["gangshangkaihuax2"] ~= nil then
		extras.gangshangkaihua_x2 = valueList["gangshangkaihuax2"] end
	if valueList["dingguipai"] ~= nil then
		extras.dinggui = valueList["dingguipai"] end
	if valueList["matype"] ~= nil then
		if valueList["maima"] > 0 then
			extras.maima = valueList["matype"] end
		end
	fanbeiCreateList(extras.fanbei, valueList)
end

kawuxingCreateList = function(valueList, extras)
	if valueList["banpindao"] ~= nil then
		extras.banpindao = valueList["banpindao"]
	end
	if valueList["ldzmmm"] ~= nil then
		extras.liangdaomaima = valueList["ldzmmm"]
	end
	if valueList["fengding"] ~= nil then
		extras.max_fan_count = valueList["fengding"]
	end
end


fanbeiCreateList = function(fanbei, valueList)
	local fanValues = {
		["ddp"] = valueList["ddp"],
		["qd"] = valueList["qd"],
		["hj"] = valueList["hj"],
		["hsh"] = valueList["hsh"],
		["hys"] = valueList["hys"],
		["qys"] = valueList["qys"],
		["hyj"] = valueList["hyj"],
		["qyj"] = valueList["qyj"],
		["zys"] = valueList["zys"],
		["xsy"] = valueList["xsy"],
		["dsy"] = valueList["dsy"],
		["xsx"] = valueList["xsx"],
		["dsx"] = valueList["dsx"],
		["jlbd"] = valueList["jlbd"],
		["ssy"] = valueList["ssy"],
		["th"] = valueList["th"],
		["dh"] = valueList["dh"]
	}

	for k, v in pairs(fanValues) do
		if v ~= nil then
			fanbei[k] = v
		end
	end
end

createRoomByRequest = function(proto, request, callback)	
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))	
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, proto, request, OPT_NONE, function(success, reason, ret)		
		wnd:setParent(nil)		
		if success then
			local reply = modLobbyProto.CreateRoomReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.CreateRoomReply.SUCCESS then
				local roomId = reply.room.id
				local roomHost = reply.room.host
				local roomPort = reply.room.port
				local gameType = reply.room.game_type
				callback(true, "", roomId, roomHost, roomPort, gameType)
			elseif code == modLobbyProto.CreateRoomReply.FAILURE then
				callback(false, TEXT("创建房间失败"))
			elseif code == modLobbyProto.CreateRoomReply.LACK_OF_ROOM_CARDS then
				local r = TEXT(sf("%s不足", roomcardText()))
				callback(false, r, nil, nil, nil, nil, true)
			elseif code == modLobbyProto.CreateRoomReply.IN_OTHER_ROOM then
				callback(false,TEXT("已经在其他房间"))
			elseif code == modLobbyProto.CreateRoomReply.TOO_MANY_ROOMS then
				callback(false,TEXT("房间数量超出最大限制"))
			else
				callback(false, TEXT("创建房间失败"))
			end
		else
			callback(false, reason)
		end
	end)

end

createRoom = function(valueList, ruleType, callback)
	local request = modLobbyProto.CreateRoomRequest()
	--request = createList(valueList, request, ruleType)
	createList(valueList, request, ruleType)
	createRoomByRequest(modLobbyProto.CREATE_ROOM, request, callback)
end

createPokerRoom = function(valueList, ruleType, callback)

	local request = modCardBattleCreate.genCreatePokerRoomRequest(valueList, ruleType)
	createRoomByRequest(modLobbyProto.CREATE_POKER_ROOM, request, callback)
end

enterRoom = function(roomid, callback)	
	local request = modRoomProto.EnterRoomRequest()
	request.channel_id = modUtil.getOpChannel()
	request.user_id = modUserData.getUID()
	request.room_id = roomid
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modRoomProto.ENTER_ROOM, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modRoomProto.EnterRoomReply()
			reply:ParseFromString(ret)
			local isRoomCardError = false
			local code = reply.error_code
			if code == modRoomProto.EnterRoomReply.SUCCESS then
				result = modUIAllFunction.enterRoomConvert(roomid, reply)
				--logv("info","success")
				callback(success, reason, result)
				--logv("info","success")
			elseif code == modRoomProto.EnterRoomReply.FAILURE then
				success = false
				reason = TEXT("进入房间失败")
			elseif code == modRoomProto.EnterRoomReply.NO_ROOM then
				success = false
				reason = TEXT("找不到房间")
			elseif code ==modRoomProto.EnterRoomReply. ROOM_FULL then
				success = false
				reason = TEXT("房间已满")
			elseif code == modRoomProto.EnterRoomReply.ROOM_GAMING then
				success = false
				reason = TEXT("牌局已开始")
			elseif code == modRoomProto.EnterRoomReply.IN_OTHER_ROOM then
				success = false
				reason = TEXT("已经在其他房间")
			elseif code == modRoomProto.EnterRoomReply.LACK_OF_ROOM_CARDS then
				success = false
				reason = TEXT(sf("%s不足", roomcardText()))
				isRoomCardError = true
			else
				success = false
				reason = TEXT("进入房间失败")
			end
			if code ~= modRoomProto.EnterRoomReply.SUCCESS then
				callback(success, reason, nil, isRoomCardError)
			end
		else
			callback(false, "")
		end
	end, true)
end

discardCard = function(cardId, isTing, callback)
	local request = modGameProto.AnswerChooseCardToDiscardRequest()
	request.card_id = cardId
	request.pre_ting = isTing
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modGameProto.ANSWER_CHOOSE_CARD_TO_DISCARD, request, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modGameProto.AnswerChooseCardToDiscardReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGameProto.AnswerChooseCardToDiscardReply.SUCCESS then
				callback(true, "")
			else
				callback(false, TEXT("出牌失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

chooseCombIdx = function(idx, versionId, callback)
	local request = modGameProto.AnswerChooseCombinationRequest()
	request.comb_index = idx
	request.version = versionId
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modGameProto.ANSWER_CHOOSE_COMBINATION, request, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modGameProto.AnswerChooseCombinationReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGameProto.AnswerChooseCombinationReply.SUCCESS then
				callback(true, "")
			end
		else
			callback(false, reason)
		end
	end)
end

chooseAnGangIdx = function (angang_id,player_id,callback)
	logv("warn","chooseAnGangIdx",angang_id,player_id)
	local request = modGameProto.AnswerChooseAngangRequest()
	request.angang_id = angang_id
	request.player_id = player_id
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE,modGameProto.ANSWER_CHOOSE_ANGANG, request, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modGameProto.AnswerChooseAngangReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGameProto.AnswerChooseAngangReply.SUCCESS then
				callback(true, "")
			end
		else
			callback(false,reason)
		end
	end)
end

answerChooseCardRequest = function(cardIds, callback)
	local request = modGameProto.AnswerChooseCardsRequest()
	for _, id in pairs(cardIds) do
		request.card_ids:append(id)
	end
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modGameProto.ANSWER_CHOOSE_CARDS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modGameProto.AnswerChooseCardsReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGameProto.AnswerChooseCardsReply.SUCCESS then
				callback(true, "")
			elseif reply.error_code == modGameProto.AnswerChooseCardsReply.FAILURE then
				callback(false, "选择失败")
				for _, id in pairs(cardIds) do
					print(id, "choose card request", table.size(cardIds))
				end

			elseif reply.error_code == modGameProto.AnswerChooseCardsReply.BAD_CHOICE then
				callback(false, "无效的选择")
			end
		else
			callback(false, "操作失败")
		end
	end)
end

answerChooseFlag = function(idx, callback)
	local request = modGameProto.AnswerChoosePlayerFlagRequest()
	request.player_flag_index = idx
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modGameProto.ANSWER_CHOOSE_PLAYER_FLAG, request, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modGameProto.AnswerChoosePlayerFlagReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGameProto.AnswerChoosePlayerFlagReply.SUCCESS then
				callback(success, "")
			elseif reply.error_code == modGameProto.AnswerChoosePlayerFlagReply.FAILURE then
				callback(false, reason)
			end
		else
			callback(false, reason)
		end

	end)
end

confirmCalcResult = function(callback)
	local request = modGameProto.AnswerCheckGameOverRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modGameProto.ANSWER_CHECK_GAME_OVER, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modGameProto.AnswerCheckGameOverReply()
			reply:ParseFromString(ret)
			if reply.error_code == modGameProto.AnswerCheckGameOverReply.SUCCESS then
				callback(true, "")
			else
				callback(false, TEXT("操作失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

answerCloseRoom = function(yesOrCancel,callback)
	local request = modRoomProto.AnswerCloseRoomRequest()
	request.yes_or_no = yesOrCancel
	local wnd = modUtil.loadingMessage(TEXT("通讯中.."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE,modRoomProto.ANSWER_CLOSE_ROOM,request,OPT_NONE,function(success,reason,ret)
		wnd:setParent(nil)
		if	success then
			local reply = modRoomProto.AnswerCloseRoomReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modRoomProto.AnswerCloseRoomReply.SUCCESS then
				callback(true,"")
			elseif code == modRoomProto.AnswerCloseRoomReply.FAILURE then
				callback(false,TEXT("请求失败"))
			else
				callback(false,TEXT("未知原因,请求失败"))
			end

		else
			callback(false,reason)
		end
	end)
end

updateUserProps = function(userId, callback)
	local request = modLobbyProto.GetUserPropsRequest()
	request.user_id = userId
	request.all_require = true

	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_USER_PROPS, request, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modLobbyProto.GetUserPropsReply()
			reply:ParseFromString(ret)
			if reply.avatar_url == nil or reply.avatar_url == "" then
				local image = "ui:image_default_female.png"
				if reply.gender == T_GENDER_MALE then
					image = "ui:image_default_male.png"
				end
				reply.nickname = reply.nickname
				reply.avatar_url = image
			end
			callback(success, reply)
		end
	end)
end

dismissRoom = function(time,callback)
	local request = modRoomProto.AskCloseRoomRequest()
	request.user_id = modUserData.getUID()
	request.timeout = time or 1
	local wnd = modUtil.loadingMessage(TEXT("通讯中.."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE,modRoomProto.ASK_CLOSE_ROOM,request,OPT_NONE,function(success,reason,ret)
		wnd:setParent(nil)
		if success then
			local reply = modRoomProto.AskCloseRoomReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modRoomProto.AskCloseRoomReply.SUCCESS then
				callback(true,"")
			elseif code == modRoomProto.AskCloseRoomReply.FAILURE then
				callback(false,TEXT("解散失败."))
			elseif code == modRoomProto.AskCloseRoomReply.NOT_OWNER then
				callback(false,TEXT("您不是房主."))
			else
				callback(false,TEXT("操作失败."))
			end
		else
			callback(false,reason)
		end
	end)
end

leaveRoom = function(callback)
	local request = modRoomProto.LeaveRoomRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE,modRoomProto.LEAVE_ROOM,request,OPT_NONE,function(success,reason,ret)
	wnd:setParent(nil)
	if success then
		local reply = modRoomProto.LeaveRoomReply()
		reply:ParseFromString(ret)
		local code = reply.error_code
		if code == modRoomProto.LeaveRoomReply.SUCCESS then
			callback(true,"")
		elseif code == modRoomProto.LeaveRoomReply.FAILURE then
			callback(false,TEXT("离开失败"))
		elseif code == modRoomProto.LeaveRoomReply.GAMING then
			callback(false,TEXT("正在游戏,无法离开"))
		elseif code == modRoomProto.LeaveRoomReply.OWNER then
			callback(false,TEXT("房主无法离开游戏"))
		else
			infoMessage("未知原因，离开失败")
		end
	else
		infoMessage("请求失败")
	end
	end)
end


getOwnedRoom = function(clubId, callback)
	local request = modLobbyProto.GetOwnedRoomInfosRequest()
	request.club_id = clubId or -1
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_OWNED_ROOM_INFOS, request, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modLobbyProto.GetOwnedRoomInfosReply()
            reply:ParseFromString(ret)
			local code = reply.error_code
			if success then
				callback(true,reply)
			elseif code == modLobbyProto.GetOwnedRoomInfosReply.FAILURE then
				callback(false,TEXT("请求代开信息失败"))
			end
		end
	end)
end

dismissOwnerRoom = function(roomId,callback)
	local request = modLobbyProto.CloseOwnedRoomRequest()
	request.room_id = roomId
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.CLOSE_OWNED_ROOM, request, OPT_NONE, function(success,reason,ret)
		if success then
			local reply = modLobbyProto.CloseOwnedRoomReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.CloseOwnedRoomReply.SUCCESS then
				callback(true, "")
			elseif code == modLobbyProto.CloseOwnedRoomReply.FAILURE then
				callback(false, "解散代开房间失败")
			elseif code == modLobbyProto.CloseOwnedRoomReply.ASKING_FOR_CLOSE then
				callback(false, "正在等待玩家投票!")
			else
				callback(false, "未知原因, 解散失败")
			end
		else
			callback(false, "失败")
		end
	end)
end

joinMatchRoom = function(callback)
	local request = modLobbyProto.JoinMatchRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.JOIN_MATCH, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.JoinMatchReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.JoinMatchReply.SUCCESS then
				if callback then
					callback(true, "", reply.room)
				end
			elseif code == modLobbyProto.JoinMatchReply.FAILURE then
					callback(false, "匹配失败")
			elseif code == modLobbyProto.JoinMatchReply.LACK_OF_GOLD_COINS then
				callback(false, "金币不足")
			end

		end
	end)
end

-- 自己所有游戏录像集合
getAllGameVideos = function(t, pageSize, pageNumber, clubId, callback)
	local request = modLobbyProto.GetAllGameRecordGroupsRequest()
	request.grgc = t
	request.page_size = page_size or 10
	request.page_number = page_number or 0
	request.club_id = clubId or -1
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_ALL_GAME_RECORD_GROUPS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetGameRecordGroupsReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetGameRecordGroupsReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.GetGameRecordGroupsReply.FAILURE then
				callback(false, "请求游戏记录失败!")
			end
		else
		end
	end)
end

-- 指定keys的录像集合
getGameVideosByKeys = function(keys, callback)
	local request = modLobbyProto.GetGameRecordGroupsRequest()
	for _, key in ipairs(keys) do
		request.game_record_group_ids:append(key)
	end
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_GAME_RECORD_GROUPS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetGameRecordGroupsReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetGameRecordGroupsReply.SUCCESS then
				callback(true, "", reply)

			elseif code == modLobbyProto.GetGameRecordGroupsReply.FAILURE then
				callback(false, "请求游戏记录失败!")
			end
		else
		end
	end)
end

getGameVideoInfosByKeys = function(keys, callback)
	local request = modLobbyProto.GetGameRecordInfosRequest()
	for _, key in ipairs(keys) do
		request.game_record_ids:append(key)
	end
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_GAME_RECORD_INFOS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetGameRecordInfosReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetGameRecordInfosReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.GetGameRecordInfosReply.FAILURE then
				callback(false, "请求游戏记录信息失败!")
			end
		else
			infoMessage(reason)
		end
	end)
end

getGameVideo = function(id, callback)
	local request = modLobbyProto.GetGameRecordRequest()
	request.game_record_id = id
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_GAME_RECORD, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetGameRecordReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetGameRecordReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.GetGameRecordReply.FAILURE then
				callback(false, "请求游戏记录失败!")
			end
		else
		end
	end)
end

-- 取多个玩家属性
getUserPropsRequest = function(request, nameList, uids)
	if not nameList or not request or not uids then return end
	for _, uid in ipairs(uids) do
		request.user_ids:append(uid)
	end
	for _, name in pairs(nameList) do
		local propName = modUserPropCache.pUserPropCache:instance():getProtoKeyByPropKey(name)
		if propName then
			request[propName] = true
		else
			log("error", "not prop:", propName)
		end
	end
	return request
end

getMultiUserProps = function(uids, propKeyList, callback)
	local request = modLobbyProto.GetMultiUserPropsRequest()
	getUserPropsRequest(request, propKeyList, uids)
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_MULTI_USER_PROPS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetMultiUserPropsReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetMultiUserPropsReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.GetMultiUserPropsReply.FAILURE then
				callback(false, "请求多人玩家信息失败!")
			end
		else
		end
	end)
end


moveVideo = function(id, t, clubId, callback)
	local request = modLobbyProto.MoveGameRecordGroupRequest()
	request.game_record_group_id = id
	request.new_grgc = t
	request.club_id = clubId or -1
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.MOVE_GAME_RECORD_GROUP, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.MoveGameRecordGroupReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.MoveGameRecordGroupReply.SUCCESS then
				callback(true, "")
			elseif code == modLobbyProto.MoveGameRecordGroupReply.FAILURE then
				callback(false, "移动录像失败!!")
			end
		end
	end)
end

changeCard = function(oldId, newId, callback)
	local request = modGameProto.ReplaceHeldCardRequest()
	request.old_held_card_id = oldId
	request.new_held_card_id = newId
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modGameProto.REPLACE_HELD_CARD, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modGameProto.ReplaceHeldCardReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modGameProto.ReplaceHeldCardReply.SUCCESS then
				callback(true, "")
			elseif code == modGameProto.ReplaceHeldCardReply.FAILURE then
				callback(false, "更换失败!!")
			end
		end
	end)
end

getUndealtCards = function(callback)
	local request = modGameProto.GetUndealtCardsRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modGameProto.GET_UNDEALT_CARDS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modGameProto.GetUndealtCardsReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modGameProto.GetUndealtCardsReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modGameProto.GetUndealtCardsReply.FAILURE then
				callback(false, "查询失败!!")
			end
		end
	end)
end

startRealNameAuth = function(name, no, callback)
	if name == "" or no == "" then
		log("error", "name or no is nil!!!")
		return
	end
	local request = modLobbyProto.StartRealNameAuthRequest()
	request.real_name = name
	request.phone_no = no
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.START_REAL_NAME_AUTH, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.StartRealNameAuthReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.StartRealNameAuthReply.SUCCESS then
				callback(true, sf("短信验证码发送成功，请在%d分钟内完成验证", reply.timeout / 60), reply.min_interval)
			elseif code == modLobbyProto.StartRealNameAuthReply.FREQUENT then
				callback(false, sf("操作频繁，请%d分钟后再试!", reply.min_interval / 60))
			elseif code == modLobbyProto.StartRealNameAuthReply.INVALID_REAL_NAME then
				callback(false, "无效的姓名")
			elseif code == modLobbyProto.StartRealNameAuthReply.INVALID_PHONE_NO then
				callback(false, "无效的手机号码")
			elseif code == modLobbyProto.StartRealNameAuthReply.FAILURE then
				callback(false, "短信发送失败!!")
			end
		else
			log("error", "请求StartRealNameAuthRequest", success)
		end
	end)
end

inviteCode = function(code, callback)
	if code == "" then
		log("error", "code is nil!!!")
		return
	end
	local request = modLobbyProto.BindInviteCodeRequest()
	request.invite_code = code
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.BIND_INVITE_CODE, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.BindInviteCodeReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.BindInviteCodeReply.SUCCESS then
				callback(true, "恭喜您，绑定成功！将获得绑定奖励")
			elseif code == modLobbyProto.BindInviteCodeReply.BAD_IC then
				callback(false, "请填入正确的邀请码")
			elseif code == modLobbyProto.BindInviteCodeReply.FAILURE then
				callback(false, "绑定失败!!")
			end
		end
	end)
end

completeRealNameAuth = function(name, no, code, callback)
	if name == "" or no == "" or code == "" then
		log("error", "name or no or code is nil!!!")
		return
	end
	local request = modLobbyProto.CompleteRealNameAuthRequest()
	request.real_name = name
	request.phone_no = no
	request.verification_code = code
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.COMPLETE_REAL_NAME_AUTH, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.CompleteRealNameAuthReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.CompleteRealNameAuthReply.SUCCESS then
				callback(true, "")
			elseif code == modLobbyProto.CompleteRealNameAuthReply.TIMED_OUT then
				callback(false, "验证码超时")
			elseif code == modLobbyProto.StartRealNameAuthReply.FAILURE then
				callback(false, "认证失败!!")
			end
		end
	end)
end

getUserPerf = function(uid, channelId, callback)
	local request = modLobbyProto.GetUserPerfRequest()
	request.user_id = uid
	if channelId and channelId ~= "" then
		request.channel_id = channelId
	end
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_USER_PERF, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetUserPerfReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetUserPerfReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.GetUserPerfReply.FAILURE then
				callback(false, "请求玩家战绩失败!!")
			end
		end
	end)
end


commitGeoLocation = function(longitude, latitude, callback)
	local request = modRoomProto.SetUserGeoLocationRequest()
	request.user_geo_location.user_id = modUserData.getUID()
	request.user_geo_location.latitude = tostring(sf("%.8f", latitude))
	request.user_geo_location.longitude = tostring(sf("%.8f", longitude))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modRoomProto.SET_USER_GEO_LOCATION, request, OPT_NONE, function(success, reason, ret)
		if success then
			callback(true, "")
		else
			callback(false, "上报位置失败")
		end
	end)
end

fetchGeoLocations = function(uids, callback)
	local request = modRoomProto.GetUserGeoLocationsRequest()
	for _, uid in ipairs(uids) do
		request.user_ids:append(tonumber(uid))
	end
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modRoomProto.GET_USER_GEO_LOCATIONS, request, OPT_NONE, function(success, reason, ret)
		if success then
			local reply = modRoomProto.GetUserGeoLocationsReply()
			reply:ParseFromString(ret)
			if reply.error_code == modRoomProto.GetUserGeoLocationsReply.SUCCESS then
				local infos = {}
				for _, location in ipairs(reply.user_geo_locations) do
					local uid = location.user_id
					local longitude = tonumber(location.longitude)
					local latitude = tonumber(location.latitude)
					infos[uid] = {longitude, latitude}
				end
				callback(true, "", infos)
			else
				callback(false, "获取玩家位置失败")
			end
		else
			callback(false, "获取玩家位置失败")
		end
	end)
end

sendMessage = function(id, uids, callback)
	local request = modChatProto.SendChatMessageRequest()
	for _, uid in pairs(uids) do
		request.to_user_ids:append(uid)
	end
	request.chat_message.category = modChatProto.ChatMessage.ROOM
	request.chat_message.type = modChatProto.ChatMessage.FIXED
	local tmp = modChatProto.ChatMessage.Fixed()
	tmp.fixed_id = id
	request.chat_message.data = tmp:SerializeToString()

	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modChatProto.SEND_CHAT_MESSAGE, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modChatProto.SendChatMessageReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modChatProto.SendChatMessageReply.SUCCESS then
				callback(true, "")
			elseif code == modChatProto.SendChatMessageReply.FAILURE then
				callback(false, "发送失败！")
			end
		else
			callback(false, "发送请求失败！")
		end
	end)
end

getSharedRoomHistories = function(index, size, clubId, callback)
	local request = modLobbyProto.GetSharedRoomHistoriesRequest()
	request.page_size = size or 10
	request.page_number = index or 0
	request.club_id = clubId or -1
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_SHARED_ROOM_HISTORIES, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetSharedRoomHistoriesReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetSharedRoomHistoriesReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.GetSharedRoomHistoriesReply.FAILURE then
				callback(false, "获取失败!!")
			end
		end
	end)
end


delSharedRoomHistories = function(id, clubId, callback)
	local request = modLobbyProto.DeleteSharedRoomHistoryRequest()
	request.shared_room_history_id = id
	request.club_id = clubId or -1
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.DELETE_SHARED_ROOM_HISTORY, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.DeleteSharedRoomHistoryReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.DeleteSharedRoomHistoryReply.SUCCESS then
				callback(true, "")
			elseif code == modLobbyProto.DeleteSharedRoomHistoryReply.FAILURE then
				callback(false, "删除失败!!")
			end
		end
	end)
end

shareSuccess = function(callback)
	local request = modLobbyProto.GiveDailySharingAwardRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GIVE_DAILY_SHARING_AWARD, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GiveDailySharingAwardReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GiveDailySharingAwardReply.SUCCESS then
				callback(true, "分享成功，恭喜您获得奖励")
			elseif code == modLobbyProto.GiveDailySharingAwardReply.FAILURE then
				callback(false, "分享失败!!")
			elseif code == modLobbyProto.GiveDailySharingAwardReply.GIVEN then
				callback(false, "您已经分享过了, 明天继续获得奖励吧")
			end
		end
	end)
end

shareRedpacketSuccess = function(callback)
	local request = modLobbyProto.SendRedEnvelopeRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.SEND_RED_ENVELOPE, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
--		-- test
--		success = true

		if success then
			local reply = modLobbyProto.SendRedEnvelopeReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.SendRedEnvelopeReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.SendRedEnvelopeReply.FAILURE then
				callback(false, "分享失败!!")
			elseif code == modLobbyProto.SendRedEnvelopeReply.SENT then
				callback(false, "您已经分享过了, 下次再分享吧")
			end
		else
			infoMessage("请求失败")
		end
	end)
end

openRedpacket = function(callback)
	local request = modLobbyProto.OpenRedEnvelopeRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.OPEN_RED_ENVELOPE, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.OpenRedEnvelopeReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.OpenRedEnvelopeReply.SUCCESS then
				callback(true, "")
			elseif code == modLobbyProto.OpenRedEnvelopeReply.FAILURE then
				callback(false, "打开红包失败!!")
			elseif code == modLobbyProto.OpenRedEnvelopeReply.NO_MONEY then
				callback(false, "红包已经发完啦, 下次记得快点吧")
			else
				callback(false, "未知原因，打开失败")
			end
		else
			infoMessage("请求失败")
		end
	end)
end


getShareDaily = function(callback)
	local request = modLobbyProto.GetDailySharingInfoRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modLobbyProto.GET_DAILY_SHARING_INFO, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modLobbyProto.GetDailySharingInfoReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modLobbyProto.GetDailySharingInfoReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modLobbyProto.GetDailySharingInfoReply.FAILURE then
				callback(false, "获取失败!!")
			end
		end
	end)
end

stopAutoPlaying = function(callback)
	local request = modGameProto.StopAutoPlayingRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_BATTLE, modGameProto.STOP_AUTO_PLAYING, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modGameProto.StopAutoPlayingReply()
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modGameProto.StopAutoPlayingReply.SUCCESS then
				callback(true, "", reply)
			elseif code == modGameProto.StopAutoPlayingReply.FAILURE then
				callback(false, "停止托管失败!!")
			end
		else
			infoMessage("请求失败")
		end
	end)
end
