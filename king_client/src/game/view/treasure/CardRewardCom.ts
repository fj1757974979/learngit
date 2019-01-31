module Treasure {

	export class CardRewardCom extends fairygui.GComponent {

		private _countText: fairygui.GTextField;
		private _count: number;
		private _card: UI.CardCom;
		private _newHintImg: fairygui.GLoader;
		private _cardObj: CardPool.Card;
		private _bg: fairygui.GLoader;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._countText = this.getChild("title").asTextField;
			this._card = this.getChild("card").asCom as UI.CardCom;
			this._newHintImg = this.getChild("newHintIcon").asLoader;
			this._newHintImg.visible = false;
			this._bg = this.getChild("bg").asLoader;
		}

		public get count() {
			return this._count;
		}

		public set count(cnt: number) {
			this._count = cnt;
			this._countText.text = `x${this._count}`;
		}

		public setCardObj(card: CardPool.Card) {
			this._cardObj = card;
			this._card.cardObj = card;
			this._card.setDeskFront();
			this._card.setDeskBackground();
			this._card.setCardImg();
			this._card.setEquip();
			this._card.setNumText();
			this._card.setNumOffsetText();
			this._card.setName();
			this._card.setQualityMode(true);
			
			if (this._count == card.amount && card.level == 1) {
				this._newHintImg.visible = true;
			} else {
				this._newHintImg.visible = false;
			}

			if (this._cardObj.rare >= 3) {
				this._bg.url = `cards_bg4_png`;
			} else {
				this._bg.url = ``;
			}
		}

		public cardObj(): CardPool.Card {
			return <CardPool.Card>this._card.cardObj;
		}

		public hideNewHint() {
			this._newHintImg.visible = false;
		}

		public async playTrans() {
			await new Promise<void>(resolve => {
				this.getTransition("t0").play(() => {
					resolve();
				});
            });
		}

		public enableClick(b: boolean) {
			if (b) {
				this.addClickListener(this._onClick, this);
			} else {
				this.removeClickListener(this._onClick, this);
			}
		}

		private _onClick() {
			let cardId = this._cardObj.cardId;
			let card = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
			Core.ViewManager.inst.open(ViewName.cardInfo, card);
		}
	}
}