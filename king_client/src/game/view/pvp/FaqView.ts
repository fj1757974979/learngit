module Pvp {
	export class FaqView extends Core.BaseWindow {

		private _faqText: fairygui.GTextField;

		public initUI() {
			super.initUI();
			this.modal = true;
			this.center();

			this._faqText = this.getChild("textList").asList.getChildAt(0).asCom.getChild("mailText").asTextField;

			this.getChild("closeBtn").asButton.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);
		}

		public async open(...param: any[]) {
			super.open(...param);

			let text = param[0];
			this._faqText.text = text;
		}
	}
}