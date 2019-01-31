module Home {
	export class LoginFacebook extends Core.BaseView {

		private _facebookBtn: fairygui.GButton;
		private _touristBtn: fairygui.GButton;
		private _googleBtn: fairygui.GButton;
		private _callback: () => Promise<void>;
		private _bg: fairygui.GLoader;

		public initUI() {
			super.initUI();

			this._myParent = Core.LayerManager.inst.maskLayer;

			if (window.gameGlobal.isMultiLan) {
				// logo
				let logo = new fairygui.GLoader();
				logo.url = "loading_logoName_png";
				logo.autoSize = false;
				logo.fill = fairygui.LoaderFillType.ScaleMatchWidth;
				logo.x = 0;
				logo.y = 58;
				logo.addRelation(this.getChild("bg"), fairygui.RelationType.Top_Top);
				this.addChild(logo);
            	this.adjust(this.getChild("bg"), Core.AdjustType.NO_BORDER);
				logo.width = Math.min(fairygui.GRoot.inst.getDesignStageWidth(), this.getChild("bg").width);
			} else {
				this.adjust(this.getChild("bg"), Core.AdjustType.NO_BORDER);
			}

			this._facebookBtn = this.getChild("facebookBtn").asButton;
			this._touristBtn = this.getChild("touristBtn").asButton;
			this._googleBtn = this.getChild("googleBtn").asButton;

			this._bg = this.getChild("bg").asLoader;
            this._bg.url = (window.gameGlobal.logoUrl || "loading_logo_lzd_jpg").replace("png", "jpg");

			this._facebookBtn.addClickListener(this._onFacebookLogin, this);
			this._touristBtn.addClickListener(this._onTouristLogin, this);
			this._googleBtn.addClickListener(this._onGooglePlusLogin, this);
			if (window.gameGlobal.isFbAdvert) {
				this._facebookBtn.visible = true;
				this._googleBtn.visible = false;
				this._touristBtn.visible = false;
				this._facebookBtn.x = 122;
			} else if (Core.DeviceUtils.isAndroid()) {
				this._facebookBtn.visible = true;
				this._googleBtn.visible = true;
				this._touristBtn.visible = false;
			} else if (Core.DeviceUtils.isiOS()) {
				this._facebookBtn.visible = true;
				this._googleBtn.visible = false;
				if (IOS_EXAMINE_VERSION) {
					this._touristBtn.visible = true;
				} else {
					this._touristBtn.visible = false;
				}
				this._facebookBtn.x = 122;
			} else {
				this._facebookBtn.visible = true;
				this._googleBtn.visible = false;
				this._touristBtn.visible = true;
				this._facebookBtn.x = 122;
			}
		}

		private async _onFacebookLogin() {
			if (this._callback) {
				await platform.login({loginType: "facebook"});
				let channelUserInfo = await platform.getUserInfo();
				if (!channelUserInfo) {
					return;
				}
				Core.ViewManager.inst.open(ViewName.connectView);
				let ret = await HomeMgr.inst.onSdkAccountLogin(channelUserInfo);
				Core.ViewManager.inst.close(ViewName.connectView);
				if (ret == 0) {
					this._callback();
					this._callback = null;
				}
			}
		}

		private async _onGooglePlusLogin() {
			if (this._callback) {
				await platform.login({loginType: "google"});
				let channelUserInfo = await platform.getUserInfo();
				if (!channelUserInfo) {
					return;
				}
				Core.ViewManager.inst.open(ViewName.connectView);
				let ret = await HomeMgr.inst.onSdkAccountLogin(channelUserInfo);
				Core.ViewManager.inst.close(ViewName.connectView);
				if (ret == 0) {
					this._callback();
					this._callback = null;
				}
			}
		}

		private async _onTouristLogin() {
			if (this._callback) {
				Core.ViewManager.inst.open(ViewName.connectView);
				let ret = await Home.HomeMgr.inst.onTouristLogin();
				Core.ViewManager.inst.close(ViewName.connectView);
				if (ret == 0) {
					this._callback();
					this._callback = null;
				}
			}
		}

		public async open(...param: any[]) {
			await super.open(...param);
			this._callback = param[0];
		}

		public async close(...param: any[]) {
			await super.close(...param);
			
		}
	}
}