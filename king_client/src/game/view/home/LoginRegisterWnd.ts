module Home {

    export class LoginRegisterWnd extends Core.BaseView {
        private _accountText: fairygui.GTextField;
        private _passwordText: fairygui.GTextField;
        private _password2Text: fairygui.GTextField;

        private _callback: () => Promise<void>;

        public initUI() {
			super.initUI();
            this._myParent = Core.LayerManager.inst.maskLayer;
			this.center();

            this._accountText = this.getChild("account").asTextField;
            this._passwordText = this.getChild("password").asTextField;
            this._password2Text = this.getChild("password2").asTextField;

            this.getChild("acceptBtn").addClickListener(this._onRegister, this);
            this.getChild("closeBtn").addClickListener(()=>{
                Core.ViewManager.inst.closeView(this);
            }, this);
        }

        public async open(...param: any[]) {
			await super.open(...param);
            this._accountText.text = "";
            this._passwordText.text = "";
            this._password2Text.text = "";
            this._callback = param[0];
		}

        private async _onRegister() {
            let account = this._accountText.text.trim();
            if (account.length <= 0) {
                return;
            }

            let password = this._passwordText.text;
            let password2 = this._password2Text.text;
            if (password != password2) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60134));
                //this._errorText.text = Core.StringUtils.TEXT(60134);
                return;
            }

            if (password.length > 8 || password.length < 4) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60143));
                //this._errorText.text = Core.StringUtils.TEXT(60143);
                return;
            }

            //if (Core.WordFilter.inst.containsDirtyWords(account)) {
            //    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60167));
                //this._errorText.text = Core.StringUtils.TEXT(60167);
            //    return;
            //}

            let errcode = await HomeMgr.inst.onRegister(account, password);
            console.log("register ret = ", errcode);
            if (errcode == 0) {
                Core.ViewManager.inst.closeView(this);
                if (this._callback) {
                    this._callback();
                    this._callback = null;
                }
                GameAccount.inst.saveToLocalAccount(account, password);
                GameAccount.inst.setPassword(account, password);
            } else if (errcode == 101) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60167));
            } else {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60118));
                //this._errorText.text = Core.StringUtils.TEXT(60118);
            }
        }
    }

}