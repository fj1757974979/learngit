module Battle {

    export class TextEffect implements IEffect {

        private _textField: fairygui.GTextField;
        private _isStop: boolean = false;

        constructor(movieId:number, targetCount:number, value:number) {
            let txt = Core.StringUtils.TEXT(movieId);
            if (txt == null) {
                txt = "";
            }
            txt = txt.replace("x", "" + targetCount);
            txt = txt.replace("v", "" + Math.abs(value));
            this._textField = new fairygui.GTextField();
            this._textField.textParser = Core.StringUtils.parseColorText;
            this._textField.text = txt;
            this._textField.fontSize = 30;
            this._textField.strokeColor = 0x000000;
            this._textField.stroke = 3;
            this._textField.bold = true;
            this._textField.align = fairygui.AlignType.Center;
            this._textField.verticalAlign = fairygui.VertAlignType.Middle;
            this._textField.color = Core.TextColors.white;
            if (!window.gameGlobal.isMultiLan) {
                this._textField.font = "AaKaiTi";
            }
        }

        public play(parent:fairygui.GComponent, isLoop:boolean, isLoopStop:boolean, visible:boolean): Promise<void> {
            if (this._isStop) {
                return null;
            }

            if (!LanguageMgr.inst.isChineseLocale()) {
                this._textField.autoSize = fairygui.AutoSizeType.Shrink;
                this._textField.setSize(parent.width, parent.height);
            }

            this._textField.fontSize = 32;
            this._textField.fontSize *= parent.width / 125;
            if (parent.visible) {
                this._textField.y = parent.height / 2;
                this._textField.x = parent.width / 2;
            } else {
                // 放在卡的父节点，防止卡透明看不到
                this._textField.y = parent.y + parent.height / 2;
                this._textField.x = parent.x + parent.width / 2;
                parent = parent.parent;
            }

            this._textField.visible = visible;
            parent.addChild(this._textField);       

            let p = Core.EffectUtil.showFromCenter(this._textField, 300, 133, 500);
            if (!isLoop) {
                let p2 = new Promise<void>(resolve=>{
                    p.then(()=>{
                        this._textField.removeFromParent();
                        resolve();
                    });
                });

                if (visible) {
                    return p2;
                }
            } else {
                p.then(()=>{
                    this._textField.removeFromParent();
                    egret.callLater(this.play, this, parent, isLoop, isLoopStop, visible);
                });
            }
            return null;
        }

        public resize(parent:fairygui.GComponent): void {
            if (this._textField == null) {
                return;
            }
            this._textField.removeFromParent();
            parent.addChild(this._textField);
        }

        public stop() {
            this._isStop = true;
        }

        public setVisible(val:boolean) {
            
        }
    }

}
