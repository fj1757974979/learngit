module Battle {

    export class MCEffect implements IEffect {

        private isStop: boolean = false;
        private _mc: Core.EMovieClip;
        private _movieId: string;
        private _realMovieId: string;

        constructor(movieId:string) {
            this._movieId = movieId;
            let movieIdInfo = movieId.split("_");
            if (movieIdInfo.length >= 2 && parseInt(movieIdInfo[1]) > 0) {
                this._realMovieId = movieIdInfo[0];
            } else {
                this._realMovieId = movieId;
            }
            this._mc = Core.MCFactory.inst.getMovieClip(this._realMovieId, this._realMovieId);
        }

        public play(parent:fairygui.GComponent, isLoop:boolean, isLoopStop:boolean, visible:boolean): Promise<void> {
            if (this._mc == null) {
                return null;
            }
            this._mc.visible = visible;
            if (this.isStop) {
                return null;
            }
            if (isLoop) {
                parent.addChild(this._mc);
                this._mc.x = parent.width / 2;
                this._mc.y = parent.height / 2;
                this._mc.gotoAndPlay(1, -1);
                if (visible) {
		            SoundMgr.inst.playSoundAsync(`${this._realMovieId}_mp3`);
                }
                return null;
            }

            let gPoint = parent.localToRoot(parent.width / 2, parent.height / 2);
            this._mc.x = gPoint.x;
            this._mc.y = gPoint.y;
            fairygui.GRoot.inst.addChild(this._mc);
            
            let p = new Promise<void>(resolve => {

                if (isLoopStop) {
                    let self = this;
                    let onDone: Function = function() {
                        if (self._mc == null) {
                            resolve();
                            return;
                        }
                        if (self._mc.parent != null) {
                            self._mc.parent.removeChild(self._mc);
                        }

                        self._mc.scaleX = parent.width / 125;
                        self._mc.scaleY = parent.height / 162;
                        self._mc.x = parent.width / 2;
                        self._mc.y = parent.height / 2;
                        self._mc.gotoAndStop(self._mc.totalFrames);
                        parent.addChild(this._mc);
                        resolve();
                    }

                    if (this._mc.totalFrames <= 1) {
                        this._mc.gotoAndPlay(1, 1);
                        onDone.apply(this, null);
                    } else {
                        this._mc.once(egret.MovieClipEvent.COMPLETE, onDone, this);
                        this._mc.gotoAndPlay(1, 1);
                    }

                } else {

                    this._mc.once(egret.MovieClipEvent.COMPLETE, ()=>{
                        if (this._mc == null) {
                            return;
                        }
                        this._mc.scaleX = 1;
                        this._mc.scaleY = 1;
                        Core.MCFactory.inst.revertMovieClip(this._mc);
                        this._mc = null;
                        resolve();
                    }, this);
                    this._mc.gotoAndPlay(1, 1);
                }

                if (visible) {
		            SoundMgr.inst.playSoundAsync(`${this._realMovieId}_mp3`);
                }
            }); 
            
            if (visible) {
                return p;
            } else {
                return null;
            }
        }

        public resize(parent:fairygui.GComponent): void {
            if (this._mc == null) {
                return;
            }
            this._mc.removeFromParent();
            parent.addChild(this._mc);
            this._mc.scaleX = 1;
            this._mc.scaleY = 1;
            if (this._mc.parent != null) {
                this._mc.x = this._mc.parent.width / 2;
                this._mc.y = this._mc.parent.height / 2;
            }
        }

        public stop() {
            this.isStop = true;
            if (this._mc == null) {
                return;
            }
            this._mc.stop();
            this._mc.scaleX = 1;
            this._mc.scaleY = 1;
            Core.MCFactory.inst.revertMovieClip(this._mc);
            this._mc = null;
        }

        public setVisible(val:boolean) {
            if (this._mc) {
                this._mc.visible = val;
            }
        }
    }

}
