module Reborn {

    export class RebornEquipInfo extends Core.BaseWindow {

        private _nameText: fairygui.GTextField;
        // private _closeBtn: fairygui.GButton;
        private _buyBtn: fairygui.GButton;
        private _btnBuyFree: fairygui.GButton;
        private _equipIcon: fairygui.GLoader;
        private _equipCom: fairygui.GComponent;
        private _descText: fairygui.GRichTextField;
        
        private _key: number;
        private _type: CardPool.BuyType;
        private _buyData: any;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this.adjust(this.contentPane.getChild("closeBg"));
            this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);
            this._equipCom = this.contentPane.getChild("priv").asCom;
            this._nameText = this._equipCom.getChild("name").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            // this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._buyBtn = this.contentPane.getChild("btnBuy").asButton;
            this._btnBuyFree = this.contentPane.getChild("btnBuyFree").asButton;
            this._equipIcon = this._equipCom.getChild("icon").asLoader;
            this._descText = this._equipCom.getChild("desc").asRichTextField;
            this._descText.addEventListener(egret.TextEvent.LINK, htmlClickCallback, this);
            // this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._buyBtn.addClickListener(this._onBuyBtn, this);
            this._btnBuyFree.addClickListener(this._onBuyBtn, this);
        }

        public async open(...param: any[]) {
            super.open(...param);

            this._key = param[0];
            this._type = param[1];
            this._buyData = param[2];
            if (this._type == CardPool.BuyType.Reborn) {
                let equipData1 = Data.sold_equip.get(this._key);
                let equipData = Equip.EquipMgr.inst.getEquipData(equipData1.equipId);
                this._nameText.text = equipData.equipName;
                this._descText.text = equipData.getSkillDesc();
                this._equipIcon.url = equipData.equipIcon;
                this._buyBtn.visible = false;
                this._btnBuyFree.visible = !Equip.EquipMgr.inst.hasEquip(equipData1.equipId);
                
                if (Player.inst.hasEnoughEquipMoney()) {
                    this._btnBuyFree.getChild("title").asTextField.color = 0xffffff;
                } else {
                    this._btnBuyFree.getChild("title").asTextField.color = 0xff0000;
                }
            } else if (this._type == CardPool.BuyType.War) {
                let equipData = Equip.EquipMgr.inst.getEquipData(this._buyData.equipId);
                this._nameText.text = equipData.equipName;
                this._descText.text = equipData.getSkillDesc();
                this._equipIcon.url = equipData.equipIcon;
                this._btnBuyFree.visible = false;
                this._buyBtn.visible = !Equip.EquipMgr.inst.hasEquip(equipData.equipID);
                this._buyBtn.title = this._buyData.fightPrice.toString();
                this._buyBtn.getChild("n11").asLoader.url = "war_fightIcon_png";
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
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70189), this._nameText.text), () => {
                    RebornMgr.inst.onBuyEquip();
                }, null, this);
            } else if (this._type == CardPool.BuyType.War) {
                Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70369), this._nameText.text), () => {
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
                let equipData = Equip.EquipMgr.inst.getEquipData(this._buyData.equipId);
                getRewardData.addOther(equipData.equipName , equipData.equipIcon);
                Core.ViewManager.inst.open(ViewName.getRewardWnd, getRewardData);
                Core.ViewManager.inst.closeView(this);
            }
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }

    export class EquipItem extends fairygui.GButton {

        private _priceText: fairygui.GTextField;
        private _equipIcon: fairygui.GLoader;
        private _equipName: fairygui.GTextField;
        private _buyCtr: fairygui.Controller;
        
        private _key: number;
        private _fame: number;

        constructFromXML(xml: any): void {
            this._priceText = this.getChild("price").asTextField;
            this._equipIcon = this.getChild("icon").asLoader;
            this._equipName = this.getChild("title").asTextField;
            this._buyCtr = this.getController("c1");

            this.addClickListener(this._onBox, this);
        }

        public setEquip(key: number) {
            this._key = key;
            let equipData1 = Data.sold_equip.get(this._key);
            let equipData = Equip.EquipMgr.inst.getEquipData(equipData1.equipId);
            // this._priceText.text = this._fame.toString();
            this._equipIcon.url = equipData.equipIcon;
            this._equipName.text = equipData.equipName;

            if (equipData.hasEquip) {
                this._buyCtr.selectedIndex = 1;
            } else {
                this._buyCtr.selectedIndex = 0;
            }
        }

        private _onBox() {
            // if (this._buyCtr.selectedIndex == 0) {
                RebornMgr.inst.openEquipInfo(this._key);
            // }
        }
    }
}