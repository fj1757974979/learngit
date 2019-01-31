module Social {

	export class ChatletCom extends fairygui.GComponent {

		private _chatlet: IChatlet;
		private _headCom: Social.HeadCom;
		private _nameText: fairygui.GTextField;
		private _messageText: fairygui.GTextField;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._headCom = this.getChild("head").asCom as Social.HeadCom;
			this._nameText = this.getChild("name").asTextField;
			this._messageText = this.getChild("messageTxt").asTextField;
		}

		public setChatlet(chatlet: IChatlet) {
			this._headCom.setAll(chatlet.headUrl, `headframe_${chatlet.frameUrl}_png`);
			this._nameText.text = chatlet.name;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._messageText.text = chatlet.msg;
			this._messageText.funcParser = Core.StringUtils.parseFuncText;
			if (chatlet.pvpLevel != 0) {
				if (chatlet.uid == Player.inst.uid && chatlet.pvpLevel < 2) {
					this.getChild("rankTitleText").asTextField.text = Pvp.Config.inst.getPvpTitle(Pvp.PvpMgr.inst.getPvpLevel());
				} else {
					this.getChild("rankTitleText").asTextField.text = Pvp.Config.inst.getPvpTitle(chatlet.pvpLevel);
				}

				this.getChild("rankTitleText").visible = true;
			} else {
				this.getChild("rankTitleText").visible = false;
			}

			let h = this.getChild("contentGrp").height;
			//this.height = h + this.getChild("time").height;
			let textLength = chatlet.msg.length;
			let textWidth = this._messageText.textWidth;
			let textHeight = this._messageText.height;
			let lineNums = (<egret.TextField>(this._messageText.displayObject)).numLines;
			//文字区域最大长度350，未换行时气泡大小随着内容多少变化
			if (textWidth <= 350 && lineNums <= 1) { //textHeight <=30) {
				this.getChild("bottom").asLoader.width = textWidth + 20;
			} else 	{
			//对于自己的发言，换行后左对齐
				this._messageText.align = fairygui.AlignType.Left;
			}
			

			// this.getChild("bottom").asLoader.width = this._messageText.height;

			this._headCom.addClickListener(this._onDetail, this);
			if (window.gameGlobal.isMultiLan) {
				// 多语言版本显示国旗
				let flagImgWnd = this.getChild("countryFlagImg").asImage;
				flagImgWnd.visible = true;
				LanguageMgr.inst.setCountryFlagImg(flagImgWnd, UserLocalCache.inst.getUserCountry(chatlet.uid));
			}
			this._headCom.addClickListener(this._onDetail, this);
			this._chatlet = chatlet;
		}

		public showTimeText(b: boolean) {
			this.getChild("time").visible = b;
			let h = this.getChild("contentGrp").height;
			if (b) {
				let time = this._chatlet.timeStamp;
				this.getChild("time").asTextField.text = ChatMgr.secToChatDate(time);
			} else {
				//不显示时间高度降低30
				this.height = this.height - 30;
				this.getChild("time").asTextField.height = 10;
			}
		}

		private async _onDetail() {
			if (this._chatlet.isMyselfChat()) {
				await Social.SocialMgr.inst.openSelfInfoView();
			} else {
				let playerInfo = await FriendMgr.inst.fetchPlayerInfo(this._chatlet.uid);
				if (playerInfo) {
					Core.ViewManager.inst.open(ViewName.friendInfo, this._chatlet.uid, playerInfo);
				}
			}
		}
	}
}
