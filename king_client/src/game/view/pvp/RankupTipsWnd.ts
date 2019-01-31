module Pvp {

	export class RankupTipsWnd extends Core.BaseWindow {

		protected _rankIconImg: fairygui.GLoader;
		protected _rankTitleText: fairygui.GTextField;
		protected _confirmBtn: fairygui.GButton;
		protected _onClosePlayTreasureAni: boolean;

		public initUI() {
			super.initUI();
			this.modal = true;
			this.center();

			this._rankIconImg = this.contentPane.getChild("rankIcon").asLoader;
			this._rankTitleText = this.contentPane.getChild("rankLevel").asTextField;
			this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;

			this._onClosePlayTreasureAni = false;

			this._confirmBtn.addClickListener(this._onConfirm, this);
		}

		public async open(...param: any[]) {
			await super.open(...param);

			this._onClosePlayTreasureAni = param[0];
			if (this._onClosePlayTreasureAni == true) {
				let matchView = <Pvp.MatchView>Core.ViewManager.inst.getView(ViewName.match);
				let treasureCom = matchView.getLatestAddTreasureCom();
				if (treasureCom) {
					let treasure = treasureCom.treasure;
					if (treasure) {
						treasureCom.hideContent();
                    	treasureCom.touchable = false;
					}
				}
			}
			let pvpLevel = PvpMgr.inst.getPvpLevel();
			let team = Pvp.Config.inst.getPvpTeam(pvpLevel);
			this._rankIconImg.url = `common_rank${team}_png`;
			this._rankTitleText.text = Pvp.Config.inst.getPvpTitle(pvpLevel);
		}

		private async _onConfirm() {
			await Core.ViewManager.inst.closeView(this);
			let pvpLevel = PvpMgr.inst.getPvpLevel();
			await Core.ViewManager.inst.open(ViewName.rankRewardView, this._onClosePlayTreasureAni);
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60174) + <string>Pvp.Config.inst.getPvpTitle(pvpLevel));   
			
		}

		public async close(...param: any[]) {
			await super.close(...param);
		}
	}

	export class RankupRewardTipsWnd extends RankupTipsWnd {

		protected _cardList: fairygui.GList;

		public initUI() {
			super.initUI();
			this._cardList = this.contentPane.getChild("resultList").asList;
		}

		public async open(...param: any[]) {
			await super.open(...param);
			let cardIds = param[1] as Array<number>;
			cardIds.forEach(cardId => {
				let resData = CardPool.CardPoolMgr.inst.getCardData(cardId, 1);
				if (resData) {
					let cardObj = new CardPool.Card(resData);
					cardObj.amount = 1;
					let cardCom = fairygui.UIPackage.createObject(PkgName.treasure, "cardCnt", Treasure.CardRewardCom).asCom as Treasure.CardRewardCom;
					cardCom.count = 1
					cardCom.setCardObj(cardObj);
					cardCom.enableClick(true);
					this._cardList.addChild(cardCom);
				}
			});
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._cardList.removeChildren();
		}
	}
}