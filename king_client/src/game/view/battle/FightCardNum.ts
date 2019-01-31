module Battle {

    export class FightCardNum {
        private _numCom: fairygui.GComponent;
        private _pos: CardNumPos;
        private _isMoving: boolean;
        private _fightBeginTrans: fairygui.Transition;
        private _fightWinTrans: fairygui.Transition;
        private _fightLoseTrans: fairygui.Transition;
        private _value: fairygui.GTextField;
        private _isBlinking: boolean;
        private _valueOldFont: string;
        private _valueOldFontSize: number;

        constructor(numCom: fairygui.GComponent, pos:CardNumPos) {
            this._numCom = numCom;
            this._pos = pos;
            this._isMoving = false;
            this._fightBeginTrans = numCom.getTransition("newbieFightBegin");
            this._fightWinTrans = numCom.getTransition("newbieFightWin");
            this._fightLoseTrans = numCom.getTransition("newbieFightLose");
            this._value = numCom.getChild("value").asTextField;
        }

        public get isMoving(): boolean {
            return this._isMoving;
        }

        public async blink(isGuide:boolean, isOwn:boolean) {
            if (this._fightBeginTrans.playing) {
                return;
            }
            if (isGuide) {
                let numImg = this._numCom.getChild("img").asLoader;
                let mask = new fairygui.GLoader();
                mask.autoSize = false;
                mask.fill = fairygui.LoaderFillType.ScaleNoBorder;
                mask.rotation = numImg.rotation;
                mask.x = numImg.x;
                mask.y = numImg.y;
                mask.width = numImg.width;
                mask.height = numImg.height;
                mask.url = "cards_circle_m_w_png";
                mask.setPivot(0.5, 0.5);

                this._numCom.addChild(mask);
                mask.alpha = 0;

                let self = this;
                let _beginBlink = function() {    
                    egret.Tween.get(mask).to({alpha:0.6}, 750).to({alpha:0}, 500).call(()=>{
                        if (self._isBlinking) {
                            _beginBlink();
                        } else {
                            self._numCom.removeChild(mask);
                        }
                    }, self);
                }
        
                this._isBlinking = true;
                _beginBlink();
                //self._fightFlashTrans.play(null, null, null, -1);
                this._valueOldFont = this._value.font;
                this._valueOldFontSize = this._value.fontSize;
                if (isOwn) {
                    this._value.font = "ui://tlhdbap0p1qsm";
                } else {
                    this._value.font = "ui://tlhdbap0p1qsw";
                }
                this._value.fontSize = 24;
            }

            if (this._fightBeginTrans.playing) {
                return;
            }
            await new Promise<void>(resolve => {
                this._fightBeginTrans.play(() => {
                    resolve();
                }, this);
            });
        }

        public stopBlink() {
            this._isBlinking = false;
            this._value.font = this._valueOldFont;
            this._value.fontSize = this._valueOldFontSize;
        }

        public async attack(callback:()=>Promise<void>, thisArg:any) {
            if (this._isMoving) {
                await fairygui.GTimers.inst.waitTime(177);
                await callback.call(thisArg);
                return;
            }

            this._isMoving = true;
            let props1: any;
            let props2: any;
            let props3: any;
            let oldPoint: number;

            switch(this._pos) {
            case CardNumPos.UP:
                oldPoint = this._numCom.y;
                props1 = {y:oldPoint+10};
                props2 = {y:oldPoint-20};
                props3 = {y:oldPoint-40};
                break;
            case CardNumPos.DOWN:
                oldPoint = this._numCom.y;
                props1 = {y:oldPoint-10};
                props2 = {y:oldPoint+20};
                props3 = {y:oldPoint+40};
                break;
            case CardNumPos.LEFT:
                oldPoint = this._numCom.x;
                props1 = {x:oldPoint+10};
                props2 = {x:oldPoint-20};
                props3 = {x:oldPoint-40};
                break;
            case CardNumPos.RIGHT:
                oldPoint = this._numCom.x;
                props1 = {x:oldPoint-10};
                props2 = {x:oldPoint+20};
                props3 = {x:oldPoint+40};
                break;
            default:
                await fairygui.GTimers.inst.waitTime(177);
                await callback.call(thisArg);
                return;
            }

            await new Promise<void>(resolve => {
                let p: Promise<void>;
                let self = this;
                egret.Tween.get(this._numCom).to(props1, 70).wait(37).to(props2, 70).call(()=>{
                    p = callback.call(thisArg);
                }, this).to(props3, 37).wait(70).call(async function() {
                    // self._numCom.scaleX = 1;
                    // self._numCom.scaleY = 1;
                    self._isMoving = false;
                    if (self._pos == CardNumPos.UP) {
                        self._numCom.y = oldPoint;
                    } else if (self._pos == CardNumPos.DOWN) {
                        self._numCom.y = oldPoint;
                    } else if (self._pos == CardNumPos.LEFT) {
                        self._numCom.x = oldPoint;
                    } else {
                        self._numCom.x = oldPoint;
                    }
                    if (p) {
                        await p;
                    }
                    resolve();
                }, this);

                this._fightWinTrans.play();
            })
        }

        public async beAttack(winPos:CardNumPos) {
            if (this._isMoving) {
                return;
            }

            this._isMoving = true;
            let props: any;
            let oldPoint: number;

            if (winPos == CardNumPos.UP) {
                oldPoint = this._numCom.y;
                props = {y:oldPoint-10};
            } else if (winPos == CardNumPos.DOWN) {
                oldPoint = this._numCom.y;
                props = {y:oldPoint+10};
            } else if (winPos == CardNumPos.LEFT) {
                oldPoint = this._numCom.x;
                props = {x:oldPoint-10};
            }  else {
                oldPoint = this._numCom.x;
                props = {x:oldPoint+10};
            }
                
            let self = this;
            await new Promise<void>(resolve => {
                egret.Tween.get(this._numCom).to(props, 70).wait(37).call(()=>{
                    self._isMoving = false;
                    if (winPos == CardNumPos.UP || winPos == CardNumPos.DOWN) {
                        self._numCom.y = oldPoint;
                    }  else {
                        self._numCom.x = oldPoint;
                    }
                    resolve();
                }, this);

                this._fightLoseTrans.play();
            });
            
            
        }
    }

}
