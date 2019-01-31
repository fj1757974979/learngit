module Home {

    export class LoginAccountWnd extends Core.BaseView {
        private _passwordText: fairygui.GTextField;
        private _comboAccount: fairygui.GComboBox;

        private _registerBtn: fairygui.GButton;
        private _loginBtn: fairygui.GButton;
        private _sdkBtn: fairygui.GButton;

        private _comboAccountSelectedIdx: number;

        private _callback: (isSdk: boolean) => Promise<void>;

        public initUI() {
			super.initUI();
            this._myParent = Core.LayerManager.inst.maskLayer;
			this.center();

            this.adjust(this.getChild("bg"));

            this._passwordText = this.getChild("password").asTextField;
            this._comboAccount = this.getChild("boxBtn").asComboBox;

            this._registerBtn = this.getChild("registerBtn").asButton;
            this._loginBtn = this.getChild("acceptBtn").asButton;
            this._sdkBtn = this.getChild("sdkBtn").asButton;

            this._comboAccountSelectedIdx = null;

            this._loginBtn.addClickListener(this._onLogin, this);
            this._registerBtn.addClickListener(this._onRegister, this);
            this._sdkBtn.addClickListener(this._onSdkLogin, this);

            this._comboAccount.addEventListener(fairygui.StateChangeEvent.CHANGED, this._onComboAccountChanged, this);
        }

        public async open(...param: any[]) {
			await super.open(...param);
            this._callback = param[0];

            let accounts = GameAccount.inst.getLocalAccounts();
            let recentAccount = GameAccount.inst.getRecentLocalAccount();
            if (accounts) {
                let items = [];
                let values = [];
                let i = 0;
                accounts.forEach(info => {
                    items.push(info.account);
                    values.push(info.pwd);
                    if (info.account == recentAccount) {
                        this._comboAccountSelectedIdx = i;
                    } else {
                        ++ i;
                    }
                });
                this._comboAccount.items = items;
                this._comboAccount.values = values;
                if (this._comboAccountSelectedIdx != null) {
                    this._comboAccount.selectedIndex = this._comboAccountSelectedIdx;
                    this._passwordText.text = values[this._comboAccountSelectedIdx];
                }
            }
		}
       
        private async _onRegister() {
            Core.ViewManager.inst.open(ViewName.loginRegister, () => {
                if (this._callback) {
                    this._callback(false);
                    this._callback = null;
                }
                Core.ViewManager.inst.closeView(this);
            });
        }

        private async _onSdkLogin() {
            if (this._callback) {
                this._callback(true);
                this._callback = null;
            }
            Core.ViewManager.inst.closeView(this);
        }

        private async _onLogin() {
            let account = this._comboAccount.text.trim();
            let password = this._passwordText.text;
            if (account.length > 0) {
                let errcode = await HomeMgr.inst.onAccountLoginWithPwd(account, password);
                if (errcode == 0) {
                    GameAccount.inst.saveToLocalAccount(account, password);
                    GameAccount.inst.setPassword(account, password);
                    if (this._callback) {
                        this._callback(false);
                        this._callback = null;
                    }
                    Core.ViewManager.inst.closeView(this);
                } else {
                    if (errcode == 1) {
                        Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60155));
                    } else {
                        Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60133));
                    }
                }
            } else {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60122));
            }
        }

        private async _onComboAccountChanged() {
            this._passwordText.text = this._comboAccount.value;
        }
    }

}