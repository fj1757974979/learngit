module Shop {
	export class CardCntCom extends fairygui.GComponent {

		private _cardCom: UI.CardCom;
		private _titleText: fairygui.GTextField;

		private _cardObj: CardPool.Card;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._cardCom = this.getChild("card").asCom as UI.CardCom;
			this._titleText = this.getChild("title").asTextField;

			this.addClickListener(() => {
				if (this._cardObj) {
					Core.ViewManager.inst.open(ViewName.cardInfoOther, this._cardObj);
				}
			}, this);
		}

		public setCardInfo(gcardId: string, count: number) {
			let data = Data.pool.get(gcardId);
			let cardObj = new CardPool.Card(data);
			this._cardCom.cardObj=  cardObj;
			this._cardCom.setName();
			this._cardCom.setOwnBackground();
			this._cardCom.setOwnFront();
			this._cardCom.setCardImg();
			this._cardCom.setEquip();
			//this._cardCom.setNumText();
			//this._cardCom.setNumOffsetText();
			//this._cardCom.setSkill();
			this._cardCom.visibleRareStars(true);
			this._titleText.text = `x${count}`;

			this._cardObj = cardObj;
		}
	}
}