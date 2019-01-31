module Core {

    export class LayerManager {
        private static _inst: LayerManager;
        private static _designWidth: number;
        private static _designHeight: number;

        private _mainLayer: fairygui.GRoot;
        private _maskLayer: fairygui.GRoot;
        private _topLayer: fairygui.GRoot;
        private _layers: Array<fairygui.GRoot>;

        constructor() {
            let stage = egret.MainContext.instance.stage;
            this._mainLayer = fairygui.GRoot.inst;
            this._maskLayer = new fairygui.GRoot();
            this._topLayer = new fairygui.GRoot();
            if (LayerManager._designWidth && LayerManager._designHeight) {
                this._mainLayer.setDesignSize(LayerManager._designWidth, LayerManager._designHeight);
                this._maskLayer.setDesignSize(LayerManager._designWidth, LayerManager._designHeight);
                this._topLayer.setDesignSize(LayerManager._designWidth, LayerManager._designHeight);
            }

            stage.addChild(this._mainLayer.displayObject);
            stage.addChild(this._maskLayer.displayObject);
            stage.addChild(this._topLayer.displayObject);
            this._layers = [this._mainLayer, this._topLayer];
        }

        public static get inst(): LayerManager {
            if (!LayerManager._inst) {
                LayerManager._inst = new LayerManager();
            }
            return LayerManager._inst;
        }

        public static setDesignSize(width:number, height:number) {
            LayerManager._designWidth = width;
            LayerManager._designHeight = height;
            
            if (LayerManager._inst) {
                LayerManager._inst._mainLayer.setDesignSize(LayerManager._designWidth, LayerManager._designHeight);
                LayerManager._inst._maskLayer.setDesignSize(LayerManager._designWidth, LayerManager._designHeight);
                LayerManager._inst._topLayer.setDesignSize(LayerManager._designWidth, LayerManager._designHeight); 
            }
        }

        public static getDesignWidth(): number {
            return this._designWidth;
        }

        public static getDesignHeight(): number {
            return this._designHeight;
        }

        public get mainLayer(): fairygui.GRoot {
            return this._mainLayer;
        }

        public get maskLayer(): fairygui.GRoot {
            return this._maskLayer;
        }

        public get topLayer(): fairygui.GRoot {
            return this._topLayer;
        }

        public getTopView(): BaseView | BaseWindow {
            for (let i=this._layers.length-1; i>=0; i--) {
                let layer = this._layers[i];
                let cnt: number = layer.numChildren;
                for (let j=cnt-1; j>= 0; j--) {
                    let v = layer.getChildAt(j);
                    if (v instanceof BaseView) {
                        return <BaseView>v;
                    } else if (v instanceof BaseWindow) {
                        return <BaseWindow>v;
                    }
                }
            }
            return null;
        }
    }

}