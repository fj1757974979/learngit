module Battle {

    export class BonusTips extends fairygui.GComponent {
        
        private _setBonusName(bonusName:string) {
            this.getChild(`${this.getController("result").selectedPage}BonusName`).asTextField.text = bonusName;
        }

        private _getAmountTxt(idx:number): fairygui.GTextField {
            let txt = this.getChild(`${this.getController("result").selectedPage}Res${idx}AmountTxt`);
            if (txt) {
                return txt.asTextField;
            }
            return null;
        }

        private _getResImg(idx:number): fairygui.GImage {
            let img = this.getChild(`${this.getController("result").selectedPage}Res${idx}Img`);
            if (img) {
                return img.asImage;
            }
            return null;
        }

        public async show(bonusName: string, resChange: Array<any>) {
            for (let change of resChange) {
                if (change.Amount < 0) {
                    this.getController("result").setSelectedPage("lose");
                    break;
                }
            }
            this._setBonusName(bonusName);

            for (let i=0; i<resChange.length; i++) {
                let amountTxt = this._getAmountTxt(i+1);
                let img = this._getResImg(i+1);
                if (!amountTxt || !img) {
                    break;
                }
                amountTxt.visible = true;
                img.visible = true;
                let change = resChange[i];
                amountTxt.text = (change.Amount > 0) ? "+" + change.Amount : change.Amount.toString();
                img.texture = Utils.resType2Texture(change.Type);
            }

            await Core.EffectUtil.showLeftToRight(this);
        }
    }


    export class GoldGobTips extends fairygui.GComponent {

        public async show(gold:number, isLadder:boolean) {
            let stateCtrl = this.getController("state");
            let trans: fairygui.Transition;
            if (isLadder) {
                stateCtrl.setSelectedPage("normal");
                trans = this.getTransition("show");
                let title = this.getChild("title").asTextField;
                if (gold > 0) {
                    title.color = Core.TextColors.green;
                    title.text = `+${gold}`
                } else {
                    title.color = Core.TextColors.red;
                    title.text = `${gold}`
                }
            } else {
                stateCtrl.setSelectedPage("forbid");
                trans = this.getTransition("show2");
            }

            if (trans.playing) {
                return;
            }
            await new Promise<void>(resolve => {
                trans.play(()=>{
                    resolve();
                }, this);
            })
        }
    }

}