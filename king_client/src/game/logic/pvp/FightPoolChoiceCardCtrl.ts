module Pvp {

    export class FightPoolChoiceCardCtrl implements UI.IChoiceCardCtrl {
        private _fightPool: FightCardPool;

        constructor(fightPool:FightCardPool) {
            this._fightPool = fightPool;
        }

        public getCamps(): Array<Camp> {
            return [this._fightPool.camp, Camp.HEROS];
        }

        public getTitleCamps(): Array<Camp> {
            return [this._fightPool.camp, Camp.HEROS];
        }

        public needDiyCard(): boolean {
            return true;
        }

        public getCardState(cardObj:UI.ICardObj): string {
            if (cardObj.isInCampaignMission) {
                return UI.BaseCardItem.campaignBanState;
            }
            return UI.BaseCardItem.NormalState;
        }

        public getChoiceCard(): Array<UI.ICardObj> {
            return this._fightPool.cards.concat();
        }

        public getMinAmount(): number {
            return 0;
        }

        public getMaxAmount(): number {
            return 5;
        }

        public visableCampaign(): boolean {
            return false;
        }
        
        public needEnergyProgress(): boolean {
            return true;
        }

        public needExpProgress(): boolean {
            return false;
        }

        public async onConfirm(choiceCard: Array<UI.ICardObj>, _:number): Promise<boolean> {
            let choiceCardids = [0, 0, 0, 0, 0];
            this._fightPool.cards = choiceCard;
            for (let i = 0; i < choiceCard.length; i++) {
                if (choiceCard[i]) {
                    choiceCardids[i] = choiceCard[i].cardId;
                }
            }
            let arg = pb.PoolUpdateCard.encode({"PoolId":this._fightPool.id, "Cards":choiceCardids});
            let result = await Net.rpcCall(pb.MessageID.C2S_POOL_UPDATE_CARD, arg);
            if (result.errcode == 0) {
                Core.EventCenter.inst.dispatchEventWith(GameEvent.FightPoolUpdateCardEv, false, this._fightPool);
                return true;
            } else {
                return false;
            }
        }
    }

}