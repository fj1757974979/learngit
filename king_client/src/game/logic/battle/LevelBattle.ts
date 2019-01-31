module Battle {

    export class LevelBattle extends Battle implements UI.IChoiceCardCtrl {
        private _needChoiceCardNum: number;
        // {cardId: ICardObj}
        private _choiceCardPool: Collection.Dictionary<number, FightCard>;
        private _choiceCards: Array<UI.ICardObj>;
        private _initHandCards: Array<FightCard>;
        private _levelId: number;
        private _isBeginFight: boolean;

        constructor(data:any, ...param:any[]) {
            super(data.Desk, ...param);
            this._isBeginFight = false;
            this._levelId = param[0];
            this._needChoiceCardNum = data.NeedChooseNum;
            if (data.ChoiceCards) {
                this._choiceCardPool = new Collection.Dictionary<number, FightCard>();
                this._choiceCards = [null, null, null, null, null];
                let ownFighter = this.getOwnFighter();
                data.ChoiceCards.forEach(cardData => {
                    let card = new FightCard(cardData, ownFighter);
                    this.addBattleObj(card);
                    this._choiceCardPool.setValue(card.cardId, card);
                })
                this._initHandCards = ownFighter.handCard.concat();
            }
        }

        public get levelName():string {
            return Level.LevelMgr.inst.getLevel(this._levelId).name;
        }

        public get battleType(): BattleType {
            return BattleType.LEVEL;
        }

        public get isBeginFight(): boolean {
            return this._isBeginFight;
        }
        public set isBeginFight(begin:boolean) {
            this._isBeginFight = begin;
        }

        public async levelBattleReadyDone() {
            let choicegcardIds: Array<number> = [];
            if (this._choiceCards) {
                this._choiceCards.forEach(card => {
                    if (card) {
                        choicegcardIds.push(card.gcardId);
                    }
                })
            }

            if (choicegcardIds.length < this._needChoiceCardNum) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(60214), this._needChoiceCardNum));
                return false;
            }

            let result = await Net.rpcCall(pb.MessageID.C2S_LEVEL_READY_DONE, 
                pb.LevelChooseCard.encode({"Cards":choicegcardIds}));
            if (result.errcode == 0) {
                this._isBeginFight = true;
                return true;
            }
            return false;
        }

        public getEndViewName(): string {
            //return ViewName.levelBattleEnd;
            return ViewName.levelNewBattleEnd;
        }

        public readyDone() {
            if (this._isBeginFight) {
                super.readyDone();
            }
        }

        public async boutBegin(boutUid:Long) {
            await super.boutBegin(boutUid);
            Guide.GuideMgr.inst.onLevelBattleBoutBegin(this._levelId, this.curBout);
        }

        public async boutEnd() {
            await Guide.GuideMgr.inst.onLevelBattleBoutEnd(this._levelId, this.curBout);
        }

        public async endBattle(data:any) {
            let p = super.endBattle(data);
            let isWin = data.WinUid == this.getOwnFighter().uid;
            if (isWin) {
                TD.onLevelCompleted(this._levelId);
            } else {
                TD.onLevelFailed(this._levelId);
            }
            await p;
        }

        public isEnemyHandOpen(): boolean {
            return true;
        }

        // implements UI.IChoiceCardCtrl begin -------------
        public getCamps(): Array<Camp> {
            return [Camp.WEI, Camp.SHU, Camp.WU, Camp.HEROS];
        }

        public getTitleCamps(): Array<Camp> {
            let levelData = Data.level.get(this._levelId);
            if (!levelData) {
                return [Camp.WEI, Camp.SHU, Camp.WU, Camp.HEROS];
            }
            if (levelData.nation.length <= 0) {
                return [Camp.WEI, Camp.SHU, Camp.WU, Camp.HEROS];
            }
            return levelData.nation;
        }

        public getCardState(cardObj:UI.ICardObj): string {
            if (!this._choiceCardPool.containsKey(cardObj.cardId)) {
                return UI.BaseCardItem.ForbidState;
            } else if (cardObj.isInCampaignMission) {
                return UI.BaseCardItem.campaignBanState;
            } else {
                return UI.BaseCardItem.NormalState;
            }
        }

        public getChoiceCard(): Array<UI.ICardObj> {
            return this._choiceCards.concat();
        }

        public getMaxAmount(): number {
            return this._needChoiceCardNum;
        }

        public async onConfirm(choiceCard: Array<UI.ICardObj>, _:number) {
            this._choiceCards = choiceCard;
            let newHandCards = this._initHandCards.concat();
            let idx = 0;
            for (let i=0; i<this._needChoiceCardNum; i++) {
                if (this._choiceCards[i]) {
                    newHandCards[newHandCards.length - this._needChoiceCardNum + idx] = this._choiceCardPool.getValue(this._choiceCards[i].cardId);
                    idx++;
                }
            }

            let ownFighter = this.getOwnFighter();
            ownFighter.replaceHandCard(newHandCards);
            if (ownFighter.getHandCardAmount() >= 5) {
                (<BattleView>Core.ViewManager.inst.getView(ViewName.battle)).visibleBeginBtn(true,false);
            }
            return true;
        }

        public needDiyCard(): boolean {
            return false;
        }

        public getMinAmount(): number {
            return 0;
        }

        public visableCampaign(): boolean {
            return false;
        }

        public needEnergyProgress(): boolean {
            return false;
        }

        public needExpProgress(): boolean {
            return false;
        }
        // implements UI.IChoiceCardCtrl end -------------

        public updateFightCard(cardData:any) {
            let fighter = this.getOwnFighter();
            let card = new FightCard(cardData, fighter);
            let oldCard = this._choiceCardPool.getValue(card.cardId);
            if (oldCard) {
                this.addBattleObj(card);
                this._choiceCardPool.setValue(card.cardId, card);
                fighter.updateHandCard(oldCard, card);
            }
        }
    }

    export class LevelHelpBattle extends LevelBattle implements UI.IChoiceCardCtrl {

        public get battleType(): BattleType {
            return BattleType.LevelHelp;
        }
    }

}