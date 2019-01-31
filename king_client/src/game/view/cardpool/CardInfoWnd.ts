module CardPool {

    export class CardInfoWnd extends Core.BaseWindow {
        private static _inst: CardInfoWnd;

        private _campText: fairygui.GLoader;
        private _skillDescTexts: Array<fairygui.GRichTextField>;
        protected _card: UI.CardCom;
        

        protected _cardObj: Card;
        protected _cardIndex: number;
        protected _curCardViewLevel: number;
        protected _cardObjWatchers: Core.Watcher[];
        protected _isViewMode: boolean;
        private _sayText: fairygui.GRichTextField;

        private _isMyCardInfo: boolean;

        private _politicsText: fairygui.GRichTextField;
        private _intelligenceText: fairygui.GRichTextField;
        private _forceText: fairygui.GRichTextField;
        private _commandText: fairygui.GRichTextField;

        private _politicsHintText: fairygui.GRichTextField;
        private _intelligenceHintText: fairygui.GRichTextField;
        private _forceHintText: fairygui.GRichTextField;
        private _commandHintText: fairygui.GRichTextField;

        private _typeCtrl: fairygui.Controller;

        public static get inst(): CardInfoWnd {
            return CardInfoWnd._inst;
        }

        public initUI() {
            super.initUI();
            this._cardObjWatchers = [];
            this._isViewMode = false;
            this.modal = true;
            this.pivotX = 0.5;
            this.pivotY = 0.5;
            let x = this.x;
            let y = this.y;
            this.center();
            this.adjust(this.contentPane.getChild("closeBg"));
            // this.contentPane.getChild("closeBg").x += this.x - x;
            // this.contentPane.getChild("closeBg").y += this.y - y;
            this._campText = this.contentPane.getChild("campText").asLoader;
            this._skillDescTexts = [];
            for (let i = 0; i < 3; i++) {
                this._skillDescTexts.push(this.contentPane.getChild("skillDescText" + (i + 1)).asRichTextField);
                this._skillDescTexts[i].addEventListener(egret.TextEvent.LINK, htmlClickCallback, this);
                if (window.gameGlobal.isMultiLan) {
                    if (!LanguageMgr.inst.isChineseLocale()) {
                        this._skillDescTexts[i].asRichTextField.leading = 1;
                    }
                }
            }

            //this._skillDescText.textParser = Core.StringUtils.parseColorText;

            this.contentPane.getChild("campBottom").visible = !Home.FunctionMgr.inst.isEquipOpen();
            this._campText.visible = !Home.FunctionMgr.inst.isEquipOpen();

            this._card = this.contentPane.getChild("card").asCom as UI.CardCom;

            //this._card.setOppFront();
            this._sayText = this.contentPane.getChild("say").asRichTextField;

            this.contentPane.getChild("closeBtn").asButton.addClickListener(this._onClose, this);
            this.contentPane.getChild("btnLevel1").asButton.addClickListener(function () {
                this._changeCurLevel(1);
            }, this);
            this.contentPane.getChild("btnLevel2").asButton.addClickListener(function () {
                this._changeCurLevel(2);
            }, this);
            this.contentPane.getChild("btnLevel3").asButton.addClickListener(function () {
                this._changeCurLevel(3);
            }, this);
            this.contentPane.getChild("btnLevel4").asButton.addClickListener(function () {
                this._changeCurLevel(4);
            }, this);
            this.contentPane.getChild("btnLevel5").asButton.addClickListener(function () {
                this._changeCurLevel(5);
            }, this);
            this.contentPane.getChild("closeBg").addClickListener(this._onTouchEnd, this);

            // let mx:number = null;
            // let my:number = null;
            // this.contentPane.addEventListener(egret.TouchEvent.TOUCH_BEGIN, function(evt:egret.TouchEvent) {
            //     //console.log("touch begin");
            //     mx = evt.stageX;
            //     my = evt.stageY;
            // }, this);
            // this.contentPane.addEventListener(egret.TouchEvent.TOUCH_END, function(evt:egret.TouchEvent) {
            //     //console.log("touch end");
            //     if (mx) {
            //         let dx = evt.stageX - mx;
            //         if (Math.abs(dx) > 20) {
            //             if (dx > 0) this.prev();
            //             else this.next()
            //         }
            //     }
            // }, this);

            if (!LanguageMgr.inst.isChineseLocale()) {
                this._sayText.autoSize = fairygui.AutoSizeType.None;
                this._sayText.fontSize = 16;
                this._sayText.leading = 1;
                this._sayText.setSize(329, 35);
            }

            this._typeCtrl = this.contentPane.getController("type");
            if (Home.FunctionMgr.inst.isWorldWarOpen()) {
                this._politicsText = this.contentPane.getChild("politics").asRichTextField;
                this._intelligenceText = this.contentPane.getChild("intelligence").asRichTextField;
                this._forceText = this.contentPane.getChild("force").asRichTextField;
                this._commandText = this.contentPane.getChild("command").asRichTextField;

                this._politicsHintText = this.contentPane.getChild("politicsText").asRichTextField;
                this._intelligenceHintText = this.contentPane.getChild("intelligenceText").asRichTextField;
                this._forceHintText = this.contentPane.getChild("forceText").asRichTextField;
                this._commandHintText = this.contentPane.getChild("commandText").asRichTextField;

                this._politicsHintText.funcParser = Core.StringUtils.parseFuncText;
                this._politicsHintText.text = "#fdesc,60285(政治)#e：";
                this._intelligenceHintText.funcParser = Core.StringUtils.parseFuncText;
                this._intelligenceHintText.text = "#fdesc,60286(智力)#e：";
                this._forceHintText.funcParser = Core.StringUtils.parseFuncText;
                this._forceHintText.text = "#fdesc,60287(武力)#e：";
                this._commandHintText.funcParser = Core.StringUtils.parseFuncText;
                this._commandHintText.text = "#fdesc,60288(统帅)#e：";
            } else {
                this._typeCtrl.setSelectedPage("common");
            }
            
            if (Player.inst.isNewVersionPlayer()) {
                this.contentPane.getChild("lockTxt").visible = true;
            } else {
                this.contentPane.getChild("lockTxt").visible = false;
            }
        }

        public setViewMode() {
            console.log("view mode");
            // if (this._expProgressBar) {
            //     this._expProgressBar.visible = false;
            // }
            // this._myParent = Core.LayerManager.inst.maskLayer;
            // if (this.contentPane.getChild("txtCost")) {
            //     this.contentPane.getChild("txtCost").visible = false;
            // }
            // if (this.contentPane.getChild("goldLabel")) {
            //     this.contentPane.getChild("goldLabel").visible = false;
            // }
            // if (this.contentPane.getChild("uplevelBtn")) {
            //     this.contentPane.getChild("uplevelBtn").visible = false;
            // }
            // if (this.contentPane.getChild("imgMaxLevel")) {
            //     this.contentPane.getChild("imgMaxLevel").visible = false;
            // }
            this._myParent = Core.LayerManager.inst.maskLayer;
            this.contentPane.height = 570;
            this.contentPane.center();
            this._isViewMode = true;
        }

        /**
         * @param cardObj  CardPool.Card | Diy.DiyCard
         */
        public async open(...param: any[]) {
            this.battleChangeLayer();
            CardInfoWnd._inst = this;
            super.open(...param);
            this.touchable = true;
            
            let cardObj = param[0] as Card;
            this._cardIndex = param[1] as number;
            // let noOpenAni = param[2];
            this._cardObj = cardObj;
            this._card.cardObj = cardObj;
            
            this._curCardViewLevel = cardObj.level;
            this._campText.url = Utils.camp2Url(cardObj.camp);
            this._updateLevelText(cardObj);
            this._updateEnergyProgress();
            this._updateCardInfo(cardObj);
            this._changeCurLevel(cardObj.level);

            if (cardObj.rare == CardQuality.LIMITED) {
                this.contentPane.getChild("limitTips").visible = true;
                this.contentPane.getChild("limitImg").visible = true;
                let c = this.contentPane.getChild("limitTips2");
                if (c) c.visible = true;
            } else {
                this.contentPane.getChild("limitTips").visible = false;
                this.contentPane.getChild("limitImg").visible = false;
                let c = this.contentPane.getChild("limitTips2");
                if (c) c.visible = false;
            }

            let id = cardObj.cardId;
            let info = Data.hero_say.get(id);
            if (info) {
                // console.log(`${id} ${info.say}`);
                this._sayText.text = info.say;
            } else {
                this._sayText.text = '';
            }

            this.contentPane.getChild("skillDescBg1").asGraph.visible = false;
            this.contentPane.getChild("skillDescBg2").asGraph.visible = false;
            this.contentPane.getChild("skillDescBg3").asGraph.visible = false;

            
            this._cardObjWatchers.push(Core.Binding.bindHandler(cardObj, [Card.PropEnergy], this._updateEnergyProgress, this));
            this._cardObjWatchers.push(Core.Binding.bindHandler(cardObj, [Card.PropState], this._refreshCard, this));
            //egret.MainContext.instance.stage.addEventListener(egret.TouchEvent.TOUCH_END, this._onTouchEnd, this);
            //this.contentPane.root.addEventListener(egret.TouchEvent.TOUCH_TAP, this._onTouchEnd, this);

            SoundMgr.inst.playSoundAsync("page_mp3");

            if (this._isViewMode) return;

            this.scaleX = 0.5;
            this.scaleY = 0.5;
            // await 
            new Promise<void>(resolve => {
                egret.Tween.get(this).to({ scaleX: 1, scaleY: 1 }, 300, egret.Ease.backOut).call(() => {
                    resolve();
                });
            });
        }

        public async close(...param: any[]) {
            if (this._isViewMode) {
                this._doClose();
                return;
            }
            await new Promise<void>(resolve => {
                egret.Tween.get(this).to({ scaleX: 0, scaleY: 0 }, 300, egret.Ease.backIn).call(function () {
                    this._doClose();
                    this._card.unloadCardImg();
                    resolve();
                }, this);
            })
        }

        private _doClose(...param: any[]) {
            //this.contentPane.root.removeEventListener(egret.TouchEvent.TOUCH_TAP, this._onTouchEnd, this);
            this._cardObjWatchers.forEach(w => {
                w.unwatch();
            });
            this._cardObjWatchers = [];
            super.close(...param);
        }

        private _onTouchEnd(evt: egret.TouchEvent) {
            if (Core.ViewManager.inst.getView("htmlCardView") && !this._isViewMode) return;
            this._onClose();
        }

        protected _refreshCard() {
            this._updateCardInfo(this._cardObj);
        }
        
        private _updateCardInfo(cardObj: Card) {
            this._card.cardObj = cardObj;
            if (!Core.ViewManager.inst.getView("htmlCardView")) this._card.unloadCardImg();
            this._card.setCardImg();
            this._card.setEquip();
            this._card.setName();
            this._card.setSkill();
            this._card.setNumText();
            this._card.setNumOffsetText();
            this._card.setBriefMode(true);
            this._card.setDeskBackground();

            this._updateCardWarInfo();
        }

        private _updateCardWarInfo() {
            if (!Home.FunctionMgr.inst.isWorldWarOpen()) {
                return;
            }
            let gcardId = this._card.cardObj.gcardId;
            let conf = Data.pool.get(gcardId);
            this._politicsText.text = `${conf.politics}`;
            this._intelligenceText.text = `${conf.intelligence}`;
            this._forceText.text = `${conf.force}`;
            this._commandText.text = `${conf.command}`;
        }

        private _updateEnergyProgress() {
        }


        protected _updateLevelText(cardObj: Card) {
            //console.log(cardObj.skillDesc);
            let skills: Array<string> = (cardObj.skillDesc || "").split("\n").filter(function (str, index, array) { return str != ""; });
            for (let i = 0; i < 3; i++) {
                if (skills[i]) {
                    let skin = "";
                    if (this._cardObj.skin && this._cardObj.skin != "") {
                        skin = Data.skin_config.get(this._cardObj.skin).bind;
                    }
                    let skillDescText = skills[i].replace(/level/g, this._curCardViewLevel.toString());
                    skillDescText = skillDescText.replace(/skin/g, skin);
                    this._skillDescTexts[i].text = skillDescText;
                } else {
                    this._skillDescTexts[i].text = "";
                }
            }
        }

        protected _changeCurLevel(level: number) {
            let cardObj = this._cardObj.getLevelObj(level);
            if (!cardObj) {
                return;
            }
            this._curCardViewLevel = level;
            for (let i = 1; i <= 5; i++) {
                this.contentPane.getChild("btnLevel" + i).asButton.selected = false;
                let hasLevel = this._cardObj.getLevelObj(i) != null;
                this.contentPane.getChild("btnLevel" + i).asButton.enabled = hasLevel;
                util.setObjGray(this.contentPane.getChild("levelTxt" + i), !hasLevel);
            }
            this.contentPane.getChild("btnLevel" + cardObj.level).asButton.selected = true;

            let img = this.contentPane.getChild("curLevelImg");
            img.y = this.contentPane.getChild("btnLevel" + this._cardObj.level).asButton.y + 11;
            this._updateCardInfo(cardObj);
            this._updateLevelText(cardObj);
        }

        

        private _onClose() {
            this.touchable = false;
            Core.ViewManager.inst.closeView(this);
        }

        public async playUplevelEffect() {
            /*
            await new Promise((resolve) => {
                this.contentPane.getTransition("levelup").play(resolve);
            });

            await new Promise((resolve => {
                this.contentPane.getChild("btnLevel" + 2).asCom.getTransition("blink").play(resolve);
            }));

            await new Promise((resolve=> {
                this._card.getChild("leftNum").asCom.getTransition("blink").play(resolve);
            }));
            */

            if (Home.FunctionMgr.inst.isWorldWarOpen()) {
                this._typeCtrl.setSelectedPage("pvp");
            }
            let curLevelObj = this._cardObj.getLevelObj(this._cardObj.level);
            let prevLevelObj = this._cardObj.getLevelObj(this._cardObj.level - 1);
            if (!prevLevelObj) return;

            SoundMgr.inst.playSoundAsync("levelup_mp3");
            if (curLevelObj.leftNum != prevLevelObj.leftNum || curLevelObj.leftNumOffset != prevLevelObj.leftNumOffset) {
                this._card.getChild("leftNum").asCom.getTransition("blink").play();
            }
            if (curLevelObj.rightNum != prevLevelObj.rightNum || curLevelObj.rightNumOffset != prevLevelObj.rightNumOffset) {
                this._card.getChild("rightNum").asCom.getTransition("blink").play();
            }
            if (curLevelObj.upNum != prevLevelObj.upNum || curLevelObj.upNumOffset != prevLevelObj.upNumOffset) {
                this._card.getChild("upNum").asCom.getTransition("blink").play();
            }
            if (curLevelObj.downNum != prevLevelObj.downNum || curLevelObj.downNumOffset != prevLevelObj.downNumOffset) {
                this._card.getChild("downNum").asCom.getTransition("blink").play();
            }

            let curIds = curLevelObj.skillIds;
            let prevIds = prevLevelObj.skillIds;
            let index = 1;
            //console.log("curids:" + curIds.join(","));
            //console.log("prevIds:" + prevIds.join(","));

            this.contentPane.getChild("skillDescBg1").asGraph.visible = true;
            this.contentPane.getChild("skillDescBg2").asGraph.visible = true;
            this.contentPane.getChild("skillDescBg3").asGraph.visible = true;

            if (curIds) {
                for (let i = 0; i < curIds.length; i++) {
                    let skillRes = Data.skill.get(curIds[i]);
                    if (!skillRes || !skillRes.name) continue;
                    let find = false;
                    if (prevIds) {
                        for (let j = 0; j < prevIds.length; j++) {
                            if (prevIds[j] == curIds[i]) {
                                find = true;
                            }
                        }
                    }
                    if (!find) {
                        this.contentPane.getTransition("skill" + index + "blink").play();
                    }
                    index++;
                }
            }

            await new Promise((resolve) => {
                this.contentPane.getChild("btnLevel" + this._cardObj.level).asCom.getTransition("blink").play(resolve);
            });

            await new Promise((resolve) => {
                if (LanguageMgr.inst.isChineseLocale()) {
                    this.contentPane.getTransition("levelupTip").play(resolve);
                } else {
                    this.contentPane.getTransition("levelupTip2").play(resolve);
                }
            });
        }
    }

}
