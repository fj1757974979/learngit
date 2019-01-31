//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (c) 2014-present, Egret Technology.
//  All rights reserved.
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the Egret nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY EGRET AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL EGRET AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;LOSS OF USE, DATA,
//  OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//////////////////////////////////////////////////////////////////////////////////////


class Main extends egret.DisplayObjectContainer {

    private _loadingView: LoadingView;

    public constructor() {
        super();
        egret.MainContext.instance.stage.maxTouches = 2;
        this.addEventListener(egret.Event.ADDED_TO_STAGE, this.onAddToStage, this);
        Core.NativeMsgCenter.inst.addListener(Core.NativeMessage.ON_START, () => {
            console.log("native onStart");
            egret.lifecycle.onResume();
        }, null);
        Core.NativeMsgCenter.inst.addListener(Core.NativeMessage.ON_STOP, () => {
            console.log("native onStop");
            egret.lifecycle.onPause();
        }, null);
        Core.NativeMsgCenter.inst.addListener(Core.NativeMessage.USE_NATIVE_SOUND, () => {
            window.support.nativeSound = true;
            console.log("native useNativeSound");
            fairygui.GRoot.inst.playSoundAsync = function(name:string, volumeScale: number = 1) {
                let vs: number = this._volumeScale * volumeScale;
                NativeSoundApi.playSound(name, vs);
            }
        }, null);
        Core.NativeMsgCenter.inst.addListener(Core.NativeMessage.SET_SUPPORT_RECORD, (ret) => {
            window.support.record = ret.support;
            window.support.topMargin = ret.topMargin;
            window.support.bottomMargin = ret.bottomMargin;
        }, null);
        Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.USE_NATIVE_SOUND);
        Core.NativeMsgCenter.inst.addListener(Core.NativeMessage.GET_TD_CHANNEL_ID, (ret) => {
            window.gameGlobal.tdChannel = ret.tdChannelID;
            // 使用native版本的td
            if (ret.native) {
                TD.initNativeTD();
            }
            console.log("tdChannel " + window.gameGlobal.tdChannel + " " + ret.native);
        }, null);
        Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.GET_TD_CHANNEL_ID);
    }

    private onAddToStage(event: egret.Event) {
        console.log("runGame");

        egret.lifecycle.addLifecycleListener((context) => {
            // custom lifecycle plugin

            context.onUpdate = () => {

            }
        })

        egret.lifecycle.onPause = () => {
            TD.onPageLeave();
            Home.HomeMgr.inst.stopBgSound(false);
            console.log("game onPause");
        }

        egret.lifecycle.onResume = () => {
            TD.Account();
            SoundMgr.inst.playSoundAsync("click_mp3", 0.01);
            Home.HomeMgr.inst.playBgSound();
            SoundMgr.inst.cleanSoundTimerRecords();
            console.log("game onResume");
        }

        if (Core.DeviceUtils.isWXGame()) {
            RES.setMaxLoadingThread(8);
        } else {
            RES.setMaxLoadingThread(8);
        }
        RES.setMaxRetryTimes(8);
        //egret.registerFontMapping("AaKaiTi", "fonts/AaKaiTi.ttf");
        if (!window.gameGlobal.isMultiLan) {
            egret.TextField.default_fontFamily = "AaKaiTi";
        }
        this.runGame();//.catch(e => {
        //     console.log(e);
        // });
    }

    private _cleanText(container: egret.DisplayObjectContainer) {
        const children = container.$children;
        const length = children.length;
        for (let i = 0; i < length; ++i) {
            const child = children[i];
            if (child.$children && child.$children.length) {
                this._cleanText(<egret.DisplayObjectContainer>child);
            }
            else if (child.$renderNode) {
                let textNode: egret.sys.TextNode;
                if (child.$renderNode instanceof egret.sys.TextNode) {
                    textNode = child.$renderNode;
                }
                else if (child.$renderNode instanceof egret.sys.GroupNode && child.$renderNode.drawData[0] instanceof egret.sys.TextNode) {
                    textNode = child.$renderNode.drawData[0];
                }
                if (textNode) {
                    textNode.clean();
                }
            }
        }
    }

    private refreshTextRender() {
        if (Core.DeviceUtils.isWXGame()) {
            wx.triggerGC();
            console.log("triggerGC");
        }
    }

    private async runGame() {
        if (window.gameGlobal.isPC) {
            Core.UIConfig.defaultFontSize = 40;
            this.stage.orientation = egret.OrientationMode.LANDSCAPE;
        } else if (Core.DeviceUtils.isMobile() || Core.DeviceUtils.isWXGame()) {
            this.stage.orientation = egret.OrientationMode.PORTRAIT;
        }

        if (!window.support.bottomMargin) window.support.bottomMargin = 0;
        if (!window.support.topMargin) window.support.topMargin = 0;

        if (Core.DeviceUtils.isWXGame()) {
            await this.loadResourceWX();
        } else {
            await this.loadResource();
        }

        fairygui.GTextField.textLocaler = (id: number) => {
            return Core.StringUtils.TEXT(id);
        }

        genPlatformProxy();
        genAdsPlatformProxy();

        await this.createGameScene();
    }

    private loadJson() {
        console.log("loadJson");
        let textRegx = /#TEXT_(\d+)/g;
        class xlsdata {
            private _data:any;
            private _keys:any[];
            constructor(name:string) {
                this._data = RES.getRes(name);
                this._keys = [];
                if (!this._data) {
                    console.error(`loading json ${name} failed`);
                    return;
                }

                for (let key in this._data) {
                    if (isNaN(Number(key))) {
                        this._keys.push(key);
                    } else {
                        this._keys.push(Number(key));
                    }
                }
            }
            public get(id:string | number) {
                //if (!id) return null;
                id = id.toString()
                let info = this._data[id];
                if (info && !info.__ischecked__) {
                    for (let key in info) {
                        let val = info[key];
                        if (typeof val === "string" && val.match(textRegx)) {
                            info[key] = val.replace(textRegx, function (match, text):string {
                                return Core.StringUtils.TEXT(parseInt(text));
                            });
                        } else if (typeof val === "object") {
                            let arr = []
                            for (let k in val) {
                                let v = val[k]
                                if (typeof v === "string" && v.match(textRegx)) {
                                    arr[k] = v.replace(textRegx, function (match, text):string {
                                        return Core.StringUtils.TEXT(parseInt(text));
                                    });
                                } else {
                                    arr[k] = v;
                                }
                            }
                            info[key] = arr;
                        }
                    }
                    info.__ischecked__ = true;
                    this._data[id] = info;
                }
                return info;
            }
            public get keys():any[] {
                return this._keys;
            }
        }
        let clses = RES.getRes("start_json");
        window.Data = {}
        console.log(`${clses}`);
        for (let cls of clses) {
            ((mod) => {
                mod[cls] = new xlsdata(cls + "_json");
            })(Data);
        }
        Core.StringUtils.textGameData = Data.text;
        Core.StringUtils.textGameData2 = Data.text2;
        console.log("loadJson done");
        console.log(`${Data.rank.get(5).title}`);
    }

    private async loadJSScript(reporter?:RES.PromiseTaskReporter) {
        var count = 0;
        var total = 0;
        window.Data = {}
        var global = {
            "window": window,
            "Core": Core,
            "Data": Data,
            "dofile_async": null
        }
        var loadContent = {}
        var textLoaded = false;
        var textLoaded2 = false;
        var resolve;
        var load_config_js = function (path) {
            total++;
            console.log(`loading ${path} ${count}`);
            RES.getResAsync(path).then(value => {
                count++;
                console.log(`loading ${path} done ${count}`);
                if (path == "text_json" || path == "text2_json" || path == "start_json" || (textLoaded && textLoaded2)) {
                    //console.log(`execute ${path} done ${value}`);
                    jsjs.run(value, global);
                    console.log(`execute ${path} done`);
                    if (path == "text_json") {
                        textLoaded = true;
                    }
                    if (path == "text2_json") {
                        textLoaded2 = true;
                    }
                } else {
                    loadContent[path] = value;
                }

                if (count == total && path != "start_json") {
                    for (var key in loadContent) {
                        jsjs.run(loadContent[key], global);
                        console.log(`execute ${key} done`);
                    }
                    loadContent = null;
                    resolve();
                    resolve = null;
                }
                if (reporter) reporter.onProgress(count, total < 5 ? 100 : total, null);
            }).catch(reason => {
                console.log(`loading ${path} error:${reason}`);
                fairygui.GTimers.inst.callDelay(50, () => {
                    load_config_js(path);
                }, this, null);
            });
        }

        global.dofile_async = load_config_js;
        let p = new Promise<void>(resol => {
            resolve = resol;
            //Core.WordFilter.inst.registerWords([]);
            load_config_js("start_json");
        });
        await p;
    }

    private async loadDefaultConfig() {
        while (true) {
            try {
                let resConfigPath = "resource/default.res.json?v=";
                let resDir = "resource/";
                if (window.gameGlobal.isPC) {
                    resConfigPath = "resource_pc/default.res.json?v=";
                    resDir = "resource_pc/"
                } else if (window.gameGlobal.isMultiLan) {
                    if (window.gameGlobal.isFbAdvert) {
                        let language = navigator.language;
                        LanguageMgr.inst.initLocale("hk", language);
                    } else if (Core.DeviceUtils.isMobile()) {
                        let ret = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(Core.NativeMessage.GET_LOCALE, Core.NativeMessage.GET_LOCALE);
                        let country = ret["country"];
                        let language = ret["language"];
                        LanguageMgr.inst.initLocale(country, language);
                    } else {
                        LanguageMgr.inst.initLocale("hk", "zh-Hant-HK");
                    }

                    LanguageMgr.inst.initTextField();

                    resConfigPath = `${resDir}/default.res.${LanguageMgr.inst.cur}.json?v=`;
                }
                if (!Core.DeviceUtils.isWXGame()) {
                    await RES.loadConfig(resConfigPath + window.gameGlobal.version, resDir);
                } else {
                    let url = `${WXGame.WXGameMgr.getWebClientHost()}/resource/`;
                    console.log(url);
                    //await RES.loadConfig("default.res.json?v=" + Math.random(), url);
                    // 改成从本地loading
                    await RES.loadConfig("default.res.json", url);
                    // 把urlroot设置成网络的
                    window.gameGlobal.version = RES.config.getResourceVersion();
                    console.log("++++++++ set resource version: ", window.gameGlobal.version);
                    if (!WXGame.WXGroupLoader.inst.isNewbieLoader) {
                        // 第一次加载的玩家不加载字体
                        loadWXFont(url + "fonts/AaKaiTi.ttf", () => {
                                this._cleanText(this.stage);
                        });
                    } else {
                        fairygui.GTimers.inst.callDelay(1000 * 30, () => {
                            loadWXFont(url + "fonts/AaKaiTi.ttf", () => {
                                this._cleanText(this.stage);
                            });
                        }, this);
                    }
                    
                    fairygui.GTimers.inst.callDelay(1000 * 60 *5, async () =>{
                        while (true) {
                            this._cleanText(this.stage);
                            // 小游戏每5分钟刷新一次文字，因为会偶尔出现文字显示异常现象
                            await fairygui.GTimers.inst.waitTime(1000 * 60 * 5);
                        }
                    }, this);
                }
                return;
            } catch (e) {
                console.log("load default resource config fail, waiting retry");
                await fairygui.GTimers.inst.waitTime(100);
                continue;
            }
        }
    }

    private async loadResourceWX() {
         try {
            let t1 = new Date().getTime();
            await WXGame.initLoaders();
            Core.LayerManager.setDesignSize(this.stage.stageWidth, this.stage.stageHeight);

            WXGame.WXGameMgr.prepareLogin();
            WXGame.WXGameMgr.inst.initLaunchOptEvent();
            await platform.init();
            await Promise.all([
                platform.login(),
                WXGame.WXGroupLoader.inst.loadZip("init_wx.zip", null, null),
            ]);
            // await platform.login();
            // 加载一个初始包
            // await WXGame.WXGroupLoader.inst.loadZip("init_wx.zip", null, null);

            let t2 = new Date().getTime();
            await this.loadDefaultConfig();
            console.log("download init_wx.zip success");

            await RES.loadGroup("init_wx", 0).catch(reason => {
                 console.log(reason);
            });

            console.log("load init_wx success");
            let t3 = new Date().getTime();
            
            fairygui.GTimers.inst.add(60000, -1, this.refreshTextRender, this);
            Core.init();
            fairygui.UIPackage.addPackage(PkgName.loading);
            fairygui.UIObjectFactory.setPackageItemExtension(fairygui.UIPackage.getItemURL(PkgName.loading, "loadingProgressBar"), UI.MaskProgressBar);
            this._loadingView = fairygui.UIPackage.createObject(PkgName.loading, ViewName.loading, LoadingView) as LoadingView;
            this._loadingView.initUI();
            this._loadingView.addToParent();

            WXGame.WXGameMgr.afterLogin();
            
            let act = WXGame.WXShareType.SHARE_GAME;
            let shareId = 18;
            let imageUrl = `${WXGame.WXGameMgr.getWebClientHost()}/resource/king_ui/assets/society/shareVideo2.png?${Date.now()}`;
            let query = WXGame.WXGameMgr.inst.getBaseWXShareQuery() + `&act=${act}&shareId=${shareId}`;
            window.sharePlatform.enableShareMenu(true, "九格棋盘，重拾童年欢乐！", imageUrl, query);
            
            Core.loadTD();

            console.log("download zip");
            let jsRepoter = new LoadingReporter(this._loadingView, "loadjs");
            if (WXGame.WXGroupLoader.inst.isNewbieLoader) {
                await Promise.all([
                    WXGame.WXGroupLoader.inst.loadGroup("preload_wx",
                        new LoadingReporter(this._loadingView, "preload_wx.zip"),
                        new LoadingReporter(this._loadingView, "preload_wx")),
                    (async () => {
                        await WXGame.WXGroupLoader.inst.loadZip("json_wx.zip", new LoadingReporter(this._loadingView, "json_wx.zip"), true);
                        await RES.loadGroup("json_wx", 0, jsRepoter);
                        //await this.loadJSScript(jsRepoter);
                        await this.loadJson();
                    })(),
                    WXGame.WXGroupLoader.inst.loadZip("guide_fight_wx.zip",
                        new LoadingReporter(this._loadingView, "guide_fight_wx.zip"), true),
                        //new LoadingReporter(this._loadingView, "guide_fight_wx")),
                    WXGame.WXGroupLoader.inst.loadZip("fight_effect_wx.zip",
                        new LoadingReporter(this._loadingView, "fight_effect_wx.zip"), true)]);
                        //new LoadingReporter(this._loadingView, "fight_effect_wx"))]);
            }
            console.log("download zip success");

            let t4 = new Date().getTime();
            // 加载脚本和加载preload同时执行
            if (WXGame.WXGroupLoader.inst.isNewbieLoader) {
                //await this.loadJSScript(jsRepoter);
            } else {
                //await RES.loadGroup("json_wx", 0, jsRepoter);
                //console.log("load json_wx success");
                await Promise.all([RES.loadGroup("json_wx", 0, jsRepoter),
                    RES.loadGroup("preload", 0, new LoadingReporter(this._loadingView, "preload"))]);
                console.log("load preload success");
                this.loadJson();
            }

            let t5 = new Date().getTime();
            console.log(`loading time: init=${t2-t1} loading=${t3-t2} json,preload=${t4-t3} execute=${t5-t4} total=${t5-t1}`);
        }
        catch (e) {
            console.error(e);
        }
    }

    private async loadResource() {
        try {
            await this.loadDefaultConfig();
            await RES.loadGroup("loading", 0).catch(reason => {
                 egret.log(reason);
            });
            this.stage.scaleMode = egret.StageScaleMode.NO_SCALE;
            if (window.gameGlobal.isPC) {
                Core.LayerManager.setDesignSize(1920, 1080);
            } else {
                Core.LayerManager.setDesignSize(480, 800);
            }
            Core.init();
            fairygui.UIPackage.addPackage(PkgName.loading);
            fairygui.UIObjectFactory.setPackageItemExtension(fairygui.UIPackage.getItemURL(PkgName.loading, "loadingProgressBar"), UI.MaskProgressBar);
            this._loadingView = fairygui.UIPackage.createObject(PkgName.loading, ViewName.loading, LoadingView) as LoadingView;
            this._loadingView.initUI();
            this._loadingView.addToParent();

            if (!IOS_EXAMINE_VERSION) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.ON_SHOW_LOADING);
            }

            Core.loadTD();
            // 加载脚本和加载preload同时执行
            await Promise.all([RES.loadGroup("json_wx", 0, new LoadingReporter(this._loadingView, "json_wx")),
                RES.loadGroup("preload", 0, new LoadingReporter(this._loadingView, "preload"))]);
            this.loadJson()
        }
        catch (e) {
            console.error(e);
        }
    }

    /**
     * 创建游戏场景
     * Create a game scene
     */
    private async createGameScene() {

        let t1 = new Date().getTime();
        UI.setPackageItemExtension();
        let netWaitPanel = fairygui.UIPackage.createObject(PkgName.loading, "netWaiting", Core.WaitPanel) as Core.WaitPanel;
        let alertPanel = fairygui.UIPackage.createObject(PkgName.common, "alertPanel", Core.AlertPanel) as Core.AlertPanel;
        let confirmPanel = fairygui.UIPackage.createObject(PkgName.common, "confirmPanel", Core.ConfirmPanel) as Core.ConfirmPanel;
        let privShowPanel = fairygui.UIPackage.createObject(PkgName.common, "PrivShowPanel", Core.PrivShowPanel) as Core.PrivShowPanel;
        let flagPanel = fairygui.UIPackage.createObject(PkgName.common, "winFlagAni", Core.FlagShowPanel) as Core.FlagShowPanel;

        Core.MaskUtils.registerNetMask(netWaitPanel);
        Core.TipsUtils.registerAlertPanel(alertPanel);
        Core.TipsUtils.registerConfirmPanel(confirmPanel);
        Core.TipsUtils.registerPrivPanel(privShowPanel);
        Core.TipsUtils.registerFlagPanel(flagPanel);

        Core.TipsUtils.newTipsCom = function (): Core.ITipsCom {
            return fairygui.UIPackage.createObject(PkgName.common, "tips", UI.TipsCom) as Core.ITipsCom;
        }

        let [isMaintain, message] = Net.SConn.inst.isMaintain();
        if (isMaintain) {
            if (!message || message == "") {
                message = Core.StringUtils.TEXT(60243);
            } else {
                let text = parseInt(message);
                if (!isNaN(text)) {
                    message = Core.StringUtils.TEXT(text);
                }
            }
            Core.TipsUtils.alert(message);
            return;
        }

        //this._loadingView.setText("createGameScene1");
        let t2 = new Date().getTime();
        Guide.init();
        Home.init();
        Level.init();
        Battle.init();
        CardPool.init();
        Pvp.init();
        Treasure.init();
        Social.init();
        Shop.init();
        TD.init();
        Quest.init();
        Equip.init();
        War.init();
        Huodong.init();
        //this._loadingView.setText("createGameScene2");

        let t3 = new Date().getTime();
        if (Core.DeviceUtils.isWXGame()) {
            WXGame.init();
        } else {
            //Core.ViewManager.inst.createAllView();
        }

        let homePromise = null;
        if (Core.DeviceUtils.isWXGame() && WXGame.WXGroupLoader.inst.isNewbieLoader) {
        } else {
            this._loadingView.clear();
            homePromise = Promise.all([
                RES.loadGroup("common",0, new LoadingReporter(this._loadingView, "common")),
                RES.loadGroup("card",0, new LoadingReporter(this._loadingView, "card"))
                ]);
        }

        //this._loadingView.setText("createGameScene3");

        this._loadingView.hideProgress(true);
        if (!Core.DeviceUtils.isWXGame()) {
            await platform.init();
            await Net.SConn.inst.connectServer();
            await Home.HomeMgr.inst.enterLogin(this._loadingView);
            // Core.ViewManager.inst.createAllView();
        } else {
            // await platform.init();
            // await platform.login();
            await Net.SConn.inst.connectServer();
            await Home.HomeMgr.inst.enterLogin(this._loadingView);

            //WXGame.WXGameMgr.inst.showConnectView(false);
            this._loadingView.hideProgress(false);
            this._loadingView.clear();
            if (Core.DeviceUtils.isWXGame() && WXGame.WXGroupLoader.inst.isNewbieLoader) {
                await Promise.all([
                    RES.loadGroup("fight_effect_wx", 0, new LoadingReporter(this._loadingView, "fight_effect_wx")),
                    RES.loadGroup("guide_fight_wx", 0, new LoadingReporter(this._loadingView, "guide_fight_wx"))]);
            }
            this._loadingView.hideProgress(true);
            Core.ViewManager.inst.close(ViewName.login);
        }

        //this._loadingView.setText("createGameScene42");
        let t4 = new Date().getTime();
        let t5 = new Date().getTime();
        await sharePlatform.init();
        await adsPlatform.init();
        //this._loadingView.setText("createGameScene43");

        Payment.init();

        let checkNewbieGuideHomePromise = null;
        let needNewbieGuideHome = Home.HomeMgr.inst.needNewbieGuideHome();
        if (window.gameGlobal.isSDKLogin && !GameAccount.inst.isAccountLogin) {
            // 检测新手，出选阵营界面
            this._loadingView.visible = false;
            Core.ViewManager.inst.close(ViewName.login);
            checkNewbieGuideHomePromise = Home.HomeMgr.inst.checkNewbieGuideHome();
            this._loadingView.visible = true;
        }

        if (needNewbieGuideHome && checkNewbieGuideHomePromise) {
            await checkNewbieGuideHomePromise;
        }

        if (window.gameGlobal.isSDKLogin && !GameAccount.inst.isAccountLogin) {
            if (Core.DeviceUtils.isWXGame()) {
                //WXGame.WXGameMgr.inst.showConnectView(true);
            }
            await Home.HomeMgr.inst.onLoginDone();
            if (Core.DeviceUtils.isWXGame()) {
                //WXGame.WXGameMgr.inst.showConnectView(false);
            }
        }
        if (Core.DeviceUtils.isWXGame()) {
            WXGame.WXGameMgr.inst.tryHandleLaunchOptions();
        }

        //this._loadingView.setText("createGameScene5");

        //this._loadingView.setText("createGameScene6");
        this._loadingView.removeFromParent();
        this._loadingView.destroy();
        this._loadingView = null;

        await homePromise;
        
        let t6 = new Date().getTime();

        console.log(`createScene: ${t6-t1} = ${t2-t1} + ${t3-t2} + ${t4 - t3} + ${t5 - t4} + ${t6 - t5}`);
    }
}
