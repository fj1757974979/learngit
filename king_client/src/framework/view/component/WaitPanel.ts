module Core {

    export class WaitPanel extends BaseView {
        private _waitImg: fairygui.GLoader;

        constructor() {
            super(LayerManager.inst.maskLayer);
        }

        public initUI() {
            super.initUI();
            this._waitImg = this.getChild("loadingCircle").asLoader;
        }

        public async open(...param:any[]) {
            if (this.parent) {
                return;
            }
            this.addToParent();
            this._waitImg.visible = false;
            fairygui.GTimers.inst.add(800, 1, this.rotationWaitImg, this);
        }

        private rotationWaitImg() {
            this._waitImg.visible = true;
            EffectUtil.rotationEffect(this._waitImg, 1000);
        }

        public async close(...param:any[]) {
            if (!this.parent) {
                return;
            }
            this.parent.removeChild(this);
            fairygui.GTimers.inst.remove(this.rotationWaitImg, this);
            EffectUtil.removeRotationEffect(this._waitImg);
        }
    }

}