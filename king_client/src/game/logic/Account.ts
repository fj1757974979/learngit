
class GameAccount {
    private static _inst: GameAccount;

    private _accountName: string;
    private _archiveID:number;
    private _isTouristLogin: boolean;
    private _loginChannel: string;
    private _isAccountLogin: boolean = false;

    private _localAccountInfo: Collection.Dictionary<string, string>;

    public static get inst(): GameAccount {
        if (!GameAccount._inst) {
            GameAccount._inst = new GameAccount();
        }
        return GameAccount._inst;
    }

    public constructor() {
        this._localAccountInfo = new Collection.Dictionary<string, string>();
    }

    public get isAccountLogin(): boolean {
        return this._isAccountLogin;
    }

    public set isAccountLogin(b: boolean) {
        this._isAccountLogin = b;
    }

    public login(name:string, isTouristLogin: boolean, loginChannel: string) {
        this._accountName = name;
        this._isTouristLogin = isTouristLogin;
        this._loginChannel = loginChannel;
    }

    public loginPlayer(archiveID: number) {
        this._archiveID = archiveID;
    }

    public get accountName(): string {
        return this._accountName;
    }

    public get isTouristLogin(): boolean {
        return this._isTouristLogin;
    }

    public get loginChannel(): string {
        return this._loginChannel;
    }

    public get archiveID(): number {
        return this._archiveID;
    }

    public getPassword(account:string): string {
        let pwd = egret.localStorage.getItem(`pwd:${account}`);
        if (pwd) {
            return pwd;
        } else {
            return "";
        }
    }

    public md5hashPassword(pwd:string):string {
        return new md5().hex_md5("kc_1" + pwd);
    }

    public setPassword(account:string, pwd:string) {
        egret.localStorage.setItem(`pwd:${account}`, pwd);
    }

    public getLocalAccounts(): Array<{account: string, pwd: string}> {
        let info = egret.localStorage.getItem("accountInfo");
        if (!info || info == "") {
            return null;
        } else {
            let channel = window.gameGlobal.channel;
            let accountInfo = JSON.parse(info);
            if (!accountInfo[channel]) {
                return null;
            }
            let accountInfos: Array<{account: string, pwd: string}> = accountInfo[channel]["accounts"];
            if (accountInfos) {
                accountInfos.forEach(element => {
                    this._localAccountInfo.setValue(element.account, element.pwd);
                });
            }
            return accountInfos;
        }
    }

    public getRecentLocalAccount(): string {
        let info = egret.localStorage.getItem("accountInfo");
        if (!info || info == "") {
            return null;
        } else {
            let channel = window.gameGlobal.channel;
            let accountInfo = JSON.parse(info);
            if (!accountInfo[channel]) {
                return null;
            }
            return accountInfo[channel]["recentAccount"];
        }
    }

    public saveToLocalAccount(account: string, pwd: string) {
        let info = egret.localStorage.getItem("accountInfo");
        if (!info || info == "") {
            egret.localStorage.setItem("account", "{}");
            info = egret.localStorage.getItem("account");
        }
        let channel = window.gameGlobal.channel;
        let accountInfo = JSON.parse(info);
        if (!accountInfo[channel]) {
            accountInfo[channel] = {};
        }
        if (!accountInfo[channel]["accounts"]) {
            accountInfo[channel]["accounts"] = [];
        }
        if (!this._localAccountInfo.containsKey(account)) {
            this._localAccountInfo.setValue(account, pwd);
            accountInfo[channel]["accounts"].push({account: account, pwd: pwd});
        }
        accountInfo[channel]["recentAccount"] = account;
        egret.localStorage.setItem("accountInfo", JSON.stringify(accountInfo));
    }
}