module Battle {

    export class GuideBattle extends Battle {
        private _guideBattleID: number;
        private _canAttactGuide: boolean;

        constructor(data:any, ...param:any[]) {
            super(data);
            this._guideBattleID = Player.inst.getResource(ResType.T_GUIDE_PRO) + 1;
            this._canAttactGuide = true;
        }
        
        public get battleType(): BattleType {
            return BattleType.Guide;
        }

        public getEndViewName(): string {
            return ViewName.pvpNewBattleEnd;
        }

        public async boutBegin(boutUid:Long) {
            await super.boutBegin(boutUid);
            await Guide.GuideMgr.inst.onGuideBattleBoutBegin(this._guideBattleID, this.curBout);
        }

        public async boutEnd() {
            await Guide.GuideMgr.inst.onGuideBattleBoutEnd(this._guideBattleID, this.curBout);
        }

        public canAttactGuide(): boolean {
            let can = this._guideBattleID == 1 && this._canAttactGuide;
            if (can) {
                this._canAttactGuide = false;
            }
            return can;
        }

        public async restoredDone(curBoutUid:Long, curBout:number) {
            this._canAttactGuide = false;
            await super.restoredDone(curBoutUid, curBout);
        }

        public beforeEndBattle(isWin: boolean) {
            Guide.GuideMgr.inst.saveGuideBattleSign(!isWin);
        }

        public getGuideBattleID() {
            return this._guideBattleID;
        }
    }

}