module Social {
	export class InviteWaitingWnd extends Core.BaseView {

		private _cancelMatchBtn: fairygui.GButton;
		private _countdown: number;
		private _countdownHdr: () => void;
		private _onCancelCallback: () => void;

        public initUI() {
			this._myParent = Core.LayerManager.inst.maskLayer;
			super.initUI();
			this.adjust(this.getChild("background"));
            this.center();
            this._cancelMatchBtn = this.getChild("cancelMatchBtn").asButton;
            this._cancelMatchBtn.addClickListener(this._onCancel, this);
			this.getChild("time").asTextField.text = "";
		}

		public async open(...param:any[]) {
            SoundMgr.inst.playBgMusic("matching_mp3");
            super.open(...param);
			this._cancelMatchBtn.visible = true;
            await fairygui.GTimers.inst.waitTime(1);
            this.getTransition("shake").play(null, null, null, -1);
			this._countdown = 60;
			this._countdownHdr = () => {
				this._countdown --;
				this.getChild("time").asTextField.text = Core.StringUtils.secToString(this._countdown, "hm");
			};
			fairygui.GTimers.inst.add(1000, this._countdown, this._countdownHdr, this);

			this._onCancelCallback = param[0];
		}

		public async close(...param:any[]) {
			if (this._countdownHdr) {
				fairygui.GTimers.inst.remove(this._countdownHdr, this);
				this._countdownHdr = null;
				this.getChild("time").asTextField.text = "";
			}
            // SoundMgr.inst.playBgMusic("bg_mp3");
            // await Core.PopUpUtils.removePopUp(this, 7);
            await new Promise<void>(resolve => {
                egret.Tween.get(this).to({ scaleX: 0, scaleY: 0 }, 300, egret.Ease.backIn).call(function () {
                    resolve();
                }, this);
            })
            await super.close(...param);
            this.getTransition("shake").stop();
        }

		private async _onCancel() {
			if (this._onCancelCallback) {
				this._onCancelCallback();
			}
			SoundMgr.inst.playBgMusic("bg_mp3");
			await Core.ViewManager.inst.closeView(this);
		}

		public async readyFight() {
            this._cancelMatchBtn.visible = false;
			if (this._countdownHdr) {
				fairygui.GTimers.inst.remove(this._countdownHdr, this);
				this._countdownHdr = null;
				this.getChild("time").asTextField.text = "";
			}
            await fairygui.GTimers.inst.waitTime(2000);
            this.getTransition("shake").stop();
            this.getTransition("open").play(this._openAnimationDone, this);           
            await fairygui.GTimers.inst.waitTime(1000);
        }

		private _openAnimationDone() {
			Core.ViewManager.inst.closeView(this);
		}

		public async cancelFight() {
			SoundMgr.inst.playBgMusic("bg_mp3");
			await Core.ViewManager.inst.closeView(this);
		}
	}
}