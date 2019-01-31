// TypeScript file
module Social {
    export class PrivateChatHintCom extends fairygui.GComponent {

        private _numText: fairygui.GTextField;
        private _observee: Long;

        protected constructFromXML(xml:any) {
			super.constructFromXML(xml);

			this._numText = this.getChild("textNum").asTextField;
			this._observee = null;
		}

        public observePrivateChatNum(uid?: Long) {
			this._observee = uid;
			this._updateHintNum();
			Core.EventCenter.inst.addEventListener(GameEvent.PrivateChatHintEv, this._onPrivateChatHintNumChange, this);
		}

		private _onPrivateChatHintNumChange(evt: egret.Event) {
			let uid = <Long>evt.data;
			if (!this._observee || uid == this._observee) {
				this._updateHintNum();
			}
		}

		private _updateHintNum() {
			let num = ChatMgr.inst.getPrivateHintsNum(this._observee);
			if (num <= 0) {
				this.visible = false;
			} else if (num > 99) {
				this.visible = true;
				this._numText.text = "99+";
			} else {
				this.visible = true;
				this._numText.text = `${num}`;
			}
		}
    }

    export class ApplyFriendHintCom extends fairygui.GComponent {

		private _numText: fairygui.GTextField;

		protected constructFromXML(xml:any) {
			super.constructFromXML(xml);

			this._numText = this.getChild("textNum").asTextField;
		}

		public observerFriendApplyNum() {
			this._updateHintNum();
			Core.EventCenter.inst.addEventListener(GameEvent.ApplyFriendHintEv, this._updateHintNum, this);
		}

		private _updateHintNum() {
			let num = FriendMgr.inst.applyNum;
			if (num <= 0) {
				this.visible = false;
			} else if (num > 99) {
				this.visible = true;
				this._numText.text = "99+";
			} else {
				this.visible = true;
				this._numText.text = `${num}`;
			}
		}
    }

    export class SocialHintCom extends fairygui.GComponent {

		private _numText: fairygui.GTextField;

		protected constructFromXML(xml:any) {
			super.constructFromXML(xml);

			this._numText = this.getChild("textNum").asTextField;
		}

		public observerSocialHintNum() {
			this._updateHintNum();
			Core.EventCenter.inst.addEventListener(GameEvent.PrivateChatHintEv, this._updateHintNum, this);
			Core.EventCenter.inst.addEventListener(GameEvent.ApplyFriendHintEv, this._updateHintNum, this);
		}

		private _updateHintNum() {
			let num = ChatMgr.inst.getPrivateHintsNum();
			num += FriendMgr.inst.applyNum;
			if (num <= 0) {
				this.visible = false;
			} else if (num > 99) {
				this.visible = true;
				this._numText.text = "99+";
			} else {
				this.visible = true;
				this._numText.text = `${num}`;
			}		
		}
    }
}
