// TypeScript file
module Core {
    export function callJS(message: string): void {
        console.log("callJS:" + message);
        let data = JSON.parse(message);
        let msg: NativeMessage = data.msg;
        let items = NativeMsgCenter.inst.getListeners(msg);
        if (items) {
            items.forEach((item, _) => {
                if (item.callback) {
                    if (item.thisArg) {
                        item.callback.apply(item.thisArg, [data.args]);
                    } else {
                        item.callback(data.args);
                    }
                    if (item.resolve) {
                        item.resolve(data.args);
                    }
                }
            });
        }
    }

    export class NativeMessage {
        public static INIT_SDK = "initSDK";
        public static INIT_SDK_DONE = "initSDKDone";
        public static LOGIN = "login";
        public static LOGIN_DONE = "loginDone";
        public static ON_START = "onStart";
        public static ON_STOP = "onStop";
        public static USE_NATIVE_SOUND = "useNativeSound";
        public static PLAY_SOUND = "playSound";
        public static PLAY_MUSIC = "playMusic";
        public static STOP_MUSIC = "stopMusic";
        public static SET_MUSIC_VOLUME = "setMusicVolume";
        public static ON_ENTER_GAME = "onEnterGame";
        public static ON_CREATE_ROLE = "onCreateRole";
        public static ON_LEVEL_UP = "onLevelUp";
        public static GET_TD_CHANNEL_ID = "getTDChannelID";
        public static START_RECORD = "startRecord";
        public static STOP_RECORD = "stopRecord";
        public static START_RECORD_COMPLETE = "startRecordComplete";
        public static ADS_INIT = "initAds";
        public static ADS_SHOW_RWD = "showRwdAds";
        public static ADS_FINISH_RWD = "finishRwdAds";
        public static ADS_IS_READY = "adsIsReady";
        public static ADS_READY = "adsReady";
        public static ON_START_MATCH = "onStartMatch";
        public static SAVE_TO_PHOTO = "saveToPhoto";
        public static SHARE_VIDEO = "shareVideo";
        public static SHARE_LINK = "shareLink";
        public static SHARE_LINK_COMPLETE = "shareLinkComplete";
        public static INIT_APPSTORE_PAY = "initAppstorePay";
        public static APPSTORE_REQ_PRODUCTS = "appstoreRequestProducts";
        public static APPSTORE_GET_PRODUCTS = "appstoreGetProducts";
        public static START_PAY = "startPay";
        public static FINISH_PAY = "finishPay";
        public static SET_SUPPORT_RECORD = "setSupportRecord";
        public static OPEN_APP_COMMENT = "openAppComment";
        public static ON_SHOW_LOADING = "onShowLoading";
        public static SHARE_APP2WECHAT = "shareApp2Wechat";
        public static SHARE_APP2WECHATTIMELINE = "shareApp2Wechat";
        public static LOGIN_GAME_CENTER = "loginGameCenter";
        public static SCORE_TO_GAME_CENTER = "scoreToGameCenter";
        public static SHOW_GAME_CENTER_RANK = "showGameCenterRank";
        public static CREATE_NOTIFY = "createNotify";
        public static REMOVE_NOTIFY = "removeNotify";
        public static SET_LOADING_PERCENT = "setLoadingPercent";
        public static GOOGLEPLAY_REQ_PRODUCTS = "googleplayReqProducts";
        public static GOOGLEPLAY_GET_PRODUCTS = "googleplayGetProducts";

        // talkingdata native 接口
        public static TD_ACCOUNT = "td_Account";
        public static TD_ONPAGELEAVE = "td_onPageLeave";
        public static TD_ONMISSIONBEGIN = "td_onMissionBegin";
        public static TD_ONMISSIONCOMPLETED = "td_onMissionCompleted";
        public static TD_ONMISSIONFAILED = "td_onMissionFailed";
        public static TD_ONITEMPURCHASE = "td_onItemPurchase";
        public static TD_ONITEMUSE = "td_onItemUse";
        public static TD_ONEVENT = "td_onEvent";
        public static TD_SETLEVEL = "td_setLevel";

        public static GET_LOCALE = "getLocale";
        public static APPSTORE_CHECK_VERSION = "appStoreCheckVersion";
    }

    export class ListenerItem {
        public callback: (args: any) => void;
        public thisArg: any;
        public resolve: (value? :void|PromiseLike<void>) => void;
    }

    export class NativeMsgCenter {

        private static _inst: NativeMsgCenter = null;
        private _listeners: Collection.Dictionary<NativeMessage, Collection.Dictionary<ListenerItem, boolean>>;

        public static get inst(): NativeMsgCenter {
            if (!NativeMsgCenter._inst) {
                NativeMsgCenter._inst = new NativeMsgCenter();
            }
            return NativeMsgCenter._inst;
        }

        public constructor() {
            this._listeners = new Collection.Dictionary<NativeMessage, Collection.Dictionary<ListenerItem, boolean>>();

            egret.ExternalInterface.addCallback("callJS", Core.callJS);
        }

        public getListeners(msg:NativeMessage) {
            return this._listeners.getValue(msg);
        }

        public addListener(name: NativeMessage, callback: (args: any)=>void, thisArg: any): ListenerItem {
            let item = new ListenerItem();
            item.callback = callback;
            item.thisArg = thisArg;
            item.resolve = null;
            if (!this._listeners.containsKey(name)) {
                this._listeners.setValue(name, new Collection.Dictionary<ListenerItem, boolean>());
            }
            let items = this._listeners.getValue(name);
            items.setValue(item, true);
            return item;
        }

        public removeListener(name: NativeMessage, callback: (args: any)=>void, thisArg: any) {
            let items = this._listeners.getValue(name);
            if (items) {
                let dels = Array<ListenerItem>();
                items.forEach((item, _) => {
                    if (item.callback == callback && item.thisArg == thisArg) {
                        dels.push(item);
                    }
                });
                dels.forEach(item => {
                    items.remove(item);
                });
            }
        }

        public callNative(name: NativeMessage, args: any = {}) {
            let callArgs = {
                "msg": name,
                "args": args
            }
            let message = JSON.stringify(callArgs);
            egret.ExternalInterface.call("callNative", message);
            try {
                if (callNative != null) {
                    callNative(message);
                }
            } catch (e) {
                console.error("callNative error ", e);
            }
        }

        private _waitMessageCallback(arg: any) {

        }

        public async sendAndWaitNativeMessage(sendName: NativeMessage, waitName: NativeMessage, args?:any) {
            let listener = this.addListener(waitName, this._waitMessageCallback, this);
            let ret =  await new Promise<any>(resolve => {
                listener.resolve = resolve;
                this.callNative(sendName, args);
            });
            this.removeListener(waitName, this._waitMessageCallback, this);
            return ret;
        }
    }
}
