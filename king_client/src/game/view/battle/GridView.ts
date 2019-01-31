module Battle {

    export class GridView extends fairygui.GComponent {
        private _selectedImg: fairygui.GLoader;
        private _inGridCard: FightCardView;
        private _gridId:number;

        private _effectPlayer: EffectPlayer;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._selectedImg = this.getChild("selectedImg").asLoader;
            this._effectPlayer = new EffectPlayer(this);
            this._effectPlayer.removeEffectFunc = EffectPlayer.removeAllEffectByID;
            this.selected = false;
        }

        public get gridId(): number {
            return this._gridId;
        }
        public set gridId(val:number) {
            this._gridId = val;
        }

        public get selected(): boolean {
            return this._selectedImg.visible;
        }
        public set selected(val:boolean) {
            this._selectedImg.visible = val;
        }

        public get inGridCard(): FightCardView {
            return this._inGridCard;
        }
        public set inGridCard(card:FightCardView) {
            this._inGridCard = card;
        }

        public isInGrid(x:number, y:number, w:number, h:number): boolean {
            let gx = this.x - 30;
            let gy = this.y - 40;
            let gw = this.width + 60;
            let gh = this.height + 80;
			return gx <= x && gy <= y && (x - gx) <= (gw - w) && 
				(y - gy) <= (gh - h);
		}

        public playEffect(effectId:string | number, playType:number, visible:boolean=true, 
            targetCount?:number, value?:number): Promise<void> {
            return this._effectPlayer.playEffect(effectId, playType, true, targetCount, value);
        }

        public async setup(gridObj:GridObj) {
            gridObj.view = this;
            if (gridObj.inGridCard) {
                let [cardView, p] = this.addCard(gridObj.inGridCard, 0);
                if (p) {
                    await p;
                }
                (<FightCard>cardView.cardObj).gridObj = gridObj;
            }

            if (gridObj.initEffects) {
                gridObj.initEffects.forEach(effect => {
                    let textEffectID = parseInt(effect.MovieID);
                    if (isNaN(textEffectID)) {
                        // mc effect
                        this.playEffect(effect.MovieID, effect.PlayType);
                    } else {
                        // text effect
                        this.playEffect(textEffectID, effect.PlayType);
                    }
                })
            }
        }

        public addCard(cardObj:FightCard, transType:number=1): [FightCardView, Promise<void>] {
            let middleCard = fairygui.UIPackage.createObject(PkgName.cards, "middleCard", FightCardView) as FightCardView;
            middleCard.cardObj = cardObj;
            cardObj.view = middleCard;
            middleCard.setFrontSkin();
            middleCard.setPivot(0.5, 0.5, true);
            middleCard.x = this.width / 2;
            middleCard.y = this.height / 2;
            middleCard.touchable = true;
            middleCard.selectGrid = this;
            this.selected = false;
            this.addChild(middleCard);
            this.inGridCard = middleCard;
            let trans: fairygui.Transition;
            if (transType==1) {
                trans = middleCard.getTransition("add");
            } else if (transType == 2) {
                trans = middleCard.getTransition("readd")
            }

            let p: Promise<void>;
            if (trans && !trans.playing) {
                let self = this;
                p = new Promise<void>(resolve => {
                    trans.play(()=>{
                        self = null;
                        resolve();
                    }, self);
                });
            }
            
            return [middleCard, p];
        }

        public cardMoveIn(cardView:FightCardView): Promise<void> {
            return new Promise<void>(resolve => {
                cardView.selectGrid.inGridCard = null;
                let targetPoint:any = cardView.parent.rootToLocal(this.x, this.y);
                if (cardView.parent.parent == this.parent) {
                    targetPoint = { x: this.x -cardView.parent.x , y: this.y - cardView.parent.y};
                }
                SoundMgr.inst.playSoundAsync("newcard_mp3");
                egret.Tween.get(cardView).to({x:targetPoint.x + this.width / 2, y:targetPoint.y + this.height / 2}, 200).call(() => {
                    cardView.selectGrid = this;
                    this._inGridCard = cardView;
                    cardView.removeFromParent();
                    cardView.x = this.width / 2;
                    cardView.y = this.height / 2;
                    this.addChild(cardView);
                    resolve();
                }, this);
            });
        }

        public clear() {
            if (this._inGridCard) {
                if (this._inGridCard.parent) {
                    this._inGridCard.parent.removeChild(this._inGridCard, true);
                }
                this._inGridCard = null;
            }
            for (let i = 0; i < this.numChildren; ) {
                let child = this.getChildAt(i);
                if (child instanceof FightCardView) {
                    this.removeChildAt(i, true);
                } else {
                    i++;
                }
            }
            this.selected = false;
            this._effectPlayer.clearEffect();
        }

        public inGridCardToBeCopy(cardView:FightCardView) {
            this._inGridCard = cardView;
        }
    }

}