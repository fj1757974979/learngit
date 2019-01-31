module Treasure {
	export class DailyTreasureDoubleWnd extends Core.BaseWindow {

		private _closeBtn: fairygui.GButton;
		private _openBtn: fairygui.GButton;
		private _shareBtn: fairygui.GButton;
		private _advertBtn: fairygui.GButton;
		private _jadeSkipBtn: fairygui.GButton;
		//private _goldDoubleHint: fairygui.GLoader;
		private _cardDoubleHint: fairygui.GLoader;
		private _goldText: fairygui.GTextField;
		private _cardText: fairygui.GTextField;
		private _boxName: fairygui.GTextField;

		private _treasure: DailyTreasureItem;
		private _closeCallback: () => void;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._openBtn = this.contentPane.getChild("openBtn").asButton;
			this._openBtn.x = 150;
			this._shareBtn = this.contentPane.getChild("shareBtn").asButton;
			this._advertBtn = this.contentPane.getChild("advertBtn").asButton;
			this._jadeSkipBtn = this.contentPane.getChild("jadeSkipBtn").asButton;
			//this._goldDoubleHint = this.contentPane.getChild("goldDoubleHint").asLoader;
			this._cardDoubleHint = this.contentPane.getChild("cardDoubleHint").asLoader;
			this._goldText = this.contentPane.getChild("goldCntNew").asTextField;
			this._cardText = this.contentPane.getChild("cardCntNew").asTextField;
			this._boxName = this.contentPane.getChild("boxName").asTextField;

			this._closeBtn.addClickListener(this._onOpenConfirm, this);

			// this._openBtn.addClickListener(() => {
			// 	if (this._closeCallback) {
			// 		this._closeCallback();
			// 	}
			// 	Core.ViewManager.inst.closeView(this);
			// }, this);

			this._openBtn.addClickListener(this._onOpenConfirm, this);

			this._shareBtn.addClickListener(() => {
				if (Player.inst.canSkipAdvertForTreasure()) {
					this._onSkipAdvert();
					return;
				}
				WXGame.WXShareMgr.inst.wechatShareDailyTreasure(this._treasure.id);
				if (!WXGame.WXGameMgr.inst.isExamineVersion) {
					WXGame.WXGameMgr.inst.registerOnShowCallback(() => {
						setTimeout(async () => {
							let args = {
								IsConsumeJade: false
							}
							let result = await Net.rpcCall(pb.MessageID.C2S_DAILY_TREASURE_READ_ADS, pb.DailyTreasureReadAdsArg.encode(args));
							if (result.errcode == 0) {
								this._treasure.isDouble = true;
								this.refresh(this._treasure);
								Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60238));
								Core.ViewManager.inst.closeView(this);
							}
						}, WXGame.WXShareMgr.inst.shareDelayOpTime);
					});
				}
			}, this);

			this._advertBtn.addClickListener(async () => {
				if (Player.inst.canSkipAdvertForTreasure()) {
					this._onSkipAdvert();
					return;
				}
				if (adsPlatform.isAdsOpen()) {
					let ret = await adsPlatform.isAdsReady();
					if (!ret.success) {
						Core.TipsUtils.showTipsFromCenter(ret.reason);
						return;
					}
					let res = await adsPlatform.showRewardAds();
					if (res) {
						let args = {
							IsConsumeJade: false
						}
						let result = await Net.rpcCall(pb.MessageID.C2S_DAILY_TREASURE_READ_ADS, pb.DailyTreasureReadAdsArg.encode(args));
						if (result.errcode == 0) {
							this._treasure.isDouble = true;
							this.refresh(this._treasure);
							Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60223));
						}
					}
				}
			}, this);

			this._jadeSkipBtn.addClickListener(this._onSkipAdvert, this);

			this._shareBtn.visible = false;
			this._advertBtn.visible = false;
			this._jadeSkipBtn.icon = Player.inst.getSkipAdvertResIcon();
		}

		public async open(...param: any[]) {
			super.open(...param);
			this.refresh(param[0]);
			this._closeCallback = param[1];
		}

		private async _onSkipAdvert() {
			if (!await Player.inst.askSubSkipAdvertRes(true) && !Player.inst.canSkipAdvertForTreasure()) {
				return;
			}
			let args = {
				IsConsumeJade: true
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_DAILY_TREASURE_READ_ADS, pb.DailyTreasureReadAdsArg.encode(args));
			if (result.errcode == 0) {
				this._treasure.isDouble = true;
				this.refresh(this._treasure);
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60179));
			}
		}

		public refresh(treasure: DailyTreasureItem) {
			if (!treasure) {
				egret.log("daily treasure is null");
			}
			this._treasure = treasure;
			//this._goldDoubleHint.visible = this._treasure.isDouble;
			this._cardDoubleHint.visible = this._treasure.isDouble;
			this._shareBtn.touchable = !this._treasure.isDouble;
			this._advertBtn.touchable = !this._treasure.isDouble;
			this._goldText.text = `x${treasure.getMinGoldCnt()} ~ ${treasure.getMaxGoldCnt()}`;
			let cardNum = 0;
			if (Player.inst.hasPrivilege(Priv.DAILY_ADD_CARD)) {
				cardNum += 20;
			}
			this._cardText.text = `x${treasure.getCardNum() + cardNum}`;
			this._boxName.text = `${treasure.getName()}`;

			if (!treasure.isDouble) {
				this._jadeSkipBtn.visible = true;
				this._openBtn.visible = false;
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
				if (Core.DeviceUtils.isWXGame()) {
					this._advertBtn.visible = false;
					this._shareBtn.visible = false;
					this.contentPane.getChild("txt2").asTextField.text = Core.StringUtils.TEXT(60237);
					this._shareBtn.icon = "common_btnGreen_png";
					this._jadeSkipBtn.x = 150;
				} else if (adsPlatform.isAdsOpen()) {
					this._advertBtn.visible = true;
					this._shareBtn.visible = false;
					this.contentPane.getChild("txt2").asTextField.text = Core.StringUtils.TEXT(60237);
				} else {
					this._advertBtn.visible = false;
					this._shareBtn.visible = false;
					this._jadeSkipBtn.x = 150;
				}
				this._openBtn.icon = "common_btnGrey_png";
				this._openBtn.title = Core.StringUtils.TEXT(60045);
			} else {
				this._openBtn.visible = true;
				this._openBtn.icon = "common_btnGreen_png";
				this._openBtn.title = Core.StringUtils.TEXT(60045);
				this._shareBtn.visible = false;
				this._advertBtn.visible = false;
				this._jadeSkipBtn.visible = false;
				this.contentPane.getChild("txt2").asTextField.text = Core.StringUtils.TEXT(60109);
			}
		}

		private async _onOpenConfirm() {
			let treasure = this._treasure;
			if (!treasure.isDouble) {
				Core.TipsUtils.confirm(Core.StringUtils.TEXT(60227), async function() {
					if (this._closeCallback) {
						this._closeCallback();
					}
					Core.ViewManager.inst.closeView(this);
				}, () => {}, this, Core.StringUtils.TEXT(60039), Core.StringUtils.TEXT(60057));
			} else {
				if (this._closeCallback) {
					this._closeCallback();
				}
				Core.ViewManager.inst.closeView(this);
			}
		}
		public async close(...param: any[]) {
			super.close(...param);
			this._closeCallback = null;
		}
	}
}
