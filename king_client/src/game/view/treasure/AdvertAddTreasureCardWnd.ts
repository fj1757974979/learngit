module Treasure {
	export class AdvertAddTreasureCardWnd extends Core.BaseWindow {

		private _callback: (ok: boolean, jade: boolean, cnt?: number) => Promise<void>;

		private _advertBtn: fairygui.GButton;
		private _jadeSkipBtn: fairygui.GButton;
		private _shareBtn: fairygui.GButton;
		private _closeBtn: fairygui.GButton;
		private _hintText: fairygui.GTextField;
		private _hintText2: fairygui.GTextField;
		private _treasureId: number;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._advertBtn = this.contentPane.getChild("advertBtn").asButton;
			this._jadeSkipBtn = this.contentPane.getChild("jadeSkipBtn").asButton;
			this._shareBtn = this.contentPane.getChild("shareBtn").asButton;
			this._shareBtn.x = 270;
			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._hintText = this.contentPane.getChild("txt2").asTextField;
			this._hintText2 = this.contentPane.getChild("txt3").asTextField;
			this._hintText2.visible = true;

			this._closeBtn.addClickListener(this._onClose, this);
			this._shareBtn.addClickListener(this._onShare, this);
			this._advertBtn.addClickListener(this._onAdvert, this);
			this._jadeSkipBtn.addClickListener(this._onSkipAdvert, this);
			this._jadeSkipBtn.visible = true;

			if (Core.DeviceUtils.isWXGame()) {
				this._advertBtn.visible = false;
				this._shareBtn.visible = false;
				this._jadeSkipBtn.x = 150;
			} else if (adsPlatform.isAdsOpen()) {
				this._advertBtn.visible = true;
				this._shareBtn.visible = false;
			} else {
				this._advertBtn.visible = false;
				this._shareBtn.visible = false;
				this._jadeSkipBtn.x = 150;
			}

			this._jadeSkipBtn.icon = Player.inst.getSkipAdvertResIcon();
		}

		private async _onClose() {
			if (this._shareBtn.visible) {
				Core.TipsUtils.confirm(Core.StringUtils.TEXT(60217), async () => {
					if (this._callback) {
						await this._callback(false, false, 0);
						this._callback = null;
					}
					Core.ViewManager.inst.closeView(this);
				}, null, this, Core.StringUtils.TEXT(60041), Core.StringUtils.TEXT(60040));
			} else {
				if (this._callback) {
					await this._callback(false, false, 0);
					this._callback = null;
				}
				Core.ViewManager.inst.closeView(this);
			}

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
					await this._callback(true, false, 0);
				}
				Core.ViewManager.inst.closeView(this);
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60230));
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60172));
			}
		}

		private async _onSkipAdvert() {
			if (!await Player.inst.askSubSkipAdvertRes(true) && !Player.inst.canSkipAdvertForTreasure()) {
				return;
			}
			if (this._callback) {
				await this._callback(true, true, 0);
			}
			Core.ViewManager.inst.closeView(this);
			Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60191));
		}

		private async _onShare() {
			if (Player.inst.canSkipAdvertForTreasure()) {
				this._onSkipAdvert();
				return;
			}
			if (Core.DeviceUtils.isWXGame()) {
				WXGame.WXShareMgr.inst.wechatShareAddTreasureCard(this._treasureId);
				if (!WXGame.WXGameMgr.inst.isExamineVersion) {
					WXGame.WXGameMgr.inst.registerOnShowCallback(() => {
						setTimeout(async () => {
							if (this._callback) {
								await this._callback(true, false, 0);
							}
							Core.ViewManager.inst.closeView(this);
							Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60239));
						}, WXGame.WXShareMgr.inst.shareDelayOpTime);
					});
				}
			}
		}

		private async _onShareAddCard(ev: egret.Event) {
			let args = <pb.WatchTreasureAddCardAdsReply>ev.data;
			if (this._callback) {
				await this._callback(false, false, args.AddCardAmount);
				this._callback = null;
			}
			Core.ViewManager.inst.closeView(this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			this._treasureId = param[0];
			this._callback = param[1];

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

			if (this._shareBtn.visible) {
				Core.EventCenter.inst.addEventListener(GameEvent.AddTreasureCardEv, this._onShareAddCard, this);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._callback = null;
			Core.EventCenter.inst.removeEventListener(GameEvent.AddTreasureCardEv, this._onShareAddCard, this);
		}
	}
}
