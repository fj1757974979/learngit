
class LanguageMgr {
    
    private static _inst: LanguageMgr;

    private _default: string;
    private _cur: string;
    private _countryCode: string;
    private _supportedLanguage: {};

    public static get inst() {
        if(!this._inst) {
            this._inst = new LanguageMgr();
        }
        return this._inst;
    }

    public constructor() {
        this._countryCode = "cn";
        this._supportedLanguage = {};
        this._supportedLanguage["cn"] = "简体中文";
        this._supportedLanguage["tw"] = "繁體中文";
        this._supportedLanguage["en"] = "English";
        this._supportedLanguage["id"] = "Bahasa indonesia";
        this._supportedLanguage["th"] = "ไทย";
    }

    public get supportedLanguage(): any {
        return this._supportedLanguage;
    }

    public getLanguageDescription(lanCode: string): string {
        return this._supportedLanguage[lanCode];
    }

    private _filterLan(lan: string): string {
        if (this._supportedLanguage[lan]) {
            return lan;
        } else {
            return "en";
        }
    }

    public get default(): string {
        if (!this._default) {
            //语言初始化
            this._default = window.gameGlobal.locale;
        }
        return this._default;
    }

    public set cur(area: string) {
        area = this._filterLan(area);
        this._cur = area;
        egret.localStorage.setItem("curLanguage", area);
    }

    public get cur(): string {
        if (!this._cur) {
            let localCur = egret.localStorage.getItem("curLanguage");
            if (localCur) {
                this._cur = localCur;
            } else {
                this._cur = this.default;
            }  
        }
        return this._cur;
    }

    public isChineseLocale(): boolean {
        if (!window.gameGlobal.isMultiLan) {
            return true;
        }
        return this.cur == "cn" || this.cur == "tw";
    }

    public get countryCode(): string {
        return this._countryCode;
    }

    public get countryFlagCode(): string {
        let flagCode = egret.localStorage.getItem("flagCode");
        if (flagCode && flagCode != "") {
            return flagCode;
        } else {
            return this._countryCode;
        }
    }

    public async setCountryFlagImg(img: fairygui.GImage, country?: string) {
        if (!country) {
            country = this._countryCode;
        }
        let imgUrl = `flags_${country}_png`;
        await Utils.setImageUrlPicture(img, imgUrl);
    }

    public initTextField() {
        if (!this.isChineseLocale()) {
            fairygui.GTextField.wordWrap = true;
        }
    }

    public getCardItemTemplateName(): string {
        if (this.isChineseLocale()) {
            return "cardItem";
        } else {
            return "cardItem2";
        }
    }

    public initLocale(country: string, language: string) {
        if (Core.DeviceUtils.isWXGame()) {
            return;
        }
        if (!window.gameGlobal.isMultiLan) {
            return;
        }
        
        // 统一繁体
        // window.gameGlobal.locale = "tw";
        if (Core.DeviceUtils.isAndroid()) {
            this._countryCode = country.toLowerCase().substr(0, 2);
        } else {
            this._countryCode = country.toLowerCase();
        }
        // if (Core.DeviceUtils.isAndroid()) {
            let ctr = this._countryCode;
            if (ctr.indexOf("cn") >= 0) {
                window.gameGlobal.locale = "cn";
            } else {
                if (ctr.indexOf("hk") >= 0 || ctr.indexOf("tw") >= 0 || ctr.indexOf("mo") >= 0) {
                    window.gameGlobal.locale = "tw";
                } else {
                    // 非中文
                    // TODO
                    window.gameGlobal.locale = this._filterLan(ctr);
                    // window.gameGlobal.locale = ctr;
                }
            }
        // } else if (Core.DeviceUtils.isiOS()) {
        //     let lan = language.toLowerCase();
        //     if (lan.indexOf("zh") >= 0) {
        //         if (language.indexOf("yue") >= 0) {
        //             window.gameGlobal.locale = "tw"
        //         } else if (language == "zh-TW" || language == "zh-Hant-TW") {
        //             // 台湾
        //             window.gameGlobal.locale = "tw";
        //         } else if (language == "zh-HK" || language == "zh-Hant-HK") {
        //             // 香港
        //             window.gameGlobal.locale = "tw";
        //         } else if (language == "zh-MO" || language == "zh-Hant-MO") {
        //             // 澳门
        //             window.gameGlobal.locale = "tw";
        //         } else if (language == "zh-Hant-CN") {
        //             // 其他地区繁体
        //             window.gameGlobal.locale = "tw";
        //         } else if (language == "zh-Hans-CN") {
        //             // 简体中文
        //             window.gameGlobal.locale = "cn";
        //         } 
        //     } else {
        //         // 非中文
        //         // TODO
        //         // window.gameGlobal.locale = "cn";
        //         window.gameGlobal.locale = this._filterLan(language.split("-")[0].toLowerCase());
        //     }
        // }
        egret.log("initLocale: ", window.gameGlobal.locale);
        egret.log("country: ", this._countryCode);
    }
}
    