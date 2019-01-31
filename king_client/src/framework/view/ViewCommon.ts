module Core {

    export class ViewCommon {
        private _adjustObjs: Array<[fairygui.GObject, AdjustType]>;
        private _view: fairygui.GComponent;

        constructor(view:fairygui.GComponent) {
            this._view = view;
        }

        public adjust(display:fairygui.GObject, adjustType:AdjustType=AdjustType.EXACT_FIT) {
            //this._doAdjust(display, adjustType);
            if (!Core.DeviceUtils.isMobile() && !window.gameGlobal.isPC) {
                return;
            }
            
            if (Core.DeviceUtils.isWXGame()) {
                this._doAdjust(display, adjustType);
                return;
            }  
            
            if (!this._adjustObjs) {
                this._adjustObjs = new Array<[fairygui.GObject, AdjustType]>();
                fairygui.GRoot.inst.displayObject.stage.addEventListener(egret.Event.RESIZE, this._onResize, this);
            }
            this._adjustObjs.push([display, adjustType]);
            this._doAdjust(display, adjustType);
        }

        private _onResize() {
            this._adjustObjs.forEach(objArr => {
                this._doAdjust(objArr[0], objArr[1]);
            });
        }

        private _doAdjust(display:fairygui.GObject, adjustType:AdjustType=AdjustType.EXACT_FIT) {
            let uiRoot = fairygui.GRoot.inst;
            if (adjustType == AdjustType.NO_BORDER) {
                let scaleX = uiRoot.getDesignStageWidth() / this._view.width;
                let scaleY = uiRoot.getDesignStageHeight() / this._view.height;
                let scale = scaleX > scaleY ? scaleX: scaleY;
                display.width = display.initWidth * scale;
                display.height = display.initHeight * scale;
            } else {
                let adjustContext: fairygui.GObject;
                if (display instanceof fairygui.GComponent) {
                    adjustContext = (<fairygui.GComponent>display).getChild("adjustContext");
                }
                display.width = uiRoot.getDesignStageWidth();
                display.height = uiRoot.getDesignStageHeight() /* - window.support.topMargin */;
                if (adjustContext) {
                    let scaleX = uiRoot.getDesignStageWidth() / this._view.width;
                    let scaleY = uiRoot.getDesignStageHeight() / this._view.height;
                    let scale = scaleX > scaleY ? scaleX: scaleY;
                    adjustContext.width = adjustContext.initWidth * scale;
                    adjustContext.height = adjustContext.initHeight * scale/* - window.support.topMargin */;
                }
            }
            // console.log(`${display.width},${window.support.topMargin}`);
            display.x = this._view.width/2  - display.width/2 ;
            display.y = this._view.height / 2 - display.height / 2/* + window.support.topMargin/2*/;
            if (Core.DeviceUtils.isWXGame()) {
                this._view.y = -display.y;
            }
        }

        public destroy() {
            if (this._adjustObjs) {
                fairygui.GRoot.inst.displayObject.stage.removeEventListener(egret.Event.RESIZE, this._onResize, this);
                this._adjustObjs = null;
            }
            this._view = null;
        }

        private getSubNode(parent:fairygui.GComponent, nodeName:string, childs:Array<fairygui.GComponent>): fairygui.GObject {
            let node = parent.getChild(nodeName);
            if (node) {
                return node;
            }
            let childAmount = parent.numChildren;
            for(let i=0; i<childAmount; i++) {
                let c = parent.getChildAt(i);
                if (!c) {
                    break;
                }
                if (c instanceof fairygui.GComponent) {
                    childs.push(c);
                }
            }
            return null;
        }

        public getNode(nodeName:string): fairygui.GObject {
            let childs: Array<fairygui.GComponent> = [];
            let c = this.getSubNode(this._view, nodeName, childs)
            if (c) {
                return c;
            }

            for (let i=0; i<childs.length; i++) {
                c = this.getSubNode(childs[i], nodeName, childs)
                if (c) {
                    return c;
                }
            }
            return null;
        }
    }

}