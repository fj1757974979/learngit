module Battle {

    export class CardBigWnd extends Core.BaseWindow {
        private _frontImg: fairygui.GLoader;
        private _baseImg: fairygui.GLoader;
        private _icon: fairygui.GImage;
        private _imgUrl: string;

        public initUI() {
            this._myParent = Core.LayerManager.inst.maskLayer;
            this.adjust(this.getChild("closeBg"));
            super.initUI();
            this.center();

            this._frontImg = this.getChild("frontImg").asLoader;
            this._baseImg = this.getChild("baseImg").asLoader;
            this._icon = this.getChild("icon").asImage;
            let scale = fairygui.GRoot.inst.getDesignStageWidth() / 480;
            this.setScale(scale, scale);

            this.getChild("closeBg").addClickListener(this.close, this);
        }

        public async open(...param: any[]) {
            this.toTopLayer();
            super.open(...param);
            let fightCard = param[0] as FightCard;

            let self = this;
            UI.CardImgTextureMgr.inst.fetchTexture(fightCard.icon, fightCard.skin, "b", (icon, texture, url) => {
                self._icon.texture = texture;
            });
        }
    }

    export class CardDetailWnd extends Core.BaseWindow {
        private _frontImg: fairygui.GLoader;
        private _baseImg: fairygui.GLoader;
        private _icon: fairygui.GImage;
        private _skillDescTxt: fairygui.GRichTextField[];
        private _skillBg: fairygui.GLoader[];
        private _equipSkillDescTxt: fairygui.GRichTextField;
        private _equipSkillBg: fairygui.GLoader;
        private _equipSkillDescTxtY: number;
        private _equipSkillBgY: number;
        private _nameTxt: fairygui.GTextField;
        private _nameImg: fairygui.GLoader;
        private _imgUrl: string;

        private _fightCard: FightCard;

        static resigterView() {
            if (!Core.ViewManager.inst.getView(ViewName.cardDetail)) {
                let cardDetailWnd = fairygui.UIPackage.createObject(PkgName.cards, "bigCard", CardDetailWnd) as CardDetailWnd;
                Core.ViewManager.inst.register(ViewName.cardDetail, cardDetailWnd);
            }
        }

        public initUI() {
            this._myParent = Core.LayerManager.inst.maskLayer;
            this.adjust(this.getChild("closeBg"));
            super.initUI();
            super.center();
            this.y = this.y + 15;
            this._frontImg = this.getChild("frontImg").asLoader;
            this._baseImg = this.getChild("baseImg").asLoader;
            this._icon = this.getChild("icon").asImage;
            this._nameImg = this.getChild("nameImg").asLoader;
            this._skillDescTxt = [];
            this._skillBg = [];
            for (let i = 1; i <= 4; i++) {
                this._skillDescTxt.push(this.getChild("skillDescTxt" + i).asRichTextField);
                this._skillBg.push(this.getChild("skillBg" + i).asLoader);
                this._skillDescTxt[i-1].addEventListener(egret.TextEvent.LINK, htmlClickCallback, this);
            }
            this._equipSkillDescTxt = this.getChild("equipDescTxt").asRichTextField;
            this._equipSkillDescTxt.addEventListener(egret.TextEvent.LINK, htmlClickCallback, this);
            this._equipSkillDescTxtY = this._equipSkillDescTxt.y;
            this._equipSkillBg = this.getChild("equipSkillBg").asLoader;
            this._equipSkillBgY = this._equipSkillBg.y;
            this._nameTxt = this.getChild("nameText").asTextField;
            this._nameTxt.textParser = Core.StringUtils.parseColorText;
            this.getChild("closeBg").addClickListener(this._onTouchBegin, this);

            this._adjustWidgetByLocale();
        }

        private _adjustWidgetByLocale() {
            if (LanguageMgr.inst.isChineseLocale()) {
                return;
            }
            this._nameImg.setSize(166, 39);
            this._nameImg.setXY(209, 0);
            this._nameTxt.setSize(166, 30);
            this._nameTxt.setXY(209, 4);
            this._nameTxt.fontSize = 24;
            this._nameTxt.autoSize = fairygui.AutoSizeType.Shrink;
            for (let i = 0; i < 4; i++) {
                let textWnd = this._skillDescTxt[i];
                textWnd.autoSize = fairygui.AutoSizeType.Shrink;
                textWnd.leading = 0;
            }
            this._equipSkillDescTxt.autoSize = fairygui.AutoSizeType.Shrink;
            this._equipSkillDescTxt.leading = 0;
        }

        public async open(...param: any[]) {
            super.open(...param);
            let fightCard = param[0] as FightCard;

            if (this._fightCard && this._fightCard != fightCard && this._fightCard.view) {
                this._fightCard.view.isDetailOpen = false;
            }

            this._fightCard = fightCard;
            let rare = fightCard.rare;
            if (fightCard.side == Side.OWN) {
                this._frontImg.url = `cards_back1_b${rare}_png`; //"cards_back1_b_png";
                if (rare == CardQuality.LIMITED) {
                    this._baseImg.url = "cards_base1_b_ex_png";
                } else {
                    this._baseImg.url = "cards_base1_b_png";
                }
            } else {
                this._frontImg.url = `cards_back2_b${rare}_png`; //"cards_back2_b_png";
                if (rare == CardQuality.LIMITED) {
                    this._baseImg.url = "cards_base2_b_ex_png";
                } else {
                    this._baseImg.url = "cards_base2_b_png";
                }
            }

            let self = this;
            UI.CardImgTextureMgr.inst.fetchTexture(fightCard.icon, fightCard.skin, "b", (icon, texture, url) => {
                self._icon.texture = texture;
                self._imgUrl = url;
            });

            for (let i = 0; i < 4; i++) {
                this._skillDescTxt[i].visible = false;
                this._skillBg[i].visible = false;
            }
            this._equipSkillDescTxt.visible = false;
            this._equipSkillBg.visible = false;
            let battle = BattleMgr.inst.battle;
            if (fightCard.isShowFogUI()) {
                this._nameImg.visible = false;
                this._nameTxt.visible = false;
                return;
            }

            this._nameImg.visible = true;
            this._nameTxt.visible = true;
            if (rare == CardQuality.LIMITED) {
                this._nameImg.url = "cards_name_b_ex_png";
            } else {
                this._nameImg.url = "cards_name_b_png";
            }
            this._nameTxt.text = fightCard.name;
            //this._skillDescTxt.text = fightCard.skillDesc;
            let skills: Array<string> = (fightCard.skillDesc || "").split("\n").filter(function (str, index, array) { return str != ""; });
            let level:string = "1";
            level = fightCard.level.toString();
            if (fightCard.collectCard != null) {
                level = fightCard.collectCard.level.toString();
            }
            let skillIndex: number = -1;
            for (let i = 0; i < skills.length; i++) {
                skillIndex = i;
                let skin = "";
                if (fightCard.skin && fightCard.skin != "") {
                    skin = Data.skin_config.get(fightCard.skin).bind;
                }
                let skillDescText = skills[i].replace(/level/g, level);
                skillDescText = skillDescText.replace(/skin/g, skin);
                this._skillDescTxt[i].text = skillDescText;
                this._skillDescTxt[i].visible = true;
                this._skillBg[i].visible = true;
                this._skillBg[i].url = "cards_skillBg" + ((skills.length - i - 1) % 2 + 1) + "_png"
            }

            if (!fightCard.equipment) {
                return;
            }
            let equipSkillDesc = fightCard.equipment.getSkillDesc();
            if (!equipSkillDesc || equipSkillDesc == "") {
                return;
            }

            this._equipSkillBg.visible = true;
            this._equipSkillDescTxt.visible = true;
            this._equipSkillDescTxt.text = equipSkillDesc;
            if (skillIndex < 0) {
                this._equipSkillBg.y = this._skillBg[0].y;
                this._equipSkillDescTxt.y = this._skillDescTxt[0].y;
            } else if (skillIndex < this._skillDescTxt.length - 1) {
                this._equipSkillBg.y = this._skillBg[skillIndex+1].y;
                this._equipSkillDescTxt.y = this._skillDescTxt[skillIndex+1].y;
            } else {
                this._equipSkillBg.y = this._equipSkillBgY;
                this._equipSkillDescTxt.y = this._equipSkillDescTxtY;
            }
        }

        public async close(...param: any[]) {
            if (this._imgUrl) {
                RES.destroyRes(this._imgUrl);
                this._imgUrl = undefined;
                if (this._icon && this._icon.texture) {
                    this._icon.texture.dispose();
                    this._icon.texture = undefined;
                }
            }
            super.close(...param);
        }

        private _onTouchBegin(evt:egret.TouchEvent) {
            if (Guide.GuideMgr.inst.isInGuide) {
                Core.ViewManager.inst.closeView(this);
                this.close();
                return;
            }

            if (Core.ViewManager.inst.getView("htmlCardView") && Core.ViewManager.inst.getView("htmlCardView").isShow()) return;
            Core.ViewManager.inst.closeView(this);
            this.close();
        }
    }

}
