module UI {

    export class MaskProgressBar extends fairygui.GComponent {
        protected _bar: fairygui.GLoader;
        protected _bar2: fairygui.GLoader;
        protected _icon: fairygui.GLoader;

        private _progressAniResolve: (value? :void|PromiseLike<void>) => void;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._bar = this.getChild("bar").asLoader;
            this._bar.mask = new egret.Rectangle(0, 0, this._bar.width, this._bar.height);

            let bar2 = this.getChild("bar2");
            if (bar2) {
                this._bar2 = bar2.asLoader;
                this._bar2.mask = new egret.Rectangle(0, 0, this._bar2.width, this._bar2.height);
            }
            this._progressAniResolve = null;
        }

        get bar() {
            return this._bar;
        }
        get ba2() {
            if (this._bar2) {
                return this._bar2;
            }
        }

        set __icon(icon: fairygui.GLoader) {
            this._icon = icon;
            //this._icon.setPivot(0.5, 0.5, true);
        }

	public set value(val:number) {
	    this.setProgress(val, 100);
	}

        public setProgress(cur:number, max:number) {
            let mask = this._bar.mask;
            if (max == 0) {
                mask.width = this._bar.width;
            } else {
                mask.width = this._bar.width * (cur / max);
                mask.width = mask.width > this._bar.width ? this._bar.width : mask.width;
            }
            this._bar.mask = mask;
        }
        public setProgress2(cur: number, max: number) {
            if (this._bar2) {
                let mask = this._bar2.mask;
                if (max == 0) {
                    mask.width = this._bar2.width;
                } else {
                    mask.width = this._bar2.width * (cur / max);
                    mask.width = mask.width > this._bar2.width ? this._bar2.width : mask.width;
                }
                this._bar2.mask = mask;
            }
        }

        public async doProgressAnimation(from:number, to:number, max:number, changeCb?:(cur:number)=>void) {
            this.setProgress(from, max);
            if (max == 0) {
                return;
            }
            let mask = this._bar.mask;
            let toWidth = this._bar.width * (to / max);
            toWidth = toWidth > this._bar.width ? this._bar.width : toWidth;
            //let v = 0.05;
            //let diffWidth = Math.abs(toWidth - mask.width);
            await new Promise<void>(resolve => {
                this._progressAniResolve = resolve;
                egret.Tween.get(mask, {onChange:()=>{
                    this._bar.mask = mask;
                    if(this._icon) {
                        this._icon.x = this._bar.mask.width + 62; 
                    }
                    if (changeCb) {
                        changeCb(this._bar.mask.width / this._bar.width * max);
                    }
                }, onChangeObj:this}).to({width:toWidth}, 1000).call(()=>{
                    this._progressAniResolve = null;
                    resolve();
                }, this);
            });
        }

        public stopProgressAnimation() {
            if (this._progressAniResolve) {
                this._progressAniResolve();
                this._progressAniResolve = null;
            }
            egret.Tween.removeTweens(this._bar.mask);
        }
    }

}
