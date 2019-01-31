module Battle {

    export class VideoPlayer {
        private static _inst: VideoPlayer;
        private _waitStop: any;
        private _isPlaying: boolean;
        private _recordStartSuccess: boolean;
        private _isAskingRecordScreen: boolean;

        private _data: pb.VideoBattleData;

        public static get inst(): VideoPlayer {
            if (!VideoPlayer._inst) {
                VideoPlayer._inst = new VideoPlayer();
            }
            return VideoPlayer._inst;
        }

        public get isPlaying():boolean {
            return this._isPlaying;
        }

        public get recordStartSuccess():boolean {
            return this._recordStartSuccess;
        }

        public async playById(id: number) {
            let args = { VideoID: id };
            let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_VIDEO, pb.WatchVideoArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.WatchVideoResp.decode(result.payload);
                await this.play(<pb.VideoBattleData>reply.VideoData);
            }
        }

        public async startRecord() {
            if (window.support.record) {
                this._isAskingRecordScreen = true;
                this._recordStartSuccess = false;
                let ret = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(Core.NativeMessage.START_RECORD, Core.NativeMessage.START_RECORD_COMPLETE);
                this._recordStartSuccess = ret.success;
                this._isAskingRecordScreen = false;
                let battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
                if (this._recordStartSuccess) {
                    battleView.setRecordMode(true);
                }
            }
        }
        
        public async play(data: pb.VideoBattleData) {
            if (data.Actions.length < 2) {
                return;
            }
            this._data = data;
            let beginData = pb.FightDesk.decode(data.Actions[0].Data);
            BattleMgr.inst.beginBattle(beginData, BattleType.VIDEO, data.ShareUid);
            if (!BattleMgr.inst.battle) {
                return;
            }
            this._recordStartSuccess = false;
            this.playBattle();
        }        

        public async playBattle() {
            try {
            //Core.MaskUtils.showTransMask();
            this._isPlaying = true;
            
            for (let i = 1; i < this._data.Actions.length; i++) {
                while (this._isAskingRecordScreen) {
                    await fairygui.GTimers.inst.waitTime(30);
                }
                
                if (this._waitStop) {
                    this._isPlaying = false;
                    this._waitStop();
                    this._waitStop = null;
                    return;
                }

                let battle = BattleMgr.inst.battle;
                if (!battle) {
                    this._isPlaying = false;
                    return;
                }

                await fairygui.GTimers.inst.waitTime(400);
                let action = this._data.Actions[i];
                switch (action.ID) {
                    case pb.VideoAction.ActionID.BoutBegin:
                        let actionData1 = pb.FightBoutBegin.decode(action.Data);
                        await battle.boutBeginAni(actionData1.BoutUid as Long);
                        await BoutActionPlayer.inst.playActions(actionData1.Actions, null);
                        await battle.boutBegin(actionData1.BoutUid as Long);
                        await fairygui.GTimers.inst.waitTime(600);
                        break;
                    case pb.VideoAction.ActionID.BoutAction:
                        let actionData2 = pb.FightBoutResult.decode(action.Data);
                        await BoutActionPlayer.inst.playCard(actionData2.UseCardObjID, actionData2.TargetGridId, actionData2.CardNeedTalk,
                            actionData2.IsUseCardInFog, actionData2.IsUseCardPublicEnemy);
                        await BoutActionPlayer.inst.playActions(actionData2.Actions, actionData2.WinUid as Long);
                        break;
                    case pb.VideoAction.ActionID.End:
                        //Core.MaskUtils.hideTransMask();
                        let actionData3 = pb.BattleResult.decode(action.Data);
                        BattleMgr.inst.endBattle(actionData3, true);
                        this._isPlaying = false;
                        this.stopRecord();
                        return;
                    default:
                        break;
                }
            }
            
            } catch (e) {
                console.log(e);
            }
            this._isPlaying = false;
            if (this._waitStop) {
                this._waitStop();
            }
            this._waitStop = null;
            this.stopRecord();
        }

        public stopRecord() {
            if (window.support.record && this._recordStartSuccess) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.STOP_RECORD);
            
                let battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
                if (battleView) {
                    battleView.setRecordMode(false);
                }
            }
        }

        public async stop() {
            if (!this._isPlaying) {
                return;
            }
            await new Promise<void>(reslove => {
                this._waitStop = reslove;
            });

        }
    }

}