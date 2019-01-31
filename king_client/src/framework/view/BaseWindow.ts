module Core {

    export class BaseWindow extends fairygui.Window implements IBaseView {
        private _isInit: boolean;
        protected _myParent: fairygui.GRoot;
        private _viewCommon: ViewCommon;

        constructor() {
            super();
            this._viewCommon = new ViewCommon(this);
        }

        public setVisible(flag:boolean) {
            this.visible = flag;
        }

        public adjust(display:fairygui.GObject, adjustType:AdjustType=AdjustType.EXACT_FIT) {
            if (adjustType == AdjustType.EXCEPT_MARGIN) {
                this._viewCommon.adjust(display, AdjustType.EXACT_FIT);
                display.height -= window.support.topMargin;
            } else {
                this._viewCommon.adjust(display, adjustType);
            }            
        }

        public isInit():boolean {
            return this._isInit;
        }

        public isShow():boolean {
            return this.parent != null && this.visible;
        }

        public addToParent():void {

        }

        public removeFromParent():void {

        }
        public battleChangeLayer() {
            if (Core.ViewManager.inst.isShow(ViewName.battle)) {
                this.toTopLayer();
            } else {
                this.toMainLayer();
            }
        }

        public toTopLayer() {
            this._myParent = Core.LayerManager.inst.topLayer;
        }
        public toMainLayer() {
            this._myParent = Core.LayerManager.inst.mainLayer;
        }

        public initUI():void {
            this._isInit = true;
        }

        public async open(...param:any[]) {
            if (this._myParent) {
                this._myParent.showWindow(this);
            } else {
                this.show();
            }
        }

        public async close(...param:any[]) {
            this.hide();
        }

        public destroy() {
            this._viewCommon.destroy();
            this.dispose();
        }

        public getNode(nodeName:string): fairygui.GObject {
            return this._viewCommon.getNode(nodeName);
        }
    }

}