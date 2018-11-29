local modSessionMgr = import("net/mgr.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")
local modUtil = import("util/util.lua")

getMails = function(minMailId, mailCount, callback)
	local request = modMailProto.GetMailsRequest()
	request.min_mail_id = minMailId
	request.max_mail_count = mailCount
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modMailProto.GET_MAILS, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modMailProto.GetMailsReply()
			reply:ParseFromString(ret)
			if reply.error_code == modMailProto.GetMailsReply.SUCCESS then
				callback(true, "", reply.mails)
			else
				callback(false, TEXT("获取邮件失败"))
			end
		else
			callback(false, reason)
		end
	end)
end

processMail = function(mailId, processReq, callback)
	local request = modMailProto.ProcessMailRequest()
	request.mail_id = mailId
	request.mail_request = processReq:SerializeToString()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modMailProto.PROCESS_MAIL, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modMailProto.ProcessMailReply()
			reply:ParseFromString(ret)
			if reply.error_code == modMailProto.ProcessMailReply.SUCCESS then
				callback(true, "", reply.mail_reply)
			else
				if reply.error_code == modMailProto.ProcessMailReply.NO_MAIL then
					callback(false, TEXT("邮件不存在"))
				elseif reply.error_code == modMailProto.ProcessMailReply.NO_NEED_PROCESSING then
					callback(false, TEXT("邮件不需要处理"))
				elseif reply.error_code == modMailProto.ProcessMailReply.PROCESSED then
					callback(false, TEXT("已处理"))
				else
					callback(false, TEXT("处理失败"))
				end
			end
		else
			callback(false, reason)
		end
	end)
end

getLatestMailId = function(callback)
	local request = modMailProto.GetLatestMailIDRequest()
	local wnd = modUtil.loadingMessage(TEXT("通讯中..."))
	modSessionMgr.instance():callRpc(T_SESSION_PROXY, modMailProto.GET_LATEST_MAIL_ID, request, OPT_NONE, function(success, reason, ret)
		wnd:setParent(nil)
		if success then
			local reply = modMailProto.GetLatestMailIDReply()
			reply:ParseFromString(ret)
			if reply.error_code == modMailProto.GetLatestMailIDReply.SUCCESS then
				callback(true, "", reply.latest_mail_id)
			else
				callback(false, TEXT("获取失败"))
			end
		else
			callback(false, reason)
		end
	end)
end
