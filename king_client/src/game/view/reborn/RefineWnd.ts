module Reborn {

    export class RefineCardItem extends fairygui.GButton {

        private _priceText: fairygui.GTextField;
        private _cardCom: UI.CardCom;
        private _selectedMask: fairygui.GComponent;

        constructFromXML(xml: any): void {
            this._priceText = this.getChild("price").asTextField;
            this._selectedMask = this.getChild("selectedMask").asCom;
            this._cardCom = this.getChild("card").asCom as UI.CardCom;
        }

        public setCard(card: CardPool.Card) {
            this._priceText.text = card.amount.toString();
            this._cardCom.cardObj = card;
            this._cardCom.setCardImg();
            this._cardCom.setName();
        }
    }
    
    export class RefineWnd extends Core.BaseWindow {

        private _cardList: fairygui.GList;

        private _allBtn: fairygui.GButton;
        private _confirmBtn: fairygui.GButton;
        private _btnClose: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.adjust(this.contentPane.getChild("bg"),Core.AdjustType.EXCEPT_MARGIN);

            this._cardList = this.contentPane.getChild("cardList").asList;
            this._allBtn = this.contentPane.getChild("allBtn").asButton;
            this._confirmBtn = this.contentPane.getChild("n35").asButton;

            this._allBtn.addClickListener(this._onAllBtn, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
            this._btnClose = this.contentPane.getChild("btnClose").asButton;
            this._btnClose.addClickListener(this._onClose, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._refresh();
        }

        private _refresh() {
            this._cardList.removeChildrenToPool();
            let indexs = RebornMgr.inst.refineCardIndexs;
            let cards = RebornMgr.inst.refineCards;

			indexs.forEach(_index => {
                let card = cards.getValue(_index);
                let item = this._cardList.addItemFromPool() as RefineCardItem;
				item.setCard(card.card);
			});
        }

        private async _onConfirmBtn() {
            let selects = this._cardList.getSelection();
            if (selects.length <= 0) {
                Core.TipsUtils.showTipsFromCenter("");
                return ;
            }
        }

        private async _onAllBtn() {
            this._cardList.selectAll();
        }

        private _onClose() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            super.close(...param);
        }
        
    }
}