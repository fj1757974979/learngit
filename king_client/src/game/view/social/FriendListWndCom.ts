module Social {

	export class FriendOptionWnd extends Core.BaseWindow {

		private _uid: Long;
		private _friend: Friend;

		private _viewBtn: fairygui.GButton;
		private _fightBtn: fairygui.GButton;
		private _chatBtn: fairygui.GButton;

		public initUI() {
			super.initUI();
			this._viewBtn = this.contentPane.getChild("viewBtn").asButton;
			this._fightBtn = this.contentPane.getChild("fightBtn").asButton;
			this._chatBtn = this.contentPane.getChild("chatBtn").asButton;

			this._viewBtn.addClickListener(this._onDetail, this);
			this._fightBtn.addClickListener(this._onFight, this);
			this._chatBtn.addClickListener(this._onChat, this);

			if (!LanguageMgr.inst.isChineseLocale()) {
				this._viewBtn.getChild("title").asTextField.fontSize = 12;
				this._fightBtn.getChild("title").asTextField.fontSize = 12;
				this._chatBtn.getChild("title").asTextField.fontSize = 12;
			}
		}

		public async open(...param: any[]) {
			super.open(...param);
			this._friend = <Friend>param[0];
			this._uid = this._friend.uid;
			this.x = param[1];
			this.y = param[2];
			// this.root.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
			let playerInfo = await FriendMgr.inst.fetchPlayerInfo(this._uid);
			if (playerInfo && playerInfo.CanInviteBattle) {
				this.contentPane.getChild("fightBtn").enabled = true;
			} else {
				this.contentPane.getChild("fightBtn").enabled = false;
			}
		}

		private async _onDetail() {
			let playerInfo = await FriendMgr.inst.fetchPlayerInfo(this._uid);
			if (playerInfo) {
				Core.ViewManager.inst.open(ViewName.friendInfo, this._uid, playerInfo);
				Core.ViewManager.inst.closeView(this);
			}
		}

		private async _onFight() {
			if (await FriendMgr.inst.inviteBattle(this._uid)) {
				await Core.ViewManager.inst.open(ViewName.inviteWaiting, () => {
					FriendMgr.inst.cancelInviteBattle();
				});
				Core.ViewManager.inst.closeView(this);
			}
		}

		private _onChat() {
			this.visible = false;
			Core.ViewManager.inst.open(ViewName.privateChatWnd, this._uid, () => {
				this.visible = true;
			}, this._friend.name, this._friend.headImgUrl);
		}

		public async close(...param: any[]) {
			super.close(...param);
			// this.root.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onClose, this);
		}

		private _onClose(evt:egret.TouchEvent) {
			let x = evt.stageX / fairygui.GRoot.contentScaleFactor;
			let y = evt.stageY / fairygui.GRoot.contentScaleFactor;
			if (x >= this.x && x <= this.x + this.width && y >= this.y && y <= this.y + this.height) {
				return;
			} else {
				Core.ViewManager.inst.closeView(this);
			}
		}
	}

	export class FriendItemBase extends fairygui.GComponent {
		protected _headCom: HeadCom;
		protected _nameText: fairygui.GTextField;
		protected _rankTitleText: fairygui.GTextField;
		protected _rankImg: fairygui.GLoader;
		protected _scoreText: fairygui.GTextField;
		protected _wechatFlag: fairygui.GLoader;

		protected _onlineCtrl: fairygui.Controller;

		protected _friend: Friend;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._headCom = this.getChild("head").asCom as HeadCom;
			this._nameText = this.getChild("nameText").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._rankTitleText = this.getChild("rankTitleText").asTextField;
			this._rankImg = this.getChild("rankImg").asLoader;
			this._scoreText = this.getChild("scoreText").asTextField;
			if (this.getChild("wechatFlag")) {
				this._wechatFlag = this.getChild("wechatFlag").asLoader;
			} else {
				this._wechatFlag = null;
			}

			this._onlineCtrl = this.getController("online");
		}

		public setFriendInfo(friend: Friend) {
			this._headCom.setAll(friend.headImgUrl, `headframe_${friend.frameUrl}_png`);
			this._nameText.text = friend.name;
			let pvpScore = friend.score;
			let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel(pvpScore);
			this._rankTitleText.text = Pvp.Config.inst.getPvpTitle(pvpLevel);
			let team = Pvp.Config.inst.getPvpTeam(pvpLevel);
			this._rankImg.url = `common_rank${team}_png`;
			let star = Pvp.PvpMgr.inst.getPvpStarCnt(pvpScore);
			this._scoreText.text = `${star}`;

			if (friend.isOnline) {
				this._onlineCtrl.setSelectedIndex(1);
			} else {
				this._onlineCtrl.setSelectedIndex(0);
			}

			if (this._wechatFlag) {
				if (friend.isWeChatFriend) {
					this._wechatFlag.visible = true;
				} else {
					this._wechatFlag.visible = false;
				}
			}

			this._friend = friend;
		}

		public get friend(): Friend {
			return this._friend;
		}
	}

	class LastOppItemCom extends FriendItemBase {
		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
		}
	}

	export class FriendItemCom extends FriendItemBase {

		private _offlineTimeText: fairygui.GTextField;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._offlineTimeText = this.getChild("offlineTime").asTextField;
		}

		public setFriendInfo(friend: Friend) {
			super.setFriendInfo(friend);

			let onlineTime = friend.lastOnlineTime;
			if (onlineTime && onlineTime > 0) {
				console.debug(`${Date.now()/1000}`, `${onlineTime}`)
				this._offlineTimeText.text = `${Core.StringUtils.secToString(Date.now()/1000 - onlineTime, "dhm")}`;
			}
		}
	}

	export class FriendListWndCom extends fairygui.GComponent implements ISocialCom {

		private _friendList: fairygui.GList;
		private _searchBtn: fairygui.GButton;
		private _applyListBtn: fairygui.GButton;
		private _inviteBtn: fairygui.GButton;
		private _wechatInviteBtn: fairygui.GButton;

		private _uid2FriendItem: Collection.Dictionary<Long, FriendItemBase>;

		private _friendsIndex: number;
		private _friendsArray: Array<Friend>;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._friendList = this.getChild("friendList").asList;
			this._searchBtn = this.getChild("searchBtn").asButton;
			this._applyListBtn = this.getChild("applyBtn").asButton;
			this._inviteBtn = this.getChild("inviteBtn").asButton;
			this._wechatInviteBtn = this.getChild("wechatBtn").asButton;
			
			this._friendsIndex = 0;
			this._friendsArray = new Array<Friend>();
			this._friendList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._pullList, this);

			if (Core.DeviceUtils.isWXGame()) {
				this._inviteBtn.visible = true;
				this._wechatInviteBtn.visible = true;
			} else {
				this._inviteBtn.visible = false;
				this._wechatInviteBtn.visible = false;
			}


			this._friendList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardItem, this);
			this._applyListBtn.addClickListener(() => {
				Core.ViewManager.inst.open(ViewName.applyInfo);
			}, this);
			this._searchBtn.addClickListener(() => {
				Core.ViewManager.inst.open(ViewName.friendSearch);
			}, this);
			this._wechatInviteBtn.addClickListener(this._onWechatFight, this);
			this._inviteBtn.addClickListener(this._onWechatInvite, this);

			this._uid2FriendItem = new Collection.Dictionary<Long, FriendItemBase>();
			Core.EventCenter.inst.addEventListener(GameEvent.DeletedByFriend, this._onBeDeleted, this);
			Core.EventCenter.inst.addEventListener(GameEvent.DelFriend, this._onDelFriend, this);
			(<ApplyFriendHintCom>this.getChild("applyFriendNewHint").asCom).observerFriendApplyNum();
		}

		public async refresh() {
			let result = await FriendMgr.inst.fetchFriendList();
			// this._friendList.cacheContent(false);
			this._friendList.removeChildren(0, -1, true);
			this._uid2FriendItem.clear();
			if (result) {
				let opp = result.lastOpp;
				if (opp) {
					let oppItem = fairygui.UIPackage.createObject(PkgName.social, "lastOpponent", LastOppItemCom).asCom as LastOppItemCom;
					oppItem.setFriendInfo(opp);
					this._friendList.addChild(oppItem);
				}
			}

			if (result.friends != null) {
				this._friendsIndex = 0;
				this._friendsArray = result.friends;
				this._pullList();
				//
				// result.friends.forEach(friend => {
				// 	let friendItem = fairygui.UIPackage.createObject(PkgName.social, "friendItem", FriendItemCom).asCom as FriendItemCom;
				// 	friendItem.setFriendInfo(friend);
				// 	friendItem.displayObject.cacheAsBitmap = true;
				// 	this._friendList.addChild(friendItem);
				// 	this._uid2FriendItem.setValue(friend.uid, friendItem);
				// });
				//
				// this._friendList.cacheContent(true);
				if (result.friends.length > 0 ) {
					this.getChild("emptyHintText").visible = false;
				} else {
					this.getChild("emptyHintText").visible = true;
				}
			}
		}

		private async _addFriends(friends: Friend[]) {
			friends.forEach(friend => {
					let friendItem = fairygui.UIPackage.createObject(PkgName.social, "friendItem", FriendItemCom).asCom as FriendItemCom;
					friendItem.setFriendInfo(friend);
					friendItem.displayObject.cacheAsBitmap = true;
					this._friendList.addChild(friendItem);
					this._uid2FriendItem.setValue(friend.uid, friendItem);
				});
		}

		private async _pullList() {
			let count = 30;
			if (this._friendsArray.length <= this._friendsIndex) {
				return;
			}

			if (this._friendsArray.length <= this._friendsIndex + count) {
				count = this._friendsArray.length - this._friendsIndex;
			}
			let _friends = this._friendsArray.slice(this._friendsIndex, this._friendsIndex + count);
			this._friendsIndex += count;
			this._addFriends(_friends);
		}

		public async onChosen(b: boolean) {
			/*
			if (!b) {
				this._friendList.removeChildren(0, -1, true);
				this._uid2FriendItem.clear();
			}
			*/
			return true;
		}

		private async _onClickCardItem(evt:fairygui.ItemEvent) {
			let item = evt.itemObject as FriendItemBase;
			let friend = item.friend;
			if (item instanceof LastOppItemCom) {
				let playerInfo = await FriendMgr.inst.fetchPlayerInfo(friend.uid);
				if (playerInfo) {
					Core.ViewManager.inst.open(ViewName.friendInfo, friend.uid, playerInfo);
				}
			} else {
				//console.log(`${evt.stageY} ${fairygui.GRoot.contentScaleFactor}`);
				let x = 260;
				let y = evt.stageY / fairygui.GRoot.contentScaleFactor - 30;
				await Core.ViewManager.inst.openPopup(ViewName.friendOption, friend, x, y);
				//let view = <FriendOptionWnd>Core.ViewManager.inst.getView(ViewName.friendOption);
				//view.toTopLayer();
				// let x = evt.stageX / fairygui.GRoot.contentScaleFactor;
				// if (x + view.width > fairygui.GRoot.inst.getDesignStageWidth()) {
				// 	x = fairygui.GRoot.inst.getDesignStageWidth() - view.width;
				// }
				// view.x = x;
				// view.y = y;
			}
		}

		private _onBeDeleted(evt:egret.Event) {
			let uid = <Long>evt.data;
			if (this._uid2FriendItem.containsKey(uid)) {
				let item = this._uid2FriendItem.getValue(uid);
				this._friendList.removeChild(item);
				this._uid2FriendItem.remove(uid);
			}
		}

		private _onDelFriend(evt:egret.Event) {
			let uid = <Long>evt.data;
			let item = this._uid2FriendItem.getValue(uid);
			this._friendList.removeChild(item);
			this._uid2FriendItem.remove(uid);
		}

		private _onWechatFight() {
			WXGame.WXShareMgr.inst.wechatFight();
		}

		private _onWechatInvite() {
			WXGame.WXShareMgr.inst.wechatInvite();
		}
	}
}