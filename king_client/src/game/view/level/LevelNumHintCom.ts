module Level {
	export class LevelNumHintCom extends fairygui.GComponent {

		private _numText: fairygui.GTextField;
		private _chapterIdInfo: Collection.Dictionary<number, boolean>;

		protected constructFromXML(xml:any) {
			super.constructFromXML(xml);

			this._numText = this.getChild("textNum").asTextField;
			this._chapterIdInfo = new Collection.Dictionary<number, boolean>();
		}

		public observeLevelNum() {
			this._updateHintNum();
			Core.EventCenter.inst.addEventListener(Core.Event.LevelHintNumChangeEv, this._onLevelHintNumChange, this);
		}

		private _onLevelHintNumChange(evt: egret.Event) {
			this._updateHintNum();
		}

		private _updateHintNum() {
			let num = LevelMgr.inst.getTotalLevelHintNum();
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