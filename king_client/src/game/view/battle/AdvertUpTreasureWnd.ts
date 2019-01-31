module Battle {
	export class AdvertUpTreasureWnd extends Core.BaseWindow {

		private _boxImg1: fairygui.GLoader;
		private _boxNameText1: fairygui.GTextField;
		private _boxImg2: fairygui.GLoader;
		private _boxNameText2: fairygui.GTextField;
		private _closeBtn: fairygui.GButton;
		private _advertBtn: fairygui.GButton;
		private _shareBtn: fairygui.GButton;
		private _jadeSkipBtn: fairygui.GButton;

		private _hintText: fairygui.GTextField;

		private _callback: (b: boolean, jade: boolean) => Promise<void>;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._boxImg1 = this.contentPane.getChild("boxIcon1").asLoader;
			this._boxNameText1 = this.contentPane.getChild("boxName1").asTextField;
			this._boxImg2 = this.contentPane.getChild("boxIcon2").asLoader;
			this._boxNameText2 = this.contentPane.getChild("boxName2").asTextField;
			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._advertBtn = this.contentPane.getChild("advertBtn").asButton;
			this._shareBtn = this.contentPane.getChild("shareBtn").asButton;
			this._jadeSkipBtn = this.contentPane.getChild("jadeSkipBtn").asButton;

			this._hintText = this.contentPane.getChild("txt2").asTextField;

			this._closeBtn.addClickListener(this._onClose, this);
			this._advertBtn.addClickListener(this._onAdvert, this);
			this._jadeSkipBtn.addClickListener(this._onSkipAdvert, this);
			this._shareBtn.addClickListener(this._onShare, this);
			this._shareBtn.x = 270;

			this._jadeSkipBtn.visible = true;

			if (Core.DeviceUtils.isWXGame()) {
				this._advertBtn.visible = false;
				this._shareBtn.visible = false;
				this._jadeSkipBtn.x = 150;
				this._hintText.text = Core.StringUtils.TEXT(60253);
			} else if (adsPlatform.isAdsOpen()) {
				this._advertBtn.visible = true;
				this._shareBtn.visible = false;
				this._hintText.text = Core.StringUtils.TEXT(60204);
			} else {
				this._advertBtn.visible = false;
				this._shareBtn.visible = false;
				this._jadeSkipBtn.x = 150;
				this._hintText.text = Core.StringUtils.TEXT(60253);
			}

			this._jadeSkipBtn.icon = Player.inst.getSkipAdvertResIcon();

			this._callback = null;
		}

		private async _onClose() {
			if (this._shareBtn.visible) {
				Core.TipsUtils.confirm(Core.StringUtils.TEXT(60217), async () => {
					WXGame.WXShareMgr.inst.cancelCurShare();
					if (this._callback) {
						await this._callback(false, false);
						this._callback = null;
					}
					Core.ViewManager.inst.closeView(this);
				}, null, this, Core.StringUtils.TEXT(60041), Core.StringUtils.TEXT(60040));
			} else if (this._advertBtn.visible) {
				Core.TipsUtils.confirm(Core.StringUtils.TEXT(60194), async () => {
					if (this._callback) {
						await this._callback(false, false);
						this._callback = null;
					}
					Core.ViewManager.inst.closeView(this);
				}, null, this, Core.StringUtils.TEXT(60041), Core.StringUtils.TEXT(60040));
			} else {
				if (this._callback) {
					await this._callback(false, false);
					this._callback = null;
				}
				Core.ViewManager.inst.closeView(this);
			}
		}

		public async open(...param: any[]) {
			super.open(...param);

			let treasureId1 = param[0];
			let treasureId2 = param[1];
			this._callback = param[2];

			let treasure1 = new Treasure.TreasureItem(-1, treasureId1);
			let treasure2 = new Treasure.TreasureItem(-1, treasureId2);
			this._boxImg1.url = treasure1.image;
			this._boxNameText1.text = treasure1.getName();
			this._boxImg2.url = treasure2.image;
			this._boxNameText2.text = treasure2.getName();

			if (Player.inst.hasEnoughResToSkipAdvert() || Player.inst.canSkipAdvertForTreasure()) {
				this._jadeSkipBtn.titleColor = 0xffff00;
				if (Player.inst.canSkipAdvertForTreasure()) {
					this._jadeSkipBtn.text = Core.StringUtils.TEXT(70114);
				} else {
					this._jadeSkipBtn.text = "3";
				}
			} else {
				this._jadeSkipBtn.titleColor = 0xff0000;
			}

			this._jadeSkipBtn.icon = Player.inst.getSkipAdvertResIcon();
		}

		private async _onAdvert() {
			if (Player.inst.canSkipAdvertForTreasure()) {
				this._onSkipAdvert();
				return;
			}
			let ret = await adsPlatform.isAdsReady();
			if (!ret.success) {
				Core.TipsUtils.showTipsFromCenter(ret.reason);
				return;
			}
			let res = await adsPlatform.showRewardAds();
			if (res) {
				if (this._callback) {
					await this._callback(true, false);
					this._callback = null;
				}
				Core.ViewManager.inst.closeView(this);
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60213));
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60172));
			}
		}

		private async _onSkipAdvert() {
			if (!await Player.inst.askSubSkipAdvertRes(true) && !Player.inst.canSkipAdvertForTreasure()) {
				return;
			}

			if (this._callback) {
				await this._callback(true, true);
				this._callback = null;
			}
			Core.ViewManager.inst.closeView(this);
			Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60144));
		}

		private async _onShare() {
			if (Player.inst.canSkipAdvertForTreasure()) {
				this._onSkipAdvert();
				return;
			}
			if (Core.DeviceUtils.isWXGame()) {
				WXGame.WXShareMgr.inst.wechatShareUpTreasure();
				if (!WXGame.WXGameMgr.inst.isExamineVersion) {
					WXGame.WXGameMgr.inst.registerOnShowCallback(() => {
						setTimeout(async () => {
							if (this._callback) {
								await this._callback(true, false);
								this._callback = null;
							}
							Core.ViewManager.inst.closeView(this);
							Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60232));
						}, WXGame.WXShareMgr.inst.shareDelayOpTime);
					});

				}
			}
		}

		public async close(...param: any[]) {
			await super.close(...param);

		}
	}
}
