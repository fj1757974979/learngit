module Guide {

    export class GuideView extends egret.DisplayObjectContainer {
        private _bg:GuideMaskBackgroud;
        private _touchMask1:egret.Shape;
        private _touchMask2:egret.Shape;
        private _textBg:egret.Bitmap;
        private _textKuang:egret.Bitmap;
        private _hand:egret.MovieClip;
        private _txt:egret.TextField;
        private _textArrow:egret.Bitmap;
        private _dragCardArrow:fairygui.GImage;

        private _targetOnclickCallback: Function;
        private _targetOnclickThisArg: any;

        constructor() {
            super();
            this.touchEnabled = true;
            let stage = egret.MainContext.instance.stage;
            //this.width = stage.stageWidth;
            //this.height = stage.stageHeight;
            this.width = fairygui.GRoot.inst.getDesignStageWidth();
            this.height = fairygui.GRoot.inst.getDesignStageHeight();
            this.x = fairygui.GRoot.inst.width / 2 - this.width / 2;
            this.y = fairygui.GRoot.inst.height / 2 - this.height / 2;

            this._bg = new GuideMaskBackgroud(this.width, this.height);
            this.addChild(this._bg);

            this._touchMask1 = new egret.Shape();
            this._touchMask1.touchEnabled = true;
            this._touchMask1.visible = false;
            this.addChild(this._touchMask1);

            this._textKuang = new egret.Bitmap(RES.getRes("guide_textKuang_png"));
            this._textKuang.visible = false;
            this.addChild(this._textKuang);
            let scale9Rect:egret.Rectangle = new egret.Rectangle(30, 26, this._textKuang.width - 60, this._textKuang.height - 52);
            this._textKuang.scale9Grid = scale9Rect;

            this._textArrow = new egret.Bitmap(RES.getRes("guide_textArrow_png"));
            this._textArrow.visible = false;
            this.addChild(this._textArrow);

            this._textBg = new egret.Bitmap(RES.getRes("guide_textBg_png"));
            this._textBg.visible = false;
            this.addChild(this._textBg);

            //this._dragCardArrow = new egret.Bitmap(RES.getRes("guide_dragArrow_png"));
            //this._dragCardArrow.anchorOffsetY = this._dragCardArrow.height;
            //this._dragCardArrow.anchorOffsetX = this._dragCardArrow.width / 2;
            this._dragCardArrow = fairygui.UIPackage.createObjectFromURL("ui://kzx2kelphyug0").asImage;
            this._dragCardArrow.setPivot(0.5, 1, true);

            let jsonData: any = RES.getRes("effect_click_mc_json");
            let pngData: egret.Texture = RES.getRes("effect_click_tex_png");
            let factory = new egret.MovieClipDataFactory(jsonData, pngData);
            let mcData: egret.MovieClipData = factory.generateMovieClipData("click");
            this._hand = new egret.MovieClip(mcData);
            this._hand.gotoAndStop(1);
            this._hand.touchEnabled = false;
            this._hand.visible = false;
            this.addChild(this._hand);

            this._txt = new egret.TextField();
            if (window.gameGlobal.isPC) {
                this._txt.size = 35;
                this._txt.lineSpacing = 5;
            } else {
                this._txt.size = 23;
                this._txt.lineSpacing = 4;
            }
            this._txt.visible = false;
            this._txt.textColor = Core.TextColors.black;
            if (!window.gameGlobal.isMultiLan) {
                this._txt.fontFamily = "AaKaiTi";
            } else {
                if (!LanguageMgr.inst.isChineseLocale()) {
                    this._txt.wordWrap = true;
                }
            }
            //this._txt.strokeColor = Core.TextColors.black;
            //this._txt.stroke = 2;
            //this._txt.bold = true;
            this.addChild(this._txt);
        }

        public show() {
            if (this.parent == null) {
                (<egret.DisplayObjectContainer>Core.LayerManager.inst.maskLayer.displayObject).addChild(this);
            }
        }

        public hide() {
            if (this.parent) {
                this.touchEnabled = true;
                this.parent.removeChild(this);
                this._touchMask1.visible = false;
                this._textBg.visible = false;
                this._textKuang.visible = false;
                this._textArrow.visible = false;
                this._textArrow.width = this._textArrow.texture.$sourceWidth;
                this._txt.visible = false;
                this._dragCardArrow.visible = false;
                this._hand.visible = false;
                this._hand.gotoAndStop(1);
                egret.Tween.removeTweens(this._hand);
                this._hand.alpha = 1;
                if (this._touchMask2) {
                    this.removeChild(this._touchMask2);
                    this._touchMask2 = null;
                }
                if (this._dragCardArrow.parent) {
                    this._dragCardArrow.parent.removeChild(this._dragCardArrow);
                }
            }
        }

        private _makeTouchMask(mask:egret.Shape) {
            mask.graphics.clear();
            mask.graphics.beginFill(Core.TextColors.white, 0);
            mask.graphics.drawRect(0, 0, mask.width, mask.height);
            mask.graphics.endFill();
        }

        private caclMaskTarget(tagetObj:fairygui.GObject, needDarkMask:boolean):egret.Point {
            this._touchMask1.visible = true;
            let objGlobalPoint = tagetObj.localToRoot(0, 0);
            objGlobalPoint.x -= this.x;
            objGlobalPoint.y -= this.y;
            let objRec = new egret.Rectangle(objGlobalPoint.x-1, objGlobalPoint.y-1, tagetObj.width+2, tagetObj.height+2);
            
            this._bg.beginDraw();
            if (needDarkMask) {
                
            } else {
                objRec = new egret.Rectangle(0, 0, this.width, this.height);
            }
            this._bg.draw(objRec);
            this._bg.endDraw();

            this._touchMask1.x = objRec.x;
            this._touchMask1.y = objRec.y;
            this._touchMask1.width = objRec.width;
            this._touchMask1.height = objRec.height;
            this._makeTouchMask(this._touchMask1);
            return objGlobalPoint;
        }

        public setTalkData(targetObj:fairygui.GObject, text:string, x?:number, y?:number, width?:number, needDarkMask:boolean=true) {
            this._textBg.visible = true;
            this._textKuang.visible = true;
            this._txt.visible = true;
            this._bg.touchChildren = false;

            let objGlobalPoint:egret.Point;
            if (targetObj) {
                objGlobalPoint = this.caclMaskTarget(targetObj, needDarkMask);
                this._textArrow.visible = true;
            } else {
                this._bg.beginDraw();
                this._bg.endDraw();
            }

            let maxwidth = 320;
            if (window.gameGlobal.isPC) {
                maxwidth = 500;
            }
            if (width && width > 0) {
                maxwidth = width;
            }

            //文字显示
            this._txt.width = NaN;
            this._txt.height = NaN;
            this._txt.textFlow = Core.StringUtils.parseColorText(text);
            if (this._txt.width > maxwidth) {
                this._txt.textFlow = [];
                this._txt.width = maxwidth;
                this._txt.textFlow = Core.StringUtils.parseColorText(text);
            }
            this._textBg.width = this._txt.width + 30;
            this._textBg.height = this._txt.height + 20;

            if (x && y && x >=0 && y >= 0) {
                this._textBg.x = x;
                this._textBg.y = y;
            } else if (targetObj) {
                let _distance = 40;
                if (window.gameGlobal.isPC) {
                    _distance = 54;
                }
                this._textBg.x = this.width / 2 - this._textBg.width / 2;
                this._textBg.y = objGlobalPoint.y - this._textBg.height - _distance;
                if (this._textBg.y < 2 + window.support.topMargin) {
                    this._textBg.y = objGlobalPoint.y + targetObj.height + _distance;
                } 
            } else {
                this._textBg.x = this.width / 2 - this._textBg.width / 2;
                this._textBg.y = this.height / 2 - this._textBg.height / 2;
            }
            this._txt.x = this._textBg.x + 15;
            this._txt.y = this._textBg.y + 10;
            this._textKuang.width = this._textBg.width + 22;
            this._textKuang.height = this._textBg.height + 24;
            this._textKuang.x = this._textBg.x - 12;
            this._textKuang.y = this._textBg.y - 15; 
            if (targetObj) {
                if (this._textArrow.width > this._textKuang.height) {
                    this._textArrow.width = this._textKuang.height - 1;
                }
                this._textArrow.anchorOffsetX = this._textArrow.width / 2;
                let x1 = this._textKuang.x + this._textKuang.width / 2;
                let y1 = this._textKuang.y + this._textKuang.height - this._textArrow.width;
                let x2 = objGlobalPoint.x + targetObj.width / 2;
                let y2 = objGlobalPoint.y;
                if (this._textKuang.y > objGlobalPoint.y) {
                    y2 = objGlobalPoint.y + targetObj.height;
                }
                let distance = Math.sqrt( Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2) )
                this._textArrow.height = distance;
                this._textArrow.rotation = Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI - 90;
                this._textArrow.x = x1;
                this._textArrow.y = y1;
            }
        }

        public setClickData(targetObj:fairygui.GObject, text?:string, x?:number, y?:number, width?:number) {
            this._hand.visible = true;
            if (text && text != "") {
                this.setTalkData(targetObj, text, x, y, width);
            } else {
                this.caclMaskTarget(targetObj, true);
            }
            this._bg.touchChildren = true;

            let objGlobalPoint = new egret.Point();
            targetObj.localToRoot(0, 0, objGlobalPoint);
            objGlobalPoint.x -= this.x;
            objGlobalPoint.y -= this.y;
            this._hand.x = objGlobalPoint.x + targetObj.width / 2;
            this._hand.y = objGlobalPoint.y + targetObj.height / 2;
            this._hand.gotoAndPlay(1, -1);
            
            this._touchMask1.once(egret.TouchEvent.TOUCH_TAP, ()=>{
                if (this._targetOnclickCallback) {
                    let func = this._targetOnclickCallback;
                        this._targetOnclickCallback = null;
                    func.apply(this._targetOnclickThisArg);
                }
            }, this);
        }

        public addTargetClickListener(listener:Function, thisArg:any) {
            this._targetOnclickCallback = listener;
            this._targetOnclickThisArg = thisArg;
        }

        public setDragCardData(fromObj:fairygui.GObject, toObj:fairygui.GObject, textTargetObj?:fairygui.GObject, 
            text?:string, x?:number, y?:number, width?:number) {

            if (text && text != "") {
                this.setTalkData(textTargetObj, text, x, y, width, false);
                this._touchMask1.visible = false;
            }

            this.touchEnabled = false;
            this._hand.visible = true;
            this._dragCardArrow.visible = true;

            let fromObjGlobalPoint = fromObj.localToRoot(0, 0);
            let fromobjRec = new egret.Rectangle(fromObjGlobalPoint.x-3, fromObjGlobalPoint.y-3, fromObj.width+6, fromObj.height+6);
            let toObjGlobalPoint = toObj.localToRoot(0, 0);
            let toobjRec = new egret.Rectangle(toObjGlobalPoint.x-3, toObjGlobalPoint.y-3, toObj.width+6, toObj.height+6);
            this._bg.destroy();

            let x1 = fromobjRec.x + fromobjRec.width / 2;
            let y1 = fromobjRec.y + fromobjRec.height / 2;
            let x2 = toobjRec.x + toobjRec.width / 2;
            let y2 = toobjRec.y + toobjRec.height / 2;
            let distance = Math.sqrt( Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2) )
            this._dragCardArrow.height = distance;
            this._dragCardArrow.rotation = Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI + 90;
            let arrowPoint = fromObj.parent.rootToLocal(x1, y1)
            this._dragCardArrow.x = arrowPoint.x;
            this._dragCardArrow.y = arrowPoint.y;
            fromObj.parent.addChild(this._dragCardArrow);
            fromObj.parent.swapChildren(this._dragCardArrow, fromObj);

            this._hand.gotoAndStop(this._hand.totalFrames);
            this._hand.x = fromobjRec.x + fromobjRec.width / 2 - this.x;
            this._hand.y = fromobjRec.y + fromobjRec.height / 2 - this.y;
            let tox = toobjRec.x + toobjRec.width / 2 - this.x;
            let toy = toobjRec.y + toobjRec.height / 2 - this.y;
            let v = 0.6;
            distance = Math.sqrt( Math.pow(tox - this._hand.x, 2) + Math.pow(toy - this._hand.y, 2) )
            egret.Tween.get(this._hand, { loop:true}).wait(300).to({x:tox, y:toy}, distance / v).wait(400).to({alpha:0}, 200);
        }
    }

}
