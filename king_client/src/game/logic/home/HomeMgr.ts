module Home {
    let loginSwitch = true;
    export class HomeMgr {
        private static _inst: HomeMgr;

        private _lastLoginReply: pb.LoginReply;
        private _newbieChooseCamp: Camp;
        private _loginChannel: string;

        constructor() {
	        this.playBgSound();
            this._lastLoginReply = null;
            this._newbieChooseCamp = null;
        }

        public static get inst(): HomeMgr {
            if (!HomeMgr._inst) {
                HomeMgr._inst = new HomeMgr();
            }
            return HomeMgr._inst;
        }

        public playBgSound() {
            if (Battle.BattleMgr.inst.battle) {
            this.playFightBgSound();
            } else {
            this.playMainBgSound();
            }
        }
        public stopBgSound(fadeout:boolean = true) {
            SoundMgr.inst.stopBgMusic(fadeout);
        }

        public playMainBgSound() {
	        SoundMgr.inst.playBgMusic("bg_mp3");
        }

        public playFightBgSound() {
            SoundMgr.inst.playBgMusic("fightbg_mp3");
        }

        public checkVersion(version: pb.IVersion) {
            if (!window.gameGlobal.version || !version) {
                return;
            }
            let versionInfo = window.gameGlobal.version.split(".");
            if (versionInfo.length != 3) {
                return;
            }
            let v1 = parseInt(versionInfo[0]);
            let v2 = parseInt(versionInfo[1]);
            let v3 = parseInt(versionInfo[2]);
            if (version.V1 > v1) {
                Core.TipsUtils.alert(Core.StringUtils.TEXT(60222), ()=>{
                    if (!Core.DeviceUtils.isWXGame()) {
                        window.location.reload();
                    } else {
                        WXGame.WXGameMgr.inst.exitGame();
                    }
                }, this);
            } else if (version.V1 == v1) {
                if (version.V2 > v2 || (version.V2 == v2 && version.V3 > v3)) {
                    Core.TipsUtils.confirm(Core.StringUtils.TEXT(60222), ()=>{
                        if (!Core.DeviceUtils.isWXGame()) {
                            window.location.reload();
                        } else {
                            WXGame.WXGameMgr.inst.exitGame();
                        }
                    }, null, this);
                }
            }

            if (Core.DeviceUtils.isiOS() && Core.DeviceUtils.isMobile()) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.APPSTORE_CHECK_VERSION);
            }
        }

        public async onPlayerLogin(archiveID:number): Promise<number> {
            let accountType: pb.AccountTypeEnum = pb.AccountTypeEnum.UnknowAccountType;
            if (Core.DeviceUtils.isWXGame()) {
                if (WXGame.WXGameMgr.inst.platform == "android") {
                    accountType = pb.AccountTypeEnum.Wxgame;
                } else {
                    accountType = pb.AccountTypeEnum.WxgameIos;
                }
            } else if (Core.DeviceUtils.isAndroid()) {
                accountType = pb.AccountTypeEnum.Android;
            } else if (Core.DeviceUtils.isiOS()) {
                accountType = pb.AccountTypeEnum.Ios;
            } else {
                accountType = pb.AccountTypeEnum.Android;
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_LOGIN,
                pb.LoginArg.encode({
                    "Channel":window.gameGlobal.channel,
                    "ChannelID":GameAccount.inst.accountName,
                    "ArchiveID":archiveID,
                    "AccountType":accountType,
                    "IsTourist": GameAccount.inst.isTouristLogin,
                    "LoginChannel": GameAccount.inst.loginChannel,
                    "Country": LanguageMgr.inst.countryCode
                }));
            if (result.errcode == 1) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60155));
                return result.errcode;
            }
            if (result.errcode != 0) {
                return result.errcode;
            }

            let reply = pb.LoginReply.decode(result.payload);
            GameAccount.inst.loginPlayer(archiveID);
            Player.inst.accountType = accountType;
            await Player.inst.login(reply, GameAccount.inst.accountName);
            if (Core.DeviceUtils.isWXGame()) {
                WXGame.WXGameMgr.inst.isExamineVersion = !reply.IsExamined;
                let channelUserInfo = await platform.getUserInfo();
                await WXGame.WXGameMgr.inst.onLogin(channelUserInfo);
            }

            this._lastLoginReply = reply;


            return 0;
        }

        public needNewbieGuideHome(): boolean {
            let pvpScore = Player.inst.getResource(ResType.T_SCORE);
            return pvpScore <= 0 && Player.inst.guideCamp == 0;
        }

        public async checkNewbieGuideHome() {
            let pvpScore = Player.inst.getResource(ResType.T_SCORE);
            egret.log("checkNewbieGuideHome ", pvpScore, Player.inst.guideCamp);
            if (pvpScore <= 0 && Player.inst.guideCamp == 0) {
                // newbie
                return new Promise<boolean>(resolve => {
                    // Core.ViewManager.inst.close(ViewName.login);
                    Core.ViewManager.inst.close(ViewName.loading);
                    let p = null;
                    Guide.GuideMgr.inst.enterGuideHome(async (camp: Camp) => {
                        this._newbieChooseCamp = camp;
                        resolve(true);
                    });
                    if (Core.DeviceUtils.isWXGame()) {
                        Promise.all([
                            WXGame.WXGroupLoader.inst.loadZip("preload.zip", null, true),
                            WXGame.WXGroupLoader.inst.loadZip("common.zip", null, true),
                            WXGame.WXGroupLoader.inst.loadZip("card.zip", null, true)]);
                    }
                });
            } else {
                return false;
            }
        }

        public async checkNewbieGuideBattle() {
            if (this._newbieChooseCamp != null) {
                await Guide.GuideMgr.inst.beginGuideBattle(this._newbieChooseCamp);
                this._newbieChooseCamp = null;
            }
        }

        public async onLoginDone(showHomeView: boolean = true) {
            let reply = this._lastLoginReply;
            let p;
            if (!this._newbieChooseCamp || !Core.DeviceUtils.isWXGame())
                p = Core.ViewManager.inst.open(ViewName.newHome);
            await Home.HomeMgr.inst.checkNewbieGuideBattle();
            if (p) await p;
            //questMgr
            Quest.QuestMgr.inst.loadQuest();
            await Battle.BattleMgr.inst.loadBattle(reply.FightID as Long);

            Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.ON_ENTER_GAME, {
                "userId": `${Player.inst.uid}`,
                "userName": Player.inst.name,
                "level": 1,
                "serverId": 1,
                "serverName": "commonServer"
            });

            if (Core.DeviceUtils.isWXGame()) {
                WXGame.WXGameMgr.inst.onEnterGame();
            }

            if (reply.IsInCampaignMatch && !Battle.BattleMgr.inst.battle) {
                Core.MaskUtils.showTransMask();
                await War.WarMgr.inst.openWarHome();
                Core.MaskUtils.hideTransMask();                          
            }
            

            this.checkVersion(reply.Ver);

            this._loginGameCenter();

            fairygui.GTimers.inst.callDelay(800, () => {
                // Core.ViewManager.inst.close(ViewName.login);
                Core.ViewManager.inst.close(ViewName.loading);
            }, this);

        }

        public async onAccountLoginWithPwd(name:string, pwd:string): Promise<number> {
            let ret = await this._onAccountLogin(name,pwd);
            if (ret == 100) {
                // 老账号
                Net.SConn.inst.close();
                Net.SConn.inst.setConnectOldServerFlag(true);
                await Net.SConn.inst.connectServer();
                return await this._onAccountLogin(name, pwd);
            } else {
                return ret;
            }
        }

        private async _onAccountLogin(name:string, pwd:string): Promise<number> {
            if (!loginSwitch) {
                return 1;
            }
            //if (Core.WordFilter.inst.containsDirtyWords(name)) {
            //    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60167));
            //    return false;
            //}
            loginSwitch = false;

            let result = await Net.rpcCall(pb.MessageID.C2S_ACCOUNT_LOGIN,
                pb.AccountLoginArg.encode({"Channel":window.gameGlobal.channel, "ChannelID":name,
                    "Password": GameAccount.inst.md5hashPassword( pwd )}), true, false);
            if (result.errcode == 101) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60167));
                return result.errcode;
            } else if (result.errcode == 100) {
                // 老账号
                loginSwitch = true;
                return result.errcode;
            } else if (result.errcode != 0) {
                loginSwitch = true;
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60133));
                return result.errcode;
            }
            
            egret.localStorage.setItem("account", name);
            GameAccount.inst.login(name, false, "");
            GameAccount.inst.isAccountLogin = true;
            return await this.login();
            //Core.ViewManager.inst.open(ViewName.archive, pb.AccountArchives.decode(result.payload));
            //Core.ViewManager.inst.close(ViewName.login);
        }

        private async _doSdkAccountLogin(channelUserInfo: any): Promise<number> {
            // egret.log("onSdkAccountLogin: ", JSON.stringify(channelUserInfo));
            let channelId = channelUserInfo.channel_id;
            let loginChannel = "";
            let token = "";
            if (channelUserInfo.login_channel != "") {
                loginChannel = channelUserInfo.login_channel;
            }
            if (channelUserInfo.token != "") {
                token = channelUserInfo.token;
            }
            let args = {
                Channel: window.gameGlobal.channel,
                ChannelID: channelId,
                Account: "",
                Password: "",
                SdkToken: token,
                IsTourist: false,
                LoginChannel: loginChannel
            }
            // egret.log("args: ", JSON.stringify(args));
            let result = await Net.rpcCall(pb.MessageID.C2S_SDK_ACCOUNT_LOGIN, pb.AccountLoginArg.encode(args), true, false);
            if (result.errcode != 0) {
                return result.errcode;
            }
            GameAccount.inst.login(channelId, false, loginChannel);
            return await this.onPlayerLogin(1);
        }

        public async onSdkAccountLogin(channelUserInfo: any): Promise<number> {
            let ret = await this._doSdkAccountLogin(channelUserInfo);
            if (ret == 100) {
                // 连老服务器
                Net.SConn.inst.close();
                Net.SConn.inst.setConnectOldServerFlag(true);
                await Net.SConn.inst.connectServer();
                return await this._doSdkAccountLogin(channelUserInfo);
            } else {
                return ret;
            }
        }

        public async onRegister(account:string, password:string): Promise<number> {
            let result = await Net.rpcCall(pb.MessageID.C2S_REGISTER_ACCOUNT,
                pb.RegisterAccount.encode({"Channel":window.gameGlobal.channel, "Account":account,
                    "Password": GameAccount.inst.md5hashPassword( password )}), true, false);
            if (result.errcode != 0) {
                return result.errcode;
            }

            egret.localStorage.setItem("account", account);
            GameAccount.inst.setPassword(account, password);
            GameAccount.inst.login(account, false, "");
            GameAccount.inst.isAccountLogin = true;
            await this.login();
            return result.errcode;
        }

        public async login() {
            let ret = await this.onPlayerLogin(1);
            //Core.ViewManager.inst.close(ViewName.login);
            
            // 新号的流程阻塞在选阵营界面，所以这里关掉两个弹框
            // if (Core.ViewManager.inst.getView(ViewName.loginRegister)) {
            //     Core.ViewManager.inst.getView(ViewName.loginRegister).setVisible(false);
            // }
            // if (Core.ViewManager.inst.getView(ViewName.loginAccount)) {
            //     Core.ViewManager.inst.getView(ViewName.loginAccount).setVisible(false);
            // }

            await this.checkNewbieGuideHome();
            await this.onLoginDone();
            return ret;
        }

        public async delPlayerArchive(archiveID:number) {
            let result = await Net.rpcCall(pb.MessageID.C2S_DEL_ARCHIVES,
                pb.DelArchiveArg.encode({"Channel":window.gameGlobal.channel, "ChannelID":GameAccount.inst.accountName, "ArchiveID":archiveID}));
            return result.errcode == 0;
        }

        public async onPlayerLogout() {
            let result = await Net.rpcCall(pb.MessageID.C2S_PLAYER_LOGOUT, null);
            if (result.errcode != 0) {
                return;
            }

            await Core.ViewManager.inst.closeAll();
            Player.inst.logout();
            Core.ViewManager.inst.open(ViewName.archive, pb.AccountArchives.decode(result.payload));
        }

        public async doGmCommand(command:string): Promise<boolean> {
            if (command == "clearguide") {
                Guide.clearGuide();
                Core.TipsUtils.showTipsFromCenter("i think it is ok");
                return true;
            }
				if (command == "cn") {
					LanguageMgr.inst.cur = "cn";
					Core.TipsUtils.showTipsFromCenter("switch CN");
                    window.location.reload();
					return;
				}
                if (command == "tw") {
					LanguageMgr.inst.cur = "tw";

					Core.TipsUtils.showTipsFromCenter("switch TW");
                    window.location.reload();
					return;
				}
                if (command == "en") {
					LanguageMgr.inst.cur = "en";
					Core.TipsUtils.showTipsFromCenter("switch EN");
                    window.location.reload();
					return;
				}
                if (command.substr(0, 7) == "logtxt ") {
					let reg = /^[1-9]+[0-9]*]*$/;
					let cmd = command.substr(7);
					if (reg.test(cmd)) {
						let index = parseInt(cmd);
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(index));
						return;
					}
				}

            let result = await Net.rpcCall(pb.MessageID.C2S_GM_COMMAND, pb.GmCommand.encode({"Command":command}));
            if (result.errcode != 0) {
                return false;
            }
            Core.TipsUtils.showTipsFromCenter("i think it is ok");
            return true;
        }

        private _beginPing() {
            fairygui.GTimers.inst.add(1000 * 40, -1, ()=>{
                Net.SConn.inst.ping();
            }, this);
        }

        private _loginGameCenter() {
            if (!Core.DeviceUtils.isWXGame() && Core.DeviceUtils.isiOS()) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.LOGIN_GAME_CENTER);
            }
        }

        private async _touristLogin(account: string, password: string): Promise<number> {
            let args = {
                Channel: window.gameGlobal.channel,
                Account: account,
                Password: password,
                IsTourist: true,
            };
            let result = await Net.rpcCall(pb.MessageID.C2S_SDK_ACCOUNT_LOGIN, pb.AccountLoginArg.encode(args));
            if (result.errcode == 0) {
                GameAccount.inst.login(account, true, "");
                return await this.onPlayerLogin(1);
            } else {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60097) + `[code=${result.errcode}]`);
                return result.errcode;
            }
        }

        public async tryBindOldAccount() {
            if (window.gameGlobal.channel != "lzd_pkgsdk") {
                return;
            }

            if (IOS_EXAMINE_VERSION) {
                return;
            }

            // let accounts = GameAccount.inst.getLocalAccounts();
            // if (!accounts) {
                let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_FIRE233_BIND_ACCOUNT, null);
                if (result.errcode != 0) {
                    // 弹出
                    Core.ViewManager.inst.open(ViewName.loginBindOldAccount);
                } else {
                    let reply = pb.RegisterAccount.decode(result.payload);
                    GameAccount.inst.saveToLocalAccount(reply.Account, reply.Password);
                }
            // }
        }

        private async _bindTouristAndLogin(account: string, password: string): Promise<number> {
            await platform.login();
            let channelUserinfo = await platform.getUserInfo();
            if (!channelUserinfo) {
                return -100;
            } else {
                let channelId = channelUserinfo.channel_id;
                let loginChannel = "";
                let token = "";
                if (channelUserinfo.login_channel != "") {
                    loginChannel = channelUserinfo.login_channel;
                }
                if (channelUserinfo.token != "") {
                    token = channelUserinfo.token;
                }
                let args = {
                    Channel: window.gameGlobal.channel,
                    TouristAccount: account,
                    TouristPassword: password,
                    BindAccount: {
                        Channel: window.gameGlobal.channel,
                        ChannelID: channelId,
                        Account: "",
                        Password: "",
                        SdkToken: token,
                        IsTourist: false,
                        LoginChannel: loginChannel
                    }
                };
                let result = await Net.rpcCall(pb.MessageID.C2S_TOURIST_BIND_ACCOUNT, pb.TouristBindAccountArg.encode(args));
                if (result.errcode != 0) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60250) + `[code=${result.errcode}]`);
                    return result.errcode;
                } else {
                    egret.localStorage.setItem("tbind", "true");
                    GameAccount.inst.login(channelId, false, loginChannel);
                    return await this.onPlayerLogin(1);
                }
            }
        }

        public async onTouristLogin(): Promise<number> {
            let account = egret.localStorage.getItem("taccount");
            let password = egret.localStorage.getItem("tpassword");
            let hasBind = egret.localStorage.getItem("tbind");
            if (account && account != "" && password && password != "") {
                // 是否绑定账号
                if (!hasBind || hasBind == "") {
                    let bind = await new Promise<boolean>(resolve => {
                        Core.TipsUtils.confirm(Core.StringUtils.TEXT(60249), () => {
                            resolve(true);
                        }, () => {
                            resolve(false);
                        }, this, Core.StringUtils.TEXT(60024), Core.StringUtils.TEXT(60020));
                    });
                    if (bind) {
                        return await this._bindTouristAndLogin(account, password);
                    } else {
                        return await this._touristLogin(account, password);
                    }
                } else {
                    return await this._touristLogin(account, password);
                }
            } else {
                let args = {
                    Channel: window.gameGlobal.channel
                };
                let result = await Net.rpcCall(pb.MessageID.C2S_TOURIST_REGISTER_ACCOUNT, pb.TouristRegisterAccountArg.encode(args));
                if (result.errcode == 0) {
                    let reply = pb.TouristRegisterAccountRelpy.decode(result.payload);
                    egret.localStorage.setItem("taccount", reply.Account);
                    egret.localStorage.setItem("tpassword", reply.Password);
                    return await this.onTouristLogin();
                } else {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60097) + `[code=${result.errcode}]`);
                    return result.errcode;
                }
            }
        }

        public async enterLogin(loadingView: Core.BaseView) {
            Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.ON_SHOW_LOADING);
            this._beginPing();
            egret.log("isMultiLan: ", window.gameGlobal.isMultiLan);
            await LoginNoticeView.tryOpenNoticePanel();
            if (window.gameGlobal.isMultiLan) {
                // 海外版
                if (loadingView) {
                    loadingView.visible = false;
                }
                await new Promise<void>(resolve => {
                    Core.ViewManager.inst.open(ViewName.facebookLogin, async () => {
                        resolve();
                    });
                });
                if (loadingView) {
                    loadingView.visible = true;
                }
                Core.ViewManager.inst.close(ViewName.facebookLogin);
            } else {
                await new Promise<void>(resolve => {
                    Core.ViewManager.inst.open(ViewName.login, async () => {
                        resolve();
                    });
                });
                Core.ViewManager.inst.close(ViewName.login);
            }

            // if (Core.DeviceUtils.isWXGame()) {
            //     WXGame.WXGameMgr.inst.showConnectView(false);
            // } else {
            //     await Core.ViewManager.inst.open(ViewName.login);
            // }
            // if (!window.gameGlobal.isSDKLogin) {
            //     let loginView = Core.ViewManager.inst.getView(ViewName.login) as LoginView;
            //     loginView.showAccountLoginComs(true);
            //     return;
            // }

            // let self = this;
            // let _getChannelUserInfo = async function() {
            //     // console.log("tdChannel getchannelUserInfo");
            //     if (!Core.DeviceUtils.isWXGame()) {
            //         await platform.login();
            //     }
            //     let channelUserInfo = await platform.getUserInfo();
            //     // Core.MaskUtils.hideNetMask();
            //     if (channelUserInfo) {
            //         window.gameGlobal.tdChannel = channelUserInfo.td_channel_id;
            //         // console.log(`tdChannel ${channelUserInfo.td_channel_id}`);
            //         // console.log(`channelUserId ${channelUserInfo.channel_id}`);
            //         if (channelUserInfo.account_login) {
            //             let loginView = Core.ViewManager.inst.getView(ViewName.login) as LoginView;
            //             loginView.showAccountLoginComs(true);
            //         } else {
            //             if (Core.DeviceUtils.isWXGame()) {
            //                 //WXGame.WXGameMgr.inst.showConnectView(true);
            //                 LoadingView.inst.setText(Core.StringUtils.TEXT(70121));
            //             }
            //             await self.onSdkAccountLogin(channelUserInfo);
            //             if (Core.DeviceUtils.isWXGame()) {
            //                 //WXGame.WXGameMgr.inst.showConnectView(false);
            //                 LoadingView.inst.setText(Core.StringUtils.TEXT(70125));
            //             }
            //         }
            //     } else {
            //         Core.TipsUtils.alert(Core.StringUtils.TEXT(60097), async ()=>{
            //             // await platform.login();
            //             await _getChannelUserInfo();
            //         }, self, Core.StringUtils.TEXT(60038));
            //     }
            // }
            // await _getChannelUserInfo();
        }

        public async modifyName(name:string):Promise<number> {
            let result = await Net.rpcCall(pb.MessageID.C2S_MODIFY_NAME, pb.ModifyNameArg.encode({
                Name: name,
            }), true, false);
            if (result.errcode == 0) {
                Core.EventCenter.inst.dispatchEventWith(GameEvent.ModifyNameEv, false, name);
                return 0;
            } else {
                return result.errcode;
            }
        }

        public async updateName(name: string, colorCode?: string): Promise<number> {
            let result = await Net.rpcCall(pb.MessageID.C2S_UPDATE_NAME, pb.UpdateNameArg.encode({Name: name,}), true, false);
            if (result.errcode == 0) {
                if (colorCode && colorCode != "") {
                    name = `${colorCode+name}#n`;
                }
                Core.EventCenter.inst.dispatchEventWith(GameEvent.ModifyNameEv, false, name);
                return 0;
            } else {
                return result.errcode;
            }
        }

        public async exchangeGiftCode(code:string): Promise<number> {
            let result = await Net.rpcCall(pb.MessageID.C2S_EXCHANGE_GIFT_CODE, pb.ExchangeCodeArg.encode({
                Code: code,
            }), true, false);

            if (result.errcode == 0) {
                let reply = pb.ExchangeCodeReward.decode(result.payload);
                let reward = new Treasure.TreasureReward();
                reward.setRewardForOpenReply(reply.Reward);
                Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, reply.TreasureID));
            }

            return result.errcode;
        }
    }

    async function onReLogin() {
        if (GameAccount.inst.archiveID > 0 && Player.inst.uid) {
            await Core.ViewManager.inst.closeAll();
            Player.inst.logout();
            HomeMgr.inst.login();
        }
    }

    function onBattleBegin() {
        HomeMgr.inst.playFightBgSound();
        //Core.ViewManager.inst.close(ViewName.newHome);
        let homeView = Core.ViewManager.inst.getView(ViewName.newHome) as NewHomeView;
        if (homeView) homeView.visible = false;
    }

    function onBattleEnd(){
        HomeMgr.inst.playMainBgSound();
        //Core.ViewManager.inst.open(ViewName.newHome);
        let homeView = Core.ViewManager.inst.getView(ViewName.newHome) as NewHomeView;
        if (homeView) homeView.visible = true;
    }

    export function getGameName() {
        if (window.gameGlobal.channel == "lzd_handjoy") {
            return Core.StringUtils.TEXT(90003);
        } else {
            if (Core.DeviceUtils.isWXGame()) {
                return Core.StringUtils.TEXT(90001);
            } else {
                return Core.StringUtils.TEXT(90002);
            }
        }
    }

    export function hasBowlderRes() {
        if (window.gameGlobal.channel == "lzd_handjoy") {
            return true;
        } else {
            return false;
        }
    }

    export function init() {
        initRpc();
        Core.EventCenter.inst.addEventListener(Core.Event.ReLoginEv, onReLogin, null);
        Core.EventCenter.inst.addEventListener(GameEvent.BattleBeginEv, onBattleBegin, null);
        Core.EventCenter.inst.addEventListener(GameEvent.BattleEndEv, onBattleEnd, null);

        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObj = fairygui.UIPackage.createObject;
        registerView(ViewName.login, () => {
            return createObj(PkgName.login, ViewName.login, LoginView) as LoginView;
        });

        registerView(ViewName.cmdWnd, () => {
            return createObj(PkgName.home, ViewName.cmdWnd, CmdWnd) as CmdWnd;
        }/*, async () => {
            await fairygui.UIPackage.preloadResourceByName(PkgName.home, ViewName.cmdWnd);
        }*/);

        registerView(ViewName.switchLanWnd, () => {
            return createObj(PkgName.home, ViewName.switchLanWnd, LanguageSwitchWnd) as LanguageSwitchWnd;
        });

        registerView(ViewName.archive, () => {
            return createObj(PkgName.login, ViewName.archive, ArchiveView) as ArchiveView;
        });

        registerView(ViewName.newHome, () => {
            return createObj(PkgName.home, ViewName.newHome, NewHomeView) as NewHomeView;
        });

        registerView(ViewName.loginRegister, () => {
            return createObj(PkgName.login, ViewName.loginRegister, LoginRegisterWnd) as LoginRegisterWnd;
        });

        registerView(ViewName.loginBindOldAccount, () => {
            return createObj(PkgName.login, ViewName.loginBindOldAccount, BindOldAccountView) as BindOldAccountView;
        });

        registerView(ViewName.loginAccount, () => {
            return createObj(PkgName.login, ViewName.loginAccount, LoginAccountWnd) as LoginAccountWnd;
        });

        registerView(ViewName.modifyName, () => {
            return createObj(PkgName.home, ViewName.modifyName, ModifyNameWnd) as ModifyNameWnd;
        });

        registerView(ViewName.survey, ()=> {
            return createObj(PkgName.home, ViewName.survey, Home.SurveyView);
        });

        registerView(ViewName.connectView, () => {
            return createObj(PkgName.login, ViewName.connectView, ConnectHintView) as ConnectHintView;
        });

        registerView(ViewName.descTipsWnd, () => {
            return createObj(PkgName.common, ViewName.descTipsWnd, DescTipsWnd) as DescTipsWnd;
        });

        if (window.gameGlobal.isMultiLan) {
            let facebookLoginView = fairygui.UIPackage.createObject(PkgName.login, ViewName.facebookLogin, LoginFacebook) as LoginFacebook;
            Core.ViewManager.inst.register(ViewName.facebookLogin, facebookLoginView);
		}

        registerView(ViewName.noticeView, () => {
            return createObj(PkgName.login, ViewName.noticeView, LoginNoticeView) as LoginNoticeView;
        });
    }

}
