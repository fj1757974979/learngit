module Battle {

    export interface IEffect {
        play(parent:fairygui.GComponent, isLoop:boolean, isLoopStop:boolean, visible:boolean): Promise<void>
        stop():void
        resize(parent:fairygui.GComponent): void
        setVisible(val:boolean):void
    }

    interface IEffectContainer {
        add(effectId:string | number, effect:IEffect)
        removeOne(effectId:string | number, effect:IEffect)
        getOne(effectId:string | number): IEffect
        forEach(func:Function)
        clear()
        getByID(effectId:string | number): Array<IEffect>;
        removeByID(effectId:string | number);
    }

    class TextEffectContainer extends Collection.Dictionary<number, IEffect> implements IEffectContainer {
        public add(effectId:string | number, effect:IEffect) {
            let efid = effectId as number;
            let e = this.getValue(efid);
            if (e) {
                e.stop();
            }
            this.setValue(efid, effect);
        }

        public removeOne(effectId:string | number, effect:IEffect) {
            let efid = effectId as number;
            this.remove(efid);
        }

        public getOne(effectId:string | number): IEffect {
            let efid = effectId as number;
            return this.getValue(efid);
        }

        public forEach(func:Function) {
            super.forEach((_, e:IEffect) => {
                func(e);
                return true;
            })
        }

        public getByID(effectId:string | number): Array<IEffect> {
            let e = this.getOne(effectId)
            if (e) {
                return [e];
            } else {
                return [];
            }
        }

        public removeByID(effectId:string | number) {
            this.removeOne(effectId, null);
        }
    }

    class McEffectContainer extends Collection.MultiDictionary<string, IEffect> implements IEffectContainer {
        public add(effectId:string | number, effect:IEffect) {
            this.setValue(<string>effectId, effect);
        }

        public removeOne(effectId:string | number, effect:IEffect) {
            this.remove(<string>effectId, effect);
        }

        public getOne(effectId:string | number): IEffect {
            let arr = this.getValue(<string>effectId);
            if (arr && arr.length > 0) {
                return arr[0];
            } else {
                return null;
            }
        }

        public forEach(func:Function) {
            super.keys().forEach(k => {
                let arr = super.getValue(k);
                if (arr) {
                    arr.forEach(e => {
                        func(e);
                    })
                }
            })
        }

        public getByID(effectId:string | number): Array<IEffect> {
            return this.getValue(<string>effectId);
        }

        public removeByID(effectId:string | number) {
            super.remove(<string>effectId);
        }
    }

    export class EffectPlayer {

        private playingMovieEffect: IEffectContainer;  // {effectId: [e1, e2, ...]}
        private playingTextEffect: IEffectContainer;
        private parent: fairygui.GComponent;
        public removeEffectFunc: (container:IEffectContainer, effectID:string|number)=>void;

        constructor(parent:fairygui.GComponent) {
            this.playingMovieEffect = new McEffectContainer();
            this.playingTextEffect = new TextEffectContainer();
            this.parent = parent;
            this.removeEffectFunc = EffectPlayer.defRemoveEffect;
        }

        public clearEffect() {
            this.playingMovieEffect.forEach(e => {
                e.stop();
            });
            this.playingMovieEffect.clear();
            this.playingTextEffect.forEach(e => {
                e.stop();
            })
            this.playingTextEffect.clear();
        }

        public static defRemoveEffect(container:IEffectContainer, effectID:string|number) {
            let e = container.getOne(effectID);
            if (e != null) {
                e.stop();
                container.removeOne(effectID, e);
            }
        }

        public static removeAllEffectByID(container:IEffectContainer, effectID:string|number) {
            let es = container.getByID(effectID);
            for (let e of es) {
                e.stop();
            }
            container.removeByID(effectID);
        }

        public playEffect(effectId:string | number, playType:number, visible:boolean=true, targetCount:number=0, 
            value:number=0): Promise<void> {

            let effect: IEffect = null;
            let playing: IEffectContainer;
            playing = this.playingMovieEffect;
            if (typeof effectId === "number") {
                playing = this.playingTextEffect;
            }

            if (playType != 0) {
                if (typeof effectId === "string") {
                    effect = new MCEffect(effectId);
                } else if (typeof effectId === "number") {
                    effect = new TextEffect(effectId, targetCount, value);
                } else {
                    return null;
                }
            }

            if (playType > 0) {
                return effect.play(this.parent, false, false, visible);
            }

            if (playType < 0) {
                let p:Promise<void>;
                if (playType == -1) {
                    effect.play(this.parent, true, false, visible);
                } else if (playType == -2) {
                    p = effect.play(this.parent, false, true, visible);
                }
                playing.add(effectId, effect);
                return p;
            }

            if (playType == 0) {
                if (effectId === "-1" || effectId == -1) {
                    playing.forEach(e => {
                        e.stop();
                    })
                    playing.clear();
                } else {
                    this.removeEffectFunc(playing, effectId)
                }
            }
                
            return null;
        }

        public switchParent(parent: fairygui.GComponent): void {
            this.parent = parent;
            this.playingMovieEffect.forEach(e => {
                e.resize(parent);
            })
            this.playingTextEffect.forEach(e => {
                e.resize(parent);
            })
        }

        public setVisible(val:boolean) {
            this.playingMovieEffect.forEach(e => {
                e.setVisible(val)
            })
        }

    }

}