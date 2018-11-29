local modSessionMgr = import("net/mgr.lua")
local modRoomProto = import("data/proto/rpc_pb2/room_pb.lua")
local modGameProto = import("data/proto/rpc_pb2/game_pb.lua")
local modLobbyProto = import("data/proto/rpc_pb2/lobby_pb.lua")
local modProtoToFunction = import("net/rpc/proto_to_function.lua")
local modMailProto = import("data/proto/rpc_pb2/mail_pb.lua")
local modClubProto = import("data/proto/rpc_pb2/club_pb.lua")
local modChatProto = import("data/proto/rpc_pb2/chat_pb.lua")

local disRoomTime = 60
local protos = {
	modRoomProto.CLOSE_ROOM, 
	modRoomProto.CANCEL_CLOSE_ROOM, 
	modRoomProto.ANSWER_CLOSE_ROOM, 
	modRoomProto.ASK_CLOSE_ROOM,
	modRoomProto.APPLY_CLOSE_ROOM,
	modLobbyProto.UPDATE_USER_PROPS,
	modLobbyProto.POST_NOTICES,
	modRoomProto.ADD_USER,
	modRoomProto.REMOVE_USER,
	modRoomProto.UPDATE_ONLINE,
	modGameProto.UPDATE_CARD_POOL,
	modGameProto.UPDATE_SHOWED_COMBINATIONS,
	modGameProto.ASK_CHOOSE_CARD_TO_DISCARD,
	modGameProto.ASK_CHOOSE_PLAYER_FLAG,
	modGameProto.UPDATE_PLAYER_FLAGS,
	modGameProto.START_GAME,
	modGameProto.ASK_CHOOSE_COMBINATION,
	modGameProto.ASK_CHOOSE_ANGANG,
	modGameProto.NEXT_TURN,
	modGameProto.ASK_CHECK_GAME_OVER,
	modGameProto.UPDATE_PLAYER_SCORE,
	modGameProto.UPDATE_UNDEALT_CARD_COUNT,
	modRoomProto.SHOW_CLOSURE_REPORT,
	modGameProto.ROLL_DICES,
	modChatProto.SEND_CHAT_MESSAGE,
	modGameProto.ENTER_GAME_PHASE,
	modGameProto.ASK_CHOOSE_CARDS,
	modGameProto.ROB_ANGANG_RESULT,
	modGameProto.UPDATE_WINNING_CARDS,
	modGameProto.UPDATE_MAGIC_CARDS,
	modGameProto.UPDATE_RESERVED_CARD_COUNT,
	modGameProto.UPDATE_SPECIAL_DISCARDING_POSITION,
	modGameProto.UPDATE_PLAYER_EXTRAS,
	modMailProto.NOTIFY_NEW_MAIL,
	modClubProto.UPDATE_CLUB_MEMBER,
}
local register = function()
	for _, proto in pairs(protos) do
		modSessionMgr.instance():regRpcMethod(proto, modProtoToFunction.getProtoFunction(proto))
	end
end

__init__ = function()
	register()
end

