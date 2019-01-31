module Social {
	export class SelfInfoWnd extends Core.BaseWindow {

		private _favoriteCardList: fairygui.GList;
		private _fightCardList: fairygui.GList;
		private _closeBtn: fairygui.GButton;
		private _changeHeadBtn: fairygui.GButton;
		private _modifyNameBtn: fairygui.GButton;
		private _privBtn: fairygui.GButton;
		private _headCom: Social.HeadCom;
		private _nameText: fairygui.GTextField;
		private _countryNameText: fairygui.GTextField;
		private _countryJobText: fairygui.GTextField;
		private _cityNameText: fairygui.GTextField;
		private _cityJobText: fairygui.GTextField;
		private _warCtrl: fairygui.Controller;

		private _uid: Long;
		private _playerInfo: pb.PlayerInfo;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._favoriteCardList = this.contentPane.getChild("commonlyCard").asList;
			this._fightCardList = this.contentPane.getChild("cardList").asList;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
			this._privBtn = this.contentPane.getChild("privBtn").asButton;
			this._changeHeadBtn = this.contentPane.getChild("changeHeadBtn").asButton;
			this._modifyNameBtn = this.contentPane.getChild("modifyNameBtn").asButton;
			this._headCom = this.contentPane.getChild("head").asCom as HeadCom;
			this._nameText = this.contentPane.getChild("name").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._warCtrl = this.contentPane.getController("war");

			this._countryNameText = this.contentPane.getChild("country").asTextField;
			this._countryNameText.textParser = Core.StringUtils.parseColorText;
			this._countryJobText = this.contentPane.getChild("countryJob").asTextField;
			this._countryJobText.funcParser = Core.StringUtils.parseFuncText;
			this._cityNameText = this.contentPane.getChild("city").asTextField;
			this._cityJobText = this.contentPane.getChild("cityJob").asTextField;
			this._cityJobText.funcParser = Core.StringUtils.parseFuncText;

			if (Core.DeviceUtils.isWXGame()) {
				// this._changeHeadBtn.visible = false;
				(<CardPool.AvatarNumHintCom>this.contentPane.getChild("avatarNumHint").asCom).visible = false;
				this.contentPane.getChild("head").addClickListener(this._clickHeadImage,this);
			} else {
				// this._changeHeadBtn.visible = true;
				
				
				(<CardPool.AvatarNumHintCom>this.contentPane.getChild("avatarNumHint").asCom).visible = true;
				(<CardPool.AvatarNumHintCom>this.contentPane.getChild("avatarNumHint").asCom).observerAvatarNum();
			}
			this._changeHeadBtn.visible = true;
			this._modifyNameBtn.visible = true;
			this._modifyNameBtn.addClickListener(() => {
					Core.ViewManager.inst.open(ViewName.modifyName);
				}, this);
			this._changeHeadBtn.addClickListener(() => {
					Core.ViewManager.inst.open(ViewName.avatarChangeWnd);
				}, this);
			this._privBtn.addClickListener(() => {
				Core.ViewManager.inst.open(ViewName.privPanelWnd);
			}, this);
			this._closeBtn.addClickListener(this._onClose, this);
			this._favoriteCardList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardList, this);
			this._fightCardList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardList, this);

			Core.EventCenter.inst.addEventListener(GameEvent.ModifyAvatarEv, () => {
				this._headCom.setHead(Player.inst.avatarUrl);
			}, this);
			Core.EventCenter.inst.addEventListener(GameEvent.ModifyFrameEv, () => {
				this._headCom.setFrame(Player.inst.frameUrl);
			}, this);
			Core.EventCenter.inst.addEventListener(GameEvent.ModifyNameEv, (evt: egret.Event) => {
				if (Core.ViewManager.inst.isShow(ViewName.selfInfo)) {
					this.contentPane.getChild("name").text = evt.data;
				}
            }, this);

			this._privBtn.visible = Home.FunctionMgr.inst.isFeatOpen();

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

		private async _clickHeadImage(){
			Core.ViewManager.inst.open(ViewName.haedBig);
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
			this._headCom.setAll(playerInfo.HeadImgUrl, Player.inst.frameUrl);
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
				let cardObj = CardPool.CardPoolMgr.inst.getCollectCard(data.cardId);
				cardObj.skin = card.Skin;
				let cardCom = fairygui.UIPackage.createObject(PkgName.cards, "smallCard", UI.CardCom) as UI.CardCom;
				cardCom.cardObj = cardObj;
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
				let cardObj = CardPool.CardPoolMgr.inst.getCollectCard(data.cardId);
				cardObj.skin = card.Skin;
				let cardCom = fairygui.UIPackage.createObject(PkgName.cards, "smallCard", UI.CardCom) as UI.CardCom;
				cardCom.cardObj = cardObj;
				cardCom.setDeskFront();
				cardCom.setDeskBackground();
				cardCom.setCardImg();
				cardCom.setEquip();
				cardCom.setNumText();
				cardCom.setNumOffsetText();
				cardCom.setName();
				this._fightCardList.addChild(cardCom);
			});

			if (!Core.DeviceUtils.isWXGame() && Core.ViewManager.inst.isShow(ViewName.battle)) {
				this.displayObject.cacheAsBitmap = true;
				if (pvpLevel >= 2) {
					this._modifyNameBtn.visible = true;
				}
			}

			if (window.gameGlobal.isMultiLan) {
				let flagImgWnd = this.contentPane.getChild("countryFlagImg").asImage;
				flagImgWnd.visible = true;
				LanguageMgr.inst.setCountryFlagImg(flagImgWnd);
			}
		}

		private _updateWarInfo(playerInfo: pb.PlayerInfo) {
			console.log("---- ", playerInfo.CountryJob);
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
			this._favoriteCardList.removeChildren();
			this._fightCardList.removeChildren();
		}
	}
}