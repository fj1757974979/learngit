module Battle {

    export class Fighter implements UI.IHandItemDataProvider {        
        private _objId: number;
        private _uid: Long;
        private _name: string;
        private _camp: Camp;
        private _pvpScore: number;
        private _handCard: Array<FightCard>;
        private _isGuard: boolean;
        private _casterSkill: Array<number>;
        private _initHandCard: Array<FightCard>;
        private _headIcon: string;
        private _frameIcon: string;

        private _handView: Hand;

        constructor(data:pb.Fighter, battle:Battle) {
            this._objId = data.ObjId;
            this._uid = data.Uid as Long;
            this._name = data.Name;
            if (data.NameText > 0) {
                this._name = Core.StringUtils.TEXT(data.NameText);
            }
            this._camp = data.Camp;
            this._pvpScore = data.PvpScore;
            this._headIcon = data.HeadImgUrl;
            this._frameIcon = data.HeadFrame;
            //this._isGuard = data.IsGuard;
            this._handCard = [null, null, null, null, null];
            this._initHandCard = [];
            if (data.Hand) {
                for (let i=0; i<data.Hand.length; i++) {
                    this._handCard[i] = new FightCard(data.Hand[i], this);
                    this._initHandCard.push(this._handCard[i]);
                    battle.addBattleObj(this._handCard[i]);
                }
            }
            this._casterSkill = data.CasterSkills;

            if (!this._headIcon || this._headIcon == "") {
                for (let card of this._handCard) {
                    if (card) {
                        let gcardID = card.gcardId;
                        let data = Data.pool.get(gcardID);
                        if (data) {
                            this._headIcon = `avatar_${data.cardId}_png`;
                            return;
                        }
                    }
                }
            }
        }

        public get handView():Hand {
            return this._handView;
        }
        public set handView(v:Hand) {
            this._handView = v;
        }

        public get uid(): Long {
            return this._uid;
        }

        public get name(): string {
            return this._name;
        }

        public get camp(): Camp {
            return this._camp;
        }

        public get pvpScore(): number {
            return this._pvpScore;
        }

        public get objId(): number {
            return this._objId;
        }

        public get isGuard(): boolean {
            return this._isGuard;
        }

        public get casterSkill(): Array<number> {
            return this._casterSkill;
        }

        public get handCard(): Array<FightCard> {
            return this._handCard;
        }

        public get initHandCard(): Array<FightCard> {
            return this._initHandCard;
        }

        public get headIcon(): string {
            return this._headIcon;
        }
        public get frameIcon(): string {
            if (!this._frameIcon || this._frameIcon == "") {
                this._frameIcon = "1";
            }
            return `headframe_${this._frameIcon}_png`;
        }

        public getHandCardByIdx(idx:number): FightCard {
            if (idx < 0 || idx >= this._handCard.length) {
                return null;
            }
            return this._handCard[idx];
        }

        public providerHandItemData(idx:number): UI.ICardObj {
            return this._handCard[idx];
        }

        public delHandCard(cardObj:FightCard): boolean {
            for (let i=0; i<this._handCard.length; i++) {
                if (this._handCard[i] && this._handCard[i].objId == cardObj.objId) {
                    this._handCard[i] = null;
                    return true;
                }
            }
            return false;
        }

        public kingAddHandCard(cardDatas:Array<any>) {
            let battle = BattleMgr.inst.battle;
            cardDatas.forEach(data => {
                let index = -1;
                let hasShadow = false;
                for (let i=0; i<this._handCard.length; i++) {
                    if (!this._handCard[i]) {
                        index = i;
                    } else if (this._handCard[i].isShadow) {
                        if (this._handCard[i].gcardId == data.Id) {
                            // 优先找被观星的
                            index = i;
                            hasShadow = true;
                            break;
                        } else {
                            if (index < 0) {
                                index = i;
                            }
                        }
                    }
                }

                if (index >= 0) {
                    if (!hasShadow) {
                        this._handCard[index] = new FightCard(data, this);
                    }
                    battle.addBattleObj(this._handCard[index]);
                }
            })
            this._handView.refresh();
        }

        public returnHandCard(cardData:any): number {
            let battle = BattleMgr.inst.battle;
            let index = -1;
            let hasShadow = false;
            for (let i=this._handCard.length - 1; i>=0; i--) {
                if (this._handCard[i] && this._handCard[i].isShadow) {
                    if (index < 0) {
                        index = i;
                        hasShadow = true;
                    }
                } else if (!this._handCard[i]) {
                    // 优先找没被观星的
                    index = i;
                    hasShadow = false;
                    break;
                }
            }

            if (index >= 0) {
                if (hasShadow) {
                    battle.delBattleObj(this._handCard[index].objId);
                }
                this._handCard[index] = new FightCard(cardData, this);
                battle.addBattleObj(this._handCard[index]);
                //this._handView.refresh();
            }
            return index;
        }

        public disHandCard(cardObjIDs:Array<number>) {
            let battle = BattleMgr.inst.battle;
            for (let i = 0; i < this._handCard.length; i++) {
                let card = this._handCard[i];
                if (!card) {
                    continue;
                }

                let isTarget = false;
                for (let objID of cardObjIDs) {
                    if (card.objId == objID) {
                        isTarget = true;
                    }
                }
                
                if (isTarget) {
                    this._handCard[i] = null;
                }
            }

            this._handView.refresh();
        }

        public replaceHandCard(cards:Array<FightCard>) {
            this._handCard = cards;
        }

        public getHandCardAmount(): number {
            let n = 0;
            this._handCard.forEach(card => {
                if (card) {
                    n++;
                }
            });
            return n;
        }

        public updateHandCard(oldCard:FightCard, newCard:FightCard) {
            for (let i=0; i<this._handCard.length; i++) {
                if (this._handCard[i] == oldCard) {
                    this._handCard[i] = newCard;
                    this._handView.refresh();
                    return;
                }
            }
        }

        public handShow(cardDatas:Array<any>) {
            if (cardDatas) {
                /*
                let minAlpha = 1;
                // shadow透明度递减
                for (let i=0; i<this._handCard.length; i++) {
                    if (this._handCard[i] && this._handCard[i].isShadow && this._handCard[i].view.alpha < minAlpha) {
                        minAlpha = this._handCard[i].view.alpha;
                    }
                } 
                */ 

                cardDatas.forEach(data => {
                    // 保持已有shadow（被观星）不变，
                    for (let i=0; i<this._handCard.length; i++) {
                        if (this._handCard[i] && data.Id == this._handCard[i].gcardId) {
                            return;
                        }
                    }

                    for (let i=0; i<this._handCard.length; i++) {
                        // 找空位置
                        if (!this._handCard[i]) {
                            this._handCard[i] = new FightCard(data, this);
                            this._handCard[i].isShadow = true;
                            return;
                        }
                    }
                });
            }
            this._handView.refresh();
            this._handView.show();
        }

        public handCardToBeCopy(card:FightCard) {
            for (let i=0; i<this._handCard.length; i++) {
                if (this._handCard[i] && card.objId == this._handCard[i].objId) {
                    this._handCard[i] = card;
                    this._handView.refresh();
                    return;
                }
            }
        }
    }

}
