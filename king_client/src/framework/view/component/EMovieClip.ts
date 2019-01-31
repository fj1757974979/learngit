module Core {

    export class EMovieClip extends fairygui.GObject {
        private _movieClip: egret.MovieClip;

        constructor(movieClip: egret.MovieClip) {
            super();
            this._movieClip = movieClip;
            this._movieClip["$owner"] = this;
            this._movieClip.touchEnabled = false;
            this.setDisplayObject(this._movieClip);
            //this.initWidth = this.sourceWidth = this._movieClip.width;
            //this.initHeight = this.sourceHeight = this._movieClip.height;
        }

        public get totalFrames(): number {
            return this._movieClip.totalFrames;
        }

        public gotoAndPlay(frame: string | number, playTimes?: number): void {
            this._movieClip.gotoAndPlay(frame, playTimes);
        }

        public gotoAndStop(frame: string | number): void {
            this._movieClip.gotoAndStop(frame);
        }

        public stop(): void {
            this._movieClip.stop();
        }

        public once(type: string, listener: Function, thisObject: any, useCapture?: boolean, priority?: number): void {
            this._movieClip.once(type, listener, thisObject, useCapture, priority);
        }

        public addFrameEvent(frameNum:number, name:string) {
            this._movieClip.movieClipData.events[frameNum] = name;
        }
    }

}