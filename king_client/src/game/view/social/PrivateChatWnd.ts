module Social {

	export class PrivateChatWnd extends Core.BaseWindow {

		private _closeBtn: fairygui.GButton;
		private _emojiBtn: fairygui.GButton;
		private _chatletList: fairygui.GList;
		private _inputText: fairygui.GTextInput;
		private _sendBtn: fairygui.GButton;
		private _nameText: fairygui.GTextField;
		private _lastTime: number;
		private _lastItem: ChatletCom;
		private _uid: Long;
		private _toName: string;
		private _toHeadUrl: string;

		private _arrayChat: Array<PrivateChatlet>;
		private _loadIndex: number;

		private _closeCallback: () => void;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._chatletList = this.contentPane.getChild("chatletList").asList;
			this._inputText = this.contentPane.getChild("inputText").asTextInput;
			this._sendBtn = this.contentPane.getChild("sendBtn").asButton;
			this._nameText = this.contentPane.getChild("name").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._emojiBtn = this.contentPane.getChild("emojiBtn").asButton;

			this._chatletList.scrollPane.addEventListener(fairygui.ScrollPane.PULL_DOWN_RELEASE, this._renderList, this);

			this._closeBtn.addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			}, this);
			this._sendBtn.addClickListener(this._onSend, this);
			this._emojiBtn.addClickListener(this._onEmoji, this);
			this._emojiBtn.visible = Home.FunctionMgr.inst.isEmojiToChatOpen();
		}

		public async open(...param: any[]) {
			super.open(...param);

			let uid = <Long>param[0];
			this._closeCallback = <()=>void>param[1];
			this._toName = <string>param[2];
			this._toHeadUrl = <string>param[3];
			if (!this._toName || !this._toHeadUrl) {
				let playerInfo = await FriendMgr.inst.fetchPlayerInfo(uid);
				if (playerInfo) {
					this._toName = playerInfo.Name;
				}
			}
			this._nameText.text = this._toName;
			let chatlets = await ChatMgr.inst.getPrivateChatlets(uid);
			ChatMgr.inst.cleanPrivateHintsNum(uid);
			this._lastTime = 0;
			this._lastItem = null;
			this._arrayChat = new Array<PrivateChatlet>();
			this._loadIndex = 0;
			if (chatlets) {
				chatlets.sort( (a, b) => {
					return a.timeStamp - b.timeStamp;
				})
				// this.addChatlets(chatlets, false);
				this._arrayChat = chatlets;
				this._loadIndex = this._arrayChat.length;
				this._loadChatlets();
			}
			this._uid = uid;
			ChatMgr.inst.currentChatUid = uid;
			Core.EventCenter.inst.addEventListener(GameEvent.PrivateChat, this._onPrivateChat, this);
		}

		private _addChatlets(chatlets: Array<PrivateChatlet>, isLoad?: boolean) {
			if (isLoad) {
				let lastIndex = chatlets.length - 1;
				for (let i = chatlets.length - 1; i >= 0; i--) {
					let item = this._addChatlet(chatlets[i]);
					item.showTimeText(true);
					this._chatletList.addChildAt(item, 0);
				}
				this._chatletList.scrollToView(lastIndex, false);
			} else {
				chatlets.forEach(chatlet => {
				let item = this._addChatlet(chatlet);
				this._chatletList.addChild(item);
				if (chatlet.timeStamp - this._lastTime > 60) {
					item.showTimeText(true);
				} else {
					item.showTimeText(false);
				}
				this._lastTime = chatlet.timeStamp;
				// this._lastItem = item;
				});
			}
			this._chatletList.cacheContent(false);
		}
		private _addChatlet(chatlet: PrivateChatlet) {
			let item = null;
			if (chatlet.isMyselfChat()) {
				item = fairygui.UIPackage.createObject(PkgName.social, "messageItemSelf", ChatletCom).asCom as ChatletCom;
			} else {
				item = fairygui.UIPackage.createObject(PkgName.social, "messageItem", ChatletCom).asCom as ChatletCom;
			}
			item.setChatlet(chatlet);
			
			return item;
		}

		public addChatlets(chatlets: Array<PrivateChatlet>, ani:boolean=true) {
			this._addChatlets(chatlets);
			if (this._chatletList.isBottomMost()) {
				// this._chatletList.scrollToView(this._chatletList.getChildIndex(this._lastItem), ani);
				this._chatletList.scrollToView(this._chatletList.numItems - 1, ani);
			}
		}

		private _loadChatlets() {
			let loadArray = new Array<PrivateChatlet>();
			if (this._loadIndex > 10) {
				loadArray = this._arrayChat.slice(this._loadIndex - 10, this._loadIndex);
				this._loadIndex -= 10;
			} else {
				loadArray = this._arrayChat.slice(0, this._loadIndex);
				this._loadIndex = 0;
			}
			this._chatletList.cacheContent(true);
			this._addChatlets(loadArray, true);
		}

		private async _renderList() {
			if (this._loadIndex <= 0) {
				return;
			}
			this._loadChatlets();
		}

		private async _onSend() {
			let text = this._inputText.text;
			if (!text || text == "") {
				return;
			}
			if (text.trim() == "") {
				return;
			}

			let playerInfo = await FriendMgr.inst.fetchPlayerInfo(this._uid);
			if (!playerInfo || !playerInfo.IsFriend) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60205));
				return;
			}
			let chatlets = await ChatMgr.inst.sendPrivateChat(this._uid, this._toName, this._toHeadUrl, text.trim());
			if (chatlets) {
				this.addChatlets(chatlets);
				this._inputText.text = "";
			}
		}

		private async _onEmoji() {
			Core.ViewManager.inst.openPopup(ViewName.emojiChoiceWnd, async (emojiIdx: number) => {
				let text = `#fimg,ui://common/emoji${emojiIdx}(98,98)#e`;
				let playerInfo = await FriendMgr.inst.fetchPlayerInfo(this._uid);
				if (!playerInfo || !playerInfo.IsFriend) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60205));
					return;
				}
				let chatlets = await ChatMgr.inst.sendPrivateChat(this._uid, this._toName, this._toHeadUrl, text);
				if (chatlets) {
					this.addChatlets(chatlets);
					this._inputText.text = "";
				}
            });
		}

		private _onPrivateChat(evt: egret.Event) {
			let chatlets = <Array<PrivateChatlet>>evt.data;
			if (chatlets.length > 0 && chatlets[0].uid == this._uid) {
				this.addChatlets(chatlets);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);

			if (this._closeCallback) {
				this._closeCallback();
				this._closeCallback = null;
			}

			this._chatletList.removeChildren();
			ChatMgr.inst.currentChatUid = null;
			Core.EventCenter.inst.removeEventListener(GameEvent.PrivateChat, this._onPrivateChat, this);
		}
	}
}
