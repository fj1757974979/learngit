// TypeScript file
class FacebookJsPlatform implements Platform {

    private static _inst: FacebookJsPlatform;
    private _userInfo: any;
    private _readyPromise: Promise<void>;
    private _readyResolve: (value?: void | PromiseLike<void>) => void;

    public static get inst(): FacebookJsPlatform {
        if (!FacebookJsPlatform._inst) {
            FacebookJsPlatform._inst = new FacebookJsPlatform();
        }
        return FacebookJsPlatform._inst;
    }

    constructor() {
        this._userInfo = null;
        this._readyPromise = null;
    }

    public async init() {
        this._init();
    }

    private async _init() {
        this._readyPromise = new Promise<void>(resolve => {
            (<any>window).fbAsyncInit = () => {
                FB.init({
                    appId: '740714252962921',
                    cookie: true,
                    xfbml: true,
                    version: 'v3.2'
                });
                FB.AppEvents.logPageView();
                this._readyPromise = null;
                resolve();
            };

            (function(d, s, id) {
                var js, fjs = d.getElementsByTagName(s)[0];
                if (d.getElementById(id)) {return;};
                js = d.createElement(s); js.id = id;
                js.src = "https://connect.facebook.net/en_US/sdk.js";
                fjs.parentNode.insertBefore(js, fjs);
            }(document, 'script', 'facebook-jssdk'));
        });

        await this._readyPromise;
    }

    async getUserInfo() {
        return this._userInfo;
    }

    async login(args?: any) {
        if (this._readyPromise) {
            await this._readyPromise;
        }
        await new Promise<void>(resolve => {
            FB.login((response: fb.StatusResponse) => {
                if (response.status == "connected") {
                    let authResponse: fb.AuthResponse = response.authResponse;
                    this._userInfo = {};
                    this._userInfo.channel_id = authResponse.userID;
                    this._userInfo.account_login = false;
                    this._userInfo.td_channel_id = "lzd_handjoy_fbadvert";
                    this._userInfo.token = authResponse.accessToken;
                    this._userInfo.login_channel = "facebook";
                }
                resolve();
            });
        });
        
    }

    canMakePay() {
        return false;
    }

    async pay(pid: string, price: number, count: number, isSDKPay?: boolean) {}
}