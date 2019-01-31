module Home {
	export class DescTipsWnd extends Core.BaseWindow {

		private _text: fairygui.GRichTextField;

		public initUI() {
			super.initUI();
			this.modal = true;
			this.center();

			this._text = this.getChild("txt").asRichTextField;
		}

		public async open(...param: any[]) {
			super.open(...param);

			let text: string = param[0];
			if (parseInt(text)) {
				this._text.text = Core.StringUtils.TEXT(parseInt(text));
			} else {
				this._text.text = text;
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
		}
	}
}