module CardPool {

	export class CardNumHintCom extends fairygui.GComponent {
		
		private _numText: fairygui.GTextField;
		private _observeCamp: Camp;

		protected constructFromXML(xml:any) {
			super.constructFromXML(xml);

			this._numText = this.getChild("textNum").asTextField;
			this._observeCamp = 0;
		}

		public observeCampCardNum(camp: Camp = 0) {
			this._observeCamp = camp;
			this._updateHintNum();
			Core.EventCenter.inst.addEventListener(Core.Event.CardHintNumChangeEv, this._onCardHintNumChange, this);
		}

		private _onCardHintNumChange(evt: egret.Event) {
			let camp = evt.data;
			if (!this._observeCamp || camp == this._observeCamp) {
				this._updateHintNum();
			}
		}

		private _updateHintNum() {
			let num = CardPoolMgr.inst.getCampCardHintNum(this._observeCamp);
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

	export class AvatarNumHintCom extends fairygui.GComponent {
		private _numText: fairygui.GTextField;

		protected constructFromXML(xml:any) {
			super.constructFromXML(xml);

			this._numText = this.getChild("textNum").asTextField;
		}

		public observerAvatarNum() {
			this._updateHintNum();
			Core.EventCenter.inst.addEventListener(Core.Event.AvatarHintNumChangeEv, this._updateHintNum, this);
		}

		private _updateHintNum() {
			let num = CardPoolMgr.inst.avatarHintNum;
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