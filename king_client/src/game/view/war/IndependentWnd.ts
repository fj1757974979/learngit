module War {

    export class IndependentPlayerItem extends fairygui.GComponent {

        private _lordHeadCom: Social.HeadCom;
        private _nameText: fairygui.GTextField;
        private _resultCom: fairygui.GComponent;
        protected constructFromXML(xml: any): void {
            this._lordHeadCom = this.getChild("lordHeadCom").asCom as Social.HeadCom;
            this._nameText = this.getChild("nameText").asTextField;
            this._resultCom = this.getChild("result").asCom;
        }

        public async setInfo(playerInfo: pb.ICampaignPlayer) {
            this._lordHeadCom.setAll(playerInfo.HeadImg, playerInfo.HeadFrame);
            this._nameText.text = playerInfo.Name;
            this._resultCom.visible = true;
        }
    }

    export class IndependentWnd extends Core.BaseWindow {

        private _timeText: fairygui.GTextField;
        private _playerList: fairygui.GList;
        private _campNameInput: fairygui.GTextInput;
        private _closeBtn: fairygui.GButton;
        private _confirmBtn: fairygui.GButton;
        private _hintText: fairygui.GTextField;

        private _independentData: pb.AutocephalyInfo;

        public initUI() {
            super.initUI();
            this._timeText = this.contentPane.getChild("treasureTime").asTextField;
            this._playerList = this.contentPane.getChild("playerList").asList;
            this._campNameInput = this.contentPane.getChild("campNameInput").asTextInput;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._confirmBtn =this.contentPane.getChild("confirmBtn").asButton;
            this._hintText = this.contentPane.getChild("emptyHintText").asTextField;

            this._playerList.itemClass = IndependentPlayerItem;
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._independentData = new pb.AutocephalyInfo();
            this._independentData = param[0] as pb.AutocephalyInfo;
            this._refresh();
        }
        private async _refresh() {
            this._playerList.removeChildrenToPool();
            if (this._independentData.CountryName == null || this._independentData.CountryName == "") {
                this._campNameInput.text = "";
            } else {
                this._campNameInput.text = this._independentData.CountryName;
            }
            if (this._independentData.AgreePlayers.length <= 0) {
                this._hintText.visible = true;
            } else {
                this._hintText.visible = false;
                this._independentData.AgreePlayers.forEach((player) => {
                    let com = this._playerList.addItemFromPool().asCom as IndependentPlayerItem;
                    com.setInfo(player);
                })
            }
        }
        private async _onConfirmBtn() {
            let countryName = this._campNameInput.text;
            countryName.trim();
            if (countryName.length > 2 || countryName.length <= 0) {
                return ;
            }
            let str = `确定独立成立势力${countryName}吗？`;
            Core.TipsUtils.confirm(str, () => {
                this._independent(countryName);
            }, null, this);
        }
        private async _independent(countryName: string) {
            let args = {CountryName: countryName};
            let result = await Net.rpcCall(pb.MessageID.C2S_AUTOCEPHALY, pb.AutocephalyArg.encode(args));
            if (result.errcode == 0) {
                this._independentData.CountryName = countryName;
                this._refresh();
            }
        }
        private async _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }

}