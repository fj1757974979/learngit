
class Fire2333Platform implements Platform {
    private static _inst: Fire2333Platform;
    private _sdk: any;
    private _game_id: string;
    private _app_id: string;
    private _game_key: string;
    private _timestamp: string;
    private _nonce: string;
    private _ticket: string;
    private _signature: string;
    private _login_type: string;
    private _readyPromise: Promise<void>;
    private _loginPromise: Promise<any>;
    private _userInfo: any;

    constructor() {
        //if (!this._sdk && window["xdGame"]) {
        if (!this._sdk) {
            this._game_id = Core.HttpUtils.getQueryVariable("game_id");
            this._app_id = Core.HttpUtils.getQueryVariable("app_id");
            this._game_key = Core.HttpUtils.getQueryVariable("game_key");
            this._timestamp = Core.HttpUtils.getQueryVariable("timestamp");
            this._nonce = Core.HttpUtils.getQueryVariable("nonce");
            this._ticket = Core.HttpUtils.getQueryVariable("ticket");
            this._signature = Core.HttpUtils.getQueryVariable("signature");
            this._login_type = Core.HttpUtils.getQueryVariable("login_type");

            //this._sdk = new window["xdGame"]({
            //        "game_id": this._game_id,
            //        "app_id": this._app_id,
            //        "game_key": this._game_key
            //});

            //this._readyPromise = new Promise<void>(resolve => {
            //    this._sdk.ready(function(){
            //        resolve();
            //        this._readyPromise = null;
            //        console.debug('fire2333 finish init');
            //    });
            //});
        }
    }

    public static get inst(): Fire2333Platform {
        if (!Fire2333Platform._inst) {
            Fire2333Platform._inst = new Fire2333Platform();
        }
        return Fire2333Platform._inst;
    }

    async init() {
        
    }

    async getUserInfo() {
        if (this._readyPromise) {
            await this._readyPromise;
        }
        if (this._loginPromise) {
            await this._loginPromise;
        }
        return this._userInfo;
    }

    async login(args?: any) {
        let params = new Collection.Dictionary<string, string>();
        params.setValue("game_id", this._game_id);
        params.setValue("app_id", this._app_id);
        params.setValue("game_key", this._game_key);
        params.setValue("timestamp", this._timestamp);
        params.setValue("nonce", this._nonce);
        params.setValue("ticket", this._ticket);
        params.setValue("signature", this._signature);
        params.setValue("login_type", this._login_type);
        this._loginPromise = Core.HttpUtils.post(document.location.protocol + 
            "//game.fire2333.com/user/getticketuserinfo", params);
        let reply: any;
        try {
            reply = await this._loginPromise;
            this._loginPromise = null;
        } catch(e) {
            this._loginPromise = null;
            console.error("Fire2333Platform login error", e);
            return;
        }

        if (!reply) {
            console.error("Fire2333Platform login error no reply");
            return;
        }

        let replyData = JSON.parse(reply);
        if (replyData.code != 0) {
            console.error("Fire2333Platform login error ", replyData);
            return;
        }

        console.debug("Fire2333Platform login ok", reply);
        this._userInfo = {};
        this._userInfo.channel_id = replyData.data.open_id;
    }

    canMakePay() {
        return false;
    }
    
    async pay(pid: string, price: number, count: number, isSDKPay?: boolean) {}
}
