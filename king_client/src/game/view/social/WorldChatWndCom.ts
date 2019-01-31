module Social {
	export class WorldChatWndCom extends fairygui.GComponent implements ISocialCom {

		private _chatletList: fairygui.GList;
		private _inputText: fairygui.GTextInput;
		private _sendBtn: fairygui.GButton;
		private _emojiBtn: fairygui.GButton;
		private _lastTime: number;
		private _lastItem: ChatletCom;
		private _emptyHintText: fairygui.GTextField;

		private _chatNum: number;
		private _initialized: boolean;
		private _MAX_CHAT_NUM: number;
		private _CLEAR_CHAT_NUM: number;
		private _channel: number;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._chatletList = this.getChild("chatletList").asList;
			this._inputText = this.getChild("inputText").asTextInput;
			this._sendBtn = this.getChild("sendBtn").asButton;
			this._emojiBtn = this.getChild("emojiBtn").asButton;
			let emptyHintText = this.getChild("emptyHintText");
			if (emptyHintText) {
				this._emptyHintText = emptyHintText.asTextField;
			}

			this._sendBtn.addClickListener(this._onSend, this);
			this._emojiBtn.addClickListener(this._onEmoji, this);
			this._emojiBtn.visible = Home.FunctionMgr.inst.isEmojiToChatOpen();
			this._lastTime = 0;
			
			this._chatNum = 0;
			this._MAX_CHAT_NUM = 60;
			this._CLEAR_CHAT_NUM = 30;
			this._initialized = false;
			this._channel = ChatChannel.WORLD;

			Player.inst.addEventListener(Player.LoginEvt, () => {
				this._initialized = false;
				this._removeChatlets();
			}, this);

			Core.EventCenter.inst.addEventListener(GameEvent.UnSubscribeChatEv, (ev:egret.Event)=>{
				if (ev.data != this._channel) {
					return;
				}
				this._initialized = false;
			}, this);
		}

		private _removeChatlets() {
			this._chatNum = 0;
			this._chatletList.removeChildren(0, -1, true);
			this._lastTime = 0;
		}

		public setChannel(channel:number) {
			this._channel = channel;
		}

		public async refresh() {
			if (!this._initialized) {
				let chatlets = ChatMgr.inst.drainWorldChatlets(this._channel);
				this._lastTime = 0;
				this._lastItem = null;
				// this._chatletList.cacheContent(false);
				this._chatletList.removeChildren(0, -1, true);
				chatlets.forEach(chatlet => {
					this._addChatlet(chatlet);
				});
				// this._chatletList.cacheContent(true);
				if (this._lastItem) {
					this._chatletList.scrollToView(this._chatletList.getChildIndex(this._lastItem), false);
				}
				this._initialized = true;
			}
		}

		private _addChatlet(chatlet: IChatlet) {
			let item = null;
			if (chatlet.type == ChatType.Normal) {
				if (chatlet.isMyselfChat()) {
					item = fairygui.UIPackage.createObject(PkgName.social, "messageItemSelf", ChatletCom).asCom as ChatletCom;
				} else {
					item = fairygui.UIPackage.createObject(PkgName.social, "messageItem", ChatletCom).asCom as ChatletCom;
				}			
				item.setChatlet(chatlet);
				if (chatlet.timeStamp - this._lastTime > 60) {
					item.showTimeText(true);
				} else {
					item.showTimeText(false);
				}
			} else if (chatlet.type == ChatType.CampaignNotice) {
				let rawData = (<CampaignNoticeChatlet>chatlet).getNoticeRawData();
				if (rawData.Type != pb.CampaignNoticeType.AutocephalyVoteNt) {
					item = fairygui.UIPackage.createObject(PkgName.war, "noticeFunctionItem").asCom as War.WarNoticeItem;
					item.setNotice(rawData);
				}
			}
			
			if (item) {
				this._chatletList.addChild(item);
				this._lastTime = chatlet.timeStamp;
				this._lastItem = item;
				this._chatNum += 1;
			}
		}

		public addChatlet(chatlet: PrivateChatlet) {
			if (!this._initialized) {
				return;
			}
			this._addChatlet(chatlet);
			if (this._chatNum > this._MAX_CHAT_NUM) {
				this._chatletList.removeChildren(0, this._chatNum - this._CLEAR_CHAT_NUM - 1);
				this._chatNum = this._CLEAR_CHAT_NUM;
			}
			if (this._chatletList.isBottomMost()) {
				this._chatletList.scrollToView(this._chatletList.getChildIndex(this._lastItem), true);
			}
		}

		public async onChosen(b: boolean) {
			if (b) {
				if (!this._initialized) {
					let ok = await ChatMgr.inst.subscribeChat(this._channel);
					this._removeChatlets();
					if (this._emptyHintText) {
						this._emptyHintText.visible = !ok;
					}
					return ok;
				}
				// await ChatMgr.inst.subscribeChat(ChatChannel.WORLD);
			} else {
				// await ChatMgr.inst.unsubscribeChat(ChatChannel.WORLD);
				// this._chatletList.removeChildren(0, -1, true);
				if (this._chatNum > this._MAX_CHAT_NUM) {
					this._chatletList.removeChildren(0, this._chatNum - this._CLEAR_CHAT_NUM - 1);
					this._chatNum = this._CLEAR_CHAT_NUM;
					this._chatletList.scrollToView(this._chatletList.getChildIndex(this._lastItem));
				}
				return true;
			}
		}

		private async _onSend() {
			
			let text = this._inputText.text;
			if (!text || text == "") {
				return;
			}
			if (text.trim() == "") {
				return;
			}

			let success = await ChatMgr.inst.sendChat(this._channel, text.trim());
			if (success) {
				this._inputText.text = "";
			}
		}

		private async _onEmoji() {
			Core.ViewManager.inst.openPopup(ViewName.emojiChoiceWnd, (emojiIdx: number) => {
				let text = `#fimg,ui://common/emoji${emojiIdx}(98,98)#e`;
				ChatMgr.inst.sendChat(this._channel, text);
            });
		}
	}
}