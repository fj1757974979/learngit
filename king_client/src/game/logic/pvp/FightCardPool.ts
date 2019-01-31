module Pvp {

    export class FightCardPool implements UI.IHandItemDataProvider {
        private _data:any;
        private _cards:Array<UI.ICardObj>;

        constructor(data:any) {
            this._data = data;
            this._cards = [null, null, null, null, null];
            if (!data.Cards) {
                return
            }

            for (let i=0; i<data.Cards.length; i++) {
                let cardId = data.Cards[i] as number;
                if (cardId <= 0) {
                    continue;
                }
                let collectCard:UI.ICardObj = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
                if (!collectCard) {
                    collectCard = Diy.DiyMgr.inst.getDiyCard(cardId);
                }
                if (!collectCard || collectCard.state != CardPool.CardState.Alive) {
                    continue;
                }
                this._cards[i] = collectCard;
            }
        }

        public get id():number {
            return this._data.PoolId;
        }

        public get camp():Camp {
            return this._data.Camp;
        }

        public get isFight(): boolean {
            return this._data.IsFight;
        }

        public get cards(): Array<UI.ICardObj> {
            return this._cards;
        }

        public set cards(_cards:Array<UI.ICardObj>) {
            this._cards = _cards;
        }

        public providerHandItemData(idx:number): UI.ICardObj {
            return this._cards[idx];
        }

        public getCardAmout(): number {
            let n = 0;
            this._cards.forEach(c => {
                if (c) {
                    n++
                }
            })
            return n;
        }

        public onCardInCampaignMs(cardID:number):boolean {
            for (let i=0; i<this._cards.length; i++) {
                if (this._cards[i] && this._cards[i].cardId == cardID) {
                    this._cards[i] = null;
                    return true;
                }
            }
            return false;
        }

        public isCardInPool(cardID: number): boolean {
            for (let i=0; i<this._cards.length; i++) {
                if (this._cards[i] && this._cards[i].cardId == cardID) {
                    return true;
                }
            }
            return false;
        }
    }

}