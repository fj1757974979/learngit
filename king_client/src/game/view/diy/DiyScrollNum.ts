module Diy {

    export class DiyScrollNum extends fairygui.GComponent {
        private _numSize: number;

        private nextNum(frame:number): Promise<void> {
            return new Promise<void>(resolve => {
                let speed = this._numSize / frame;
                let recty = this.displayObject.scrollRect.y;

                let i = 0;
                fairygui.GTimers.inst.add(25, frame, ()=>{
                    i++;
                    let _scrollRect = this.displayObject.scrollRect;
                    if (i >= frame) {
                        _scrollRect.y = recty + this._numSize;
                        this.displayObject.scrollRect = _scrollRect;
                        resolve();
                    } else {
                        _scrollRect.y += speed;
                        this.displayObject.scrollRect = _scrollRect;
                    }
                }, this);
                /*
                fairygui.GTimers.inst.add(33, frame, ()=>{
                    let _scrollRect = this.scrollRect;
                    _scrollRect.y += speed;
                    this.scrollRect = _scrollRect;
                }, this, ()=>{
                    let _scrollRect = this.scrollRect;
                    _scrollRect.y = recty + NUM_SIZE;
                    this.scrollRect = _scrollRect;
                    resolve();
                }, this);
                */
            });
        }

        public async playEffect(realText:fairygui.GTextField, targetNum:number) {
            this._numSize = realText.height;
            let scrollerHeight = this._numSize * (20 + targetNum + 1);
            this.width = this._numSize;
            this.height = scrollerHeight;
            for (let i=0; i<(20 + targetNum + 1); i++) {
                let num = i % 10;
                let _text = new fairygui.GTextField();
                _text.width = this._numSize;
                _text.height = this._numSize;
                _text.text = num + "";
                _text.fontSize = realText.fontSize;
                _text.color = Core.TextColors.white;
                //_text.align = fairygui.AlignType.Center;
                //_text.verticalAlign = fairygui.VertAlignType.Middle;
                _text.y = i * this._numSize;
                _text.font = realText.font;
                this.addChild(_text);
            }

            this.x = realText.x;
            this.y = realText.y;
            realText.parent.addChild(this);
            this.displayObject.scrollRect = new egret.Rectangle(0, 0, this._numSize, this._numSize);
            
            let v = 14;
            for (let i=0; i<10; i++) {
                await this.nextNum(v);
                v--;
            }
            for (let i=0; i<5; i++) {
                await this.nextNum(v);
            }
            for (let i=0; i<5; i++) {
                await this.nextNum(v);
                v++;
            }
            for (let i=0; i<targetNum; i++) {
                v += 2;
                if (v > 14) {
                    v = 14;
                }
                await this.nextNum(v);
            }
            if (this.parent) {
                this.parent.removeChild(this);
            }
        }
    }

}