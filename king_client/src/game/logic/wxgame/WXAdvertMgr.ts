module WXGame {

	export class WXAdsPlatform implements AdvertisePlatform {
		private static _inst: WXAdsPlatform = null;
		private _isAdsReaddy: boolean;
		private _rewardedVideoAd: RewardedVideoAd = null;
		private _adUnitId: string;
		private _watchAdsResolve: (value? :boolean|PromiseLike<boolean>) => void;
		private _lastErrCode: number = -1;
		private _errCode2Msg: {};

		public static get inst(): WXAdsPlatform {
			if (!WXAdsPlatform._inst) {
				WXAdsPlatform._inst = new WXAdsPlatform();
			}
			return WXAdsPlatform._inst;
		}

		public constructor() {
			this._isAdsReaddy = false;
			this._errCode2Msg = {};
			this._errCode2Msg[0] = "微信平台广告次数已达上限";
			this._errCode2Msg[1000] = "后端接口调用失败";
			this._errCode2Msg[1001] = "参数错误";
			this._errCode2Msg[1002] = "广告单元无效";
			this._errCode2Msg[1003] = "内部错误";
			this._errCode2Msg[1004] = "无合适的广告";
			this._errCode2Msg[1005] = "广告组件审核中";
			this._errCode2Msg[1006] = "广告组件被驳回";
			this._errCode2Msg[1007] = "广告组件被封禁";
			this._errCode2Msg[1008] = "广告单元已关闭";
			// console.log("check system info: ", info);
			this._watchAdsResolve = null;
		}

		public async init() {
			let info = wx.getSystemInfoSync();
			if (info.SDKVersion >= "2.0.4") {
				this._adUnitId = WXGame.WXGameMgr.inst.wxConfig.adUnitId;
				this._rewardedVideoAd = wx.createRewardedVideoAd({adUnitId:this._adUnitId});
				this._rewardedVideoAd.onLoad(() => {
					// console.log("++++ ads load success");
					this._isAdsReaddy = true;
				});
				this._rewardedVideoAd.onError(res => {
					// console.log("++++ ads load fail: ", res.errCode, res.errMsg);
					this._lastErrCode = res.errCode;
					this._isAdsReaddy = false;
				});
				this._rewardedVideoAd.onClose(res => {
					// console.log("++++ ads closed: ", res);
					if (this._watchAdsResolve) {
						if (info.SDKVersion < "2.1.0") {
							this._onEndAds(true);
							this._watchAdsResolve(true);
						} else {
							this._onEndAds(res.isEnded);
							this._watchAdsResolve(res.isEnded);
						}
						this._watchAdsResolve = null;
					}
				});
			}
		}

		public isAdsOpen(): boolean {
			if (Player.inst.isNewVersionPlayer()) {
				return false;
			}
			return true;
		}

		public async isAdsReady(): Promise<{success: boolean, reason: string}> {
			if (!this._isAdsReaddy && this._rewardedVideoAd) {
				this._rewardedVideoAd.load();
			}
			if (this._isAdsReaddy) {
				return {success: true, reason:""};
			} else {
				let msg = this._errCode2Msg[this._lastErrCode];
				if (msg) {
					return {success: false, reason:msg};
				} else {
					return {success: false, reason:"视频广告还未准备好，请稍后再试"};
				}
			}
		}

		private _onBeginAds() {
			Home.HomeMgr.inst.stopBgSound(false);
			// SoundMgr.inst.muteMusic(true);
			Net.rpcPush(pb.MessageID.C2S_WATCH_ADS_BEGIN, null);
			this._isAdsReaddy = false;
		}

		private _onEndAds(isEnd: boolean) {
			Home.HomeMgr.inst.playBgSound();
			// SoundMgr.inst.muteMusic(false);
			if (isEnd) {
				Net.rpcPush(pb.MessageID.C2S_WATCH_ADS_END, null);
			}
		}

		public async showRewardAds() {
			this._onBeginAds();
			return new Promise<boolean>((resolve) => {
				this._rewardedVideoAd.show().then(() => {
					// console.log("++++ ads show success");
					this._watchAdsResolve = resolve;
				}).catch(err => {
					// console.log("++++ ads show fail");
					this._rewardedVideoAd.load().then(() => {
						this._rewardedVideoAd.show();
						// console.log("++++ ads show success2");
						this._watchAdsResolve = resolve;
					}).catch(err1 => {
						// console.log("++++ ads show fail2");
						this._onEndAds(false);
						resolve(false);
					});
				});
			});
		}

		public async showBannerAds() {
			return false;
		}
	}
}