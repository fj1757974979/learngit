module Core {

    export interface IAlertPanel extends fairygui.GComponent {
        getAcceptBtn(): fairygui.GButton
        getTitle(): fairygui.GTextField
    }

    export interface IConfirmPanel extends IAlertPanel {
        getCancelBtn(): fairygui.GButton
    }

    export class AlertPanel extends fairygui.GComponent implements IAlertPanel {

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this.getChild("title").asTextField.funcParser = Core.StringUtils.parseFuncText;
        }
        
        public getAcceptBtn(): fairygui.GButton {
            return this.getChild("acceptBtn").asButton;
        }

        public getTitle(): fairygui.GTextField {
            return this.getChild("title").asTextField;
        }
    }

    export class ConfirmPanel extends fairygui.GComponent implements IConfirmPanel {

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this.getChild("title").asTextField.funcParser = Core.StringUtils.parseFuncText;
        }

        public getAcceptBtn(): fairygui.GButton {
            return this.getChild("acceptBtn").asButton;
        }

        public getCancelBtn(): fairygui.GButton {
            return this.getChild("cancelBtn").asButton;
        }

        public getTitle(): fairygui.GTextField {
            return this.getChild("title").asTextField;
        }
    }
    export class PrivShowPanel extends fairygui.GComponent {
        private _privList: fairygui.GList;
        private _time: number;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._privList = this.getChild("privList").asList;
        }

        public getPrivList(): fairygui.GList {
            return this._privList;
        }

        public showTip(priv: Priv) {
            this._time = 2;
            let com = this._privList.addItemFromPool().asCom;
            let iconUrl = "";
            let desc = 0;
            if (priv == Priv.VIP_PRIV) {
                let giftData = Payment.PayMgr.inst.getProducts();
                let privData = giftData.getValue("advip") as Payment.GiftProduct
                iconUrl = `shop_${privData.icon}_png`;
                desc = 10700;
            } else {
                let id = priv;
                let privData = Data.priv_config.get(id);
                iconUrl = `reborn_${privData.icon}_png`;
                desc = Utils.priv2descText(priv);
            }
            com.getChild("icon").asLoader.url = iconUrl;
            com.getChild("text").asTextField.textParser = Core.StringUtils.parseColorText;
            com.getChild("text").asTextField.text = Core.StringUtils.TEXT(desc);
            com.getTransition("t0").play();
            fairygui.GTimers.inst.remove(this._privTimer, this);
            fairygui.GTimers.inst.add(1000, -1, this._privTimer, this);
        }

        private _privTimer() {
            this._time -= 1;
            if (this._time <= 0) {
                fairygui.GTimers.inst.remove(this._privTimer, this);
                this._privList.removeChildrenToPool();
                TipsUtils.closePrivTips();
            }
        }
    }

    export class FlagShowPanel extends fairygui.GComponent {
        private _flagNumText: fairygui.GTextField;
        private _stepNum: number;
        private _fromNum: number;
        private _toNum: number;
        private _modify: number;
        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this.touchable = false;
            this._flagNumText = this.getChild("text").asTextField;
        }
        public async showTip(oldCnt: number, newCnt: number) {
            this._modify = newCnt - oldCnt;
            this._fromNum = oldCnt;
            this._toNum = newCnt;
            this.y = 300;
            //
            let stepCount = 20;
            let stepTime = 50;

            // this._timeCnt = Math.abs(this._modify);
            this._stepNum = this._modify / stepCount;

            
            this._flagNumText.text = oldCnt.toString();
            if (this._modify > 0){
                await this._playWinTransotion();
            } else {
                await this._playLoseTransotion();
            }
            fairygui.GTimers.inst.remove(this._flagTimer, this);
            fairygui.GTimers.inst.add(stepTime, stepCount, this._flagTimer, this);
            
        }
        private async _playWinTransotion() {
            await new Promise<void>(resolve => {
                this.getTransition("win").play(() => {
                    resolve();
                }, this)
            });
        }

        private async _playLoseTransotion() {
            await new Promise<void>(resolve => {
                this.getTransition("lose").play(() => {
                    resolve();
                }, this)
            });
        }

        private async _flagTimer() {
            this._fromNum += this._stepNum;
            let num = Math.round(this._fromNum);
            this._flagNumText.text = num.toString();
            
            if (num == this._toNum) { 
                window.setTimeout(() => {
                    fairygui.GTimers.inst.remove(this._flagTimer, this);
                    TipsUtils.closeFlagTips();
                },1000);
                
            }
        }

    }
}