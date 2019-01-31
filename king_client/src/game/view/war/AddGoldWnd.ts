module War {

    export class AddGoldWnd extends Core.BaseWindow {

        private _goldCom: CityInfoCom;
        private _goldInput: fairygui.GTextField;
        private _goldMaxText: fairygui.GTextField;
        private _confirmBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;
        private _recordBtn: fairygui.GButton;
        private _goldCnt: fairygui.GSlider;

        private _city: City;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;
            this._goldCom = this.contentPane.getChild("jinbi").asCom as CityInfoCom;
            this._goldInput = this.contentPane.getChild("goldInput").asTextField;
            this._goldMaxText = this.contentPane.getChild("goldMaxCnt").asTextField;
            this._confirmBtn =this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._recordBtn = this.contentPane.getChild("recordBtn").asButton;
            this._goldCnt = this.contentPane.getChild("goldCnt").asSlider;
            this._goldCnt.getChild("title").visible = false;

            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._confirmBtn.addClickListener(this._onConfirm, this);
            this._recordBtn.addClickListener(this._onRecordBtn, this);
            this._goldCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._goldInputChange, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._city = param[0];

            this._refreshView();
        }
        private async _refreshView() {
            this._goldCom.setInfo(WarResType.Gold, this._city.gold);
            this._goldMaxText.text = `${Player.inst.getResource(ResType.T_GOLD)}`;
            this._goldInput.text = "";
            this._goldCnt.value = 0;
            if (Player.inst.getResource(ResType.T_GOLD) == 0){
                this._goldCnt.grayed = true;
                this._goldCnt.touchable = false;
            } else {
                this._goldCnt.grayed = false;
                this._goldCnt.touchable = true;
                this._goldCnt.max = Player.inst.getResource(ResType.T_GOLD);
            }
            this._setConfirmBtn(false);
            this._goldInputChange();
        }
        private async _goldInputChange() {
            this._goldInput.text = `${this._goldCnt.value}`;
            this._goldCom.setInfo(WarResType.Gold, this._city.gold + this._goldCnt.value);
            this._goldMaxText.text = `${Player.inst.getResource(ResType.T_GOLD) - this._goldCnt.value}`;
            if (this._goldCnt.value == 0) {
                this._setConfirmBtn(false);
            } else {
                this._setConfirmBtn(true);
            }   
        }
        private async _setConfirmBtn(bool: boolean) {
            this._confirmBtn.touchable = bool;
            this._confirmBtn.grayed =!bool;
        }

        private async _onConfirm() {
            let gold = this._goldInput.text;
            Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70218), gold), this._onConfirmBtn, null, this);
        }
        
        private async _onConfirmBtn() {
            let args = {CityID: this._city.cityID, Gold: parseInt(this._goldInput.text)};
            let result = await Net.rpcCall(pb.MessageID.C2S_CITY_CAPITAL_INJECTION, pb.CityCapitalInjectionArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CityCapitalInjectionReply.decode(result.payload);
                this._city.gold = reply.CurGold;
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70219), this._goldInput.text));
                this._refreshView();
            }
        }
        private async _onRecordBtn() {
            let args = {CityID: this._city.cityID, Page: 0};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CITY_CAPITAL_INJECTION_HISTORY, pb.FetchCityCapitalInjectionArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CityCapitalInjectionHistory.decode(result.payload);
                Core.ViewManager.inst.open(ViewName.addGoldRecordPanel, this._city.cityID, reply);
                
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