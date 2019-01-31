module Home {

    function rpc_SyncResource(_:Net.RemoteProxy, payload:Uint8Array) {
        Player.inst.updateResource(pb.ResourceModify.decode(payload).Res, true);
    }

    function rpc_KickOut(_:Net.RemoteProxy, __:Uint8Array) {
        Net.SConn.inst.close();
        Core.TipsUtils.alert(Core.StringUtils.TEXT(60193), async function() {
            await Net.SConn.inst.connectServer();
            Core.EventCenter.inst.dispatchEventWith(Core.Event.ReLoginEv);
        }, this, Core.StringUtils.TEXT(60038));
    }

    function rpc_UpdateVersion(_:Net.RemoteProxy, payload:Uint8Array) {
        let version = pb.Version.decode(payload);
        let onPlayerIdle = function() {
            Core.EventCenter.inst.removeEventListener(GameEvent.BattleEndEv, onPlayerIdle, this);
            Core.EventCenter.inst.removeEventListener(GameEvent.MatchStopEv, onPlayerIdle, this);
            HomeMgr.inst.checkVersion(version);
        }

        if (Battle.BattleMgr.inst.battle) {
            Core.EventCenter.inst.once(GameEvent.BattleEndEv, onPlayerIdle, this);
        } else if (Pvp.PvpMgr.inst.isMatching) {
            Core.EventCenter.inst.once(GameEvent.MatchStopEv, onPlayerIdle, this);
            Core.EventCenter.inst.once(GameEvent.BattleEndEv, onPlayerIdle, this);
        } else {
            onPlayerIdle();
        }
    }

    function rpc_ClearIOSShare(_:Net.RemoteProxy, payload:Uint8Array) {
        Core.EventCenter.inst.dispatchEventWith(GameEvent.ShareIOSOK, false, false);
        Player.inst.isIOSShared = false;
    }

    function rpc_TellMe(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.TellMe.decode(payload);
        let msg:string;
        if (arg.Text > 0) {
            msg = Core.StringUtils.TEXT(arg.Text);
        } else {
            msg = arg.Msg;
        }
        Core.TipsUtils.showTipsFromCenter(msg);
    }
    
    function rpc_AddVip(_:Net.RemoteProxy, payload:Uint8Array) {        
        let arg = pb.VipRemainTime.decode(payload);
        Player.inst.vipTime = arg.RemainTime;
    }

    function rpc_OutVip(_:Net.RemoteProxy, payload:Uint8Array) {        
        Player.inst.vipTime = 0;
        // Player.inst.isVip = false;
    }

    function rpc_AddMiniVip(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.MinVipRemainTime.decode(payload);
        Player.inst.miniVipTime = arg.RemainTime;
    }

    function rpc_OutMiniVip(_:Net.RemoteProxy, payload:Uint8Array) {
        Player.inst.miniVipTime = 0;
    }

    function rpc_AddNewbieVip(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.VipRemainTime.decode(payload);
        Player.inst.hasGetVipExperience = true;
        Player.inst.vipTime = arg.RemainTime;
    }

    function rpc_OutNewbieVip(_:Net.RemoteProxy, payload:Uint8Array) {
        Core.TipsUtils.confirm(Core.StringUtils.TEXT(70368), () => {
            Core.ViewManager.inst.open(ViewName.shopView);
        });
    }

    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_SYNC_RESOURCE, rpc_SyncResource);
        Net.registerRpcHandler(pb.MessageID.S2C_KICK_OUT, rpc_KickOut);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_VERSION, rpc_UpdateVersion);
        Net.registerRpcHandler(pb.MessageID.S2C_ON_CROSS_DAY, rpc_ClearIOSShare);
        Net.registerRpcHandler(pb.MessageID.S2C_TELL_ME, rpc_TellMe);
        Net.registerRpcHandler(pb.MessageID.S2C_ADD_VIP, rpc_AddVip);
        Net.registerRpcHandler(pb.MessageID.S2C_VIP_TIMEOUT, rpc_OutVip);
        Net.registerRpcHandler(pb.MessageID.S2C_ADD_MIN_VIP, rpc_AddMiniVip);
        Net.registerRpcHandler(pb.MessageID.S2C_MIN_VIP_TIMEOUT, rpc_OutMiniVip);
        Net.registerRpcHandler(pb.MessageID.S2C_ADD_NEWBIE_VIP, rpc_AddNewbieVip);
        Net.registerRpcHandler(pb.MessageID.S2C_NEWBIE_VIP_TIMEOUT, rpc_OutNewbieVip);
    }
}