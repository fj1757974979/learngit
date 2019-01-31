module Social {

	export class SocialView extends Core.BaseView {

		private _worldChatCom: WorldChatWndCom;
		// private _warChatCom: WorldChatWndCom;
		private _privateChatCom: PrivateChatWndCom;
		private _friendListCom: FriendListWndCom;

		private _switchCtrl: fairygui.Controller;
		private _curViewCom: ISocialCom;

		private _loadTimeoutHdr: () => void;

		public initUI() {
			super.initUI();
			this.height += Utils.getResolutionDistance();
			this.y = 0;
			this._worldChatCom = this.getChild("worldChatCom").asCom as WorldChatWndCom;
			// this._warChatCom = this.getChild("warChatCom").asCom as WorldChatWndCom;
			// this._warChatCom.setChannel(ChatChannel.CampaignCountry);
			this._privateChatCom = this.getChild("privateChatCom").asCom as PrivateChatWndCom;
			this._friendListCom = this.getChild("friendCom").asCom as FriendListWndCom;

			(<PrivateChatHintCom>this.getChild("privateChatNewHint").asCom).observePrivateChatNum();
			(<ApplyFriendHintCom>this.getChild("applyFriendNewHint").asCom).observerFriendApplyNum();

			this._switchCtrl = this.getController("switch");
			this._switchCtrl.addEventListener(fairygui.StateChangeEvent.CHANGED, this._onSwitch, this);
			Core.EventCenter.inst.addEventListener(Core.Event.HomeListChangedEvt, this._onHomeListChanged, this);
			Core.EventCenter.inst.addEventListener(GameEvent.AddFriend, this._onAddFriend, this);
			Core.EventCenter.inst.addEventListener(GameEvent.ChannelChatEv, this._onChannelChat, this);

			if (!LanguageMgr.inst.isChineseLocale()) {
				this.getChild("worldChk").asButton.getChild("title").asTextField.fontSize = 15;
				this.getChild("privateChk").asButton.getChild("title").asTextField.fontSize = 15;
				this.getChild("friendChk").asButton.getChild("title").asTextField.fontSize = 15;
			}
		}

		public async open(...param: any[]) {
			//console.log("open");
			await super.open(...param);
			//this._refreshCurView();
		}

		public async close(...param: any[]) {
			await super.close(...param);
		}

		private async _onHomeListChanged(ev?: egret.Event) {
			let homeViewName = ev ? <string>ev.data : ViewName.social;
			if (homeViewName == ViewName.social) {
				if (ChatMgr.inst.getPrivateHintsNum() > 0) {
					this._switchCtrl.setSelectedPage("private");
					this._curViewCom = this._privateChatCom;
				} else if (FriendMgr.inst.applyNum > 0) {
					this._switchCtrl.setSelectedPage("friend");
					this._curViewCom = this._friendListCom;
				} else {
					this._switchCtrl.setSelectedPage("world");
					this._curViewCom = this._worldChatCom;
				}

				if (!this._curViewCom) {
					this._switchCtrl.setSelectedPage("world");
					this._curViewCom = this._worldChatCom;
					let ok = await this._curViewCom.onChosen(true);
					if (ok) {
						await this._curViewCom.refresh();
					}
				} else {
					if (!this._loadTimeoutHdr) {
						this._loadTimeoutHdr = async () => {
							this._loadTimeoutHdr = null;
							let ok = await this._curViewCom.onChosen(true);
							if (ok) {
								await this._curViewCom.refresh();
							}
						};
						fairygui.GTimers.inst.add(1000, 1, this._loadTimeoutHdr, this);
					}
				}
			} else {
				if (this._loadTimeoutHdr) {
					fairygui.GTimers.inst.remove(this._loadTimeoutHdr, this);
					this._loadTimeoutHdr = null;
				}
				this._friendListCom.onChosen(false);
				this._worldChatCom.onChosen(false);
				// this._warChatCom.onChosen(false);
				this._privateChatCom.onChosen(false);
				// this._worldChatCom.onChosen(true);
				// this._worldChatCom.refresh();
			}
		}

		private async _onAddFriend(evt: egret.Event) {
			let name = <string>evt.data;
			if (this._switchCtrl.selectedPage == "friend") {
				this._refreshCurView();
			}
		}

		private async _onChannelChat(evt: egret.Event) {
			if (evt.data.channel == pb.ChatChannel.World) {
				let chatlet = <PrivateChatlet>evt.data.chatlet;
				this._worldChatCom.addChatlet(chatlet);
			}
			// } else if (evt.data.channel == pb.ChatChannel.CampaignCountry) {
			// 	let chatlet = <PrivateChatlet>evt.data.chatlet;
			// 	this._warChatCom.addChatlet(chatlet);
			// }
		}

		private async _onSwitch() {
			let page = this._switchCtrl.selectedPage;
			let view = null;
			if (page == "world") {
				view = this._worldChatCom;
			} else if (page == "private") {
				view = this._privateChatCom;
			}
			// else if (page == "war") {
			// 	view = this._warChatCom;
			// }
			else {
				// friend
				view = this._friendListCom;
			}
			if (view != this._curViewCom) {
				if (this._loadTimeoutHdr) {
					fairygui.GTimers.inst.remove(this._loadTimeoutHdr, this);
					this._loadTimeoutHdr = null;
				}
				if (this._curViewCom) {
					await this._curViewCom.onChosen(false);
				}
				this._curViewCom = view;
				let ok = await this._curViewCom.onChosen(true);
				if (ok) {
					await this._curViewCom.refresh();
				}
			}
		}
		public async refresh() {
			await this._onHomeListChanged();
			await this._onSwitch();
		}

		private async _refreshCurView() {
			if (this._loadTimeoutHdr) {
				fairygui.GTimers.inst.remove(this._loadTimeoutHdr, this);
				this._loadTimeoutHdr = null;
			}
			await this._curViewCom.refresh();
		}
	}
}
