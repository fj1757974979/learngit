module Level {
	export class ChapterTreasureInfoWnd extends Core.BaseWindow {
		
		private _cardCom: Treasure.CardRewardCom;
		private _goldCom: Treasure.GoldRewardCom;
		private _cardId: number;

		public initUI() {
			super.initUI();
			this._goldCom = this.contentPane.getChild("gold").asCom as Treasure.GoldRewardCom;
			this._cardCom = this.contentPane.getChild("card").asCom as Treasure.CardRewardCom;
			//this.center();

			this.contentPane.getChild("bg").asLoader.addClickListener(this._onTouchBegin, this);

			this._cardCom.addClickListener(this._onClickCard, this);
			
			this.contentPane.getChild("closeBtn").addClickListener(()=>{
                Core.ViewManager.inst.closeView(this);
            }, this);
			
		}

		public async open(...param: any[]) {
			super.open(...param);
			let cardId = param[0];
			let gold = param[1];
			let rewardCom = param[2] as ChapterRewardCom;

			this._cardId = cardId;

			this.contentPane.getChild("bottom").asLoader.addRelation(rewardCom, fairygui.RelationType.Top_Bottom);
			this.contentPane.getChild("bottom").asLoader.addRelation(rewardCom, fairygui.RelationType.Center_Center);

			let resData = CardPool.CardPoolMgr.inst.getCardData(cardId, 1);
			let card = new CardPool.Card(resData);
			this._cardCom.setCardObj(card);
			this._cardCom.count = 1;
			this._cardCom.hideNewHint();

			this._goldCom.count = gold;

			//egret.MainContext.instance.stage.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchBegin, this);
		}

		public async close(...param: any[]) {
			super.close(...param);
			//egret.MainContext.instance.stage.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchBegin, this);
		}

		private _onTouchBegin() {
			Core.ViewManager.inst.closeView(this);
		}

		private _onClickCard() {
			let resData = CardPool.CardPoolMgr.inst.getCardData(this._cardId, 1);
			let card = new CardPool.Card(resData);
			if (card) {
				Core.ViewManager.inst.open(ViewName.cardInfoOther, card);
			}
		}
	}
}