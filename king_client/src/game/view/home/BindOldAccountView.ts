module Home {
	export class BindOldAccountView extends Core.BaseWindow {

		private _accountText: fairygui.GTextField;
        private _passwordText: fairygui.GTextField;
        private _password2Text: fairygui.GTextField;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._accountText = this.getChild("account").asTextField;
            this._passwordText = this.getChild("password").asTextField;
            this._password2Text = this.getChild("password2").asTextField;

            this.getChild("acceptBtn").addClickListener(this._onBind, this);
		}

		private async _onBind() {
			let account = this._accountText.text.trim();
            if (account.length <= 0) {
                return;
            }

            let password = this._passwordText.text;
            let password2 = this._password2Text.text;
            if (password != password2) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60134));
                return;
            }

            if (password.length > 8 || password.length < 4) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60143));
                return;
            }

			let args = {
				Channel: "lzd_pkgsdk",
				Account: account,
				Password: password,
			}

			let result = await Net.rpcCall(pb.MessageID.C2S_FIRE233_BIND_ACCOUNT, pb.RegisterAccount.encode(args));
			let errcode = result.errcode;

            console.log("register ret = ", errcode);
            if (errcode == 0) {
                Core.ViewManager.inst.closeView(this);
                GameAccount.inst.saveToLocalAccount(account, password);
                GameAccount.inst.setPassword(account, password);
                if (Core.DeviceUtils.isWXGame()) {
                    Core.TipsUtils.showTipsFromCenter("绑定成功！");
                } else {
				    Core.TipsUtils.showTipsFromCenter("绑定成功，您可以用绑定的账号登陆游戏啦！");
                }
            } else if (errcode == 101) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60167));
            } else {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60118));
            }
		}
	}
}