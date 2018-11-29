local modMailRpc = import("logic/post/rpc.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")

local ST_NO_NEED_PROCCESS = 0
local ST_NEED_PROCESS = 1
local ST_PROCESSED = 2

protoToMailInfo = function(proto)
	local ret = {}
	ret["id"] = proto.id
	ret["category"] = proto.category
	ret["type"] = proto.type
	ret["state"] = proto.state
	ret["from_user_id"] = proto.from_user_id
	ret["created_date"] = proto.created_date
	ret["text"] = proto.text
	return ret
end

pMail = pMail or class()

pMail.init = function(self, mgr, mailInfo)
	self.mgr = mgr
	self.mailInfo = mailInfo
end

pMail.save = function(self)
	self.mgr:saveMail(self)
end

pMail.getInfo = function(self)
	return self.mailInfo
end

pMail.getId = function(self)
	return self.mailInfo.id
end

pMail.getCategory = function(self)
	return self.mailInfo.category
end

pMail.getType = function(self)
	return self.mailInfo.type
end

pMail.getState = function(self)
	return self.mailInfo.state
end

pMail.getFromUserId = function(self)
	return self.mailInfo.from_user_id
end

pMail.getCreatedDate = function(self)
	return self.mailInfo.created_date
end

pMail.getText = function(self)
	return self.mailInfo.text
end

pMail.getAttach = function(self)
	return self.attach
end

pMail.needDisplay = function(self, t)
	if t == "all" then
		return true
	else
		return false
	end
end

pMail.needOperate = function(self)
	return false
end

pMail.operate = function(self, param, callback)
end

---------------------------------------------------------

pMailJoinClub = pMailJoinClub or class(pMail)

pMailJoinClub.operate = function(self, isAccept, callback)
	local request = modMailProto.Mail_JoinGroupRequest()
	request.accept = isAccept
	modMailRpc.processMail(self:getId(), request, function(success, reason, ret)
		if success then
			local reply = modMailProto.Mail_JoinGroupReply()
			reply:ParseFromString(ret)
			if reply.error_code == modMailProto.Mail_JoinGroupReply.SUCCESS then
				self.mailInfo["state"] = modMailProto.Mail.PROCESSED
				self:save()
				self.mgr:onProcessMail(self)
				callback(true, "")
			else
				local reason = ""
				if reply.error_code == modMailProto.Mail_JoinGroupReply.NO_GROUP then
					reason = TEXT("俱乐部已不存在")
				elseif reply.error_code == modMailProto.Mail_JoinGroupReply.GROUP_MEMBER_EXISTS then
					reason = TEXT("该玩家已经加入俱乐部了")
				elseif reply.error_code == modMailProto.Mail_JoinGroupReply.TOO_MANY_GROUP_MEMBERS then
					reason = TEXT("俱乐部成员已满")
				else
					reason = TEXT("操作失败")
				end
				callback(false, reason)
			end
		else
			callback(success, reason)
		end
	end)
end

pMailJoinClub.needDisplay = function(self, t)
	return self.mailInfo.state == ST_NEED_PROCESS
end

pMailJoinClub.needOperate = function(self)
	return self:needDisplay()
end

pMailJoinClub.save = function(self)
	pMail.save(self)
end
