// TypeScript file
module Core {
    class TouchInfo {
		public x: number;
		public y: number;
		public lastx: number;
		public lasty: number;
		public id: number;

		public updateCoord(evt: egret.TouchEvent) {
			this.lastx = this.x;
			this.lasty = this.y;
			this.x = evt.stageX;
			this.y = evt.stageY;
		}
		
		public get dx(): number {
			return this.x - this.lastx;
		}

		public get dy(): number {
			return this.y - this.lasty;
		}

		public constructor(evt: egret.TouchEvent) {
			this.x = evt.stageX;
			this.y = evt.stageY;
			this.lastx = this.x;
			this.lasty = this.y;
            this.id = evt.touchPointID;
		}
	}

	export class DragDetector {

		private _host: fairygui.GComponent = null;;
		private _checkBoundFunc: (x: number, y: number) => {x: number, y: number} = null;
		private _onDragFunc: () => void = null;
		private _maxScale: number = 5;
		private _minScale: number = 0.1;
		private _detectType: number = DragDetector.T_DRAG;

		// private _touchInfos: Collection.Dictionary<number, TouchInfo>;
		// private _touchCount: number = 0;
		// private _zoomDetecting: boolean  = true;
        private _activeTouchInfo1: TouchInfo = null;
        private _activeTouchInfo2: TouchInfo = null;

		public static T_DRAG = 1;
		public static T_ZOOM = 2;

		public constructor() {
			// this._touchInfos = new Collection.Dictionary<number, any>();
		}

		public registerTouch(host: fairygui.GComponent, t: number, param?: {minScale?: number, maxScale?: number, checkBoundCb?: (x: number, y: number) => {x: number, y: number}, onDropCb?: () => void}) {
			this._host = host;
			if (param.minScale) {
				this._minScale = param.minScale;
			}
			if (param.maxScale) {
				this._maxScale = param.maxScale;
			}
			if (param.checkBoundCb) {
				this._checkBoundFunc = param.checkBoundCb;
			}
			if (param.onDropCb) {
				this._onDragFunc = param.onDropCb;
			}
            this._detectType = t;

			host.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchBegin, this);
            host.addEventListener(egret.TouchEvent.TOUCH_MOVE, this._onDrag, this);
			host.addEventListener(egret.TouchEvent.TOUCH_END, this._onTouchEnd, this);
		}

		public unregisterTouch(host: fairygui.GComponent) {
			host.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchBegin, this);
            host.removeEventListener(egret.TouchEvent.TOUCH_MOVE, this._onDrag, this);
			host.removeEventListener(egret.TouchEvent.TOUCH_END, this._onTouchEnd, this);
			this._checkBoundFunc = null;
			this._onDragFunc = null;
			this._host = null;
            this._activeTouchInfo1 = null;
            this._activeTouchInfo2 = null;
		}

		private async _onTouchBegin(evt: egret.TouchEvent) {
			if (!this._host) {
				return;
			}
			// this._touchInfos.setValue(evt.touchPointID, new TouchInfo(evt));
			// this._touchCount = Math.min(2, this._touchCount + 1);
			// this._zoomDetecting = true;
			// Core.TipsUtils.showTipsFromCenter(`${this._touchCount} touchId: ${evt.touchPointID.toString()}`);
		}

		private async _onDrag(evt: egret.TouchEvent) {
			let touchId = evt.touchPointID;
			// Core.TipsUtils.showTipsFromCenter(`touchId: ${touchId.toString()}`);

			// let touchInfo = this._touchInfos.getValue(touchId);
			// if (!touchInfo) {
				// this._touchInfo.setValue(evt.touchPointID, new TouchInfo(evt));
				// return;
			// }
			// touchInfo.updateCoord(evt);

            if (!this._activeTouchInfo1) {
                this._activeTouchInfo1 = new TouchInfo(evt);
                // console.log("new _activeTouchInfo1");
            } else if (this._activeTouchInfo1.id == touchId) {
                this._activeTouchInfo1.updateCoord(evt);
                // console.log("update _activeTouchInfo1");
            } else if (!this._activeTouchInfo2) {
                this._activeTouchInfo2 = new TouchInfo(evt);
                // console.log("new _activeTouchInfo2");
            } else if (this._activeTouchInfo2.id == touchId) {
                this._activeTouchInfo2.updateCoord(evt);
                // console.log("update _activeTouchInfo2");
            }

			// if (this._touchCount <= 1) {
            if (this._activeTouchInfo1 && !this._activeTouchInfo2) {
				// just drop
				let point = this._checkBound(this._host.x + this._activeTouchInfo1.dx, this._host.y + this._activeTouchInfo1.dy);
				this._host.x = point.x;
				this._host.y = point.y;
			} else if (this._detectType == DragDetector.T_ZOOM) {
				// let touchIds = this._touchInfos.keys();
				// Core.TipsUtils.showTipsFromCenter(JSON.stringify(touchIds));
				if (this._activeTouchInfo1 && this._activeTouchInfo2 && this._activeTouchInfo2.id == touchId) {
					// zoom and drop
					// let touchInfo1 = this._touchInfos.getValue(touchIds[touchIds.length - 1]);
					// let touchInfo2 = this._touchInfos.getValue(touchIds[touchIds.length - 2]);
                    let touchInfo1 = this._activeTouchInfo1;
                    let touchInfo2 = this._activeTouchInfo2;
					// if (!touchInfo1 || !touchInfo2) {
					// 	this._touchCount = 0;
					// 	this._touchInfos.clear();
					// 	return;
					// }
					let currPoint1 = new egret.Point(touchInfo1.x, touchInfo1.y);
					let currPoint2 = new egret.Point(touchInfo2.x, touchInfo2.y);
					let lastPoint1 = new egret.Point(touchInfo1.lastx, touchInfo1.lasty);
					let lastPoint2 = new egret.Point(touchInfo2.lastx, touchInfo2.lasty);
					let lastCenterPoint = new egret.Point((lastPoint1.x + lastPoint2.x) / 2, (lastPoint1.y + lastPoint2.y) / 2);
					let currCenterPoint = new egret.Point((currPoint1.x + currPoint2.x) / 2, (currPoint1.y + currPoint2.y) / 2);
					let offsetx = currCenterPoint.x - lastCenterPoint.x;
					let offsety = currCenterPoint.y - lastCenterPoint.y;

					let lastDis = Math.max(1, egret.Point.distance(lastPoint1, lastPoint2));
					let currDis = Math.max(1, egret.Point.distance(currPoint1, currPoint2));
					let scale = this._host.scaleX * currDis / lastDis;

					scale = Math.max(this._minScale, Math.min(this._maxScale, scale));

					let centerLocalPoint = this._host.globalToLocal(currCenterPoint.x, currCenterPoint.y);
					let oldScale = this._host.scaleX;
					let dx = offsetx - (centerLocalPoint.x * (scale - oldScale));
					let dy = offsety - (centerLocalPoint.y * (scale - oldScale));

					let point = this._checkBound(this._host.x + dx, this._host.y + dy);
					this._host.x = point.x;
					this._host.y = point.y;
					this._host.scaleX = scale;
					this._host.scaleY = scale;
				}
			}
			if (this._onDragFunc) {
				this._onDragFunc();
			}
		}

		private async _onTouchEnd(evt: egret.TouchEvent) {
			// this._touchInfos.remove(evt.touchPointID);
			// this._touchCount --;
			// if (this._touchCount <= 0) {
			// 	this._touchCount = 0;
			// 	this._touchInfos.clear();
			// }
            this._activeTouchInfo1 = null;
            this._activeTouchInfo2 = null;
		}

		private _checkBound(fx: number, fy: number): {x: number, y: number} {
			if (this._checkBoundFunc) {
				return this._checkBoundFunc(fx, fy);
			} else {
				return this._defaultCheckBound(fx, fy);
			}
		}

		private _defaultCheckBound(fx: number, fy: number): {x: number, y: number} {
			if (!this._host) {
				return {x: 0, y: 0};
			}
			let uiRoot = fairygui.GRoot.inst;
			let x = fx;
			if (uiRoot.getDesignStageWidth() == this._host.width * this._host.scaleX) {
				x = this._host.parent.width / 2 - (this._host.width * this._host.scaleX) / 2;
			} else {
				let minX = (this._host.parent.width - uiRoot.getDesignStageWidth()) / 2;
				x = Math.min(minX, x);
				x = Math.max(this._host.parent.width - this._host.width * this._host.scaleX - minX, x);
			}
			let y = fy;
			if (uiRoot.getDesignStageHeight() == this._host.height * this._host.scaleY) {
				y = this._host.parent.height / 2 - (this._host.height * this._host.scaleY) / 2;
			} else {
				let minY = (this._host.parent.height - uiRoot.getDesignStageHeight())/2
				y = Math.min(minY, y);
				y = Math.max(this._host.parent.height - this._host.height * this._host.scaleY - minY, y);
			}
			return {x: x, y: y};
		}
	}
}