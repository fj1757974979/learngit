module CardPool {

    export class CardItem extends UI.BaseCardItem {

        private _levelUpHint: fairygui.GLoader;
        private _levelUpHint2: fairygui.GLoader;
        private _levelUpTrans: fairygui.Transition;

        private _newHint: fairygui.GLoader;
        private _needObserveLevelup: boolean;
        private _needObserveNew: boolean;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._levelUpHint = this.getChild("levelUpHint").asLoader;
            this._levelUpHint2 = this.getChild("levelUpHint2").asLoader;
            this._levelUpTrans = this.getTransition("t0");

            this._newHint = this.getChild("newHint").asLoader;

            this._newHint.visible = false;
            this._levelUpHint.visible = false;
            this._levelUpHint2.visible = false;
            this._needObserveLevelup = false;
            this._needObserveNew = false;
        }

        public watchIsNew() {
            this._needObserveNew = true;
            this._card.watchProp(Card.PropIsNew, () => {
                this._refresh();
            }, this);
            this._updateNewHint();
        }

        private _updateNewHint() {
            this._newHint.visible = (this._needObserveNew && this.cardObj.isNew);
        }

	    public update() {
	        this._refresh();
	    }

        private _refresh() {
            this.displayObject.cacheAsBitmap = false;
            this._campignUnlockText.visible = false;
            this._card.setWhile();

            this._card.setName();
            if (this._cardObj.state == CardState.Lock) {
                this._card.showEquipBtn(false);
                this._card.setNumText(false);
                this._card.setNumOffsetText(false);
                let cardId = this._cardObj.cardId;
                let level = Pvp.PvpMgr.inst.getPvpLevel();
                level = Math.max(level, 2);
                let unlockLevel = Pvp.Config.inst.getCardUnlockLevel(cardId);
                if (unlockLevel && unlockLevel <= level) {
                    this._cardObj.state = CardState.Unlock;
                    this._initUnlockSkin();
                    this._card.setQualityMode(true);
                } else if (Level.LevelMgr.inst.getCardIdUnlockLevelId(cardId) > 0) {
                    let levelId = Level.LevelMgr.inst.getCardIdUnlockLevelId(cardId);
                    let curLevelId = Level.LevelMgr.inst.curLevel;
                    if (levelId < curLevelId) {
                        this._cardObj.state = CardState.Unlock;
                        this._initUnlockSkin();
                        this._card.setQualityMode(true);
                        Core.EventCenter.inst.removeEventListener(GameEvent.ClearLevelEv, this._onCampignLevelChange, this);
                    } else {
                        this._initLockSkin();
                        this._campignUnlockText.visible = true;
                        let chapter = Level.LevelMgr.inst.getLevel(levelId).chapter;
                        this._campignUnlockText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60161), Core.StringUtils.getZhNumber(chapter));
                        Core.EventCenter.inst.addEventListener(GameEvent.ClearLevelEv, this._onCampignLevelChange, this);
                    }
                } else {
                    this._initLockSkin();
                }
            } else {
                this._card.setNumText();
                this._card.setNumOffsetText();
                if (this._cardObj.state == CardState.Alive) {
                    this._initAliveSkin();
                } else if (this._cardObj.state == CardState.Dead) {
                    this._initDeadSkin();
                } else if (this._cardObj.state == CardState.Unlock) {
		            this._initUnlockSkin();
		        }
                this._card.setQualityMode(true);
	        }
            // console.log(this.cardObj.collectCard.cardId, this.cardObj.collectCard.level, this.cardObj.collectCard.amount);
            if (this._card.cardObj.rare == CardQuality.LIMITED) {
                this.visibleExpProgress(false);
            } else if (this.cardObj.collectCard.level > 1 || this._card.cardObj.amount > 0) {
                this.visibleExpProgress(true);
            } else {
                this.visibleExpProgress(false);
            }

            this._checkLevelUpHint();
            this._updateNewHint();
            super._onPropAmountChange();
            
            this.displayObject.cacheAsBitmap = true;
        }

        public setData(card: Card, needObserverLevelUp: boolean = false) {
            this.cardObj = card;
            this._needObserveLevelup = needObserverLevelUp;
            this._refresh();
            this._card.setDeskBackground();

            this._clearWatchers();
            this.watchLevel();
            this.watchSkin();
            this.watchEquip();
            this.watchAmount();
            this.watchEnergy();
            this._card.watchProp(Card.PropState, this._onPropStateChange, this);
            Core.EventCenter.inst.addEventListener(Core.Event.CloseViewEvt, this._onViewClose, this);
        }

        private _clearWatchers() {
            this.unwatchLevel();
            this.unwatchSkin();
            this.unwatchEquip();
            this.unwatchAmount();
            this.unwatchEnergy();
            this._card.unwatchProp(Card.PropState);
        }

        private _onViewClose(evt:egret.Event) {
            let viewName = evt.data as string;
            if (viewName == ViewName.cardpool) {
                this._clearWatchers();
                Core.EventCenter.inst.removeEventListener(Core.Event.CloseViewEvt, this._onViewClose, this);
            }
        }

        protected _onPropAmountChange() {
            this.displayObject.cacheAsBitmap = false;
            super._onPropAmountChange();
            this._checkLevelUpHint();
            this.displayObject.cacheAsBitmap = true;
        }

        protected _checkLevelUpHint() {
            if (!this._needObserveLevelup) {
                return;
            }
            if (this._cardObj.rare == CardQuality.LIMITED) {
                this._levelUpHint.visible = false;
                this._levelUpHint2.visible = false;
                return;
            }
            if (this._cardObj.amount >= this._cardObj.maxAmount && this._cardObj.maxAmount > 0) {
                this.addChild(this._levelUpHint2);
                this.addChild(this._levelUpHint);
                this.addChild(this._progressText);
                this._levelUpHint.visible = true;
                this._levelUpHint2.visible = true;
                this._levelUpTrans.play(null, null, null, -1);
            } else {
                this._levelUpHint.visible = false;
                this._levelUpHint2.visible = false;
                if (this._levelUpTrans.playing) {
                    this._levelUpTrans.stop();
                }
            }
        }

        protected _onPropEnergyChange() {
            this.displayObject.cacheAsBitmap = false;
            super._onPropEnergyChange();
            this.displayObject.cacheAsBitmap = true;
        }

        private _onPropLevelChange() {
            this.displayObject.cacheAsBitmap = false;
            this._card.setName();
            this._card.setSkill();
            this.displayObject.cacheAsBitmap = true;
        }

        private _onPropStateChange() {
            this._refresh();
        }

        private _initLockSkin() {
            this.touchable = false;
            this._expProgressBar.visible = false;
            this._progressText.visible = false;
            //this._energyProgressBar.visible = false;
            //this._card.setDeskFront();
            //this._card.setBackImg();
            this._card.setOwnLockFront();
            this._card.setLockNameAndSkill(true);
            this._card.setLockCardImg();
        }

        private _initAliveSkin() {
            this._card.setCardImg();
            this._card.setEquip();
            this._card.setOwnFront();
            this._card.setSkill();
            this.touchable = true;
            this._expProgressBar.visible = true;
            this._progressText.visible = true;
            //this._energyProgressBar.visible = true;
            //this._expProgressBar.setProgress(this._cardObj.amount, this._cardObj.maxAmount);
            this.setProgress();
            //this._energyProgressBar.setProgress(this._cardObj.energy, this._cardObj.maxEnergy);
        }

        private _initDeadSkin() {
            this._expProgressBar.visible = false;
            this._progressText.visible = false
            //this._energyProgressBar.visible = false;
            this._card.setCardImg();
            this._card.setEquip();
            this._card.setGrey();
            this._card.setSkill();
        }

	    private _initUnlockSkin() {
	        this.touchable = true;
	        this._expProgressBar.visible = false;
            this._progressText.visible = false
	        this._card.setCardImg();
            this._card.setEquip();
            this._card.setGrey();
	        this._card.setName();
	    }

        private _onCampignLevelChange() {
            this._refresh();
        }

        public setRankRewardMode() {
            this._expProgressBar.visible = false;
            this._progressText.visible = false;
        }
        public setRankSeasonMode() {
            this._card.setQualityMode(false);
            this._card.setLockNameAndSkill(false);
            this._card.setName();
            this._card.setNumText(true);
            this._card.setNumOffsetText();
            this._card.setSkill();
            this._card.setOwnBackground();
            this._card.setOwnFront();
            this._onPropAmountChange();
        }
    }

}
