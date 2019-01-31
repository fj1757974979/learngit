module Battle {

    export class RewardCardItem extends UI.BaseCardItem {
        private _oldCard: CardPool.Card;
        private _newCard: CardPool.Card;

        public setData(oldCard:CardPool.Card, newCard:CardPool.Card) {
            this._oldCard = oldCard;
            this._newCard = newCard;
            if (this._oldCard) {
                this.cardObj = this._oldCard;
            } else {
                this.cardObj = this._newCard;
            }
            this.setProgress();
            this._setSkin();
        }

        private _setSkin() {
            this._card.setOwnFront();
            this._card.setCardImg();
            this._card.setEquip();
            this._card.setName();
            this._card.setSkill();
            this._card.setNumText();
            this._card.setNumOffsetText();
            if (this.cardObj.state == CardPool.CardState.Dead) {
                this._card.setGrey();
            }
        }

        public async doAnimation() {
            if (!this._oldCard) {
                return;
            }
            let p1 = this._expProgressBar.doProgressAnimation(this._oldCard.amount, this._newCard.amount, this._newCard.maxAmount);
            let p2: Promise<void>;
            /*
            if (this._energyProgressBar.parent) {
                let energy = this._newCard.energy;
                if (this._newCard.level != this._oldCard.level) {
                    energy = 0;
                }
                p2 = this._energyProgressBar.doProgressAnimation(this._oldCard.energy, energy, this._oldCard.maxEnergy);
            }
            */
            await p1;
            if (p2) {
                await p2;
            }

            this.cardObj = this._newCard;
            this._setSkin();
        }
    }

    export class RewardResBar extends fairygui.GLabel {
        private _resList: fairygui.GList;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._resList = this.getChild("resList").asList;
        }

        public show(rewardRes:Array<any>) {
            this.visible = true;
            rewardRes.forEach(resData => {
                let resLabel = this._resList.addItem().asLabel;
                resLabel.icon = Utils.resType2Icon(resData.Type);
                resLabel.title = "x" + resData.Amount;
            });
            this._resList.resizeToFit();
        }

        public hide() {
            this.visible = false;
            this._resList.removeChildren();
        }
    }

    export class BaseBattleEnd extends Core.BaseView {
        protected _resultCtrl: fairygui.Controller;
        private _isClosing: boolean;
	// private _soundChannel:egret.SoundChannel;

        public constructor() {
            super(Core.LayerManager.inst.topLayer);
        }

        public initUI() {
            super.initUI();
            this._resultCtrl = this.getController("result");
            this.adjust(this.getChild("winBg"));
            this._resultCtrl.selectedPage = "lose";
            this.adjust(this.getChild("loseBg"));
            this._resultCtrl.selectedPage = "win";
            //this.addClickListener(this._onBack, this);
        }

        public async open(...param:any[]) {
            super.open(...param);
            this._isClosing = false;
            this.touchable = false;
            let isWin = param[0] as boolean;
            let isReplay = param[2] as boolean;
            await Core.PopUpUtils.addPopUp(this, 5);
            this.touchable = true;
            SoundMgr.inst.stopBgMusic();
            if (isWin) {
                SoundMgr.inst.playSoundAsync("win_mp3");
                // this._soundChannel = SoundMgr.inst.playSound("win_mp3");
            } else {
                SoundMgr.inst.playSoundAsync("lose_mp3");
                // this._soundChannel = SoundMgr.inst.playSound("lose_mp3");
            }
        }

        public async close(...param:any[]) {
            Core.MaskUtils.showTransMask();
            super.close(...param);
            this.displayObject.cacheAsBitmap = true;
            await Core.PopUpUtils.removePopUp(this, 6);
            this.displayObject.cacheAsBitmap = false;
            Core.MaskUtils.hideTransMask();
            Core.EventCenter.inst.dispatchEventWith(GameEvent.BattleEndEv);
	        // if (this._soundChannel) {
		    //     SoundMgr.inst.fadeoutSound(this._soundChannel);
		    //     this._soundChannel = null;
	        // }

	        SoundMgr.inst.playBgMusic("bg_mp3");
        }

        private async _onBack() {
            if (this._isClosing) {
                return;
            }            
            this._isClosing = true;
            await Core.ViewManager.inst.close(ViewName.battle);
            await Core.ViewManager.inst.closeView(this);
        }

        protected cardListDoAnimation(cardList:fairygui.GList, changeCards:Array<any>) {
            if (!changeCards) {
                return;
            }
            let isCardAddexp = false;
            for (let changeData of changeCards) {
                if (!changeData.Old) {
                    continue;
                }
                let newCardObj = new CardPool.Card(CardPool.CardPoolMgr.inst.getCardData(changeData.New.CardId, changeData.New.Level));
                newCardObj.init(changeData.New);
                let oldCardObj = new CardPool.Card(CardPool.CardPoolMgr.inst.getCardData(changeData.Old.CardId, changeData.Old.Level));
                oldCardObj.init(changeData.Old);
                let cardItem = cardList.addItem() as RewardCardItem;
                cardItem.setData(oldCardObj, newCardObj);
                if (newCardObj.level > oldCardObj.level || newCardObj.amount > oldCardObj.amount) {
                    isCardAddexp = true;
                }
                cardItem.displayObject.cacheAsBitmap = true;
            }

            cardList.resizeToFit();
            cardList.visible = true;
            cardList.alpha = 0;
            let self = this;
            egret.Tween.get(cardList).to({alpha:1}, 600).call(async function() {
                await fairygui.GTimers.inst.waitTime(700);
                if (!self.isShow()) {
                    return;
                }
                if (isCardAddexp) {
                    let sound: egret.Sound = RES.getRes("addexp_mp3");
                    if (sound) {
                        sound.play(0, 1);
                    }
                }
                for (let i=0; i<cardList.numItems; i++) {
                    let cardItem = cardList.getChildAt(i);
                    if (cardItem) {
                        cardItem.displayObject.cacheAsBitmap = false;
                        (<RewardCardItem>cardItem).doAnimation();
                    }
                }
            }, this);
        }

        protected renderResList(resList: fairygui.GList, rewardRes:Array<any>) {
            resList.removeChildren();
            resList.visible = true;
            rewardRes.sort((a, b):number => {
                if (Utils.resTypePriority(a.Type) < Utils.resTypePriority(b.Type)) {
                    return -1;
                } else {
                    return 1;
                }
            });
            rewardRes.forEach(resData => {
                let resLabel = resList.addItem().asLabel;
                resLabel.icon = Utils.resType2Icon(resData.Type);
                resLabel.title = "x" + resData.Amount;
            });
            resList.resizeToFit();
        }

        protected setRewardResBar(rewardRes: Array<any>, title:string=null) {
            let resBar = this.getChild("rewardResBar") as UI.RewardResBar;
            let resBg = this.getChild("rewardResBg");
            if (!rewardRes || rewardRes.length == 0) {
                resBar.visible = false;
                resBg.visible = false;
                return;
            }

            if (title) {
                resBar.getChild("title").asTextField.text = title;
            }

            resBg.visible = true;
            resBar.visible = true;
            resBar.setData(rewardRes);
        }
    }

}
