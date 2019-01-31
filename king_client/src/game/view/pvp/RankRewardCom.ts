module Pvp {
	export class RankRewardCom extends fairygui.GComponent {

		private _rankTitleText: fairygui.GTextField;
		//private _rankBanner: UI.PvpRankBannerCom;
		private _rewardList: fairygui.GList;
		private _rankTitleTrans: fairygui.Transition;
		private _rankIcon: fairygui.GLoader;

		private _cardItems: Array<CardPool.CardItem>;
		private _pvpLevel: number;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._rankTitleText = this.getChild("RankName").asTextField;
			this._rankTitleText.textParser = Core.StringUtils.parseColorText;
			//this._rankBanner = this.getChild("rankIcon").asCom as UI.PvpRankBannerCom;
			this._rankIcon = this.getChild("rankIcon").asLoader;
			this._rewardList = this.getChild("resultList").asList;
			this._rankTitleTrans = this.getTransition("t0");

			this._rewardList.itemClass = CardPool.CardItem;
			this._rewardList.itemRenderer = this._renderRewardList;
			this._rewardList.callbackThisObj = this;

			this._cardItems = [];

			this._rewardList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardItem, this);
		}
		
		public initWithPvpLevel(pvpLevel: number) {
			this._rewardList.numItems = 0;
			this._pvpLevel = pvpLevel;
			let title = Config.inst.getPvpTeamName(pvpLevel);
			this._rankTitleText.text = `${title}`;
			// let score = Config.inst.getTotalStar(pvpLevel);
			// this._rankBanner.refresh(score);
			let team = Pvp.Config.inst.getPvpTeam(pvpLevel);
			this._rankIcon.url = `common_rank${team}_png`;
			let unlockCardIds = Config.inst.getUnlockCard(pvpLevel);
			this._rewardList.numItems = unlockCardIds.length;
		}

		private _renderRewardList(idx:number, item:fairygui.GObject) {
			let unlockCardIds = Config.inst.getUnlockCard(this._pvpLevel);
			if (idx < 0 || idx >= unlockCardIds.length) {
                console.debug("_renderRewardList error idx=%d", idx);
                return;
            }
			let cardId = unlockCardIds[idx];
			let cardItem = item as CardPool.CardItem;
			//let obj = null;
			let obj = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
			/*
			let cardObj = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
			if (cardObj) {
				obj = cardObj; //.copyObj(1);
			} else {
				obj = new CardPool.Card(CardPool.CardPoolMgr.inst.getCardData(cardId, 1));
				obj.amount = 0;
			}
			*/
			cardItem.setData(obj);
			cardItem.setRankRewardMode();
			this._cardItems.push(cardItem);
		}

		private _onClickCardItem(evt:fairygui.ItemEvent) {
			let cardItem = evt.itemObject as CardPool.CardItem;
            Core.ViewManager.inst.open(ViewName.cardInfo, cardItem.cardObj);
		}

		public update() {
			for (let card of this._cardItems) {
				card.update();
				card.setRankRewardMode();
			}
		}

		public async playRankTitleAnimation(list: fairygui.GList) {
			await new Promise<void>(reslove => {
                this._rankTitleTrans.play(()=>{
					list.touchable = true;
                    reslove();
                }, this);
            });
		}

		public destroy() {
			this._rewardList.numItems = 0;
			this._cardItems.forEach((item) => {
				item.dispose();
				console.log("	... dispose");
			})
			this._cardItems = [];
			this.dispose();
			console.log("dispose...");
		}
	}
}