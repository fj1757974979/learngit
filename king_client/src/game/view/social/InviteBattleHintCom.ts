module Social {
	export class InviteBattleHintCom extends fairygui.GComponent {

		private _uid: Long;
		private _fromName: string;
		private _tran0: fairygui.Transition;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this.getChild("yesBtn").asButton.addClickListener(this._onYes, this);
			this.getChild("noBtn").asButton.addClickListener(this._onNo, this);
			this._tran0 = this.getTransition("t0");
		}

		public setInfo(uid: Long, name: string) {
			this._uid = uid;
			this._fromName = name;
			this.getChild("txt").asTextField.textParser = Core.StringUtils.parseColorText;
			this.getChild("txt").asTextField.text = `${name}`+Core.StringUtils.TEXT(60111);
			this._tran0.play();
		}

		private async _onYes() {
			await this._replyInvite(true);
		}

		private async _onNo() {
			await this._replyInvite(false);
		}

		private async _replyInvite(agree: boolean) {
			let args = {
				Uid: this._uid,
				IsAgree: agree,
			}
			let result = await Net.rpcCall(pb.MessageID.C2S_REPLY_INVITE_BATTLE, pb.ReplyInviteBattleArg.encode(args));
			if (result.errcode == 0) {
				if (agree) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60149));
				} else {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60054));
				}
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60124));
			}
			this.visible = false;
		}
	}
}