local modUtil = import("util/util.lua")
local modSessionMgr = import("net/mgr.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")

getMails = function(minId, maxCount, callback)
	local request = modMailProto.GetMailsRequest()
	request.min_mail_id = minId or 0
	request.max_mail_count = maxCount or 0 
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modMailProto.GET_MAILS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modMailProto.GetMailsReply() 
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modMailProto.GetMailsReply.SUCCESS then
				callback(true, "", reply)
			else
				callback(false, "获取邮件失败")
			end
		else
			infoMessage(TEXT("请求失败"))
		end
	end)
end

processMailRequest = function(id, processRequest, callback)
	if not id or not processRequest then return end
	local request = modMailProto.ProcessMailRequest()
	request.mail_id = id
	request.mail_request = processRequest:SerializeToString()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modMailProto.PROCESS_MAIL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modMailProto.ProcessMailReply() 
			reply:ParseFromString(ret)
			local code = reply.error_code
			if code == modMailProto.ProcessMailReply.SUCCESS then
				callback(reply.mail_reply)	
			elseif code == modMailProto.ProcessMailReply.NO_MAIL then
				infoMessage("查找不到此邮件")
			elseif code == modMailProto.ProcessMailReply.NO_NEED_PROCESSING then
				infoMessage("不需要处理此邮件")
			elseif code == modMailProto.ProcessMailReply.PROCESSED then
				infoMessage("此邮件已经处理过了")
				callback(false, true)
			else
				infoMessage("处理邮件失败")
			end
		else
			infoMessage(TEXT("请求失败"))
		end
	end)
end

processJoinMail = function(id, isAccept, callback)
	local joinRequest = modMailProto.Mail_JoinClubRequest()
	joinRequest.accept = isAccept
	processMailRequest(id, joinRequest, function(reply) 
		local joinReply = modMailProto.Mail_JoinClubReply()
		joinReply:ParseFromString(reply)
		local code = joinReply.error_code
		if code == modMailProto.Mail_JoinClubReply.SUCCESS then
			callback(true)
		elseif code == modMailProto.Mail_JoinClubReply.NO_CLUB then
			infoMessage("不存在的俱乐部Id")
		elseif code == modMailProto.Mail_JoinClubReply.CLUB_MEMBER_EXISTS then
			infoMessage("已经加入此俱乐部")
		elseif code == modMailProto.Mail_JoinClubReply.TOO_MANY_CLUB_MEMBERS then
			infoMessage("俱乐部人数已满")
		else
			infoMessage("加入俱乐部失败")
		end
	end)
end

processReturnGoldMail = function(id, isAccept, callback)
	local joinRequest = modMailProto.Mail_ReturnGoldCoinsToClubRequest()
	joinRequest.accept = isAccept
	processMailRequest(id, joinRequest, function(reply) 
		local joinReply = modMailProto.Mail_ReturnGoldCoinsToClubReply()
		joinReply:ParseFromString(reply)
		local code = joinReply.error_code
		if code == modMailProto.Mail_ReturnGoldCoinsToClubReply.SUCCESS then
			callback(true)
		elseif code == modMailProto.Mail_ReturnGoldCoinsToClubReply.NO_CLUB then
			infoMessage("不存在的俱乐部Id")
		elseif code == modMailProto.Mail_ReturnGoldCoinsToClubReply.NO_CLUB_MEMBER then
			infoMessage("该玩家非俱乐部成员")
		elseif code == modMailProto.Mail_ReturnGoldCoinsToClubReply.NO_GOLD_COIN then
			infoMessage("捐赠数量错误")
		else
			infoMessage("捐赠金豆给俱乐部失败")
		end
	end)
end

