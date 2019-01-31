module UI {

    export class ExchangeResWnd extends fairygui.GComponent {
        private _resImg: fairygui.GLoader;
        private _inputLabel: fairygui.GLabel;
        private _goldAmountTxt: fairygui.GTextField;
		private _resDesc: fairygui.GTextField;

        private _curResType: ResType;
        private _amount: number;
		private _needGold: number;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._inputLabel = this.getChild("inputAmount").asLabel;
            this._goldAmountTxt = this.getChild("goldAmountTxt").asTextField;
            this._resImg = this.getChild("resImg").asLoader;
			let resDesc = this.getChild("desc");
			if  (resDesc) {
				this._resDesc = resDesc.asTextField;
			}
			this._needGold = 0;
			this._amount = 0;

            this.getChild("confirmBtn").asButton.addClickListener(this._onConfirm, this);
            this.getChild("addBtn").asButton.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onBeginAddAmount, this);
            this.getChild("subBtn").asButton.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onBeginSubAmount, this);
        }

        public show(resType:ResType, resBtn:ResBarBtn) {
            let exchangeData = Data.exchange.get(resType);
            if (!exchangeData) {
                return;
            }

            if (resType != this._curResType) {
			    this._curResType = resType;
			    this._resImg.url = Utils.resType2Icon(resType);
				if (this._resDesc) {
					this._resDesc.text = this._getResDesc(resType);
				} 
                this._onAmountChange(0);
            }

			Core.TipsUtils.showTipsFromTarget(this, 1, resBtn);
        }

		private _getResDesc(resType:ResType): string {
			switch(resType) {
			case ResType.T_WEAP:
			case ResType.T_HORSE:
			case ResType.T_MAT:
				return Core.StringUtils.format(Core.StringUtils.TEXT(60151), Utils.resType2Text(resType));
			case ResType.T_FORAGE:
				return Core.StringUtils.format(Core.StringUtils.TEXT(60221), Utils.resType2Text(resType));
			case ResType.T_BAN:
				return Core.StringUtils.format(Core.StringUtils.TEXT(60186), Utils.resType2Text(resType));
			case ResType.T_MED:
				return Core.StringUtils.format(Core.StringUtils.TEXT(60181), Utils.resType2Text(resType));
			default:
				return "";
			}
		}

        private _onAmountChange(amount: number) {
			let exchangeData = Data.exchange.get(this._curResType)
			if(!exchangeData) {
				return;
			}

			this._needGold = 0;
			if (amount > 0) {
				let needGold = exchangeData.buy * amount;
				this._needGold = needGold;
				this._amount = amount;
				this._goldAmountTxt.text = "- " + needGold;
                this._goldAmountTxt.color = Core.TextColors.red;
				this._inputLabel.text = "+ " + amount;
			} else if (amount < 0) {
				let gold = exchangeData.sold * - amount;
				this._amount = amount;
				this._goldAmountTxt.text = "+ " + gold;
                this._goldAmountTxt.color = Core.TextColors.green;
				this._inputLabel.text = "- " + - amount;
			} else {
				this._amount = 0;
				this._goldAmountTxt.text = "0";
                this._goldAmountTxt.color = Core.TextColors.white;
				this._inputLabel.text = "0";
			}
		}

		private _onStopChangeAmount() {
			fairygui.GRoot.inst.nativeStage.removeEventListener(egret.TouchEvent.TOUCH_END, this._onStopChangeAmount, this);
			fairygui.GTimers.inst.remove(this._changeAmount, this);
		}

		private _onBeginAddAmount() {
			this._changeAmount(1);
			fairygui.GRoot.inst.nativeStage.addEventListener(egret.TouchEvent.TOUCH_END, this._onStopChangeAmount, this);
		}

		private _onBeginSubAmount() {
			this._changeAmount(-1);
			fairygui.GRoot.inst.nativeStage.addEventListener(egret.TouchEvent.TOUCH_END, this._onStopChangeAmount, this);
		}

		private _changeAmount(modify:number, t:number=500) {
			this._onAmountChange(this._amount + modify);
			let _t = 40;
			fairygui.GTimers.inst.add(t, 1, this._changeAmount, this, modify, _t);
		}

		private _onConfirm() {
			if (this._amount != 0) {
				if (- this._amount > Player.inst.getResource(this._curResType)) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(60101), Utils.resType2Text(this._curResType)));
					return;
				}
				if (this._needGold > Player.inst.getResource(ResType.T_GOLD)) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(60101), Utils.resType2Text(ResType.T_GOLD)));
					return;
				}
				Player.inst.exchangeRes(this._curResType, this._amount);
			}
			fairygui.GRoot.inst.hidePopup(this);
		}
    }

}