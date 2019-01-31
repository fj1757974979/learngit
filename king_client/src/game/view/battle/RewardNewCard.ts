module Battle {

    export class RewardNewCard extends Core.BaseView {
        private _card: UI.CardCom;
        private _levelText: fairygui.GTextField;
        private _skillDescTxt: fairygui.GTextField;
        private _bgMask: fairygui.GGraph;
        private _preLevelBtn: fairygui.GButton;
        private _nextLevelBtn: fairygui.GButton;

        private _newCardLight: fairygui.GLoader;
        private _text1: fairygui.GTextField;
        private _img1: fairygui.GLoader;
        private _img2: fairygui.GLoader;
        private _tips: fairygui.GTextField;

        private _curCardViewLevel: number;
        private _descGroup: Array<fairygui.GObject>;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._card = this.getChild("card") as UI.CardCom;
            this._levelText = this.getChild("levelText").asTextField;
            this._skillDescTxt = this.getChild("skillDescTxt").asTextField;
            this._bgMask = this.getChild("bgMask").asGraph;
            this._preLevelBtn = this.getChild("preLevelBtn").asButton;
            this._nextLevelBtn = this.getChild("nextLevelBtn").asButton;
            this._newCardLight = this.getChild("newCardLight").asLoader;
            this._text1 = this.getChild("text1").asTextField;
            this._img1 = this.getChild("img1").asLoader;
            this._img2 = this.getChild("img2").asLoader;
            this._tips = this.getChild("tips").asTextField;
            this._tips.textParser = Core.StringUtils.parseColorText;
            this._tips.text = this._tips.text;

            this._descGroup = [this._levelText, this._skillDescTxt, this._bgMask, this._preLevelBtn, this._nextLevelBtn,
                this._newCardLight, this._text1, this._img1, this._img2, this._tips];
            this._visibleDescChild(false);

            this._preLevelBtn.addClickListener(this._onPreLevel, this);
            this._nextLevelBtn.addClickListener(this._onNextLevel, this);

            Core.LayerManager.inst.topLayer.addChild(this);
        }

        public setUplevelCtrl() {
            this.getController("type").selectedPage = "uplevel";
            this.adjust(this.getChild("bg"), Core.AdjustType.NO_BORDER);
        }

        private _visibleDescChild(visible:boolean) {
            this._descGroup.forEach(display => {
                display.visible = visible;
            })

            if (visible) {
                this._descGroup.forEach(display => {
                    display.alpha = 0;
                    egret.Tween.removeTweens(display);
                })
                let self = this;
                fairygui.GTimers.inst.add(33, 15, ()=>{
                    self._descGroup.forEach(display => {
                        if (display.alpha >= 1) {
                            return;
                        }
                        display.alpha += 1 / 15;
                    })
                }, this);
            }
        }

        private _isDescChildVisible(): boolean {
            for (let c of this._descGroup) {
                if (!c.visible) {
                    return false;
                }
            }
            return true;
        }

        private _onPreLevel() {
            this._changeCurLevel(this._curCardViewLevel - 1);
        }

        private _updateLevelText(cardObj: CardPool.Card) {
            this._levelText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60069), Core.StringUtils.getZhNumber(cardObj.level));
            this._skillDescTxt.text = cardObj.skillDesc;
            this._curCardViewLevel = cardObj.level;
        }

        private _updateCardInfo(cardObj: CardPool.Card) {
            this._card.cardObj = cardObj;
            this._card.setCardImg();
            this._card.setEquip();
            this._card.setName();
            this._card.setSkill();
            this._card.setNumText();
            this._card.setNumOffsetText();
        }

        private _changeCurLevel(level:number) {
            let cardObj = (<CardPool.Card>this._card.cardObj).getLevelObj(level);
            if (!cardObj) {
                return;
            }
            this._updateCardInfo(cardObj);
            this._updateLevelText(cardObj);
        }

        private _onNextLevel() {
            this._changeCurLevel(this._curCardViewLevel + 1);
        }

        public async show(cardObj:CardPool.Card) {
	    let soundRes:string = this.getController("type").selectedPage == "uplevel"? "uplevel_mp3" : "newcard_mp3";
	    SoundMgr.inst.playSoundAsync(soundRes);

            egret.Tween.removeTweens(this._card);
            this._updateCardInfo(cardObj);
            this._updateLevelText(cardObj);
            if (!this._isDescChildVisible()) {
                this._visibleDescChild(true);
            }
            await new Promise<void>(resolve => {
                //this._card.alpha = 0;
                this._card.scaleX = 0;
                this._card.scaleY = 0;
                
                let self = this;
                let _onClose = function() {
                    //self.removeFromParent();
                    self._bgMask.removeClickListener(_onClose, self);
                    fairygui.GTimers.inst.callDelay(200, ()=>{
                        resolve();
                    }, this);
                }

                this._bgMask.addClickListener(_onClose, this);

                egret.Tween.get(this._card).to({scaleX:1,scaleY:1},1500,
                    egret.Ease.elasticOut)
            });
        }

        public hide() {
            this.removeFromParent();
        }
    }

}
