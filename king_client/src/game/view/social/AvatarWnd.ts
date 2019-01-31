module Social {

	export class AvatarItemCom extends fairygui.GComponent {

		private _headIconImg: fairygui.GImage;
		private _newHintImg: fairygui.GLoader;
		private _url: string;
		private _cardId: number;
		private _card: CardPool.Card;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._headIconImg = this.getChild("headIcon").asImage;
			this._newHintImg = this.getChild("newHint").asLoader;
		}

		public setCard(card: CardPool.Card, skinId: string) {
			
			let cardId = card.cardId;
			if (skinId == "") {
				this._url = `avatar_${cardId}_png`;
			} else {
				this._url = `avatar_${CardPool.CardSkinMgr.inst.getSkinConf(skinId).head}_png`;
			}
			this._cardId = cardId;
			Utils.setImageUrlPicture(this._headIconImg, this._url);
			this._newHintImg.visible = CardPool.CardPoolMgr.inst.isAvatarNew(cardId);
		}

		public get url(): string {
			return this._url;
		}

		public get cardId(): number {
			return this._cardId;
		}

		public setCheck(b: boolean) {
			if (b) {
				this.getController("button").setSelectedPage("down");
			} else {
				this.getController("button").setSelectedPage("up");
			}
		}
	}

	export class FrameItemCom extends fairygui.GComponent {

		private _headFrameImg: fairygui.GImage;
		private _newHintImg: fairygui.GLoader;
		private _skinID: string;
		private _url: string;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._headFrameImg = this.getChild("headFrame").asImage;
			this._newHintImg = this.getChild("newHint").asLoader;
		}

		public setFrame(frameID: string) {
			// this._url = `headframe_${frameID}_png`;
			this._skinID = frameID;
			this._url = `headframe_${this._skinID}_png`;
			Utils.setImageUrlPicture(this._headFrameImg, this._url);
			this._newHintImg.visible = false;
		}

		public get SkinID(): string {
			return this._skinID;
		}

		public get url(): string {
			return this._url;
		}

		public setCheck(b: boolean) {
			if (b) {
				this.getController("button").setSelectedPage("down");
			} else {
				this.getController("button").setSelectedPage("up");
			}
		}
	}



	export class AvatarWnd extends Core.BaseWindow {

		private _confirmBtn: fairygui.GButton;
		private _headCom: HeadCom;
		private _nameText: fairygui.GTextField;
		private _headList: fairygui.GList;
		private _headFrameList: fairygui.GList;
		
		private _curItem: AvatarItemCom;
		private _curFrame: FrameItemCom;

		private _onceCards: Array<number>;
		
		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
			this._headCom = this.contentPane.getChild("head").asCom as HeadCom;
			this._nameText = this.contentPane.getChild("name").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._headList = this.contentPane.getChild("headList").asList;
			this._headFrameList = this.contentPane.getChild("headFrameList").asList;
			this.contentPane.getChild("headChk").visible = false;
			this.contentPane.getChild("headFrameChk").visible = false;
			

			this._confirmBtn.addClickListener(() => {
				if (this._curItem) {
					Player.inst.saveAvatarUrl(this._curItem.url);
				}
				if (this._curFrame) {
					Player.inst.saveFrameUrl(this._curFrame.SkinID);
				}
				CardPool.CardPoolMgr.inst.clearAvatarHintNum();
				Core.ViewManager.inst.closeView(this);
			}, this);

			this._headList.addEventListener(fairygui.ItemEvent.CLICK, this._onItemClick, this);
			this._headFrameList.addEventListener(fairygui.ItemEvent.CLICK, this._onFrameClick, this);
			this._curItem = null;
		}

		public async open(...param: any[]) {
			this.battleChangeLayer();
			super.open(...param);

			this._onceCards = new Array<number>();

			this._headCom.setAll(Player.inst.avatarUrl, Player.inst.frameUrl);
			this._nameText.text = Player.inst.name;

			let result1 = await Net.rpcCall(pb.MessageID.C2S_FETCH_HEAD, null);
			if (result1.errcode == 0) {
				this._onceCards = pb.HeadData.decode(result1.payload).OnceCards;
			}

			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_HEAD_FRAME, null);
			if (result.errcode == 0){
				let reply = pb.FetchHeadFrameReply.decode(result.payload);
				this._updateFrame(reply);
			}

			if (Core.DeviceUtils.isWXGame()) {
				this.contentPane.getChild("headChk").visible = false;
				this.contentPane.getChild("headFrameChk").visible = false;
				this.contentPane.getController("switch").selectedIndex = 1;
			} else {
				this.contentPane.getChild("headChk").visible = true;
				this.contentPane.getChild("headFrameChk").visible = true;
				this.contentPane.getController("switch").selectedIndex = 0;
				this._updateHead();
			}
		}

		private _updateHead() {
			this._headList.removeChildren();
			let cards: Array<CardPool.Card> = [];
			[Camp.WEI, Camp.SHU, Camp.WU, Camp.HEROS].forEach(camp => {
				let collectedCard = CardPool.CardPoolMgr.inst.getCollectCardsByCamp(camp, false);
				cards = cards.concat(collectedCard);
			});

			cards.forEach(card => {
				if (card.amount > 0 || card.level > 1 || this._onceCards.indexOf(card.cardId) != -1) {
					let skins = card.hasSkins;
					skins.forEach(skinId => {
						let item = fairygui.UIPackage.createObject(PkgName.social, "headItemCom").asCom as AvatarItemCom;
						item.setCard(card, skinId);
						this._headList.addChild(item);
						if (item.url == Player.inst.avatarUrl) {
							this._curItem = item;
							this._curItem.setCheck(true);
						}
					})
				}
			});
		}
		private _updateFrame(pbData: pb.FetchHeadFrameReply) {
			this._headFrameList.removeChildrenToPool();
			let headFrames = pbData.HeadFrames;
			headFrames.sort();

			headFrames.forEach((_headFrame) => {
				let com = this._headFrameList.addItemFromPool().asCom as FrameItemCom;
				if (!_headFrame || _headFrame == "") {
					_headFrame = "1";
				}
				com.setFrame(_headFrame);
				if (_headFrame == Player.inst.frameID) {
					this._curFrame = com;
					this._curFrame.setCheck(true);
				}
			})
		}

		private _onItemClick(evt: fairygui.ItemEvent) {
			let cardItem = evt.itemObject as AvatarItemCom;
			if (this._curItem != cardItem) {
				if (this._curItem) {
					this._curItem.setCheck(false);
				} 
				this._curItem = cardItem;
				if (this._curItem) {
					this._curItem.setCheck(true);
					this._headCom.setHead(this._curItem.url);
				}
			}
		}

		private _onFrameClick(evt: fairygui.ItemEvent) {
			let frameItem = evt.itemObject as FrameItemCom;
			if (this._curFrame != frameItem) {
				if (this._curFrame) {
					this._curFrame.setCheck(false);
				}
				this._curFrame = frameItem;
				if (this._curFrame) {
					this._curFrame.setCheck(true);
					this._headCom.setFrame(this._curFrame.url);
				}
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
		}
	}
}