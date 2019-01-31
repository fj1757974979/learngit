module Pvp {

    async function rpc_UpdateMatchInfo(_:Net.RemoteProxy, payload:Uint8Array) {
        await PvpMgr.inst.readyFight()
        let arg = pb.MatchInfo.decode(payload);
        Net.rpcCall(pb.MessageID.C2S_MATCH_READY_DONE, pb.MatchDoneArg.encode({"RoomId":arg.RoomId}));
    }

    function rpc_MatchTimeout(_:Net.RemoteProxy, payload:Uint8Array) {
        PvpMgr.inst.onMatchTimeout();
    }

    function rpc_RefreshRank(_:Net.RemoteProxy, payload:Uint8Array) {
        console.debug("rpc_RefreshRank");
        // let rankListWnd = Core.ViewManager.inst.getView(ViewName.rankListWnd) as RankListWnd;
        // if (rankListWnd) {
        //     console.debug("initialized = false");
        //     rankListWnd.initialized = false;
        // }
        PvpMgr.inst.pvpRankNeedRefresh = true;
        PvpMgr.inst.pvpSeasonRankNeedRefresh = true;
    }

    function rpc_MailRedDot(_:Net.RemoteProxy, payload:Uint8Array) {
        MailMgr.inst.dispatchEventWith(MailMgr.MailRedDot, false, true);
    }

    function rpc_SeasonBegin(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.SeasonPvpLimitTime.decode(payload);
        Core.EventCenter.inst.dispatchEventWith(GameEvent.SeasonBegin, false, arg.LimitTime);
    }
    function rpc_SeasonEnd(_:Net.RemoteProxy, payload:Uint8Array) {
        Season.SeasonMgr.inst.seaonTime = 0;
        Core.EventCenter.inst.dispatchEventWith(GameEvent.SeasonEnd, false);
    }

    function rpc_UpdateRankHandCard(_:Net.RemoteProxy, payload:Uint8Array) {        
        Core.EventCenter.inst.dispatchEventWith(GameEvent.ShowRankCard, false, false);
    }


    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_MATCH_INFO, rpc_UpdateMatchInfo);
        Net.registerRpcHandler(pb.MessageID.S2C_MATCH_TIMEOUT, rpc_MatchTimeout);
        Net.registerRpcHandler(pb.MessageID.S2C_REFRESH_RANK, rpc_RefreshRank);
        Net.registerRpcHandler(pb.MessageID.S2C_NOTIFY_NEW_MAIL, rpc_MailRedDot);
        Net.registerRpcHandler(pb.MessageID.S2C_SEASON_PVP_BEGIN, rpc_SeasonBegin);
        Net.registerRpcHandler(pb.MessageID.S2C_SEASON_PVP_STOP, rpc_SeasonEnd);
        Net.registerRpcHandler(pb.MessageID.S2C_SEASON_PVP_CHANGE_HAND_CARD, rpc_UpdateRankHandCard);
    }

}