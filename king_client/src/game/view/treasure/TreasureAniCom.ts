module Treasure {

    export class TreasureAniCom extends fairygui.GComponent {

        private _card: UI.CardCom;
		private _skin: fairygui.GComponent;
		private _emoji: fairygui.GComponent;
		private _headFrame: fairygui.GComponent;

        private _typeCtr: fairygui.Controller;

        constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._card = this.getChild("card").asCom as UI.CardCom;
            this._skin = this.getChild("skin").asCom;
            this._emoji = this.getChild("emoji").asCom;
            this._headFrame = this.getChild("headFrame").asCom;
            this._typeCtr = this.getController("type");
        }
        public setGold() {
            this._typeCtr.selectedPage = "gold";
        }
        public setJade() {
            this._typeCtr.selectedPage = "jade";
        }
        public setBowlder() {
            this._typeCtr.selectedPage = "bowlder";
        }
        public setCard(cardObj: CardPool.Card) {
            this._typeCtr.selectedPage = "card";
            this._updateCardCom(cardObj);
        }
        public setNewCard(cardObj: CardPool.Card) {
            this._typeCtr.selectedPage = "newCard";
            this._updateCardCom(cardObj);
        }
        public setSkin(skinID: string) {
            this._typeCtr.selectedPage = "skin";
            Utils.setImageUrlPicture(this._skin.getChild("cardImg").asImage, `skin_m_${skinID}_png`);
			this._skin.getChild("nameText").asTextField.text = CardPool.CardSkinMgr.inst.getSkinConf(skinID).name;
        }
        public setEmoji(emojiID: number) {
            this._typeCtr.selectedPage = "emoji";
            let icon = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_EMOJI, null, emojiID);
            this._emoji.getChild("headFrame").asLoader.url = icon;
        }
        public setHeadFrame(headFrameID: string) {
            this._typeCtr.selectedPage = "headFrame";
            let icon = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_HEAD_FRAME, null, headFrameID);
            this._headFrame.getChild("headFrame").asLoader.url = icon;

        }
        private _updateCardCom(cardObj: CardPool.Card) {
            this._card.cardObj = cardObj;
			this._card.setDeskFront();
			this._card.setDeskBackground();
			this._card.setCardImg();
			this._card.setEquip();
			this._card.setNumText();
			this._card.setNumOffsetText();
			this._card.setName();
			this._card.setQualityMode(true);
        }
    }
}