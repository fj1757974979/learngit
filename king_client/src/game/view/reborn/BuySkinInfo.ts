module Reborn {

    export class BuySkinInfo extends Core.BaseWindow {

        private _skinCom: CardPool.SkinItemCom;
        private _buyBtn: fairygui.GButton;
        
        private _key: number;
        private _type: CardPool.BuyType;
        private _buyData: any;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this.adjust(this.contentPane.getChild("closeBg"));
            this.contentPane.getChild("closeBg").addClickListener(this._onCloseBtn, this);
            this._skinCom = this.contentPane.getChild("skin").asCom as CardPool.SkinItemCom;
            this._buyBtn = this.contentPane.getChild("btnBuy").asButton;
            this._buyBtn.addClickListener(this._onBuyBtn, this);
        }

        public async open(...param: any[]) {
            super.open(...param);

            this._key = param[0];
            this._type = param[1];
            this._buyData = param[2];
            this._skinCom.setCur(false);
            this._skinCom.setUsing(false);
            if (this._type == CardPool.BuyType.Reborn) {
                
            } else if (this._type == CardPool.BuyType.War) {
                let skinData = CardPool.CardSkinMgr.inst.getSkinConf(this._buyData.skinId);
                this._skinCom.setSkin(this._buyData.skinId, skinData.general, skinData.name, skinData.resource);
                this._buyBtn.title = this._buyData.fightPrice.toString();
                this._buyBtn.getChild("n11").asLoader.url = "war_fightIcon_png";
                if (CardPool.CardSkinMgr.inst.hasSkin(skinData.general, this._buyData.skinId)) {
                    this._buyBtn.visible = false;
                } else  {
                     this._buyBtn.visible = true;
                }
                if (War.MyWarPlayer.inst.contribution >= this._buyData.fightPrice) {
                    this._buyBtn.getChild("title").asTextField.color = 0xffffff;
                } else {
                    this._buyBtn.getChild("title").asTextField.color = 0xff0000;
                }
            }
            
        }
        private async _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        private async _onBuyBtn() {
            if (this._type == CardPool.BuyType.Reborn) {
                // Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70189), this._nameText.text), () => {
                //     RebornMgr.inst.onBuyEquip();
                // }, null, this);
            } else if (this._type == CardPool.BuyType.War) {
                let skinData = CardPool.CardSkinMgr.inst.getSkinConf(this._buyData.skinId);
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70369), skinData.name), () => {
                    this._onBuy();
                }, null, this);
            }
        }
        private async _onBuy() {
            if (War.MyWarPlayer.inst.contribution < this._buyData.fightPrice) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70370));
                return;
            }
            let ok = War.WarMgr.inst.buyGoods(this._buyData.type, this._buyData.__id__);
            if (ok) {
                let getRewardData = new Pvp.GetRewardData();
                getRewardData.addSkins(this._buyData.skinId);
                Core.ViewManager.inst.open(ViewName.getRewardWnd, getRewardData);
                Core.ViewManager.inst.closeView(this);
            }
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}