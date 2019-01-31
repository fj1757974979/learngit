module CardPool {

    export class MyCardInfoWnd extends CardInfoWnd {

        private _expProgressBar: UI.MaskProgressBar;
        private _goldLabel: fairygui.GLabel;

        private _equipBtn: fairygui.GButton;
        private _upBtn: fairygui.GButton;
        private _skinBtn: fairygui.GButton;
        private _uplevelBtn: fairygui.GButton;

        public initUI() {
            super.initUI();

            this._goldLabel = this.contentPane.getChild("goldLabel").asLabel;
            this._goldLabel.textParser = Core.StringUtils.parseColorText;
            this._expProgressBar = this.contentPane.getChild("expProgressBar").asCom as UI.MaskProgressBar;

            this._skinBtn = this.contentPane.getChild("skinBtn").asButton;
            this._skinBtn.visible = Home.FunctionMgr.inst.isSkinOpen();
            this._upBtn = this.contentPane.getChild("upBtn").asButton;
            this._upBtn.visible = Home.FunctionMgr.inst.isCardUpJadeOpen();
            this._equipBtn = this.contentPane.getChild("equipBtn").asButton;
            this._equipBtn.visible = Home.FunctionMgr.inst.isEquipOpen();
            this._uplevelBtn = this.contentPane.getChild("uplevelBtn").asButton;
            
            this._card.addClickListener(this._onCard, this);
            this._equipBtn.addClickListener(this._onEquipBtn, this);
            this._upBtn.addClickListener(this._onUPbtn, this);
            this._uplevelBtn.addClickListener(this._onUplevel, this);
            this._skinBtn.addClickListener(() => {
                Core.ViewManager.inst.open(ViewName.skinView, this._cardObj);
            }, this);
        }
        private _onUPbtn () {
            Core.ViewManager.inst.open(ViewName.cardUpWnd, this._cardObj);
        }
        private _onEquipBtn() {
            Equip.EquipMgr.inst.openEquipSwitchWnd(this._card.cardObj);
        }
        private _onCard() {
            if (this._skinBtn && Home.FunctionMgr.inst.isSkinOpen()) {
                Core.ViewManager.inst.open(ViewName.skinView, this._cardObj);
            } else {
                Core.ViewManager.inst.open(ViewName.bigCard, this._cardObj);
            }
            let sound:string = this._cardObj.sound;
            if (sound && sound.length > 0)
                SoundMgr.inst.playSoundAsync(`${sound}_mp3`);
        }
        private _onUplevel() {
            if (Player.inst.isNewVersionPlayer()) {
                if (this._cardObj.level == 4) {
                    Core.TipsUtils.showTipsFromCenter("暂未开放，敬请期待");
                    return;
                }
            }
            //this.playUplevelEffect();
            if (this._cardObj.amount <= 0 && this._cardObj.level <= 1) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60125));
                return;
            } else if (this._cardObj.amount < this._cardObj.maxAmount) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60170));
                return;
            } else if (this._cardObj.amount >= this._cardObj.maxAmount && !this._checkLevelUphRes()) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60207));
                return;
            } else if (!this._cardObj.getLevelObj(this._cardObj.level + 1)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60184));
                return;
            }
            CardPoolMgr.inst.upLevelCard(this._cardObj.cardId, false);
        }
        private _checkLevelUphRes() {
            let cardObj = this._cardObj as CardPool.Card;
            if (Player.inst.getResource(ResType.T_GOLD) < cardObj.data.levelupGold) {
                return false;
            } else if (Player.inst.getResource(ResType.T_HORSE) < cardObj.data.levelupHor) {
                return false;
            } else if (Player.inst.getResource(ResType.T_WEAP) < cardObj.data.levelupWeap) {
                return false;
            } else if (Player.inst.getResource(ResType.T_MAT) < cardObj.data.levelupMat) {
                return false;
            } else {
                return true;
            }
        }
        public prev() {
            //console.log(`prev ${this._cardIndex}`);
            if (this._isViewMode) return;
            if (!this._expProgressBar) return;
            if (!this._cardIndex == null) return;
            let view = Core.ViewManager.inst.getView(ViewName.cardpool) as CardPoolView;
            if (view) view.openPrevInfo(this._cardIndex);
        }

        public next() {
            //console.log("next");
            if (this._isViewMode) return;
            if (!this._expProgressBar) return;
            if (!this._cardIndex == null) return;
            let view = Core.ViewManager.inst.getView(ViewName.cardpool) as CardPoolView;
            if (view) view.openNextInfo(this._cardIndex);
        }
        private _updateEquipBtn() {
            if (!Home.FunctionMgr.inst.isEquipOpen()) {
                return;
            }
            if (this._cardObj.equip == "" || this._cardObj.equip == undefined) {
                this._equipBtn.icon = "";
                this._equipBtn.getChild("icon").asLoader.url = "equip_equipWndEmpty_png";
                this._equipBtn.visible = true;
            } else {
                let equipData = Equip.EquipMgr.inst.getEquipData(this._cardObj.equip);
                this._equipBtn.icon = equipData.equipIconSmall;
                this._equipBtn.visible = true;
                this._equipBtn.touchable = true;
            }
        }
        private _updateUpBtn() {
            if (!Home.FunctionMgr.inst.isCardUpJadeOpen()) {
                return;
            }
            if (this._cardObj.getToLevelAmount(3)[0] > 0 && Pvp.PvpMgr.inst.getPvpLevel() >= 11) {
                this._upBtn.visible = true;
            } else {
                this._upBtn.visible = false;
            }
        }
        private _updateResLabel() {
            let needGold = this._cardObj.data.levelupGold;
            this._goldLabel.visible = needGold > 0;
            this.contentPane.getChild("txtCost").visible = needGold > 0;
            let type = ResType.T_GOLD;
            let need = needGold;

            if (need > 0) {
                let label = this._goldLabel;
                let has = Player.inst.getResource(type);
                if (has < need) {
                    label.title = `#c96160c${has}#n/${need}`;
                } else {
                    label.title = `#c19af27${has}#n/${need}`;
                }
            }
        }
        private _updateAmountProgress() {
            this._expProgressBar.setProgress(this._cardObj.amount, this._cardObj.maxAmount);
            let head = this._expProgressBar.getChild("head");
            let percent = Math.min(1, this._cardObj.amount / this._cardObj.maxAmount);
            head.x = this._expProgressBar.width * percent - 25;

            //console.log(this._cardObj.level);
            this._expProgressBar.getChild("text").asTextField.text = this._cardObj.amount + "/" + this._cardObj.maxAmount;

            if (this._cardObj.amount < this._cardObj.maxAmount || !this._cardObj.getLevelObj(this._cardObj.level + 1)) {
                this._uplevelBtn.grayed = true;
                this._uplevelBtn.getTransition("heartbeat").stop();
            } else {
                this._uplevelBtn.grayed = false;
                this._uplevelBtn.getTransition("heartbeat").play(null, null, null, -1);
            }
            if (this._cardObj.level == 5) {
                this._uplevelBtn.visible = false;
                this.contentPane.getChild("imgMaxLevel").visible = true && !this._isViewMode;
                this._expProgressBar.getChild("text").asTextField.text = this._cardObj.amount + "/" + Core.StringUtils.TEXT(60030);
            } else {
                this._uplevelBtn.visible = true && !this._isViewMode;
                this.contentPane.getChild("imgMaxLevel").visible = false;

                if (Player.inst.isNewVersionPlayer()) {
                    if (this._cardObj.level == 4) {
                        this._uplevelBtn.grayed = true;
                    } else {
                        this._uplevelBtn.grayed = false;
                    }
                }
            }
        }
        private _onSkinChange() {
            // this._card.setCardImg();
            this._refreshCard();

            if (this._skinBtn) {
                this.contentPane.getTransition("skin").play();
                let cardObj = this._cardObj.getLevelObj(this._curCardViewLevel);
                this._updateLevelText(cardObj);
                // let sound:string = this._cardObj.sound;
                //     if (sound && sound.length > 0)
                //         SoundMgr.inst.playSoundAsync(`${sound}_mp3`);
            }
        }

        private _onEquipChange() {
            this._refreshCard();
            if (this._equipBtn) {
                this._equipBtn.getTransition("equip").play();
            }
        }
        
        private _onPropLevelChange(evt: Core.PropertyEvent) {
            this._changeCurLevel(this._cardObj.level);
            this._updateResLabel();
            this._updateUpBtn();
        }
        public async open(...param: any[]) {
            await super.open(...param);
            let cardObj = param[0] as Card;
            if (cardObj.rare == CardQuality.LIMITED) {
                this._expProgressBar.visible = false;
            } else {
                this._expProgressBar.visible = true;
            }
            this.contentPane.getChild("imgMaxLevel").visible = false;
            this._updateAmountProgress();
            this._updateResLabel();
            this._updateUpBtn();
            this._updateEquipBtn();
            this._card.watchProp(CardPool.Card.PropSkin, this._onSkinChange, this);
            this._card.watchProp(CardPool.Card.PropEquip, this._onEquipChange, this);
            this._cardObjWatchers.push(Core.Binding.bindHandler(cardObj, [Card.PropAmount], this._updateAmountProgress, this));
            this._cardObjWatchers.push(Core.Binding.bindHandler(cardObj, [Card.PropLevel], this._onPropLevelChange, this));
            this._cardObjWatchers.push(Core.Binding.bindHandler(cardObj, [Card.PropEquip], this._updateEquipBtn, this));
        }

        public async close(...param: any[]) {
            super.close(...param);
            this._card.unwatchProp(CardPool.Card.PropSkin);
            this._card.unwatchProp(CardPool.Card.PropEquip);
        } 
    }
}