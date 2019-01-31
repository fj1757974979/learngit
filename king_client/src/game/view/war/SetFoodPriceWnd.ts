module War {

    export class SetFoodPriceWnd extends Core.BaseWindow {

        private _forageCom: CityInfoCom;
        private _goldInput: fairygui.GTextInput;
        private _nowPrice: fairygui.GTextField;
        private _confirmBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;

        private _city: City;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;
            this._forageCom = this.contentPane.getChild("liangcao").asCom as CityInfoCom;
            this._goldInput = this.contentPane.getChild("goldInput").asTextInput;
            this._nowPrice = this.contentPane.getChild("nowPrice").asTextField;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;

            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._goldInput.addEventListener(fairygui.ItemEvent.FOCUS_OUT, this._goldInputChange, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._city = param[0];
            this._refresh();
        }
        private _refresh() {
            this._city = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
            this._forageCom.setInfo(WarResType.Forage, this._city.forage);
            this._goldInput.text = "1";
            this._nowPrice.text = `之前价格：${this._city.foragePrice.toString()}`;
            this._goldInputChange();

        }
        private async _goldInputChange() {
            let inputStr = this._goldInput.text;
            let goldInput = Utils.str2num(inputStr);
            if (!goldInput || goldInput <= 0) {
                this._goldInput.text = "1";
            }
            // this._countGold();
        }
        private async _onConfirmBtn() {
            let newPriceStr = parseInt(this._goldInput.text);
            
            let ok = await WarMgr.inst.setForagePrice(newPriceStr);
            if (ok) {
                Core.ViewManager.inst.closeView(this);
            }
        }
        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}