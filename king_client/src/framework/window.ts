/** 
 * 平台数据接口。
 * 由于每款游戏通常需要发布到多个平台上，所以提取出一个统一的接口用于开发者获取平台数据信息
 * 推荐开发者通过这种方式封装平台逻辑，以保证整体结构的稳定
 * 由于不同平台的接口形式各有不同，白鹭推荐开发者将所有接口封装为基于 Promise 的异步形式
 */
declare interface Platform {
    init(): Promise<any>;
    getUserInfo(): Promise<any>;
    login(args?: any): Promise<any>;
    canMakePay(): boolean;
    pay(pid: string, price: number, count: number, isSDKPay?: boolean, desc?: string, orderId?: string, callbackUrl?: string): Promise<any>;
}

declare interface AdvertisePlatform {
    init(): Promise<any>;
    isAdsOpen(): boolean;
    isAdsReady(): Promise<{success: boolean, reason: string}>;
    showRewardAds(): Promise<any>;
    showBannerAds(): Promise<any>;
}

enum ShareType {
    SHARE_NONE = 0,
    SHARE_WECHAT = 1,
    SHARE_FACEBOOK = 2
}

declare interface SharePlatform {
    init(): Promise<any>;
    enableShareMenu(b: boolean, title: string, image: string, query: string): Promise<any>;
    shareAppMsg(title: string, image: string, query: string): Promise<any>;
    getShareType(): number;
    getShareLink(): string;
}

declare interface GameGlobal {
    debug: boolean
    channel: string
    tdChannel: string
    tdAppid: string
    isPC: boolean
    locale: string
    serverHost: string
    serverPort: number
    serverWssPort: number
    isSDKLogin: boolean
    isSDKPay: boolean
    version: string
    resPrefix: string
    logoUrl:string
    gameName:string
    isMultiLan:boolean
    isFbAdvert:boolean
}

declare interface DeviceSupport {
    record:boolean
    nativeSound:boolean
    topMargin:number
    bottomMargin:number
}

class DebugPlatform implements Platform {
    async getUserInfo() {
        return { nickName: "ERROR_USER" }
    }
    async login(args?: any) {}
    async init() {}
    canMakePay(): boolean {
        return false;
    }
    async pay(pid: string, price: number, count: number, isSDKPay?: boolean) {}
}

class DebugSharePlatform implements SharePlatform {
    async init() {}
    async enableShareMenu(b: boolean, title: string, image: string, query: string) {}
    async shareAppMsg(title: string, image: string, query: string){}
    getShareType(): ShareType {
        return ShareType.SHARE_NONE;
    }
    getShareLink(): string {
        return "";
    }
}

class DebugAdsPlatform implements AdvertisePlatform {
    async init() {}
    isAdsOpen(): boolean {return false;}
    async isAdsReady(): Promise<{success: boolean, reason: string}> {
        return {success: false, reason:Core.StringUtils.TEXT(60154)};
    }
    async showRewardAds() {}
    async showBannerAds() {}
}


if (!window.platform) {
    window.platform = new DebugPlatform();
}

if (!window.sharePlatform) {
    window.sharePlatform = new DebugSharePlatform();
}

if (!window.adsPlatform) {
    window.adsPlatform = new DebugAdsPlatform();
}

declare let platform: Platform;
declare let sharePlatform: SharePlatform;
declare let adsPlatform: AdvertisePlatform;

declare interface Window {
    platform: Platform
    sharePlatform: SharePlatform
    adsPlatform: AdvertisePlatform
    gameGlobal: GameGlobal
    Data:any
    support:DeviceSupport
}