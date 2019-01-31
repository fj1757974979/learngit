module Home {

    export class LoginView extends Core.BaseView {
        // private _nameTextInput: fairygui.GTextField;
        // private _registerBtn: fairygui.GButton;
        // private _touchMask: fairygui.GGraph;
        // private _touchTips: fairygui.GTextField;
        private _bg:fairygui.GLoader;
        private _callback: () => Promise<void>;
        
        public initUI() {
            super.initUI();

            this._myParent = Core.LayerManager.inst.maskLayer;
            this.adjust(this.getChild("bg"), Core.AdjustType.NO_BORDER);
            // this._nameTextInput = this.getChild("nameTextInput").asTextField;
            this._bg = this.getChild("bg").asLoader;
            this._bg.url = (window.gameGlobal.logoUrl || "loading_logo_lzd_jpg").replace("png", "jpg");

            let account = egret.localStorage.getItem("account");
            // if (account != null) {
            //     this._nameTextInput.text = account;
            // } else {
            //     this._nameTextInput.text = Core.StringUtils.TEXT(60086);
            // }

            // this._touchTips = this.getChild("touchTips").asTextField;
            // this._touchMask = this.getChild("touchMask").asGraph;
            // this._touchMask.asGraph.addClickListener(this._onEnter, this);
            // this._registerBtn = this.getChild("registerBtn").asButton;
            // this._registerBtn.addClickListener(()=>{
            //     Core.ViewManager.inst.open(ViewName.loginRegister);
            // }, this);
            // this.getChild("nameTextBg").asLoader.addClickListener(()=>{
            //     Core.ViewManager.inst.open(ViewName.loginAccount);
            // }, this);

            if (Core.DeviceUtils.isWXGame()) {
                this.getChild("isnbTxt").asTextField.visible = true;
            } else {
                this.getChild("goodTxt").asTextField.y = this.getChild("isnbTxt").asTextField.y;
            }
        }

        private async _loginWithSdk() {
            await Net.SConn.inst.connectServer();
            let _getChannelUserInfo = async function() {
                // console.log("tdChannel getchannelUserInfo");
                if (!Core.DeviceUtils.isWXGame()) {
                    await platform.login();
                }
                let channelUserInfo = await platform.getUserInfo();
                // Core.MaskUtils.hideNetMask();
                if (channelUserInfo) {
                    window.gameGlobal.tdChannel = channelUserInfo.td_channel_id;
                    // console.log(`tdChannel ${channelUserInfo.td_channel_id}`);
                    // console.log(`channelUserId ${channelUserInfo.channel_id}`);
                    if (channelUserInfo.account_login) {
                        let loginView = Core.ViewManager.inst.getView(ViewName.login) as LoginView;
                    } else {
                        if (Core.DeviceUtils.isWXGame()) {
                            //WXGame.WXGameMgr.inst.showConnectView(true);
                            LoadingView.inst.setText(Core.StringUtils.TEXT(70121));
                        }
                        await HomeMgr.inst.onSdkAccountLogin(channelUserInfo);
                        if (Core.DeviceUtils.isWXGame()) {
                            //WXGame.WXGameMgr.inst.showConnectView(false);
                            LoadingView.inst.setText(Core.StringUtils.TEXT(70125));
                        }
                    }
                } else {
                    Core.TipsUtils.alert(Core.StringUtils.TEXT(60097), async ()=>{
                        // await platform.login();
                        await _getChannelUserInfo();
                    }, self, Core.StringUtils.TEXT(60038));
                }
            }
            await _getChannelUserInfo();
            if (this._callback) {
                this._callback();
            }
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._callback = param[0];
            if (Core.DeviceUtils.isWXGame()) {
                WXGame.WXGameMgr.inst.showConnectView(false);
            }
            if (window.gameGlobal.channel == "lzd_pkgsdk") {
                await Net.SConn.inst.connectServer();
                let accounts = GameAccount.inst.getLocalAccounts();
                if (!accounts && IOS_EXAMINE_VERSION) {
                    await this._loginWithSdk();
                } else {
                    Core.ViewManager.inst.open(ViewName.loginAccount, async (isSdkLogin: boolean) => {
                        if (isSdkLogin) {
                            await this._loginWithSdk();
                        } else {
                            if (this._callback) {
                                this._callback();
                            }
                        }
                    });
                }
            } else {
                if (window.gameGlobal.isSDKLogin) {
                    await this._loginWithSdk();
                } else {
                    await Net.SConn.inst.connectServer();
                    Core.ViewManager.inst.open(ViewName.loginAccount, () => {
                        if (this._callback) {
                            this._callback();
                        }
                    });
                }
            }
        }

        public async close(...param: any[]) {
            super.close(...param);
            this._callback = null;
        }

        // private async _onEnter(evt: egret.TouchEvent) {

        //     SoundMgr.inst.playSoundAsync("click_mp3", 0.01);
        //     let name = "";
        //     let scale = fairygui.GRoot.contentScaleFactor;
        //     let x = evt.stageX / scale;
        //     let y = evt.stageY / scale;
        //     let w = this._nameTextInput.width;
        //     let h = this._nameTextInput.height;
        //     if (window.gameGlobal.channel == "debug") {
        //         name = this._nameTextInput.text.trim();
        //     } else {
        //         let channelUserInfo = await platform.getUserInfo();
        //         if (!channelUserInfo) {
        //             await HomeMgr.inst.enterLogin(null);
        //         }
        //         name = channelUserInfo.channel_id;
        //         console.log(`tdChannel ${name}`);
        //         if (name.length == 0) {
        //             name = this._nameTextInput.text.trim();
        //             console.log(`tdChannel ${name}`);
        //         }
        //     }

        //     if (name.length > 0) {
        //         let psw = GameAccount.inst.getPassword(name)
        //         await Home.HomeMgr.inst.onAccountLogin(name,psw);
        //     }
        // }
    }

}
