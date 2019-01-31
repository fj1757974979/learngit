
class PkgSDKPlatform implements Platform {

	private static _inst: PkgSDKPlatform = null;
	private _userInfo: any;
	private _init: boolean;
	private _isLogin: boolean;

	public constructor() {
		this._userInfo = null;
		this._init = false;
		this._isLogin = false;
	}

	public static  get inst(): PkgSDKPlatform {
		if (!PkgSDKPlatform._inst) {
			PkgSDKPlatform._inst = new PkgSDKPlatform();
		}
		return PkgSDKPlatform._inst;
	}

	public async init() {
		
	}

	public async getUserInfo() {
		// if (this._userInfo) {
		// 	return this._userInfo;
		// } else {
		// 	await this.login();
		// 	return this._userInfo;
		// }
		return this._userInfo;
	}

    public async login(args?: any) {
		if (this._isLogin) {
			return;
		}
		if (this._userInfo) {
			return;
		}
		this._isLogin = true;
		Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.ON_SHOW_LOADING);
		let result = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(Core.NativeMessage.LOGIN, Core.NativeMessage.LOGIN_DONE, args);
		if (result.success) {
			// egret.log("pkgsdk login: ", JSON.stringify(result));
			let info = result.info;
			this._userInfo = {};
			/* info的格式：
			JSONObject obj = new JSONObject();
            obj.put("channelID", channelID);
            obj.put("channelUserID", channelUserID);
            obj.put("token", token);
            obj.put("channelUserName", channelUserName);
            obj.put("timeStamp", timeStamp);
            obj.put("userType", userType);
			*/
        	this._userInfo.channel_id = info.channelUserID;
			this._userInfo.account_login = info.accountLogin;
			this._userInfo.td_channel_id = info.tdChannelID;
			this._userInfo.token = info.token;
			this._userInfo.login_channel = info.loginChannel;
			// console.log("tdChannel " + info.tdChannelID);
            SoundMgr.inst.playSoundAsync("click_mp3", 0.01);
		} else {
			if (result.reason) {
				Core.TipsUtils.showTipsFromCenter(result.reason);
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60096));
			}
			this._userInfo = null;
		}
		this._isLogin = false;
	}

	public canMakePay(): boolean {
		return true;
	}

	public async pay(pid: string, price: number, count: number, isSDKPay?: boolean, desc?: string, orderId?: string) {
		let result = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(
			Core.NativeMessage.START_PAY, 
			Core.NativeMessage.FINISH_PAY, 
			{
				productId: pid,
				price: price,
				count: count,
				orderId: orderId,
				isSDKPay: isSDKPay
			}
		);
		return result;
	}
}

class PkgAdsPlatform implements AdvertisePlatform {
	private static _inst: PkgAdsPlatform = null;

	public static get inst(): PkgAdsPlatform {
		if (!PkgAdsPlatform._inst) {
			PkgAdsPlatform._inst = new PkgAdsPlatform();
		}
		return PkgAdsPlatform._inst;
	}

	public constructor() {
	}

	public async init() {
		Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.ADS_INIT);
	}

    public isAdsOpen(): boolean {
		if (Player.inst.isNewVersionPlayer()) {
			return false;
		}
		return true;
	}

	public async isAdsReady(): Promise<{success: boolean, reason: string}> {
		let result = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(Core.NativeMessage.ADS_IS_READY, Core.NativeMessage.ADS_READY);
		if (result.success) {
			return {success: true, reason: ""};
		} else {
			return {success: false, reason: Core.StringUtils.TEXT(60226)};
		}
	}

    public async showRewardAds() {
		SoundMgr.inst.muteMusic(true);
		Net.rpcCall(pb.MessageID.C2S_WATCH_ADS_BEGIN, null);
		let result = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(Core.NativeMessage.ADS_SHOW_RWD, Core.NativeMessage.ADS_FINISH_RWD);
		SoundMgr.inst.muteMusic(false);
		if (result.success) {
			Net.rpcCall(pb.MessageID.C2S_WATCH_ADS_END, null);
			return result.success;
		} else {
			Core.TipsUtils.showTipsFromCenter(result.reason);
			return false;
		}
	}

    public async showBannerAds() {
		return false;
	}
}