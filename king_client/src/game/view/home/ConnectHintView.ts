module Home {
	export class ConnectHintView extends Core.BaseView {
		// private _hintText: fairygui.GTextField;

		public initUI() {
			super.initUI();
			if (!window.gameGlobal.isMultiLan) {
				this._myParent = Core.LayerManager.inst.topLayer;
			}
			// this._hintText = this.getChild("hintText").asTextField;
		}
	}
}