module Season {

    export class SeasonMgr {
        private static _inst: SeasonMgr;
        private _seasonPvpLimitTime: number;
        private _isSeasonPvpChooseCard: boolean;
        private _winDiff: number;

        constructor() {
            Core.EventCenter.inst.addEventListener(GameEvent.SeasonBegin, this._seasonBegin, this);
        }

        public static get inst(): SeasonMgr {
            if (!SeasonMgr._inst) {
                SeasonMgr._inst = new SeasonMgr();
            }
            return SeasonMgr._inst;
        }
        public updateSeasonInfo(time: number, isChooseCard: boolean) {
            this._seasonPvpLimitTime = time;
            // this._seasonPvpLimitTime = 1000000;
            this._isSeasonPvpChooseCard = isChooseCard;
            this._timerStart();
        }

        public set seaonTime(time: number) {
            this._seasonPvpLimitTime = time;
        }
        public get isSeasonPvpChooseCard() {
            return this._isSeasonPvpChooseCard;
        }
        public set isSeasonPvpChooseCard(data: boolean) {
            this._isSeasonPvpChooseCard = data;
        }

        public get isSeason(): boolean {
            let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
            let pvpTeam = Pvp.Config.inst.getPvpTeam(pvpLevel);
            if (pvpTeam >= Data.season_config.get(1).team) {
                return this._seasonPvpLimitTime > 0;
            } else {
                return false;
            }
        }
        private _timerStart() {
            this._timerStop();
            let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
            let pvpTeam = Pvp.Config.inst.getPvpTeam(pvpLevel);
            if (pvpTeam >= 6) {
                fairygui.GTimers.inst.add(1000, this._seasonPvpLimitTime, this._updateTime, this);
            }
        }
        private _updateTime() {
            this._seasonPvpLimitTime -= 1;
            if (this._seasonPvpLimitTime <= 0) {
                //赛季结束
                Core.EventCenter.inst.dispatchEventWith(GameEvent.SeasonEnd);
                this._timerStop();
                return ;
            }
            Core.EventCenter.inst.dispatchEventWith(GameEvent.UpdateSeasonTime, false, this._seasonPvpLimitTime);
        }
        private _timerStop() {
            fairygui.GTimers.inst.remove(this._updateTime, this);
        }
        private _seasonBegin(evt: egret.Event) {
            this._seasonPvpLimitTime = evt.data;
            this._timerStart();            
        }

        public async showRankHand() {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_SEASON_HAND_CARD, null);
            if (result.errcode == 0) {
                let reply = pb.FetchSeasonHandCardReply.decode(result.payload);
                Core.ViewManager.inst.open(ViewName.rankSeasonHandCard, reply);
            }
        }

        public async showRankWnd() {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_SEASON_PVP_INFO, null);
            if (result.errcode == 0) {
                let reply = pb.SeasonPvpInfo.decode(result.payload);
                Core.ViewManager.inst.open(ViewName.rankSeason, reply);
            }
        }
    }
}