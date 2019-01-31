module War {

    export class CityNoticeWnd extends Core.BaseWindow {

        private _noticeText: fairygui.GTextField;
        private _noticeInput: fairygui.GTextInput;
        private _modifyBtn: fairygui.GButton;
        private _confirmBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;
        private _btnCtr: fairygui.Controller;

        private _oldStr: string;
        private _can: boolean;
        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._btnCtr = this.contentPane.getController("view");
            this._noticeText = this.contentPane.getChild("notice").asTextField;
            this._noticeInput = this.contentPane.getChild("noticeInput").asTextInput;
            this._modifyBtn = this.contentPane.getChild("modifyBtn").asButton;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._modifyBtn.addClickListener(this._onModifyBtn, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);
            this._closeBtn.addClickListener(this._onClose, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._btnCtr.selectedIndex = 0;
            this._oldStr = param[0];
            if (!this._oldStr || this._oldStr.length == 0) {
                this._oldStr = Core.StringUtils.TEXT(70252);
            }
            this._can = param[1];
            this._refresh();
        }
        private async _refresh() {
            this._modifyBtn.visible = this._can;
            this._noticeText.text = this._oldStr;
        }
        private _onModifyBtn() {
            this._noticeInput.text = this._oldStr;
        }
        private async _onConfirmBtn() {
            let str = this._noticeInput.text;
            if (str == this._oldStr) {
                return;
            }
            let args = {Notice: str};
            let result = await Net.rpcCall(pb.MessageID.C2S_UPDATE_CITY_NOTICE, pb.CityNotice.encode(args));
            if (result.errcode == 101) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70251));
            } else if (result.errcode == 0) {
                this._oldStr = str;
                this._btnCtr.selectedIndex = 0;
                this._refresh();
            }
        }
        private async _onClose() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}