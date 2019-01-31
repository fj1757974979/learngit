module Shop {
	export class FreeItemComBase extends fairygui.GComponent {

		protected _nameText: fairygui.GTextField;
		protected _iconImg: fairygui.GLoader;
		protected _priceText: fairygui.GTextField;
		protected _cntText: fairygui.GTextField;

		protected _remainTime: number;

		protected _data: pb.ShopFreeAds;
		protected _host: FreeSellCom;

		private _titleText: string;

		protected constructFromXML(xml: any) {
			super.constructFromXML(xml);

			this._nameText = this.getChild("name").asTextField;
			this._iconImg = this.getChild("icon").asLoader;
			this._priceText = this.getChild("price").asTextField;
			this._cntText = this.getChild("cnt").asTextField;

			let self = this;
			this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, () => {
				self.getTransition("t0").play();
			}, this);

			this.addClickListener(this.onClick, this);

			if (Core.DeviceUtils.isWXGame()) {
				if (WXGame.WXGameMgr.inst.isExamineVersion) {
					this._titleText = Core.StringUtils.TEXT(60027);
				} else {
					this._titleText = Core.StringUtils.TEXT(60037);
				}
			} else {
				this._titleText = Core.StringUtils.TEXT(60037);
			}

			if (!LanguageMgr.inst.isChineseLocale()) {
				this._nameText.fontSize = 14;
			}
		}

		public setData(data: pb.ShopFreeAds) {
			this._remainTime = data.RemainTime;
			if (this._remainTime > 0) {
				this._startCountDown();
			} else {
				this._stopCountDown();
				this._priceText.text = this._titleText;
			}
			this._data = data;
		}

		public get host(): FreeSellCom {
			return this._host;
		}

		public set host(h: FreeSellCom) {
			this._host = h;
		}

		public get remainTime(): number {
			return this._remainTime;
		}

		private _execCountDown() {
			this._remainTime --;
			if (this._remainTime <= 0) {
				this._priceText.text = this._titleText;
				this._stopCountDown();
				return;
			}
			this._priceText.text = Core.StringUtils.secToString(this._remainTime, "hm");
		}

		private _startCountDown() {
			this._stopCountDown();
			this._priceText.text = Core.StringUtils.secToString(this._remainTime, "hm");
			fairygui.GTimers.inst.add(1000, this._remainTime, this._execCountDown, this);
		}

		private _stopCountDown() {
			fairygui.GTimers.inst.remove(this._execCountDown, this);
		}

		private async _fetchReward(jade: boolean): Promise<boolean> {
			if (window.gameGlobal.channel == "lzd_handjoy") {
				jade = false;
			}
			let args = {
				Type: this._data.Type,
				ID: this._data.ID,
				IsConsumeJade: jade
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_SHOP_FREE_ADS, pb.WatchShopFreeAdsArg.encode(args));
			if (result.errcode == 0) {
				let reply = pb.WatchShopFreeAdsReply.decode(result.payload);
				this._handleReward(reply.RewardPayload);
				this.setData(<pb.ShopFreeAds>reply.NextAds);
				if (this._host) {
					this._host.onFreeBuy();
				}
				return true;
			} else {
				return false;
			}
		}

		protected async _onFreeBuy(jade: boolean) {
			if (this._remainTime > 0) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60196));
				return;
			}
			if (jade || Player.inst.isVip) {
				await this._fetchReward(true);
			} else if (Core.DeviceUtils.isWXGame()) {
				await this._fetchReward(false);
			} else if (adsPlatform.isAdsOpen()) {
				let ret = await adsPlatform.isAdsReady();
				if (!ret.success) {
					Core.TipsUtils.showTipsFromCenter(ret.reason);
					return;
				}
				let res = await adsPlatform.showRewardAds();
				if (res) {
					if (await this._fetchReward(false)) {
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60192));
					}
				}
			} else {
				await this._fetchReward(false);
			}
		}

		public get canGetForShare(): boolean {
			if (adsPlatform.isAdsOpen()) {
				return false;
			} else {
				return this._data.CanGet;
			}
		}

		public set canGetForShare(b: boolean) {
			this._data.CanGet = b;
			this.onClick();
		}

		protected _handleReward(payload: any) {
			
		}

		public onClick() {

		}
	}

	export class FreeGoldItemCom extends FreeItemComBase {
		public setData(data: pb.ShopFreeAds) {
			super.setData(data);
			let id = data.ID;
			let conf = Data.free_gold.get(id);
			if (conf) {
				this._nameText.text = conf.desc;
				this._iconImg.url = conf.icon;
				this._cntText.text = `x${conf.soldGold}`;
			}
		}

		protected _handleReward(payload: any) {
			let reward = pb.WatchShopFreeAdsReply.GoldReward.decode(payload);
			let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
			shopView.onBuyGold(reward.GoldAmount);
		}

		public onClick() {
			if (this._remainTime > 0) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60196));
				return;
			}
			Core.ViewManager.inst.close(ViewName.freeGoldInfoWnd);
			let conf = Data.free_gold.get(this._data.ID);
			if (conf) {
				Core.ViewManager.inst.open(ViewName.freeGoldInfoWnd, conf, (jade) => {
					this._onFreeBuy(jade);
				}, this._data.CanGet, this._data.ID);
			}
		}
	}

	export class FreeJadeItemCom extends FreeItemComBase {
		public setData(data: pb.ShopFreeAds) {
			super.setData(data);
			let id = data.ID;
			let conf = Data.free_jade.get(id);
			if (conf) {
				this._nameText.text = conf.desc;
				this._iconImg.url = conf.icon;
				this._cntText.text = `x${conf.soldJade}`;
			}
		}

		protected _handleReward(payload: any) {
			let reward = pb.WatchShopFreeAdsReply.JadeReward.decode(payload);
			let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
			shopView.onBuyJade(reward.JadeAmount);
		}

		public onClick() {
			if (this._remainTime > 0) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60196));
				return;
			}
			Core.ViewManager.inst.close(ViewName.freeJadeInfoWnd);
			let conf = Data.free_jade.get(this._data.ID);
			if (conf) {
				Core.ViewManager.inst.open(ViewName.freeJadeInfoWnd, conf, (jade) => {
					this._onFreeBuy(jade);
				}, this._data.CanGet, this._data.ID);
			}
		}
	}

	export class FreeTreasureItemCom extends FreeItemComBase {
		public setData(data: pb.ShopFreeAds) {
			super.setData(data);
			let id = data.ID;
			let conf = null;
			if (data.Type == pb.ShopFreeAdsType.JadeAds) {
				conf = Data.free_good_treasure.get(id);
			} else {
				conf = Data.free_treasure.get(id);
			}
			if (conf) {
				let treasureId = conf.treasureId;
				let treasure = new Treasure.TreasureItem(-1, treasureId);
				this._nameText.text = treasure.getName();
				this._iconImg.url = treasure.image;
			}
		}

		protected _handleReward(payload: any) {
			let treasureReward = pb.OpenTreasureReply.decode(payload);
			let reward = new Treasure.TreasureReward();
			reward.setRewardForOpenReply(treasureReward);
			let conf = null;
			if (this._data.Type == pb.ShopFreeAdsType.JadeAds) {
				conf = Data.free_good_treasure.get(this._data.ID);
			} else {
				conf = Data.free_treasure.get(this._data.ID);
			}
			Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, conf.treasureId), () => {
				let shopView = <ShopView>Core.ViewManager.inst.getView(ViewName.shopView);
				shopView.onBuyTreasure();
			});
		}

		public onClick() {
			if (this._remainTime > 0) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60196));
				return;
			}
			let infoViewName = ViewName.freeTreasureInfoWnd;
			if (window.gameGlobal.channel == "lzd_handjoy" && 
					this._data.Type == pb.ShopFreeAdsType.JadeAds &&
					window.sharePlatform.getShareLink() != "") {
				infoViewName = ViewName.freeTreasureInfoFacebookWnd;
			}
			Core.ViewManager.inst.close(infoViewName);
			let conf = null;
			if (this._data.Type == pb.ShopFreeAdsType.JadeAds) {
				conf = Data.free_good_treasure.get(this._data.ID);
			} else {
				conf = Data.free_treasure.get(this._data.ID);
			}
			if (conf) {
				Core.ViewManager.inst.open(infoViewName, conf, (jade) => {
					this._onFreeBuy(jade);
				}, this._data.CanGet, this._data.ID);
			}
		}
	}
}