module Social {
	export class FriendInfoWnd extends Core.BaseWindow {

		private _favoriteCardList: fairygui.GList;
		private _fightCardList: fairygui.GList;
		private _addFriendBtn: fairygui.GButton;
		private _delFriendBtn: fairygui.GButton;
		private _fightBtn: fairygui.GButton;
		private _chatBtn: fairygui.GButton;
		private _closeBtn: fairygui.GButton;
		private _relateCtrl: fairygui.Controller;
		private _warCtrl: fairygui.Controller;
		private _headCom: HeadCom;
		private _nameText: fairygui.GTextField;

		private _countryNameText: fairygui.GTextField;
		private _countryJobText: fairygui.GTextField;
		private _cityNameText: fairygui.GTextField;
		private _cityJobText: fairygui.GTextField;

		private _uid: Long;
		private _playerInfo: pb.PlayerInfo;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._favoriteCardList = this.contentPane.getChild("commonlyCard").asList;
			this._fightCardList = this.contentPane.getChild("cardList").asList;
			this._addFriendBtn = this.contentPane.getChild("addBtn").asButton;
			this._delFriendBtn = this.contentPane.getChild("deleteBtn").asButton;
			this._fightBtn = this.contentPane.getChild("fightBtn").asButton;
			this._chatBtn = this.contentPane.getChild("chatBtn").asButton;
			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._relateCtrl = this.contentPane.getController("relationship");
			this._warCtrl = this.contentPane.getController("war");
			this._nameText = this.contentPane.getChild("name").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;

			this._countryNameText = this.contentPane.getChild("country").asTextField;
			this._countryNameText.textParser = Core.StringUtils.parseColorText;
			this._countryJobText = this.contentPane.getChild("countryJob").asTextField;
			this._countryJobText.funcParser = Core.StringUtils.parseFuncText;
			this._cityNameText = this.contentPane.getChild("city").asTextField;
			this._cityJobText = this.contentPane.getChild("cityJob").asTextField;
			this._cityJobText.funcParser = Core.StringUtils.parseFuncText;

			this._headCom = this.contentPane.getChild("head").asCom as HeadCom;

			this._addFriendBtn.addClickListener(this._onAddFriend, this);
			this._delFriendBtn.addClickListener(this._onDelFriend, this);
			this._fightBtn.addClickListener(this._onFight, this);
			this._chatBtn.addClickListener(this._onChat, this);
			this._closeBtn.addClickListener(this._onClose, this);

			this._favoriteCardList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardList, this);
			this._fightCardList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardList, this);

			if (!LanguageMgr.inst.isChineseLocale()) {
				this.contentPane.getChild("totalCntTitle").asTextField.fontSize = 14;
				this.contentPane.getChild("winCntTitle").asTextField.fontSize = 14;
				this.contentPane.getChild("offensiveRateTitle").asTextField.fontSize = 14;
				this.contentPane.getChild("defensiveRateTitle").asTextField.fontSize = 14;
			}

			if (Home.FunctionMgr.inst.isWorldWarOpen()) {
				this._warCtrl.setSelectedIndex(0);
			} else {
				this._warCtrl.setSelectedIndex(1);
			}
		}

		private async _onAddFriend() {
			if (this._playerInfo.IsFriend) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60147));
				return;
			}
			if (this._uid == Player.inst.uid) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60103));
				return;
			}
			if (await FriendMgr.inst.applyAddFriend(this._uid)) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60136));
				this._addFriendBtn.enabled = false;
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60082));
			}
		}

		private async _onDelFriend() {
			if (!this._playerInfo.IsFriend) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60126));
				return;
			}
			Core.TipsUtils.confirm(Core.StringUtils.TEXT(60113), async function() {
				if (await FriendMgr.inst.delFriend(this._uid)) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60094));
					Core.EventCenter.inst.dispatchEventWith(GameEvent.DelFriend, false, this._uid);
					this._relateCtrl.setSelectedIndex(0);
					this._playerInfo.IsFriend = false;
				} else {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60080));
				}
			}, () => {}, this, Core.StringUtils.TEXT(60047));
		}

		private async _onFight() {
			if (await FriendMgr.inst.inviteBattle(this._uid)) {
				await Core.ViewManager.inst.open(ViewName.inviteWaiting);
			}
		}

		private async _onChat() {
			this.visible = false;
			Core.ViewManager.inst.open(ViewName.privateChatWnd, this._uid, () => {
				this.visible = true;
			});
		}

		private async _onClose() {
			Core.ViewManager.inst.closeView(this);
		}

		private _onClickCardList(evt:fairygui.ItemEvent) {
			let cardCom = evt.itemObject as UI.CardCom;
			Core.ViewManager.inst.open(ViewName.cardInfoOther, cardCom.cardObj);
		}

		public async open(...param: any[]) {
			this.battleChangeLayer();
			super.open(...param);

			let playerInfo = <pb.PlayerInfo>param[1];
			let uid = <Long>param[0];
	
			this._playerInfo = playerInfo;
			this._uid = uid;
			this.displayObject.cacheAsBitmap = false;

			if (playerInfo.HeadImgUrl == null || playerInfo.HeadImgUrl == "") {
				playerInfo.HeadImgUrl = "society_headicon1_png";
			}
			if (!playerInfo.HeadFrame || playerInfo.HeadFrame == "") {
				playerInfo.HeadFrame = "1";
			}
			this._headCom.setAll(playerInfo.HeadImgUrl, `headframe_${playerInfo.HeadFrame}_png`)

			this._nameText.text = playerInfo.Name;
			this.contentPane.getChild("id").asTextField.text = `ID:${uid}`;
			this.contentPane.getChild("totalCnt").asTextField.text = `${playerInfo.BattleAmount}`;
			this.contentPane.getChild("winCnt").asTextField.text = `${playerInfo.BattleWinAmount}`;
			this.contentPane.getChild("offensiveRate").asTextField.text = `${playerInfo.FirstHandWinRate}%`;
			this.contentPane.getChild("defensiveRate").asTextField.text = `${playerInfo.BackHandWinRate}%`;
			this.contentPane.getChild("rankingValue").asTextField.text = Core.StringUtils.format(Core.StringUtils.TEXT(60061), playerInfo.RankScore);
			let pvpScore = playerInfo.PvpScore;
			let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel(pvpScore);
			this.contentPane.getChild("rankLevel").asTextField.text = Pvp.Config.inst.getPvpTitle(pvpLevel);
			let team = Pvp.Config.inst.getPvpTeam(pvpLevel);
			this.contentPane.getChild("rankIcon").asLoader.url = `common_rank${team}_png`;

			this._updateWarInfo(playerInfo);

			playerInfo.FavoriteCards.forEach(card => {
				let data = Data.pool.get(card.GCardID);
				let cardObj = new CardPool.Card(data);
				let cardCom = fairygui.UIPackage.createObject(PkgName.cards, "smallCard", UI.CardCom) as UI.CardCom;
				cardCom.cardObj = cardObj;
				cardCom.cardObj.equip = card.Equip;
				cardCom.setDeskFront();
				cardCom.setDeskBackground();
				cardCom.setCardImg();
				cardCom.setEquip();
				cardCom.setNumText();
				cardCom.setNumOffsetText();
				cardCom.setName();
				this._favoriteCardList.addChild(cardCom);
			});

			playerInfo.FightCards.forEach(card => {
				let data = Data.pool.get(card.GCardID);
				let cardObj = new CardPool.Card(data);
				let cardCom = fairygui.UIPackage.createObject(PkgName.cards, "smallCard", UI.CardCom) as UI.CardCom;
				cardCom.cardObj = cardObj;
				cardCom.cardObj.equip = card.Equip;
				cardCom.cardObj.skin = card.Skin;
				cardCom.setDeskFront();
				cardCom.setDeskBackground();
				cardCom.setCardImg();
				cardCom.setEquip();
				cardCom.setNumText();
				cardCom.setNumOffsetText();
				cardCom.setName();
				this._fightCardList.addChild(cardCom);
			});

			if (playerInfo.IsFriend) {
				this._relateCtrl.setSelectedIndex(1);
			} else {
				this._relateCtrl.setSelectedIndex(0);
			}

			this._addFriendBtn.enabled = true;
			if (playerInfo.CanInviteBattle && !Core.ViewManager.inst.isShow(ViewName.battle)) {
				this._fightBtn.enabled = true;
			} else {
				this._fightBtn.enabled = false;
			}

			this._addFriendBtn.enabled = (this._uid != Player.inst.uid);

			if (window.gameGlobal.isMultiLan) {
				let flagImgWnd = this.contentPane.getChild("countryFlagImg").asImage;
				flagImgWnd.visible = true;
				LanguageMgr.inst.setCountryFlagImg(flagImgWnd, playerInfo.Country);
			}

			this.displayObject.cacheAsBitmap = true;
		}

		private _updateWarInfo(playerInfo: pb.PlayerInfo) {
			if (playerInfo.CampaignCountry != "") {
				this._countryNameText.text = playerInfo.CampaignCountry;
			} else {
				this._countryNameText.text = Core.StringUtils.TEXT(70112);
			}
			if (playerInfo.CountryJob && playerInfo.CountryJob != <number>Job.UnknowJob) {
				this._countryJobText.text = Utils.job2TextDesc(playerInfo.CountryJob, true);
			} else {
				this._countryJobText.text = Core.StringUtils.TEXT(70112);
			}
			if (playerInfo.CityID != 0) {
				let cityConf = Data.city.get(playerInfo.CityID);
				this._cityNameText.text = cityConf.name;
			} else {
				this._cityNameText.text = Core.StringUtils.TEXT(70112);
			}
			if (playerInfo.CityJob && playerInfo.CityJob != <number>Job.UnknowJob) {
				this._cityJobText.text = Utils.job2TextDesc(playerInfo.CityJob, true);
			} else {
				this._cityJobText.text = Core.StringUtils.TEXT(70112);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
			this.displayObject.cacheAsBitmap = false;
			this._favoriteCardList.removeChildren(0, -1, true);
			this._fightCardList.removeChildren(0, -1, true);
		}
	}
}