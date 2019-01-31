module CardPool {

    export class CardUpWnd extends Core.BaseWindow {

        private _closeBtn: fairygui.GButton;
        private _jadeBtn: fairygui.GButton;
        private _descText: fairygui.GTextField;
        private _cardCom1: UI.CardCom;
        private _cardCom2: UI.CardCom;
        private _expProgressBar1: UI.MaskProgressBar;
        private _expProgressBar2: UI.MaskProgressBar;
        
        private _cardObj: Card;
        private _upJade: number;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;
            // this.adjust(this.contentPane.)

            this._descText = this.contentPane.getChild("txt2").asTextField;
            this._descText.textParser = Core.StringUtils.parseColorText;

            this._cardCom1 = this.contentPane.getChild("now").asCom as UI.CardCom;
            this._cardCom2 = this.contentPane.getChild("new").asCom as UI.CardCom;
            this._expProgressBar1 = this.contentPane.getChild("expProgressBarNow").asCom as UI.MaskProgressBar;
            this._expProgressBar2 = this.contentPane.getChild("expProgressBarNew").asCom as UI.MaskProgressBar;
            this._jadeBtn = this.contentPane.getChild("jadeBtn").asButton;
            this._jadeBtn.addClickListener(this._onJadeBtn, this);
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._closeBtn.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);
        }
        public async open(...param: any[]) {
            super.open(...param);

            this._cardObj = param[0];

            this._refresh();
        }
        private async _refresh() {
            this._cardCom1.cardObj = this._cardObj;
            
            let card2Data = CardPoolMgr.inst.getCardData(this._cardObj.cardId, 3);
            let cardObj2 = new Card(card2Data);
            cardObj2.skin = this._cardObj.skin;
            cardObj2.equip = this._cardObj.equip;
            this._cardCom2.cardObj = cardObj2;

            this._setCard(this._cardCom1);
            this._setCard(this._cardCom2);

            this._expProgressBar1.setProgress(this._cardObj.amount, this._cardObj.maxAmount);
            this._expProgressBar1.getChild("text").asTextField.text = this._cardObj.amount + "/" + this._cardObj.maxAmount
            this._expProgressBar2.setProgress(0, cardObj2.maxAmount);
            this._expProgressBar2.getChild("text").asTextField.text = "0" + "/" + cardObj2.maxAmount

            let upLvData = this._cardObj.getToLevelAmount(3);
            this._upJade = upLvData[0] * CardJade[CardQuality[this._cardObj.rare]] + upLvData[1]/100;

            this._jadeBtn.title =this._upJade.toString();
            if (Player.inst.hasEnoughJade(this._upJade)) {
                this._jadeBtn.getChild("title").asTextField.color = 0xffffff;
			} else {
				this._jadeBtn.getChild("title").asTextField.color = 0xff0000;
            }
        }
        private async _setCard(cardCom: UI.CardCom) {
            cardCom.setCardImg();
            cardCom.setSkill();
            cardCom.setEquip();
            cardCom.setNumOffsetText();
            cardCom.setName();
            cardCom.setNumText();
        }
        private async _onJadeBtn() {
            if (!Player.inst.hasEnoughJade(this._upJade)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
                return;
            }
            Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70190), this._upJade), 
                 this._sendUp, null, this);
        }
        public async _sendUp() {
            let ok = await CardPoolMgr.inst.upLevelCard(this._cardObj.cardId, true);
            if (ok) {
                Core.ViewManager.inst.closeView(this);
            }
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}