// TypeScript file
module Social {

    function rpc_FriendApplyNotify(_:Net.RemoteProxy, payload:Uint8Array) {
        //let arg = pb.FriendApplyNotifyArg.decode(payload);
        let num = FriendMgr.inst.applyNum;
        FriendMgr.inst.applyNum = num + 1;
    }

    function rpc_FriendApplyResult(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.FriendApplyResult.decode(payload);
        if (arg.IsAgree) {
            Core.EventCenter.inst.dispatchEventWith(GameEvent.AddFriend, false, arg.Name);
        }
    }

    function rpc_PrivateChatNotify(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.PrivateChatItem.decode(payload);
        let uid = <Long>arg.Uid;
        let chatlets = ChatMgr.inst.addPrivateChatlets(arg);
        if (chatlets) {
            ChatMgr.inst.addPrivateHintsNum(chatlets[0].uid, chatlets.length);
        }
        Core.EventCenter.inst.dispatchEventWith(GameEvent.PrivateChat, false, chatlets);
    }

    function rpc_ChatNotify(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.ChatNotify.decode(payload);
        //if (arg.Channel == ChatChannel.WORLD) {
        let chatlet = ChatMgr.inst.addChannelChatlet(arg.Channel, <pb.Chatlet>arg.Chat);
        Core.EventCenter.inst.dispatchEventWith(GameEvent.ChannelChatEv, false, {"chatlet":chatlet, "channel":arg.Channel});
        //}
    }

    function rpc_BeInviteBattle(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.BeInviteBattleArg.decode(payload);
        Core.EventCenter.inst.dispatchEventWith(GameEvent.BeInviteBattleEv, false, [arg.Uid, arg.Name]);
    }

    function rpc_InviteBattleResult(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.InviteBattleResult.decode(payload);
        Core.EventCenter.inst.dispatchEventWith(GameEvent.InviteBattleResEv, false, arg.Result);
    }

    function rpc_BeDelFriend(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.TargetPlayer.decode(payload);
        Core.EventCenter.inst.dispatchEventWith(GameEvent.DeletedByFriend, false, arg.Uid);
    }

    function rpc_InviteRewardHit(_:Net.RemoteProxy, payload:Uint8Array) {
        Core.EventCenter.inst.dispatchEventWith(InviteDataMgr.UpdateInviteHit, false, true);
    }

    function rpc_UnlockEmoji(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.UnlockEmojiArg.decode(payload);
        let team = EmojiMgr.inst.getEmojiTeam(arg.EmojiTeam);
        if (team) {
            team.isUnlock = true;
        }
    }

    function rpc_OnUnSubscribeChat(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.TargetChatChannel.decode(payload);
        ChatMgr.inst.drainWorldChatlets(arg.Channel);
        Core.EventCenter.inst.dispatchEventWith(GameEvent.UnSubscribeChatEv, false, arg.Channel);
    }

    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_FRIEND_APPLY_NOTIFY, rpc_FriendApplyNotify);
        Net.registerRpcHandler(pb.MessageID.S2C_FRIEND_APPLY_RESULT, rpc_FriendApplyResult);
        Net.registerRpcHandler(pb.MessageID.S2C_PRIVATE_CHAT_NOTIFY, rpc_PrivateChatNotify);
        Net.registerRpcHandler(pb.MessageID.S2C_CHAT_NOTIFY, rpc_ChatNotify);
        Net.registerRpcHandler(pb.MessageID.S2C_BE_INVITE_BATTLE, rpc_BeInviteBattle);
        Net.registerRpcHandler(pb.MessageID.S2C_INVITE_BATTLE_RESULT, rpc_InviteBattleResult);
        Net.registerRpcHandler(pb.MessageID.S2C_BE_DEL_FRIEND, rpc_BeDelFriend);
        Net.registerRpcHandler(pb.MessageID.S2C_WX_INVITE_SHOW_RED_DOT, rpc_InviteRewardHit);
        Net.registerRpcHandler(pb.MessageID.S2C_UNLOCK_EMOJI, rpc_UnlockEmoji);
        Net.registerRpcHandler(pb.MessageID.S2C_ON_UNSUBSCRIBE_CHAT, rpc_OnUnSubscribeChat);
    }
}