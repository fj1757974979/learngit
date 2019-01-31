module CardPool {

    export enum BuyType {
        Reborn = 0,
        War = 1,
    }

    export class BuyCardInfoWnd extends CardInfoWnd {

        private _buyType: BuyType;
        private _buyData: any;
        private _buyBtn: fairygui.GButton;

        public initUI() {
            super.initUI();

            this._buyBtn = this.contentPane.getChild("btnBuy").asButton;

            this._card.addClickListener(this._onCard, this);
            this._buyBtn.addClickListener(this._onBuyBtn, this);
        }

        private _updateBuyBtn() {
            if (CardPoolMgr.inst.getCollectCard(this._cardObj.cardId).amount > 0) {
                this._buyBtn.visible = false;
            } else {
                this._buyBtn.visible = true;
            }
            if (this._buyType == BuyType.Reborn) {
                this._buyBtn.getChild("n11").asLoader.url = "common_honorIcon_png";
                let honor = Data.sold_general.get(Reborn.RebornMgr.inst.cardKey).honorPrice;
                this._buyBtn.title = honor.toString();
                if (Player.inst.hasEnoughFeat(honor)) {
                    this._buyBtn.getChild("title").asTextField.color = 0xffffff;
                } else {
                    this._buyBtn.getChild("title").asTextField.color = 0xff0000;
                }
            } else if (this._buyType == BuyType.War) {
                this._buyBtn.getChild("n11").asLoader.url = "war_fightIcon_png";
                this._buyBtn.title = this._buyData.fightPrice.toString();
                if (War.MyWarPlayer.inst.contribution >= this._buyData.fightPrice) {
                    this._buyBtn.getChild("title").asTextField.color = 0xffffff;
                } else {
                    this._buyBtn.getChild("title").asTextField.color = 0xff0000;
                }
            }
        }

        private _onBuyBtn() {
            Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70369), this._cardObj.name), this._onBuy, null, this);
        }

        private async _onBuy() {
            if (this._buyType == BuyType.Reborn) {
                Reborn.RebornMgr.inst.onBuyCard();
            } else if (this._buyType == BuyType.War) {
                if (War.MyWarPlayer.inst.contribution < this._buyData.fightPrice) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70370));
                    return;
                }
                let ok = War.WarMgr.inst.buyGoods(this._buyData.type, this._buyData.__id__);
                if (ok) {
                    let getRewardData = new Pvp.GetRewardData();
                    getRewardData.addCards(this._cardObj.cardId, 1);
                    Core.ViewManager.inst.open(ViewName.getRewardWnd, getRewardData);
                    Core.ViewManager.inst.closeView(this);
                }
            }
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._buyType = param[2];
            this._buyData = param[3];
            this._updateBuyBtn();
        }
        private _onCard() {
            Core.ViewManager.inst.open(ViewName.bigCard, this._cardObj);
            let sound:string = this._cardObj.sound;
            if (sound && sound.length > 0)
                SoundMgr.inst.playSoundAsync(`${sound}_mp3`);
        }
        public async close(...param: any[]) {
            super.close(...param);
        } 
    }
}