// TypeScript file
module Shop {
    export class FreeGoldInfoWnd extends Core.BaseWindow {
        private _nameText: fairygui.GTextField;
		private _goldCntText: fairygui.GTextField;
		private _cardImg: fairygui.GLoader;
		private _btnBuy: fairygui.GButton;
		private _btnShare: fairygui.GButton;
		private _btnOpen: fairygui.GButton;
		private _jadeSkipBtn: fairygui.GButton;
		private _freeId: number;

		private _buyCallback: (jade:boolean) => void;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;
			this._nameText = this.contentPane.getChild("name").asTextField;
			this._goldCntText = this.contentPane.getChild("goldCnt").asTextField;
			this._cardImg = this.contentPane.getChild("icon").asLoader;
			this._btnBuy = this.contentPane.getChild("btnBuy").asButton;
			this._btnShare = this.contentPane.getChild("shareBtn").asButton;
			this._btnOpen = this.contentPane.getChild("btnOpen").asButton;
			this._jadeSkipBtn = this.contentPane.getChild("jadeSkipBtn").asButton;

			this._btnBuy.addClickListener(() => {
				this._onBuy(false);
			}, this);
			// this._btnOpen.addClickListener(this._onBuy, this);
			this._btnShare.addClickListener(this._onShare, this);
			this._jadeSkipBtn.addClickListener(this._onSkipAdvert, this);

			this.contentPane.getChild("closeBtn").addClickListener(()=>{
                Core.ViewManager.inst.closeView(this);
            }, this);
			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);

			this._jadeSkipBtn.icon = Player.inst.getSkipAdvertResIcon();
		}

		private _onBuy(jade: boolean = false) {
			if (window.gameGlobal.channel == "lzd_handjoy") {
				jade = false;
			}
			if (this._buyCallback) {
				this._buyCallback(jade);
			}
			Core.ViewManager.inst.closeView(this);
		}

		private _onSkipAdvert() {
			if (!Player.inst.hasEnoughResToSkipAdvert() && !Player.inst.isVip) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
				return;
			}
			this._onBuy(false);
		}

		private _onShare() {
			if (Player.inst.isVip) {
				this._onSkipAdvert();
				return;
			}
			if (Core.DeviceUtils.isWXGame()) {
				WXGame.WXShareMgr.inst.wechatShareFreeItem(this._freeId, pb.ShopFreeAdsType.GoldAds, WXGame.WXShareType.SHARE_FREE_GOLD);
				WXGame.WXGameMgr.inst.registerOnShowCallback(() => {
					setTimeout(() => {
						this._onBuy(false);
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60212));
					}, WXGame.WXShareMgr.inst.shareDelayOpTime);
					// fairygui.GTimers.inst.add(WXGame.WXShareMgr.inst.shareDelayOpTime, 1, () => {
					// 	this._onBuy(false);
					// }, this);
				});
			}
		}

		public async open(...param: any[]) {
			super.open(...param);

			let conf = param[0];
			let buyCallback = param[1];
			let canGetForShare = param[2];
			this._freeId = param[3];

			if (Player.inst.isVip) {
				this._jadeSkipBtn.title = Core.StringUtils.TEXT(70114);
			} else {
				this._jadeSkipBtn.title = "3";
			}

			// console.log("++++++++ ", canGetForShare, this._freeId);

			if (Player.inst.hasEnoughResToSkipAdvert()) {
				this._jadeSkipBtn.titleColor = 0xffff00;
			} else {
				this._jadeSkipBtn.titleColor = 0xff0000;
			}

			if (LanguageMgr.inst.isChineseLocale()) {
				this._nameText.text = Core.StringUtils.TEXT(60022)+`${conf.desc}?`;
			} else {
				this._nameText.text = Core.StringUtils.TEXT(60022)+` ${conf.desc}?`;
			}
			this._goldCntText.text = `x${conf.soldGold}`;
			if (conf.icon != "") {
				this._cardImg.url = conf.icon;
			}
			this._buyCallback = buyCallback;

			this._jadeSkipBtn.visible = true;

			if (Core.DeviceUtils.isWXGame()) {
				// this._btnBuy.visible = false;
				// this._btnOpen.visible = false;
				// if (WXGame.WXGameMgr.inst.isExamineVersion || Player.inst.isNewVersionPlayer()) {
				// 	this._btnShare.visible = false;
				// 	this._jadeSkipBtn.x = 95;
				// } else {
				// 	this._btnShare.visible = true;
				// 	this._jadeSkipBtn.x = 15;
				// }
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = false;
				this._jadeSkipBtn.visible = true;
				this._jadeSkipBtn.x = 95;
				this._jadeSkipBtn.title = Core.StringUtils.TEXT(70114);
			} else if (adsPlatform.isAdsOpen()) {
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = true;
			} else if (window.gameGlobal.channel == "lzd_handjoy") {
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = false;
				this._jadeSkipBtn.visible = true;
				this._jadeSkipBtn.x = 95;
				this._jadeSkipBtn.title = Core.StringUtils.TEXT(70114);
			} else {
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = false;
				this._jadeSkipBtn.visible = false;
			}
		}

		private _onClose(evt:egret.TouchEvent) {
			let x = evt.stageX / fairygui.GRoot.contentScaleFactor;
			let y = evt.stageY / fairygui.GRoot.contentScaleFactor;
			if (x >= this.x && x <= this.x + this.width && y >= this.y && y <= this.y + this.height) {
				return;
			} else {
				Core.ViewManager.inst.closeView(this);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._buyCallback = null;
			this.root.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}
    }

    export class FreeJadeInfoWnd extends Core.BaseWindow {
        private _nameText: fairygui.GTextField;
		private _goldCntText: fairygui.GTextField;
		private _cardImg: fairygui.GLoader;
		private _btnBuy: fairygui.GButton;
		private _btnShare: fairygui.GButton;
		private _btnOpen: fairygui.GButton;
		private _freeId: number;

		private _buyCallback: (jade: boolean) => void;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;
			this._nameText = this.contentPane.getChild("name").asTextField;
			this._goldCntText = this.contentPane.getChild("goldCnt").asTextField;
			this._cardImg = this.contentPane.getChild("icon").asLoader;
			this._btnBuy = this.contentPane.getChild("btnBuy").asButton;
			this._btnShare = this.contentPane.getChild("shareBtn").asButton;
			this._btnOpen = this.contentPane.getChild("btnOpen").asButton;
			this._btnBuy.addClickListener(() => {
				this._onBuy(false);
			}, this);
			this._btnOpen.addClickListener(this._onBuy, this);
			this._btnShare.addClickListener(this._onShare, this);

			this.contentPane.getChild("closeBtn").addClickListener(()=>{
                Core.ViewManager.inst.closeView(this);
            }, this);
			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);

			if (adsPlatform.isAdsOpen()) {
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = true;
			} else {
				this._btnBuy.visible = false;
			}

		}

		private _onBuy(jade: boolean = false) {
			if (this._buyCallback) {
				this._buyCallback(jade);
			}
			Core.ViewManager.inst.closeView(this);
		}

		private _onShare() {
			if (Core.DeviceUtils.isWXGame()) {
				WXGame.WXShareMgr.inst.wechatShareFreeItem(this._freeId, pb.ShopFreeAdsType.JadeAds, WXGame.WXShareType.SHARE_FREE_JADE);
				WXGame.WXGameMgr.inst.registerOnShowCallback(() => {
					setTimeout(() => {
						this._onBuy(false);
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60212));
					}, WXGame.WXShareMgr.inst.shareDelayOpTime);
					// fairygui.GTimers.inst.add(WXGame.WXShareMgr.inst.shareDelayOpTime, 1, () => {
						// this._onBuy(false);
					// }, this);
				});
			}
		}

		public async open(...param: any[]) {
			super.open(...param);

			let conf = param[0];
			let buyCallback = param[1];
			let canGetForShare = param[2];
			this._freeId = param[3];

			// console.log("++++++++ ", canGetForShare, this._freeId);

			this._nameText.text = Core.StringUtils.TEXT(60022)+`${conf.desc}?`;
			this._goldCntText.text = `x${conf.soldJade}`;
			if (conf.icon != "") {
				this._cardImg.url = conf.icon;
			}
			this._buyCallback = buyCallback;

			this._btnOpen.visible = false;
			this._btnBuy.visible = true;
			this._btnShare.visible = false;
			if (!adsPlatform.isAdsOpen() && Core.DeviceUtils.isWXGame()) {
				this._btnBuy.visible = false;
				if (canGetForShare) {
					this._btnShare.visible = false;
					this._btnOpen.visible = true;
				} else {
					this._btnShare.visible = true;
					this._btnOpen.visible = false;
				}
			}
			// this.root.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}

		private _onClose(evt:egret.TouchEvent) {
			let x = evt.stageX / fairygui.GRoot.contentScaleFactor;
			let y = evt.stageY / fairygui.GRoot.contentScaleFactor;
			if (x >= this.x && x <= this.x + this.width && y >= this.y && y <= this.y + this.height) {
				return;
			} else {
				Core.ViewManager.inst.closeView(this);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._buyCallback = null;
			this.root.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}
    }

    export class FreeTreasureInfoWnd extends Core.BaseWindow {

		private _nameText: fairygui.GTextField;
		private _rareCardNumText: fairygui.GTextField;
		private _btnBuy: fairygui.GButton;
		private _effBox0: fairygui.GLoader;
		private _effBox1: fairygui.GLoader;
		private _openTrans0: fairygui.Transition;
		private _btnShare: fairygui.GButton;
		private _btnOpen: fairygui.GButton;
		private _jadeSkipBtn: fairygui.GButton;
		private _rewardList: fairygui.GList;
		private _freeId: number;

		private _buyCallback: (jade: boolean) => void;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._rareCardNumText = this.contentPane.getChild("txt1").asTextField;
			this._nameText = this.contentPane.getChild("treasureName").asTextField;
			this._btnBuy = this.contentPane.getChild("btnBuy").asButton;
			this._btnShare = this.contentPane.getChild("shareBtn").asButton;
			this._btnOpen = this.contentPane.getChild("btnOpen").asButton;
			this._jadeSkipBtn = this.contentPane.getChild("jadeSkipBtn").asButton;
			this._effBox0 = this.contentPane.getChild("box0").asLoader;
			this._effBox1 = this.contentPane.getChild("box1").asLoader;
			this._openTrans0 = this.contentPane.getTransition("t0");

			this._rewardList = this.contentPane.getChild("rewardList").asList;

			this._btnBuy.addClickListener(() => {
				this._onBuy(false);
			}, this);
			this._btnOpen.addClickListener(this._onBuy, this);
			this._btnShare.addClickListener(this._onShare, this);
			this._jadeSkipBtn.addClickListener(this._onSkipAdvert, this);

			this.contentPane.getChild("closeBtn").addClickListener(()=>{
                Core.ViewManager.inst.closeView(this);
            }, this);
			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);

			this._jadeSkipBtn.icon = Player.inst.getSkipAdvertResIcon();
		}

		private _onBuy(jade: boolean = false) {
			if (window.gameGlobal.channel == "lzd_handjoy") {
				jade = false;
			}
			if (this._buyCallback) {
				this._buyCallback(jade);
			}
			Core.ViewManager.inst.closeView(this);
		}

		private _onShare() {
			if (Player.inst.isVip) {
				this._onSkipAdvert();
				return;
			}
			if (Core.DeviceUtils.isWXGame()) {
				WXGame.WXShareMgr.inst.wechatShareFreeItem(this._freeId, pb.ShopFreeAdsType.TreasureAds, WXGame.WXShareType.SHARE_FREE_TREASURE);
				WXGame.WXGameMgr.inst.registerOnShowCallback(() => {
					setTimeout(() => {
						this._onBuy(false);
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60212));
					}, WXGame.WXShareMgr.inst.shareDelayOpTime);
				});
			}
		}

		private _onSkipAdvert() {
			if (!Player.inst.hasEnoughResToSkipAdvert() && !Player.inst.isVip) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
				return;
			}
			this._onBuy(false);
		}

		public async open(...param: any[]) {
			super.open(...param);
			let conf = param[0];
			this._buyCallback = param[1];
			let canGetForShare = param[2];
			this._freeId = param[3];

			// console.log("++++++++ ", canGetForShare, this._freeId);

			let treasureType = conf.treasureId;
			let treasure = new Treasure.TreasureItem(-1, treasureType);

			this._nameText.text = treasure.getName();

			let rewardComs = Treasure.TreasureReward.genRewardItemComsByTreasure(treasure);
			rewardComs.forEach(com => {
				this._rewardList.addChild(com);
			});

			this._rewardList.height = Math.ceil(rewardComs.length / 2) * 50;

			let rareCardNum = treasure.getRareCardNum();
			if (rareCardNum <= 0) {
				this._rareCardNumText.visible = false;
			} else {
				this._rareCardNumText.visible = true;
				this._rareCardNumText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60130), rareCardNum);
			}

			let rareType = treasure.getRareType();
			this._effBox0.url = `treasure_${rareType}0_png`;
			this._effBox1.url = `treasure_${rareType}1_png`;

			this._jadeSkipBtn.visible = true;
			if (Player.inst.hasEnoughResToSkipAdvert() || Player.inst.isVip) {
				this._jadeSkipBtn.titleColor = 0xffff00;
				if (Player.inst.isVip) {
					this._jadeSkipBtn.text = Core.StringUtils.TEXT(70114);
				} else {
					this._jadeSkipBtn.text = "3";
				}
			} else {
				this._jadeSkipBtn.titleColor = 0xff0000;
			}
			if (Core.DeviceUtils.isWXGame()) {
				// this._btnBuy.visible = false;
				// this._btnOpen.visible = false;
				// if (WXGame.WXGameMgr.inst.isExamineVersion) {
				// 	this._btnShare.visible = false;
				// 	this._jadeSkipBtn.x = 125;
				// } else {
				// 	this._btnShare.visible = true;
				// 	this._jadeSkipBtn.x = 35;
				// }
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = false;
				this._jadeSkipBtn.visible = true;
				this._jadeSkipBtn.x = 125;
				this._jadeSkipBtn.title = Core.StringUtils.TEXT(70114);
			} else if (adsPlatform.isAdsOpen()) {
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = true;
			} else if (window.gameGlobal.channel == "lzd_handjoy") {
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = false;
				this._jadeSkipBtn.visible = true;
				this._jadeSkipBtn.x = 125;
				this._jadeSkipBtn.title = Core.StringUtils.TEXT(70114);
			} else {
				this._btnShare.visible = false;
				this._btnOpen.visible = false;
				this._btnBuy.visible = false;
				this._jadeSkipBtn.visible = false;
			}
		}

		private _onClose(evt:egret.TouchEvent) {
			let x = evt.stageX / fairygui.GRoot.contentScaleFactor;
			let y = evt.stageY / fairygui.GRoot.contentScaleFactor;
			if (x >= this.x && x <= this.x + this.width && y >= this.y && y <= this.y + this.height) {
				return;
			} else {
				Core.ViewManager.inst.closeView(this);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._buyCallback = null;
			this.root.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
			this._rewardList.removeChildren(0, -1, true);
		}
	}

	export class FreeTreasureInfoFacebookWnd extends Core.BaseWindow {

		private _nameText: fairygui.GTextField;
		private _rareCardNumText: fairygui.GTextField;
		private _effBox0: fairygui.GLoader;
		private _effBox1: fairygui.GLoader;
		private _openTrans0: fairygui.Transition;
		private _btnShare: fairygui.GButton;
		private _rewardList: fairygui.GList;
		private _freeId: number;

		private _buyCallback: (jade: boolean) => void;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._rareCardNumText = this.contentPane.getChild("txt1").asTextField;
			this._nameText = this.contentPane.getChild("treasureName").asTextField;
			this._btnShare = this.contentPane.getChild("shareBtn").asButton;
			this._effBox0 = this.contentPane.getChild("box0").asLoader;
			this._effBox1 = this.contentPane.getChild("box1").asLoader;
			this._openTrans0 = this.contentPane.getTransition("t0");

			this._rewardList = this.contentPane.getChild("rewardList").asList;

			
			this._btnShare.addClickListener(this._onShare, this);

			this.contentPane.getChild("closeBtn").addClickListener(()=>{
                Core.ViewManager.inst.closeView(this);
            }, this);
			this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);
		}

		private async _shareComplete(ret: boolean) {
            if (ret) {
                if (this._buyCallback) {
					this._buyCallback(false);
				}
				Core.ViewManager.inst.closeView(this);
            }
        }

		private async _onShare() {
			let link = window.sharePlatform.getShareLink();
            if (link != "") {
            	let ret = await window.sharePlatform.shareAppMsg(Core.StringUtils.TEXT(60254), link, "");
                this._shareComplete(ret);
			}
		}
		
		public async open(...param: any[]) {
			super.open(...param);
			let conf = param[0];
			this._buyCallback = param[1];
			let canGetForShare = param[2];
			this._freeId = param[3];

			let treasureType = conf.treasureId;
			let treasure = new Treasure.TreasureItem(-1, treasureType);

			this._nameText.text = treasure.getName();

			let rewardComs = Treasure.TreasureReward.genRewardItemComsByTreasure(treasure);
			rewardComs.forEach(com => {
				this._rewardList.addChild(com);
			});

			this._rewardList.height = Math.ceil(rewardComs.length / 2) * 50;

			let rareCardNum = treasure.getRareCardNum();
			if (rareCardNum <= 0) {
				this._rareCardNumText.visible = false;
			} else {
				this._rareCardNumText.visible = true;
				this._rareCardNumText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60130), rareCardNum);
			}

			let rareType = treasure.getRareType();
			this._effBox0.url = `treasure_${rareType}0_png`;
			this._effBox1.url = `treasure_${rareType}1_png`;
		}

		private _onClose(evt:egret.TouchEvent) {
			let x = evt.stageX / fairygui.GRoot.contentScaleFactor;
			let y = evt.stageY / fairygui.GRoot.contentScaleFactor;
			if (x >= this.x && x <= this.x + this.width && y >= this.y && y <= this.y + this.height) {
				return;
			} else {
				Core.ViewManager.inst.closeView(this);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._buyCallback = null;
			this.root.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
			this._rewardList.removeChildren(0, -1, true);
		}
	}
}
