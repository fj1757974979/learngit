module Social {
	export class ShareFacebookRewardWnd extends Core.BaseWindow {

		private _shareBtn:fairygui.GButton;
        private _pyqBtn:fairygui.GButton;
        private _closeBtn:fairygui.GButton;
        private _gotten:fairygui.GLoader;
		private _rewardNum: fairygui.GTextField;

		public initUI() {
            super.initUI();

            this.center();
            this.modal = true;

			this._shareBtn = this.getChild("shareFacebookBtn").asButton;
			this._closeBtn = this.getChild("closeBtn").asButton;

			this._rewardNum = this.getChild("cnt1").asTextField;
            this._rewardNum.text = "20";

			this._gotten = this.getChild("gotten").asLoader;
            this._gotten.visible = false;

			this._closeBtn.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);
            this._shareBtn.addClickListener(this._onShare, this);

			Core.EventCenter.inst.addEventListener(GameEvent.ShareIOSOK, this._showGotten, this);
		}

		private async _shareComplete(ret: boolean) {
            if (!Player.inst.isIOSShared && ret) {
                this._gotten.visible = true;
                let result = await Net.rpcCall(pb.MessageID.C2S_IOS_SHARE, null);
                if (result.errcode == 0) {
                    let arg = pb.IosShareReply.decode(result.payload);
                    let getData = new Pvp.GetRewardData();
                    getData.jade = arg.Jade;
                    getData.bowlder = arg.Bowlder;
                    Core.ViewManager.inst.open(ViewName.getRewardWnd, getData);
                    Core.EventCenter.inst.dispatchEventWith(GameEvent.ShareIOSOK, false, true);
                    Player.inst.isIOSShared = true;
                }
            }
        }

		private async _onShare() {
			let link = window.sharePlatform.getShareLink();
            if (link != "") {
            	let ret = await window.sharePlatform.shareAppMsg(Core.StringUtils.TEXT(60254), link, "");
                this._shareComplete(ret);
            }
		}

        private _showGotten(evt: egret.Event) {
            this._gotten.visible = evt.data;
        }

		public async open(...param: any[]) {
            super.open(...param);
            this._gotten.visible = Player.inst.isIOSShared;

        }

        public async close(...param:any[]) {
            super.close(...param);
        }
	}
}