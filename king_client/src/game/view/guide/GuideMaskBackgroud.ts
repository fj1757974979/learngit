module Guide {

    class Block {
        public x:number;
        public y:number;
        public w:number;
        public h:number;

        constructor(x:number, y: number, w:number, h:number) {
            this.x = x;
            this.y = y;
            this.w = w;
            this.h = h;
        }
    }

    /**
     * 新手引导背景，实现的是一个类似不规则遮罩的功能
     */
    export class GuideMaskBackgroud extends egret.Sprite {
        private _bgs:Array<egret.Shape>;
        private _deductRecs:Array<egret.Rectangle>;

        constructor(stageWidth:number, stageHeight:number) {
            super();
            this._bgs = [];
            this._deductRecs = [];
            this.width = stageWidth;
            this.height = stageHeight;
            this.touchEnabled = false;
        }

        public beginDraw() {
            //this.cacheAsBitmap = false;
            this.removeAllChild();
        }

        private fillColumn(blocks:Array<Block>) {
            blocks.forEach(b => {
                if (b.h <= 0 || b.w <= 0) {
                    return;
                }
                let deductRecs = this._deductRecs.sort((a:egret.Rectangle, b:egret.Rectangle):number => {
                    return a.x - b.x;
                })
                let _rowBlocks: Array<Block> = [];
                let isDone = true;

                for (let rec of deductRecs) {
                    if (rec.x >= b.x+b.w || rec.x+rec.width <= b.x || rec.y >= b.y+b.h || rec.y+rec.height <= b.y) {
                        continue;
                    }

                    if (rec.x > b.x) {
                        isDone = false;
                        this.addBg(b.x, b.y, rec.x - b.x, b.h);
                        b.w -= (rec.x - b.x)
                        b.x = rec.x;
                    }

                    let bw = rec.x + rec.width - b.x;
                    if (bw >= b.w) {
                        bw = b.w;
                    }
                    _rowBlocks.push(new Block(b.x, b.y, bw, b.h));
                    b.w -= bw;
                    b.x += bw;
                    
                    if (b.w <= 0) {
                        break;
                    }
                }

                if (b.w > 0) {
                    this.addBg(b.x, b.y, b.w, b.h);
                }

                if (isDone && _rowBlocks.length <= 1) {
                    return;
                }

                if (_rowBlocks.length > 0) {
                    this.fillRow(_rowBlocks);
                }
            })
        }

        private fillRow(blocks:Array<Block>) {
            blocks.forEach(b => {
                if (b.h <= 0 || b.w <= 0) {
                    return;
                }
                let deductRecs = this._deductRecs.sort((a:egret.Rectangle, b:egret.Rectangle):number => {
                    return a.y - b.y;
                })
                let _columnBlocks: Array<Block> = [];

                for (let rec of deductRecs) {
                    if (rec.x >= b.x+b.w || rec.x+rec.width <= b.x || rec.y >= b.y+b.h || rec.y+rec.height <= b.y) {
                        continue;
                    }

                    if (rec.y > b.y) {
                        this.addBg(b.x, b.y, b.w, rec.y - b.y);
                        b.h -= (rec.y - b.y)
                        b.y = rec.y;
                    }

                    let bh = rec.y + rec.height - b.y;
                    if (bh >= b.h) {
                        bh = b.h;
                    }
                    _columnBlocks.push(new Block(b.x, b.y, b.w, bh));
                    b.h -= bh;
                    b.y += bh;
                    if (b.h <= 0) {
                        break;
                    }
                }

                if (b.h > 0) {
                    this.addBg(b.x, b.y, b.w, b.h);
                }

                if (_columnBlocks.length > 0) {
                    this.fillColumn(_columnBlocks);
                }
            })
        }

        public endDraw() {
            try {
                if (this._deductRecs.length <= 0) {
                    this.addBg(0, 0, this.width, this.height);
                } else {
                    this.fillRow([new Block(0, 0, this.width, this.height)]);
                }
                //this.cacheAsBitmap = true;
                this._deductRecs = [];
            } catch (e) {
                console.error("guide endDraw", e);
            }
        }

        /**
         * @param deductRec 抠出矩形区域
         */
        public draw(deductRec:egret.Rectangle):void {
            this._deductRecs.push(deductRec);
        }

        public destroy():void {
            //this.cacheAsBitmap = false;
            this.removeChildren();
            this._bgs = [];
        }

        private removeAllChild():void {
            while (this.numChildren) {
                let bg:egret.Shape = <egret.Shape>this.removeChildAt(0);
                this._bgs.push(bg);
            }
        }

        /**
         * 添加一个bg
         * @param $x 初始X
         * @param $y 初始Y
         * @param $w 宽
         * @param $h 高
         */
        private addBg($x:number, $y:number, $w:number, $h:number):void {
            let bg:egret.Shape;
            if (this._bgs.length) {
                bg = this._bgs.pop();
                bg.graphics.clear();
            } else {
                bg = new egret.Shape();
            }

            bg.graphics.beginFill(0x000000, 0.0);
            bg.graphics.drawRect($x, $y, $w, $h);
            bg.graphics.endFill();
            this.addChild(bg);
        }

        /**
         * 重写hitTest
         * 检测指定坐标是否在显示对象内
         * @method egret.DisplayObject#hitTest
         * @param x {number} 检测坐标的x轴
         * @param y {number} 检测坐标的y轴
         * @param ignoreTouchEnabled {boolean} 是否忽略TouchEnabled
         * @returns {*}
         */
        /*
        public hitTest(x:number, y:number, ignoreTouchEnabled?:boolean) {
            if (this._deductRec && this._deductRec.contains(x, y)) {
                return null;
            } else {
                return this;
            }
        }
        */
    }

}