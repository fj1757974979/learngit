module WXGame {
	export class WXAuthTipsWnd extends Core.BaseWindow {
		private _cancelBtn: fairygui.GButton;
		private _callback: (b: boolean) => void;
		private _userInfoButton: any;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._cancelBtn = this.contentPane.getChild("cancelBtn").asButton;
			this._cancelBtn.addClickListener(() => {
				if (this._callback) {
					this._callback(false);
					this._callback = null;
				}
				Core.ViewManager.inst.closeView(this);
			}, this);
		}

		public async open(...param: any[]) {
			super.open(param);
			this._callback = param[0];
			let windowWidth = WXGameMgr.inst.wxSystemInfo.windowWidth;
			let windowHeight = WXGameMgr.inst.wxSystemInfo.windowHeight;
			if (this._userInfoButton) {
				this._userInfoButton.destroy();
			}
			this._userInfoButton = wx.createUserInfoButton({
				type:"image",
				image:"res/authBtn.png",
				style: {
					width:150,
					height: 50,
					left: (windowWidth - 150) / 2,
					top:(windowHeight - 50) / 2 + 45
				}
			});
			this._userInfoButton.onTap((res) => {
				if (!this._userInfoButton) {
					return;
				}
				if (!res.userInfo) {
					return;
				}
				let nickName = res.userInfo.nickName;
				let avatarUrl = res.userInfo.avatarUrl;
				if (!nickName || !avatarUrl) {
					return;
				}
				if (WXGameMgr.inst.updateWXUserInfo(nickName, avatarUrl)) {
					Core.EventCenter.inst.dispatchEventWith(GameEvent.ModifyNameEv, false, nickName);
				}
				if (this._callback) {
					this._callback(true);
					this._callback = null;
				}
				Core.ViewManager.inst.closeView(this);
			});
		}

		public async close(...param: any[]) {
			super.close(...param);
			if (this._userInfoButton) {
				this._userInfoButton.destroy();
				this._userInfoButton = null;
			}
		}
	}
}