// TypeScript file
class FacebookSharePlatform implements SharePlatform {

    private static _inst: FacebookSharePlatform = null;

	public static get inst(): FacebookSharePlatform {
		if (!FacebookSharePlatform._inst) {
			FacebookSharePlatform._inst = new FacebookSharePlatform();
		}
		return FacebookSharePlatform._inst;
	}

    public getShareType(): ShareType {
        return ShareType.SHARE_FACEBOOK;
    }

	public async init(): Promise<any> {

	}

    public async enableShareMenu(b: boolean, title: string, image: string, query: string): Promise<any> {

	}

    public async shareAppMsg(title: string, image: string, query: string): Promise<any> {
		let args = {
			title: title,
            link: image
		};
        let ret = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(Core.NativeMessage.SHARE_LINK, Core.NativeMessage.SHARE_LINK_COMPLETE, args);
        return ret.success;
	}

    public getShareLink(): string {
        if (Core.DeviceUtils.isAndroid()) {
            if (window.gameGlobal.channel == "lzd_handjoy") {
                return "https://play.google.com/store/apps/details?id=com.openew.game.lzd.handjoy";
            } else {
                // TODO
                return "";
            }
        } else if (Core.DeviceUtils.isiOS()) {
            // TODO
            if (window.gameGlobal.channel == "lzd_handjoy") {
                return "https://itunes.apple.com/cn/app/id1439678059?mt=8";
                // return "";
            } else {
                return "";
            }
        }
    }
}