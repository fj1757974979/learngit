// TypeScript file
module WXGame {

    function rpc_WXInviteBattleResult(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.WxInviteBattleResult.decode(payload);
        Core.EventCenter.inst.dispatchEventWith(GameEvent.WXInviteBattleResEv, false, arg.Result);
    }

    function rpc_WXTreasureBeHelp(_:Net.RemoteProxy, payload:Uint8Array) {
        // if (!WXGame.WXGameMgr.inst.isExamineVersion) {
        //     return;
        // }
        let arg = pb.TreasureBeHelp.decode(payload);
        let treasure = Treasure.TreasureMgr.inst().curActivatingTreasure;
        // console.log(`rpc_WXTreasureBeHelp ${treasure.id}, ${arg.TreasureID}, ${arg.OpenTimeout}`)
        if (treasure.id == arg.TreasureID) {
            treasure.openTime = Math.max(0, arg.OpenTimeout);
            if (treasure.openTime <= 0) {
                Treasure.TreasureMgr.inst().onTreasureCountDownDone(treasure);
            }
            treasure.fireUpdateEvent();
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60242));
        } else {
            console.log("rpc_WXTreasureBeHelp treasure id wrong, ", treasure.id, arg.TreasureID);
        }
    }

    function rpc_WXDailyTreasureBeHelp(_:Net.RemoteProxy, payload:Uint8Array) {
        if (!WXGame.WXGameMgr.inst.isExamineVersion) {
            return;
        }
        let treasure = Treasure.TreasureMgr.inst().getDailyTreasure();
        treasure.isDouble = true;
        let doubleView = <Treasure.DailyTreasureDoubleWnd>(Core.ViewManager.inst.getView(ViewName.dailyTreasureDouble));
        if (doubleView) {
            doubleView.refresh(treasure);
            Core.TipsUtils.showTipsFromCenter("已得到好友的帮助，每日宝箱奖励翻倍！");
        }
    }

    function rpc_WXBattleLoseBeHelp(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.BattleLoseBeHelp.decode(payload);
        let view = <Battle.PvpNewBattleEnd>(Core.ViewManager.inst.getView(ViewName.pvpNewBattleEnd));
        if (view) {
            view.onBeHelpToPreventLoseStar(arg.AddStar);
            //Core.TipsUtils.showTipsFromCenter("已得到好友的帮助，挽回了这次战斗失利！");
        }
    }

    function rpc_UpdateWXExamineState(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.WxExamineState.decode(payload);
        WXGameMgr.inst.isExamineVersion = arg.IsExamined;
    }

    function rpc_WXShareBeHelped(_:Net.RemoteProxy, payload:Uint8Array) {
        if (!WXGame.WXGameMgr.inst.isExamineVersion) {
            return;
        }
        let arg = pb.WxShareBeHelpArg.decode(payload);
        WXShareMgr.inst.shareBeHelped(arg);
    }

    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_WX_INVITE_BATTLE_RESULT, rpc_WXInviteBattleResult);
        Net.registerRpcHandler(pb.MessageID.S2C_TREASURE_BE_HELP, rpc_WXTreasureBeHelp);
        Net.registerRpcHandler(pb.MessageID.S2C_DAILY_TREASURE_BE_HELP, rpc_WXDailyTreasureBeHelp);
        Net.registerRpcHandler(pb.MessageID.S2C_BATTLE_LOSE_BE_HELP, rpc_WXBattleLoseBeHelp);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_WX_EXAMINE_STATE, rpc_UpdateWXExamineState);
        Net.registerRpcHandler(pb.MessageID.S2C_WX_SHARE_BE_HELP, rpc_WXShareBeHelped);
    }
}