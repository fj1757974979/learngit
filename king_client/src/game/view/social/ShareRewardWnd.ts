module Social {

    export class ShareRewardWnd extends Core.BaseWindow {
        
        private _shareBtn:fairygui.GButton;
        private _pyqBtn:fairygui.GButton;
        private _closeBtn:fairygui.GButton;
        private _gotten:fairygui.GLoader;
        private _rewardNum: fairygui.GTextField;
        private _titleText: fairygui.GTextField;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;

            this._shareBtn = this.getChild("shareBtn").asButton;
            this._pyqBtn = this.getChild("pyqBtn").asButton;
            this._closeBtn = this.getChild("closeBtn").asButton;

            this._rewardNum = this.getChild("cnt1").asTextField;
            this._rewardNum.text = "10";

            this._gotten = this.getChild("gotten").asLoader;
            this._gotten.visible = false;
            this._titleText = this.getChild("n24").asTextField;

            this._closeBtn.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);
            this._shareBtn.addClickListener(this._onShare, this);
            this._pyqBtn.addClickListener(this._onPyq, this);

        }

        private async _onShare() {
            if (Core.DeviceUtils.isWXGame()) {
                this._wxShare();
            } else if (Core.DeviceUtils.isiOS()) {
                this._iosShare();
            }
        }
        private async _wxShare() {
            WXGame.WXShareMgr.inst.wechatShareDailyJade();
        }
        private async _iosShare() {
            Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.SHARE_APP2WECHAT, {
				"title":Core.StringUtils.TEXT(60059),
				"description":Core.StringUtils.TEXT(60247),
				"url":"https://itunes.apple.com/cn/app/id1371944201?mt=8",
				"scene":0
			});
        }

        private async _onPyq() {
            Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.SHARE_APP2WECHAT, {
				"title":Core.StringUtils.TEXT(60059),
				"description":Core.StringUtils.TEXT(60247),
				"url":"https://itunes.apple.com/cn/app/id1371944201?mt=8",
				"scene":1
			});
        }

        private async _shareOK(ret: any) {
            if (!Player.inst.isIOSShared && ret.scene == 1) {
                this._gotten.visible = true;
                let result = await Net.rpcCall(pb.MessageID.C2S_IOS_SHARE, null);
                if (result.errcode == 0) {
                    let arg = pb.IosShareReply.decode(result.payload);
                    let getData = new Pvp.GetRewardData();
                    getData.jade = arg.Jade;
                    Core.ViewManager.inst.open(ViewName.getRewardWnd, getData);
                    Core.EventCenter.inst.dispatchEventWith(GameEvent.ShareIOSOK, false, true);
                    Player.inst.isIOSShared = true;
                }
            }
            
        }

        private _showGotten(evt: egret.Event) {
            this._gotten.visible = evt.data;
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._gotten.visible = Player.inst.isIOSShared;
            if (Core.DeviceUtils.isWXGame()) {
                this._titleText.text = Core.StringUtils.format("每日首次有微信好友点击分享链接进入可获得以下奖励");
                this._pyqBtn.visible = false;
                this._shareBtn.setXY(110,270);
            } else if (Core.DeviceUtils.isiOS()) {
                Core.NativeMsgCenter.inst.addListener(Core.NativeMessage.SHARE_APP2WECHAT, this._shareOK, this);
                this._titleText.text = Core.StringUtils.TEXT(70071);
                this._pyqBtn.visible = true;
                this._shareBtn.setXY(15,270);
            }
            Core.EventCenter.inst.addEventListener(GameEvent.ShareIOSOK, this._showGotten, this);
        }

        public async close(...param:any[]) {
            super.close(...param);
            Core.NativeMsgCenter.inst.removeListener(Core.NativeMessage.SHARE_APP2WECHAT, this._shareOK, this);
            Core.EventCenter.inst.removeEventListener(GameEvent.ShareIOSOK, this._showGotten, this);
            if (Player.inst.getResource(ResType.T_GUIDE_PRO) <= 1) {
                Guide.GuideMgr.inst.continueGuide();
            }
        }

    }
}