module Battle {

    export class Battle {
        private _battleID: Long;
        protected _fighter1: Fighter;
        protected _fighter2: Fighter;
        protected _ownFighter: Fighter;
        private _curBout:number;
        private _curBoutUid: Long;
        // 9宫格牌座
        private _grids: Array<GridObj>;
        // {objId: IBattleObj}
        private _battleObs: Collection.Dictionary<number, IBattleObj>;
        // 延迟到战斗结束才弹的tips
        private _delayTips: Array<string>;
        private _isFirstHand: boolean;
        protected _isFirstPvp: boolean;
        
        constructor(data:any, ..._:any[]) {
            this._battleID = data.DeskId;
            this._isFirstPvp = data.IsFirstPvp;
            this._battleObs = new Collection.Dictionary<number, IBattleObj>();
            this._grids = [];
            this._curBout = 0;
            this._fighter1 = new Fighter(data.Fighter1, this);
            this._fighter2 = new Fighter(data.Fighter2, this);
            for (let i = 0; i < data.Grids.length; i++) {
                let gridData = data.Grids[i];
                let obj = new GridObj(i, gridData, this);
                this._grids.push(obj);
                this.addBattleObj(obj);
            }

            if (this._fighter1.uid == Player.inst.uid) {
                this._ownFighter = this._fighter1;
            } else if (this._fighter2.uid == Player.inst.uid) {
                this._ownFighter = this._fighter2;
            } else {
                this._ownFighter = this._fighter1;
            }
        }

        public get battleID(): Long {
            return this._battleID;
        }

        public get battleType(): BattleType {
            return BattleType.PVP;
        }

        public get fighter1(): Fighter {
            return this._fighter1;
        }

        public get fighter2(): Fighter {
            return this._fighter2;
        }

        public get curBout(): number {
            return this._curBout;
        }

        public get isFirstHand(): boolean {
            return this._isFirstHand;
        }

        public isPvp(): boolean {
            if (this.battleType == BattleType.PVP) {
                return true;
            } else {
                return false;
            }
        }

        public getFighter(uid:Long): Fighter {
            if (this._fighter1.uid == uid) {
                return this._fighter1;
            } else {
                return this._fighter2;
            }
        }

        public getOwnFighter(): Fighter {
            return this._ownFighter;
        }

        public getEnemyFighter(): Fighter {
            if (this._ownFighter.uid != this._fighter1.uid) {
                return this._fighter1;
            } else {
                return this._fighter2;
            }
        }

        public getOtherFighter(uid: Long): Fighter {
            if (uid != this._fighter1.uid) {
                return this._fighter1;
            } else {
                return this._fighter2;
            }
        }

        public addBattleObj(obj:IBattleObj) {
            this._battleObs.setValue(obj.objId, obj);
        }

        public getBattleObj(objId:number): IBattleObj {
            return this._battleObs.getValue(objId);
        }

        public delBattleObj(objId:number) {
            this._battleObs.remove(objId);
        }

        public getEndViewName(): string {
            //return ViewName.pvpBattleEnd;
            return ViewName.pvpNewBattleEnd;
        }
        /**
         * 非教程战斗返回null
         */
        public getGuideBattleID() {
            return null;
        }

        public async boutBeginAni(boutUid:Long) {
            let battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
            let isMyBout = boutUid == this._ownFighter.uid;
            if (this._curBout == 0) {
                await battleView.playOffensiveAni(isMyBout);
            }
            if (this._curBoutUid != boutUid) {
                await battleView.playTurnAni(isMyBout);
            }
        }

        public async boutBegin(boutUid:Long) {
            this._curBout++;
            let lastBoutUid = this._curBoutUid;
            this._curBoutUid = boutUid;
            let battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
            let isMyBout = this.isMyBout();
            if (this._curBout == 1) {
                if (isMyBout) {
                    this._isFirstHand = true;
                }
                Core.EventCenter.inst.dispatchEventWith(GameEvent.BattleBeginEv, false, this.battleType);
            }
            let curFighter = this.getFighter(boutUid);
            await battleView.boutBegin(curFighter);

            if (this.battleType != BattleType.VIDEO && isMyBout && curFighter.getHandCardAmount() <= 0) {
                this.playCard(0, 0);
            }

            if (this._isFirstPvp && this.battleType == BattleType.PVP) {
                await Guide.GuideMgr.inst.onNewbiePvpBattleBoutBegin(this.curBout);
            }
        }

        public async boutEnd() {
            if (this._isFirstPvp && this.battleType == BattleType.PVP) {
                await Guide.GuideMgr.inst.onNewbiePvpBattleBoutEnd(this.curBout);
            }
        }

        public isMyBout(): boolean {
            return this._curBoutUid == this._ownFighter.uid;
        }

        public async playCard(cardObjId:number, gridId:number): Promise<boolean> {
            let targetCard = <FightCard>this.getBattleObj(cardObjId);
            if (targetCard && !Guide.GuideMgr.inst.canPlayCard(targetCard, gridId)) {
                return false;
            }

            let result = await Net.rpcCall(pb.MessageID.C2S_FIGHT_BOUT_CMD, 
                pb.FightBoutCmd.encode({"UseCardObjID":cardObjId, "TargetGridId":gridId})
                , true, false);
            if ( result.errcode != 0 ) {
                if (result.errcode == 100) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60188));
                }
                return false;
            }

            let reply = pb.FightBoutResult.decode(result.payload);
            Core.EventCenter.inst.dispatchEventWith(GameEvent.BattlePlayCardEv, false, {"card":targetCard, "gridIdx":gridId});
            (<BattleView>Core.ViewManager.inst.getView(ViewName.battle)).onPlayBoutActions();
            await BoutActionPlayer.inst.playCard(reply.UseCardObjID, reply.TargetGridId, reply.CardNeedTalk, reply.IsUseCardInFog, 
                reply.IsUseCardPublicEnemy);
            await BoutActionPlayer.inst.playActions(reply.Actions, reply.WinUid as Long);
            await fairygui.GTimers.inst.waitTime(100);
            await this.boutEnd();

            this.readyDone();

            return true;
        }

        public readyDone() {
            Net.rpcPush(pb.MessageID.C2S_FIGHT_BOUT_READY_DONE, null);
        }

        public async restoredDone(curBoutUid:Long, curBout:number) {
            this._curBout = curBout;
            Net.rpcPush(pb.MessageID.C2S_FIGHT_BOUT_READY_DONE, null);
            await this.boutEnd();
            this.boutBegin(curBoutUid);
        }

        public beforeEndBattle(b: boolean) {

        }

        public async endBattle(data:any, isReplay:boolean=false) {
            Guide.GuideMgr.inst.hideGuide();
            Core.EventCenter.inst.addEventListener(Core.Event.CloseViewEvt, this._onBattleEnd, this);
            let p = (<BattleView>Core.ViewManager.inst.getView(ViewName.battle)).endBattle(this, data, isReplay);
            if (this.battleType == BattleType.PVP && !isReplay) {
                let isWin = data.WinUid == this.getOwnFighter().uid;
                if (isWin) {
                    TD.onPvpCompleted(this);
                } else {
                    TD.onPvpFailed(this);
                }
            }
            await p;
            Core.EventCenter.inst.dispatchEventWith(GameEvent.BattleEndEv);
        }

        public getGridById(gridId:number): GridObj {
            if (gridId < 0 || gridId >= this._grids.length) {
                return null;
            }
            return this._grids[gridId];
        }

        /**
         * @param idx  我方手牌左边开始依次1到5，棋盘左上角开始，依次6到14，对手手牌左边开始，依次15到19
         */
        public getCardByIdx(idx:number):FightCard {
            if (idx >= 1 && idx <= 5) {
                return this.getOwnFighter().getHandCardByIdx(idx - 1);
            } else if (idx >= 15 && idx <= 19) {
                return this.getEnemyFighter().getHandCardByIdx(idx - 15);
            } else if (idx >= 6 && idx <= 14) {
                let grid = this.getGridById(idx - 6);
                if (grid) {
                    return grid.inGridCard;
                }
            }
            return null;
        }

        public addDelayTips(tips:string) {
            if (!this._delayTips) {
                this._delayTips = [];
            }
            this._delayTips.push(tips);
        }

        public isEnemyHandOpen(): boolean {
            return false;
        }

        protected _onBattleEnd(evt:egret.Event) {
            if (evt.data != this.getEndViewName()) {
                return;
            }
            Core.EventCenter.inst.removeEventListener(Core.Event.CloseViewEvt, this._onBattleEnd, this);
            if (this._delayTips) {
                for (let i=0; i<this._delayTips.length; i++) {
                    Core.TipsUtils.alert(this._delayTips[i]);
                }
            }
        }
    }

}
