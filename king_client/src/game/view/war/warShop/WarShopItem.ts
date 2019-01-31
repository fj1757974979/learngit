module War {
    export class WarShopItem extends fairygui.GComponent {

        private _warShopType: WarShopType;
        private _warItemData: any;

        private _itemCtr: fairygui.Controller;
        private _maskCtr: fairygui.Controller;

        private _cardCom: UI.CardCom;
        private _equipCom: fairygui.GComponent;
        private _resCom: fairygui.GComponent;
        private _skinCom: fairygui.GComponent;

        private _price: fairygui.GTextField;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._itemCtr = this.getController("c1");
            this._maskCtr = this.getController("c2");
            this._price = this.getChild("price").asTextField;

            this._cardCom = this.getChild("card").asCom as UI.CardCom;
            this._equipCom = this.getChild("equip").asCom;
            this._resCom = this.getChild("gold").asCom;
            this._skinCom = this.getChild("skin").asCom;
            this.addClickListener(this._onBox, this);
        }

        public async setType(type: WarShopType, data: any) {
            this._warShopType = type;
            this._warItemData = data;
            this._itemCtr.selectedIndex = this._warShopType;
            this._refresh();
            
        }
        private async _refresh() {
            this._price.text = this._warItemData.fightPrice.toString();
            if (MyWarPlayer.inst.contribution >= this._warItemData.fightPrice) {
                this._price.color = 0xffffff;
            } else {
                this._price.color = 0xff0000;
            }
            if (this._warShopType == WarShopType.card) {
                let poolData = CardPool.CardPoolMgr.inst.getCardData(this._warItemData.cardId, 1);
                let cardobj = new CardPool.Card(poolData);
                this._updateCard(cardobj);
                if (CardPool.CardPoolMgr.inst.getCollectCard(this._warItemData.cardId).amount > 0) {
                    this._maskCtr.selectedIndex = 1;
                } else {
                    this._maskCtr.selectedIndex = 0;
                }
            } else if (this._warShopType == WarShopType.equip) {
                let equipData = Equip.EquipMgr.inst.getEquipData(this._warItemData.equipId);
                this._equipCom.getChild("icon").asLoader.url = equipData.equipIcon;
                this._equipCom.getChild("equipName").asTextField.text = equipData.equipName;
                if (equipData.hasEquip) {
                    this._maskCtr.selectedIndex = 1;
                } else {
                    this._maskCtr.selectedIndex = 0;
                }
            } else if (this._warShopType == WarShopType.skin) {
                let skinData = CardPool.CardSkinMgr.inst.getSkinConf(this._warItemData.skinId);
                Utils.setImageUrlPicture(this._skinCom.getChild("cardImg").asImage, `skin_m_${this._warItemData.skinId}_png`);
                this._skinCom.getChild("nameText").asTextField.text = skinData.name;
                if (CardPool.CardSkinMgr.inst.hasSkin(skinData.general, this._warItemData.skinId)) {
                    this._maskCtr.selectedIndex = 1;
                } else  {
                    this._maskCtr.selectedIndex = 0;
                }

            } else if (this._warShopType == WarShopType.res) {
                this._resCom.getChild("goldCnt").asTextField.text = this._warItemData.cnt.toString();
            }
        }
        private _updateCard(cardObj : CardPool.Card) {
            this._cardCom.cardObj = cardObj;
            this._cardCom.setName();
            this._cardCom.setOwnBackground();
            this._cardCom.setOwnFront();
            this._cardCom.setCardImg();
            this._cardCom.setEquip();
        }

        private _onBox() {
            if (this._warShopType == WarShopType.card) {
                Core.ViewManager.inst.open(ViewName.featCardInfo, this._cardCom.cardObj, null, CardPool.BuyType.War, this._warItemData);
            } else if (this._warShopType == WarShopType.equip) {
                Core.ViewManager.inst.open(ViewName.rebornEquipInfo, this._warItemData.equipId, CardPool.BuyType.War, this._warItemData);
            } else if (this._warShopType == WarShopType.res) {
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70371), this._warItemData.cnt), this._onBuy, null, this);
            } else if (this._warShopType == WarShopType.skin) {
                Core.ViewManager.inst.open(ViewName.buySkinInfo, this._warItemData.skinId, CardPool.BuyType.War, this._warItemData);
            }
        }
        private async _onBuy() {
            if (War.MyWarPlayer.inst.contribution < this._warItemData.fightPrice) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70370));
                return;
            }
            let ok = War.WarMgr.inst.buyGoods(this._warItemData.type, this._warItemData.__id__);
            if (ok) {
                // Core.ViewManager.inst.closeView(this);
                let getRewardData = new Pvp.GetRewardData();
                getRewardData.gold = this._warItemData.cnt;
                Core.ViewManager.inst.open(ViewName.getRewardWnd, getRewardData);
            }
        }
    }
}