module Social {
	export class FriendListOptionWnd extends Core.BaseWindow {

		private _optCallback: (friend?: Friend) => void;
		private _friendList: fairygui.GList;
		private _closeBtn: fairygui.GButton;
		private _friends: Array<Friend>

		public initUI() {
			super.initUI();
			this.modal = true;
			this.center();
			this._friendList = this.contentPane.getChild("friendList").asList;
			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._closeBtn.addClickListener(this._onClose, this);
			this._optCallback = null;

			this._friendList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickItem, this);
			this._friendList.itemClass = FriendItemCom;
			this._friendList.itemRenderer = this._renderFriendList;
			this._friendList.callbackThisObj = this;
			this._friendList.setVirtual();

			this._friends = [];
		}

		private async _onClickItem(evt: fairygui.ItemEvent) {
			let item = <FriendItemCom>evt.itemObject;
			if (this._optCallback) {
				this._optCallback(item.friend);
				this._optCallback = null;
			}
			Core.ViewManager.inst.closeView(this);
		}

		private async _renderFriendList(idx:number, item:fairygui.GObject) {
			let friend = this._friends[idx];
			let friendItem = <FriendItemCom>item;
			friendItem.setFriendInfo(friend);
		}

		public async open(...param: any[]) {
			await super.open(...param);
			this._optCallback = param[0];

			let result = await FriendMgr.inst.fetchFriendList();
			this._friendList.numItems = 0;
			if (result && result.friends != null) {
				this._friends = result.friends;
				this._friendList.numItems = this._friends.length;
			}
		}

		private async _onClose() {
			if (this._optCallback) {
				this._optCallback();
			}
			Core.ViewManager.inst.closeView(this);
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._optCallback = null;
		}
	}
}