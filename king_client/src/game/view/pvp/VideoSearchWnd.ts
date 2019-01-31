module Pvp {

	export class VideoSearchWnd extends Core.BaseWindow {

		private _closeBtn: fairygui.GButton;
		private _confirmBtn: fairygui.GButton;
		private _searchInput: fairygui.GTextInput;
		private _warningText: fairygui.GTextField;

		public initUI() {
			
			super.initUI();
			this.center();
			this.modal = true;

			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
			this._searchInput = this.contentPane.getChild("searchInput").asTextInput;
			this._warningText = this.contentPane.getChild("warning").asTextField;

			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);

			this._confirmBtn.addClickListener(this._onSearch, this);
			this._searchInput.addEventListener(egret.Event.FOCUS_IN, () => {
				this._warningText.text = "";
			}, this);
		}

		public async open(...param: any[]) {
			super.open(...param);
			this._warningText.text = "";
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._searchInput.text = "";
		}

		private async _onSearch() {
			let id = Core.StringUtils.stringToLong(this._searchInput.text);
			if (!id) {
				this._warningText.text = Core.StringUtils.TEXT(60156);
				return;
			}
			let args = {VideoID: id};
			let result = await Net.rpcCall(pb.MessageID.C2S_WATCH_VIDEO, pb.WatchVideoArg.encode(args));
				if (result.errcode == 0) {
					Core.ViewManager.inst.closeView(this);
					let reply = pb.WatchVideoResp.decode(result.payload);
					await Battle.VideoPlayer.inst.play(<pb.VideoBattleData>reply.VideoData);
					this._warningText.text = "";
				} else {
					this._warningText.text = Core.StringUtils.TEXT(60114);
					return;
				}	
			}
		}
}