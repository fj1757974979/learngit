module Battle {

    export class VideoBattle extends Battle {

        constructor(data:any, ...param:any[]) {
            super(data, ...param);
            this._isFirstPvp = false;

            if (this._fighter1.uid == Player.inst.uid) {
                this._ownFighter = this._fighter1;
            } else if (this._fighter2.uid == Player.inst.uid) {
                this._ownFighter = this._fighter2;
            } else {
                this._ownFighter = this._fighter1;

                if (param.length > 0) {
                    let shareUid = param[0] as Long;
                    if (this._fighter1.uid == shareUid) {
                        this._ownFighter = this._fighter1;
                    } else if (this._fighter2.uid ==shareUid) {
                        this._ownFighter = this._fighter2;
                    }
                }
            }
        }

        public get battleType(): BattleType {
            return BattleType.VIDEO;
        }

        public getEndViewName(): string {
            return ViewName.levelNewBattleEnd;
        }

        public isEnemyHandOpen(): boolean {
            return true;
        }

        public async endBattle(data:any, isReplay:boolean=false) {
            let p = super.endBattle(data, isReplay);
            Quest.QuestMgr.inst.onWatchVideo();
            await p;
        }
    }

}