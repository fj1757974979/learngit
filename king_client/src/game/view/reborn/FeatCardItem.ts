module Reborn {

    export class FeatCardItem extends fairygui.GButton {

        private _priceText: fairygui.GTextField;
        private _card: UI.CardCom;
        private _buyCtr: fairygui.Controller;
        
        private _key: number;
        private _price: number;


        constructFromXML(xml: any): void {
            this._priceText = this.getChild("price").asTextField;
            this._card = this.getChild("card").asCom as UI.CardCom;
            this._buyCtr = this.getController("c1");
            this.addClickListener(this._onBox, this);
        }

        public setCard(key: number) {
            this._key = key;
            let cardData = Data.sold_general.get(key);
            this._price = cardData.honorPrice;
            this._priceText.text = this._price.toString();
            
            let myCard = CardPool.CardPoolMgr.inst.getCollectCard(cardData.cardId);
            if (myCard.amount == 0) {
                this._buyCtr.selectedIndex = 0;
            } else {
                this._buyCtr.selectedIndex = 1;
            }

            let poolData = CardPool.CardPoolMgr.inst.getCardData(cardData.cardId, 1);
            
            let cardobj = new CardPool.Card(poolData);
            this._card.cardObj = cardobj;
            this._card.setName();
			this._card.setOwnBackground();
			this._card.setOwnFront();
			this._card.setCardImg();
            this._card.setEquip();
        }

        private _onBox() {
            // if (this._buyCtr.selectedIndex == 0) {
                // Core.ViewManager.inst.open(ViewName.featCardInfo, this._card.cardObj, this._key);
                RebornMgr.inst.openCardInfo(this._key, this._card.cardObj);
            // }
        }
    }
}