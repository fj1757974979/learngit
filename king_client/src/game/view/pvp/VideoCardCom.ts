module Pvp {
	export class VideoCardCom extends fairygui.GComponent {

		private _nameText: fairygui.GTextField;
		private _image: fairygui.GLoader;
		private _frame: fairygui.GLoader;
		private _cardId: number;
		private _skinId: string;
		private _equipId: string;
		private _bg: fairygui.GLoader;
		private _nameBg:fairygui.GLoader;
		private _equipBtn: fairygui.GButton;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			
			this._nameText = this.getChild("nameText").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._image = this.getChild("cardImg").asLoader;
			this._frame = this.getChild("frameImg").asLoader;
			this._bg = this.getChild("baseImg").asLoader;
			this._nameBg = this.getChild("nameBg").asLoader;
			this._equipBtn = this.getChild("equipBtn").asButton;
			this._cardId = null;
			this._skinId = null;
			this._equipId = null;

			this.addClickListener(() => {
				if (this._cardId) {
					let data = Data.pool.get(this._cardId);
					console.debug(data);
					let cardObj = new CardPool.Card(data);
					cardObj.level = data.level;
					if (this._skinId) {
						cardObj.skin = this._skinId;
					}
					if (this._equipId) {
						cardObj.equip = this._equipId;
					}
					Core.ViewManager.inst.open(ViewName.cardInfoOther, cardObj);
				}
				
			}, this);
		}

		public setCardId(card: pb.ISkinGCard, isWin: boolean) {
			let cardId = card.GCardID;
			let cardSkin = card.Skin;
			let cardEquip = card.Equip;
			let data = Data.pool.get(cardId);
			if (data) {
				let icon = data.icon;
				let name = data.name;
				this._nameText.text = name;
				let width = this._image.width;
            	let height = this._image.height;
				UI.CardImgTextureMgr.inst.fetchTexture(icon, cardSkin, "m", (_, texture)=>{
					this._image.texture = texture;
					this._image.width = width;
					this._image.height = height;
				});
				if (cardEquip == "") {
					this._equipBtn.visible = false;
				} else {
					this._equipBtn.visible = true;
					let equidata = Data.item.get(cardEquip);
					this._equipBtn.icon = `equip_${equidata.iconSmall}_png`;
					if (isWin) {
						this._equipBtn.getChild("bg").asLoader.url = `equip_equipWnd_png`;
					} else {
						this._equipBtn.getChild("bg").asLoader.url = `equip_equipWndEnemy_png`;
					}
				}
				let rare = data.rare;
				this._frame.url = `cards_deck_s${rare}_png`;
				if (rare == 99) {
					this._nameBg.url = "pvp_name_limited_png";
				} else {
					this._nameBg.url = "pvp_name_normal_png";
				}
				this._cardId = cardId;
				this._skinId = cardSkin;
				this._equipId = cardEquip;
				// if (isEnemy == 2) {
				// 	this._bg.url = `cards_base2_s_png`;
				// } else {
				// 	this._bg.url = `cards_base1_s_png`;
				// }
			}
		}
	}
}