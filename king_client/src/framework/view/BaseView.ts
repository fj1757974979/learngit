module Core {

    export class BaseView extends fairygui.GComponent implements IBaseView {
        protected _myParent: fairygui.GComponent;
        private _isInit: boolean;
        private _viewCommon: ViewCommon;

        constructor(parent?: fairygui.GComponent) {
            super();
            if (parent) {
                this._myParent = parent;
            } else {
                this._myParent = fairygui.GRoot.inst;
            }
            this._isInit = false;
            this._viewCommon = new ViewCommon(this);
        }

        public adjust(display:fairygui.GObject, adjustType:AdjustType=AdjustType.EXACT_FIT) {
            if (adjustType == AdjustType.EXCEPT_MARGIN) {
                this._viewCommon.adjust(display, AdjustType.EXACT_FIT);
                display.height -= window.support.topMargin;
            } else {
                this._viewCommon.adjust(display, adjustType);
            }            
        }

        public setVisible(flag:boolean):void {
            this.visible = flag;
        }

        public isInit():boolean {
            return this._isInit;
        }

        public isShow():boolean {
            return this.parent != null && this.visible;
        }

        public addToParent(parent?: fairygui.GComponent):void {
            if (parent) {
                this._myParent = parent;
            }
            this._myParent.addChild(this);
        }

        public removeFromParent():void {
            if (this.parent) {
                this.parent.removeChild(this);
            }
        }

        public initUI():void {
            this._isInit = true;
        }

        public async open(...param:any[]) {

        }

        public async close(...param:any[]) {

        }

        public toTopLayer() {
            Core.LayerManager.inst.topLayer.addChild(this);
        }

        public toMainLayer() {
            Core.LayerManager.inst.mainLayer.addChild(this);
        }

        public destroy() {
            this._myParent = null;
            this._viewCommon.destroy();
            this.dispose();
        }

        public getNode(nodeName:string): fairygui.GObject {
            return this._viewCommon.getNode(nodeName);
        }
    }

}