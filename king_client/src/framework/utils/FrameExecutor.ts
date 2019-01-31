module Core {

    /**
     *  分帧处理
     */
    export class FrameExecutor {
        private _delayFrame:number;
        private _functions:Array<Array<any>>;
        private _isCancel: boolean;

        constructor(delayFrame:number=1) {
            this._delayFrame = delayFrame;
            this._functions = [];
        }

        public regist(func:Function, thisObj:any, ...param:any[]):void {
            this._functions.push([func, thisObj, param]);
        }

        public cancel() {
            this._isCancel = true;
        }

        public execute() {
            if (this._isCancel) {
                return
            }

            if (this._functions.length) {
                let arr:Array<any> = this._functions.shift();
                arr[0].call(arr[1], ...arr[2]);
                fairygui.GTimers.inst.add(fairygui.GTimers.FPS30, 1, this.execute, this);
            }
        }
    }

}