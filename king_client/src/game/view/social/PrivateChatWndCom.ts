module Social {

	export class PrivateChatItemCom extends fairygui.GComponent {

		private _newHintCom: PrivateChatHintCom;
		private _uid: Long;
		private _chatlet: PrivateChatlet;
		private _time: number;
		private _lastChatlet: PrivateChatlet;
		private _headCom: Social.HeadCom;
		private _nameText: fairygui.GTextField;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._newHintCom = this.getChild("newHint").asCom as PrivateChatHintCom;
			this._headCom = this.getChild("head").asCom as Social.HeadCom;
			this._nameText = this.getChild("name").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this.addClickListener(this._onClick, this);
		}

		public async setUid(chatlet: PrivateChatlet,uid: Long) {
			this._uid = uid;
			this._chatlet = chatlet;
			return await this.refresh();
		}

		public async refresh() {
			let chatlet = this._chatlet;
			if (chatlet) {
				this._headCom.setAll(chatlet.fromHeadUrl, `headframe_${chatlet.frameUrl}_png`);
				this._nameText.text = chatlet.fromName;
				let message = chatlet.msg;
				if (message.indexOf("#fimg") >=0) {
					message = Core.StringUtils.TEXT(70188);
				}
				this.getChild("lastMessageTxt").asTextField.text = message;
				this.getChild("lastMessageTxt").asTextField.funcParser = Core.StringUtils.parseFuncText;
				this.getChild("lastMessageTxt").asTextField.touchable = false;
				this.getChild("lastMessageTime").asTextField.text = ChatMgr.secToChatDate(chatlet.timeStamp);
				this._newHintCom.observePrivateChatNum(this._uid);
				this._time = chatlet.timeStamp;
				this._lastChatlet = chatlet;
				return true;
			} else {
				return false;
			}
		}

		public get time(): number {
			return this._time;
		}

		private async _onClick() {
			if (this._uid) {
				Core.ViewManager.inst.open(ViewName.privateChatWnd, this._uid, async () => {
					this._chatlet = await ChatMgr.inst.getLatestPrivateChatlet(this._uid);
					await this.refresh();
				}, this._lastChatlet.fromName, this._lastChatlet.fromHeadUrl);
			}
		}
	}
	
	export class PrivateChatWndCom extends fairygui.GComponent implements ISocialCom {

		private _entryList: fairygui.GList;
		private _uidToItem: Collection.Dictionary<string, PrivateChatItemCom>;
		private _chatlets: Collection.Dictionary<Long, PrivateChatlet>;
		private _uidlist: Array<Long>;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._entryList = this.getChild("chatEntryList").asList;
			this._uidToItem = new Collection.Dictionary<string, PrivateChatItemCom>();
			this._entryList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._pullChatList, this);
		}

		public async refresh() {
			this._chatlets = new Collection.Dictionary<Long, PrivateChatlet>();
			this._uidlist = new Array<Long>();
			//获取好友列表
			await FriendMgr.inst.fetchFriendList();
			if (this._entryList.numItems > 0) {
				this._entryList.scrollToView(0);
			}
			this._entryList.removeChildren();
			
			let uidKeys = await ChatMgr.inst.getPrivateUidKeys();
			let allItems: Array<PrivateChatItemCom> = [];
			for (let i = 0; i < uidKeys.length; ++ i) {
				let key = uidKeys[i];
				let uid = Core.StringUtils.stringToLong(key);
				let chatlet = await ChatMgr.inst.getLatestPrivateChatlet(uid);
				if (chatlet) {
					this._chatlets.setValue(uid,chatlet);
					this._uidlist.push(uid);
				}
			};
			this._uidlist.sort((id1: Long, id2: Long): number => {
				if (this._chatlets.getValue(id1).timeStamp < this._chatlets.getValue(id2).timeStamp) {
					return 1;
				} else {
					return -1;
				}
			});
			if (this._uidlist.length > 0) {
				this.getChild("emptyHintText").visible = false;
				this._pullChatList();
			} else {
				this.getChild("emptyHintText").visible = true;
			}
		}

		private async _pullChatList() {
			let count = 0;
			if (this._uidlist.length > 10) {
				count = 10;
			} else {
				count = this._uidlist.length;
			}
			let friends = FriendMgr.inst.friends;
			for (let i = 0; i < count; i++) {
				let _uid = this._uidlist.splice(0,1)[0];
				let chatlet = this._chatlets.getValue(_uid);
				if (friends) {
					friends.forEach( _friend => {
						if (_friend.uid == _uid) {
							chatlet.fromHeadUrl = _friend.headImgUrl;
							chatlet.fromName = _friend.name;
							chatlet.frameUrl = _friend.frameUrl;
						}
					})
				}
				let item = fairygui.UIPackage.createObject(PkgName.social, "privateChatItem", PrivateChatItemCom).asCom as PrivateChatItemCom;
				item.setUid(chatlet, _uid);
				this._uidToItem.setValue(`${_uid}`, item);
				this._entryList.addChild(item);
			}
		}

		public async onChosen(b: boolean) {
			if (b) {
				Core.EventCenter.inst.addEventListener(GameEvent.PrivateChat, this._onPrivateChat, this);
			} else {
				Core.EventCenter.inst.removeEventListener(GameEvent.PrivateChat, this._onPrivateChat, this);
			}
			return true;
		}

		private async _onPrivateChat(evt: egret.Event) {
			let chatlets = <Array<PrivateChatlet>>evt.data;
			if (chatlets.length > 0) {
				let uid = `${chatlets[0].uid}`;
				let item = this._uidToItem.getValue(uid);
				if (item) {
					this._entryList.removeChild(item);
					this._entryList.addChildAt(item, 0);
					await item.refresh();
				} else {
					for (let i = 0; i < this._uidlist.length; i ++) {
						if (this._uidlist[i] == chatlets[0].uid) {
							this._uidlist.splice(i, 1);
							break;
						} 
					}
					let item = fairygui.UIPackage.createObject(PkgName.social, "privateChatItem", PrivateChatItemCom).asCom as PrivateChatItemCom;
					item.setUid(chatlets[0],chatlets[0].uid);
					this._uidToItem.setValue(`${chatlets[0].uid}`, item);
					this._entryList.addChild(item);
				}
			}
		}
	}
}