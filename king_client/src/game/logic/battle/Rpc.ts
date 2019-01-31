module Battle {

    async function rpc_ReadyFight(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.FightDesk.decode(payload);
        // if (arg.Type == BattleType.Campaign) {
        //     await Core.ViewManager.inst.open(ViewName.enterWarAni);
        // }
        await BattleMgr.inst.beginBattle(arg, arg.Type);
        if (arg.Type == BattleType.Campaign) {
            Core.ViewManager.inst.close(ViewName.warHome);
            // let enterAniView: War.WarEnterAniView = Core.ViewManager.inst.getView(ViewName.enterWarAni) as War.WarEnterAniView;
            // if (enterAniView) {
            //     await enterAniView.dismiss();
            //     Core.ViewManager.inst.close(ViewName.enterWarAni);
            // }
        }
    }

    async function rpc_FightBoutBegin(_:Net.RemoteProxy, payload:Uint8Array) {
        let battle = BattleMgr.inst.battle;
        if (battle) {
            let arg = pb.FightBoutBegin.decode(payload);
            let curFighter = battle.getFighter(arg.BoutUid as Long);
            (<BattleView>Core.ViewManager.inst.getView(ViewName.battle)).beginBoutTimer(curFighter, arg.BoutTimeout);
            await battle.boutBeginAni(arg.BoutUid as Long);
            await BoutActionPlayer.inst.playActions(arg.Actions, null);
            await battle.boutBegin(arg.BoutUid as Long);
        }
    }

    async function rpc_FightBoutResult(_:Net.RemoteProxy, payload:Uint8Array) {
        let battle = BattleMgr.inst.battle;
        if (!battle) {
            return;
        }

        if (battle.battleType != BattleType.PVP) {
            await Guide.GuideMgr.inst.waitGuideComplete();
        }

        let arg = pb.FightBoutResult.decode(payload);
        (<BattleView>Core.ViewManager.inst.getView(ViewName.battle)).onPlayBoutActions();
        await BoutActionPlayer.inst.playCard(arg.UseCardObjID, arg.TargetGridId, arg.CardNeedTalk, arg.IsUseCardInFog, arg.IsUseCardPublicEnemy);
        await BoutActionPlayer.inst.playActions(arg.Actions, arg.WinUid as Long);
        await fairygui.GTimers.inst.waitTime(100);
        await battle.boutEnd();

        battle.readyDone();
    }

    function rpc_FightEnd(_:Net.RemoteProxy, payload:Uint8Array) {
        BattleMgr.inst.endBattle(pb.BattleResult.decode(payload));
    }

    function rpc_CampaignFightEnd(_:Net.RemoteProxy, payload:Uint8Array) {
        //old?
        // BattleMgr.inst.endBattle(pb.CampaignFightResult.decode(payload));
    }

    function rpc_UpdateFightCard(_:Net.RemoteProxy, payload:Uint8Array) {
        let battle = BattleMgr.inst.battle;
        if (battle && battle instanceof LevelBattle) {
            (<LevelBattle>battle).updateFightCard(pb.Card.decode(payload));
        }
    }

    function rpc_SyncEmoji(_:Net.RemoteProxy, payload:Uint8Array) {
        if (!BattleMgr.inst.battle || !BattleMgr.inst.battle.isPvp()) {
            return;
        }

        let reply = pb.SendEmojiArg.decode(payload);
        let battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
        if (battleView.isShow()) {
            battleView.showEnemyEmoji(reply.EmojiID);
        }
    }

    function rpc_ReadyLevelFight(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.LevelBattle.decode(payload);
        BattleMgr.inst.beginBattle(arg, arg.Desk.Type, arg.LevelID);
    }

    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_READY_FIGHT, rpc_ReadyFight);
        Net.registerRpcHandler(pb.MessageID.S2C_FIGHT_BOUT_BEGIN, rpc_FightBoutBegin);
        Net.registerRpcHandler(pb.MessageID.S2C_FIGHT_BOUT_RESULT, rpc_FightBoutResult);
        Net.registerRpcHandler(pb.MessageID.S2C_BATTLE_END, rpc_FightEnd);
        // Net.registerRpcHandler(pb.MessageID.S2C_CAMPAIGN_FIGHT_END, rpc_CampaignFightEnd);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_FIGHT_CARD, rpc_UpdateFightCard);
        Net.registerRpcHandler(pb.MessageID.S2C_SYNC_EMOJI, rpc_SyncEmoji);
        Net.registerRpcHandler(pb.MessageID.S2C_READY_LEVEL_FIGHT, rpc_ReadyLevelFight);
    }
}
