module UI {

    export class ChoiceCardItem extends BaseCardItem {
        private _needEnergyProgress:boolean;
        private _needExpProgress:boolean;
        private _refreshExecutor: Core.FrameExecutor;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this.getChild("levelUpHint").asLoader.visible = false;
            this.getChild("levelUpHint2").asLoader.visible = false;
            this.getChild("newHint").asLoader.visible = false;
            //this._stateCtrl.addEventListener(fairygui.StateChangeEvent.CHANGED, this._refreshState, this);
        }

        public setData(cardObj:ICardObj, needEnergyProgress:boolean, needExpProgress:boolean) {
            this.cardObj = cardObj;
            this._needEnergyProgress = needEnergyProgress;
            this._needExpProgress = needExpProgress;
            this._refreshState();
        }

        public get selected(): boolean {
            return this._selected;
        }

        public set selected(value:boolean) {
            this.displayObject.cacheAsBitmap = false;
            this.setSelected(value);
            this.displayObject.cacheAsBitmap = true;
        }

        public watch() {
            //this.watchLevel();
            if (this._refreshExecutor) {
                this._refreshExecutor.execute();
                this._refreshExecutor = null;
            }
            this._card.watchProp(CardPool.Card.PropLevel, this._onPropLevelChange, this);
            this.watchAmount();
            if (this._needEnergyProgress) {
                this.watchEnergy();
            }
            this._card.watchProp(CardPool.Card.PropState, this._refreshState, this);
            this._card.watchSkin();
            this._card.watchEquip();
        }

        protected _onPropAmountChange() {
            this.displayObject.cacheAsBitmap = false;
            super._onPropAmountChange();
            this.displayObject.cacheAsBitmap = true;
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
            this._card.setNumText();
            this._card.setNumOffsetText();
            this.displayObject.cacheAsBitmap = true;
        }

        public unwatch() {
            this.unwatchLevel();
            this.unwatchAmount();
            if (this._needEnergyProgress) {
                this.unwatchEnergy();
            }
            this._card.unwatchProp(CardPool.Card.PropState);
            this._card.unwatchSkin();
            this._card.unwatchEquip();
        }

        private _frameSetNormalSkin() {
            this.displayObject.cacheAsBitmap = false;
            this._card.setCardImg();
            this._card.setEquip();
            this.visibleEnergyProgress(this._needEnergyProgress);
            //this._energyProgressBar.visible = true;
            // this._expProgressBar.visible = true;
            this.setProgress();
        }

        private _frameSetStateSkin() {
            this.displayObject.cacheAsBitmap = false;
            if (this._cardObj.state == CardPool.CardState.Dead) {
                this._card.setGrey();
            } else if (this.state == BaseCardItem.NormalState) {
                this._card.setWhile();
            } else {
                this._card.setBlack();
            }
            this.displayObject.cacheAsBitmap = true;
        }

        private _frameSetNameAndSkill() {
            this.displayObject.cacheAsBitmap = false;
            this._card.setName();
            this._card.setSkill();
        }

        private _frameSetNumText() {
            this.displayObject.cacheAsBitmap = false;
            this._card.setNumText();
        }

        private _frameSetNumOffsetText() {
            this.displayObject.cacheAsBitmap = false;
            this._card.setNumOffsetText();
        }

        private _frameRefreshState() {
            this._refreshExecutor = new Core.FrameExecutor();
            this._refreshExecutor.regist(this._frameSetNormalSkin, this);
            this._refreshExecutor.regist(this._frameSetNameAndSkill, this);
            this._refreshExecutor.regist(this._frameSetNumText, this);
            this._refreshExecutor.regist(this._frameSetNumOffsetText, this);
            this._refreshExecutor.regist(this._frameSetStateSkin, this);
            this._refreshExecutor.execute();
        }

        private _refreshState() {
            this.displayObject.cacheAsBitmap = false;
            this._card.setNumText();
            this._card.setNumOffsetText();
            this._card.setCardImg();
            this._card.setEquip();
            this._card.setName();
            this._card.setSkill();
            this._card.setOwnFront();
            this._card.setDeskBackground();

            this.visibleEnergyProgress(this._needEnergyProgress);
            this.visibleExpProgress(this._needExpProgress);
            //this._energyProgressBar.visible = true;
            this._expProgressBar.visible = true;
            this.setProgress();

            if (this._cardObj.state == CardPool.CardState.Dead) {
                this._card.setGrey();
            } else if (this.state == BaseCardItem.NormalState) {
                this._card.setWhile();
            } else {
                this._card.setBlack();
            }
            this.displayObject.cacheAsBitmap = true;
        }
    }

}