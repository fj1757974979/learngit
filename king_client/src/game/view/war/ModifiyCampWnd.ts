module War {

    export class ModifyCampFlagWnd extends Core.BaseWindow {

        private _flagList: fairygui.GList;
        private _inputName: fairygui.GTextInput;
        private _campName: fairygui.GTextField;
        private _campFlag: fairygui.GLoader;
        private _closeBtn: fairygui.GButton;
        private _confirmBtn: fairygui.GButton;
        
        private _country: Country;
        private _curFlagCom: CampIconCom;
        private _curFlagUrl: string;
        private _curFlagIndex: number;
        private _curName: string;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._flagList = this.contentPane.getChild("headList").asList;
            // this._inputName = this.contentPane.getChild("searchInput").asTextInput;
            this._campName = this.contentPane.getChild("campName").asTextField;
            this._campFlag = this.contentPane.getChild("campFlag").asLoader;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;

            // this._inputName.addEventListener(fairygui.ItemEvent.CHANGE, this._changeName, this);
            // this._inputName.addEventListener(fairygui.ItemEvent.FOCUS_OUT, this._changeNameEnd, this);
            this._flagList.addEventListener(fairygui.ItemEvent.CLICK, this._changeFlag, this);
            this._closeBtn.addClickListener(this._onClose, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
        }
        private _changeFlag(evt: fairygui.ItemEvent) {
            let falgCom = evt.itemObject as CampIconCom;
            let index = this._flagList.getChildIndex(evt.itemObject);
            this._curFlagUrl = `war_flag${index}_png`;
            this._campFlag.url = this._curFlagUrl;
            this._curFlagIndex = index;
            this._curFlagCom.setChoose(false);

            falgCom.setCampFlag(this._curFlagUrl);
            falgCom.setCampName(this._curName);
            falgCom.setChoose(true);
            this._curFlagCom = falgCom;
            this._checkChange();
            
        }
        private _changeName() {
            // let name = this._inputName.text;
            //  this._inputName.text = this.autoAddEllipsis(name, 2);
            
        }
        private autoAddEllipsis(str: string, len: number) {
            let _ret = this.cutString(str, len); 
            let _cutStringn = _ret; 
            return _cutStringn;
        }
        private cutString(pStr: string, pLen: number) { 
            // 原字符串长度 
            let _strLen = pStr.length; 
            let _cutString; 
            let _lenCount = 0; 
            var bytesCount = 0;

            for (let i = 0; i < _strLen; i++) {
                var c = pStr.charCodeAt(i);
                if ((c >= 0x0001 && c <= 0x007e) || (0xff60<=c && c<=0xff9f)) {
                    bytesCount += 1;
                } else {
                    bytesCount += 2;
                }
                if (bytesCount > 2) {
                    _cutString = pStr.substr(0, i);
                    return _cutString;
                } else if (bytesCount == 2) {
                    _cutString = pStr.substr(0, i + 1);
                    return _cutString;
                }
            }
            return pStr; 
        } 

        private _changeNameEnd() {
            // let name = this._inputName.text.trim();
            // name = this.autoAddEllipsis(name, 2);
            // this._inputName.text = name;
            // this._curName = name;
            // this._campName.text = this._curName;
            // this._curFlagCom.setCampName(this._curName);
            // this._checkChange();
        }
        private _checkChange() {
            if (this._curName == this._country.countryName && this._curFlagUrl == this._country.countryFlag) {
                this._setConfirmBtn(false);
            } else if (this._curName.trim() == "") {
                this._setConfirmBtn(false);
            } else {
                this._setConfirmBtn(true);
            }
        }
        private _setConfirmBtn(bool: boolean) {
            this._confirmBtn.touchable = bool;
            this._confirmBtn.grayed = !bool;
        }
        private _onClose() {
            Core.ViewManager.inst.closeView(this);
        }
        private async _onConfirmBtn() {
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(70267), this._confirm, null, this);
        }
        private async _confirm() {
            let args = {Flag: this._curFlagIndex.toString()};
            let result = await Net.rpcCall(pb.MessageID.C2S_COUNTRY_MODIFY_FLAG, pb.CountryModifyFlagArg.encode(args));
            if (result.errcode == 0) {
                Core.ViewManager.inst.closeView(this);
            }
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._country = param[0];
            this._curName = this._country.countryName;
            this._curFlagUrl = this._country.countryFlag;
            this._curFlagCom = null;
            this._campName.text = this._country.countryName;
            this._campFlag.url = this._country.countryFlag;
            // this._inputName.text = this._curName;
            this._flagList.removeChildrenToPool();
            for(let i = 0; i < 11; i++) {
                let flagCom = this._flagList.addItemFromPool().asCom as CampIconCom;
                let flagUrl = `war_flag${i}_png`;
                flagCom.setCampFlag(flagUrl);
                if (flagUrl == this._curFlagUrl) {
                    flagCom.setCampName(this._curName);
                    flagCom.setChoose(true);
                    this._curFlagCom = flagCom;
                    this._curFlagIndex = i;
                } else {
                    flagCom.setChoose(false);
                }
            }
            // this._changeNameEnd();
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}