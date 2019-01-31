module Home {

	class NoticeChkCom extends fairygui.GButton {

		private _noticeId: number;
		private _callback: (noticeId: number) => void;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this.addClickListener(this._onClick, this);
		}

		public setNoticeId(id: number, callback: (noticeId: number) => void) {
			this._noticeId = id;
			this._callback = callback;
			this.title = Data.notice_config.get(id).title;
		}

		private async _onClick() {
			if (this._callback) {
				this._callback(this._noticeId);
			}
		}

		public get noticeId(): number {
			return this._noticeId;
		}
	}

	export class LoginNoticeView extends Core.BaseWindow {

		public static SAVE_TIME_KEY = "noticeTime";

		private _textList: fairygui.GList;
		private _titleList: fairygui.GList;
		private _text: fairygui.GRichTextField;
		private _closeBtn: fairygui.GButton;

		public initUI() {
			super.initUI();

			this.modal = true;
			this.center();

			this._myParent = Core.LayerManager.inst.topLayer;

			this._textList = this.getChild("textList").asList;
			this._titleList = this.getChild("pageList").asList;
			this._text = this._textList.getChildAt(0).asCom.getChild("mailText").asRichTextField;
			this._closeBtn = this.getChild("closeBtn").asButton;

			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);
		}

		public async open(...param: any[]) {
			await super.open(...param);

			let noticeIds = Data.notice_config.keys;
			let firstCom: NoticeChkCom = null;
			noticeIds.forEach(noticeId => {
				let com = fairygui.UIPackage.createObject(PkgName.login, "noticeChk", NoticeChkCom) as NoticeChkCom;
				com.setNoticeId(noticeId, (noticeId: number) => {
					this._onChooseNotice(noticeId);
				});
				this._titleList.addChild(com);
				if (!firstCom) {
					firstCom = com;
				}
			});
			if (firstCom) {
				this._onChooseNotice(firstCom.noticeId);
				firstCom.getController("button").setSelectedPage("down");
			}
		}

		private _onChooseNotice(noticeId: number) {
			this._text.text = "\n" + Data.notice_config.get(noticeId).content;
		}

		public async close(...param: any[]) {
			await super.close(...param);
			Core.ViewManager.inst.closeView(this);
		}

		public static async tryOpenNoticePanel() {
			let noticeIds = Data.notice_config.keys;
			if (noticeIds.length <= 0) {
				return;
			} else {
				let saveTimeStr = egret.localStorage.getItem(LoginNoticeView.SAVE_TIME_KEY);
				let saveTime = "";
				if (saveTimeStr && saveTimeStr != "") {
					saveTime = JSON.parse(saveTimeStr);
				}
				let newTime = Data.notice_config.get(noticeIds[0]).time;
				if (saveTime != newTime) {
					await Core.ViewManager.inst.open(ViewName.noticeView);
					saveTimeStr = JSON.stringify(newTime);
					egret.localStorage.setItem(LoginNoticeView.SAVE_TIME_KEY, saveTimeStr);
				}
				
			}
		}
	}
}