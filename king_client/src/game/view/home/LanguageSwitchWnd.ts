module Home {

	export class LanguageSwitchItem extends fairygui.GButton {

		private _lanCode: string;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
		}

		public initLanguage(code: string, text: string) {
			this.title = text;
			this._lanCode = code;
		}

		public get lanCode(): string {
			return this._lanCode;
		}

	}

	export class LanguageSwitchWnd extends Core.BaseWindow {

		private _closeBtn: fairygui.GButton;
		private _languageList: fairygui.GList;
		private _confirmBtn: fairygui.GButton;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._closeBtn = this.getChild("closeBtn").asButton;
			this._languageList = this.getChild("languageList").asList;
			this._confirmBtn = this.getChild("confirmBtn").asButton;
			this._closeBtn.addClickListener(this._onClose, this);
			this._confirmBtn.addClickListener(this._onConfirm, this);
		}

		public async open(...param: any[]) {
			await super.open(...param);
			let supportedLan = LanguageMgr.inst.supportedLanguage;
			let index = 0;
			for (let lanCode in supportedLan) {
				let text = supportedLan[lanCode];
				let com = fairygui.UIPackage.createObject(PkgName.home, "languageItem", LanguageSwitchItem).asCom as LanguageSwitchItem;
				com.initLanguage(lanCode, text);
				this._languageList.addChild(com);
				if (lanCode == LanguageMgr.inst.cur) {
					this._languageList.selectedIndex = index;
				}
				index ++;
			}
		}

		private _onClose() {
			Core.ViewManager.inst.closeView(this);
		}

		private _onConfirm() {
			let com = this._languageList.getChildAt(this._languageList.selectedIndex) as LanguageSwitchItem;
			if (com.lanCode != LanguageMgr.inst.cur) {
				LanguageMgr.inst.cur = com.lanCode;
				window.location.reload();
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._languageList.removeChildren(0, -1, true);
		}
	}
}