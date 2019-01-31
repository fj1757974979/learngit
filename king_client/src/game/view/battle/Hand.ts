module Battle {

    export abstract class Hand implements UI.IHandItemBuilder {
        protected _owner: Fighter;
        protected _handCardGrid: UI.HandCardGrid;
        protected _isShow: boolean;
        private _isFightBegin: boolean;

        constructor(handCardGrid:UI.HandCardGrid, owner:Fighter) {
            this._handCardGrid = handCardGrid;
            this._handCardGrid.disabled = true;
            this._owner = owner;
            owner.handView = this;
            this._handCardGrid.dataProvider = owner;
            this._isShow = false;
            this._isFightBegin = false;
        }

        public get isShow(): boolean {
            return this._isShow;
        }

        public get handCardGrid(): UI.HandCardGrid {
            return this._handCardGrid;
        }

        protected _forEachCard(callback:Function) {
            for (let i=0; i<5; i++) {
                let cardCom = this._handCardGrid.getItem(i);
                if (!cardCom) {
                    continue;
                }
                let fightCardCom = cardCom as FightCardView;
                callback.call(this, fightCardCom);
            }
        }

        public bringCardToFront(card:FightCardView) {
            if (card.parent) {
                card.parent.setChildIndex(card, card.parent.numChildren);
            }
        }

        public handDraggable(able:boolean) {
            this._forEachCard((fightCardCom:FightCardView) => {
                if (!(<FightCard>fightCardCom.cardObj).isShadow) {
                    fightCardCom.draggable = able;
                }
            })
        }

        public handTouchable(able:boolean) {
            this._forEachCard((fightCardCom:FightCardView) => {
                fightCardCom.touchable = able;
            })
        }

        public handVisibleLightCircle(able:boolean) {
            this._forEachCard((fightCardCom:FightCardView) => {
                fightCardCom.visibleLightCircle(able);
            })
        }

        public buildHandItem(idx:number, cardObj: UI.ICardObj): UI.IHandItem {
            if (!cardObj) {
                return null;
            }
            let fightCardObj = cardObj as FightCard;
            let cardCom = fairygui.UIPackage.createObject(PkgName.cards, "smallCard", FightCardView) as FightCardView;
            cardCom.cardObj = fightCardObj;
            fightCardObj.view = cardCom;
            this.updateCardSkin(cardCom);
            cardCom.hand = this;
            return cardCom;
        }

        public updateCardSkin(cardCom:FightCardView) {
            let cardObj = <FightCard>cardCom.cardObj;
            if (this._isShow) {
                cardCom.setFrontSkin();
            } else {
                cardCom.hideFront();
                cardCom.showEquipBtn(false);
                if (cardObj.owner == this._owner) {
                    cardCom.setBackImg();
                } else {
                    cardCom.setOwnBackImg();
                }
            }

            if (BattleMgr.inst.battle) {
                if (BattleMgr.inst.battle.getOwnFighter() == this._owner) {
                    cardCom.getChild("lightCircle").asLoader.url = "cards_cardLightSelf_png";
                } else {
                    cardCom.getChild("lightCircle").asLoader.url = "cards_cardLightEnemy_png";
                }
            }

            if ((<FightCard>cardCom.cardObj).isShadow) {
                cardCom.alpha = 0.3;
            } else {
                cardCom.alpha = 1;
            }
            cardCom.touchable = this._isShow;
        }

        public show() {
            this._isShow = true;
        }

        public refresh(force:boolean=false) {
            this._handCardGrid.refresh(force);
        }

        public clear() {
            this._owner = null;
            this._handCardGrid.clear();
        }

        public async boutBegin(curFighter: Fighter) {
            let isMyBout = curFighter.uid == this._owner.uid;
            this.handVisibleLightCircle(isMyBout);
            if (!this._isFightBegin) {
                this._isFightBegin = true;
                this._handCardGrid.disabled = true;
            }

            /*
            if (isMyBout && this._owner.getHandCardAmount() <= 0) {
                // 我的回合，没手牌
                let ps: Array<Promise<void>> = [];
                for (let i=0; i<5; i++) {
                    let handGrid = this._handCardGrid.getGrid(i);
                    if (!handGrid) {
                        continue;
                    }
                    ps.push( Core.EffectUtil.blink(handGrid) );
                }

                await Promise.all(ps);
            }
            */
        }

        public getGridByIndex(index:number): fairygui.GComponent {
            return this._handCardGrid.getGrid(index);
        }

        public getGuideClickNode(): fairygui.GObject {
            let node = new fairygui.GGraph();
            for (let i=0; i<this._handCardGrid.itemNum; i++) {
                if (this._handCardGrid.getItem(i)) {
                    continue;
                }
                let gird = this._handCardGrid.getGrid(i);
                node.graphics.clear();
                node.graphics.beginFill(Core.TextColors.white, 0);
                node.graphics.drawRect(0, 0, this._handCardGrid.width - gird.x, this._handCardGrid.height);
                node.graphics.endFill();
                node.x = gird.x;
                node.y = gird.y;
                node.width = this._handCardGrid.width - gird.x;
                node.height = this._handCardGrid.height;
                this._handCardGrid.addChildAt(node, 0);

                node.once(egret.TouchEvent.TOUCH_TAP, ()=>{
                    this._handCardGrid.removeChild(node);
                    gird.dispatchEventWith(egret.TouchEvent.TOUCH_TAP);
                }, this);

                return node;
            }
            return null;
        }
    }

    export class MyHand extends Hand {
        private _canDragCard: boolean
        
        constructor(handCardGrid:UI.HandCardGrid, battle:Battle, owner:Fighter) {
            super(handCardGrid, owner);
            this._isShow = true;
            this._handCardGrid.itemBuilder = this;
            this._canDragCard = true;

            if (battle instanceof LevelBattle && !(<LevelBattle>battle).isBeginFight) {
                if ((<LevelBattle>battle).getMaxAmount() > 0) {
                    this._handCardGrid.choiceCardCtrl = <LevelBattle>battle;
                    (<BattleView>Core.ViewManager.inst.getView(ViewName.battle)).visibleBeginBtn(true,false);
                } else {
                    (<BattleView>Core.ViewManager.inst.getView(ViewName.battle)).visibleBeginBtn(true,false);
                }
            } else if (battle.battleType == BattleType.VIDEO) {
                this._canDragCard = false;
            }
            this._handCardGrid.refresh();
        }

        public async boutBegin(curFighter: Fighter) {
            await super.boutBegin(curFighter);
            this.handDraggable(this._canDragCard);
        }
    }

    export class EnemyHand extends Hand {
        
        constructor(handCardGrid:UI.HandCardGrid, battle:Battle, owner:Fighter) {
            super(handCardGrid, owner);
            this._handCardGrid.itemBuilder = this;
            if (battle.isEnemyHandOpen()) {
                super.show();
            }
            this._handCardGrid.refresh();
        }

        public show() {
            super.show();
            this._forEachCard((fightCardCom:FightCardView) => {
                //fightCardCom.setOppFront();
                //fightCardCom.setOppBackground();
                //fightCardCom.setCardImg();
                //fightCardCom.setName();
                //fightCardCom.setNumText();
                //fightCardCom.setSkill();
                //fightCardCom.touchable = true;
                //fightCardCom.getChild("lightCircle").asLoader.url = "cards_cardLightEnemy_png";
                fightCardCom.setFrontSkin();
            });
        }
    }

}
