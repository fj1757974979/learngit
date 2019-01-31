module Reborn {

    export class PrivInfo extends Core.BaseWindow {

        private _nameText: fairygui.GTextField;
        // private _closeBtn: fairygui.GButton;
        private _buyBtn: fairygui.GButton;
        private _privIcon: fairygui.GLoader;
        private _privCom: fairygui.GComponent;
        private _descText: fairygui.GTextField;
        
        private _key: number;
        private _fame: number;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this.adjust(this.contentPane.getChild("closeBg"));
            this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);
            this._privCom = this.contentPane.getChild("priv").asCom;
            this._nameText = this._privCom.getChild("name").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            // this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._buyBtn = this.contentPane.getChild("btnBuy").asButton;
            this._privIcon = this._privCom.getChild("icon").asLoader;
            this._descText = this._privCom.getChild("desc").asTextField;

            // this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._buyBtn.addClickListener(this._onBuy, this);
        }

        public async open(...param: any[]) {
            super.open(...param);

            this._key = param[0];
            let privData1 = Data.sold_priv.get(this._key);
            this._fame = privData1.famePrice;

            let privData = Data.priv_config.get(this._key);
            this._nameText.text = privData.name;
            this._descText.text = privData.desc;
            this._privIcon.url = `reborn_${privData.icon}_png`
            this._buyBtn.getChild("title").asTextField.text = this._fame.toString();
            this._buyBtn.visible = !Player.inst.hasPrivilege(this._key);
            if (Player.inst.hasEnoughFame(this._fame)) {
				this._buyBtn.getChild("title").asTextField.color = 0xffffff;
			} else {
				this._buyBtn.getChild("title").asTextField.color = 0xff0000;
			}
        }
        private async _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        private async _onBuy() {
            RebornMgr.inst.onBuyPriv();
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }

    export class PrivItem extends fairygui.GButton {

        private _priceText: fairygui.GTextField;
        private _privIcon: fairygui.GLoader;
        private _privName: fairygui.GTextField;
        private _buyCtr: fairygui.Controller;
        
        private _key: number;
        private _fame: number;

        constructFromXML(xml: any): void {
            this._priceText = this.getChild("price").asTextField;
            this._privIcon = this.getChild("icon").asLoader;
            this._privName = this.getChild("title").asTextField;
            this._buyCtr = this.getController("c1");

            this.addClickListener(this._onBox, this);
        }

        public setPriv(key: number) {
            this._key = key;
            let privData = Data.sold_priv.get(key);
            this._fame = privData.famePrice;
            this._priceText.text = this._fame.toString();
            this._privIcon.url = `reborn_${Data.priv_config.get(key).icon}_png`;
            this._privName.text = Data.priv_config.get(key).name;

            if (Player.inst.hasPrivilege(this._key)) {
                this._buyCtr.selectedIndex = 1;
            } else {
                this._buyCtr.selectedIndex = 0;
            }
        }

        private _onBox() {
            // if (this._buyCtr.selectedIndex == 0) {
                RebornMgr.inst.openPrivInfo(this._key);
            // }
        }
    }
}