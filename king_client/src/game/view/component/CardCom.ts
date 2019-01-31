module UI {

    export interface ICardObj {
        collectCard: CardPool.Card | Diy.DiyCard
        gcardId: number
        cardId: number
        upNum: number
        downNum: number
        leftNum: number
        rightNum: number
        upNumOffset: number
        downNumOffset: number
        leftNumOffset: number
        rightNumOffset: number
        name: string
        skin: string
        equip: string
        rare: CardQuality
        skill1Name: string
        skill2Name: string
        skill3Name: string
        skill4Name: string
        skillDesc: string
	    skillIds: Array<number>
        state: CardPool.CardState
        energy: number
        amount: number
        maxEnergy: number
        maxAmount: number
        isNew: boolean
        weapon: string
        sound: string
        // callback: (icon:number)
        icon: number
        isInCampaignMission: boolean;
    }

    export class CardRareCom extends fairygui.GComponent {

        private _starImgs: Array<fairygui.GLoader>;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._starImgs = [];
            for (let i = 1; i <= 5; ++ i) {
                let star = this.getChild(`star${i}`);
                if (star) {
                    this._starImgs.push(star.asLoader);
                }
            }
        }

        public setRare(rare: CardQuality) {
            if (rare > CardQuality.BOOM) {
                rare = CardQuality.BOOM;
            }
            let stars: Array<fairygui.GLoader> = [];
            for (let i = 0; i < rare; i ++) {
                this._starImgs[i].visible = true;
                stars.push(this._starImgs[i]);
            }
            for (let j = rare; j < this._starImgs.length; j ++) {
                this._starImgs[j].visible = false;
            }
            let starw = stars[0].width;
            let cnt = stars.length;
            let gap = 1;
            let startx = (this.width - (cnt * starw + (cnt - 1) * gap))/2;
            stars.forEach(starImg => {
                starImg.x = startx;
                startx += starw + gap;
            })
        }
    }

    export class CardCom extends fairygui.GComponent implements IHandItem {
        private _cardImg: fairygui.GImage;
        private _baseImg: fairygui.GLoader;
        private _frontImg: fairygui.GLoader;
        private _nameText: fairygui.GTextField;
        private _nameImg: fairygui.GLoader;
        private _imgUrl: string;
        private _skin: string;

        protected _skill1Text: fairygui.GTextField;
        protected _skill2Text: fairygui.GTextField;
        protected _skill3Text: fairygui.GTextField;
        protected _skill4Text: fairygui.GTextField;
        private _skill1Bottom: fairygui.GLoader;
        private _skill2Bottom: fairygui.GLoader;
        private _skill3Bottom: fairygui.GLoader;
        private _skill4Bottom: fairygui.GLoader;
        private _skillStartPos: number;
        private _skillStartPosY: number;
        private _skillAreaWidth: number;
        private _skillAreaHeight: number;
        private _skillUnitWidth: number;
        private _skillUnitHeight: number;

        protected _upNum: fairygui.GComponent;
        protected _downNum: fairygui.GComponent;
        protected _leftNum: fairygui.GComponent;
        protected _rightNum: fairygui.GComponent;
        private _upNumOffset: fairygui.GTextField;
        private _downNumOffset: fairygui.GTextField;
        private _leftNumOffset: fairygui.GTextField;
        private _rightNumOffset: fairygui.GTextField;
        private _lightCircle :fairygui.GLoader;

        private _lockGrayBg: fairygui.GGraph;
        private _lockBlackBg: fairygui.GGraph;
        private _blackMask: fairygui.GGraph;
        private _cardObj: ICardObj;
        private _inHandPoint: egret.Point;
        private _cardObjWatchers: Collection.Dictionary<string, Core.Watcher>;
        private _rareCom: CardRareCom;

        protected _equipBtn: fairygui.GButton;

        private _isBriefMode: boolean;
        private _isQualityMode: boolean;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._cardObjWatchers = new Collection.Dictionary<string, Core.Watcher>();
            this._cardImg = this.getChild("cardImg").asImage;
            this._baseImg = this.getChild("baseImg").asLoader;
            this._frontImg = this.getChild("frontImg").asLoader;
            this._nameText = this.getChild("nameText").asTextField;
            this._nameText.textParser = Core.StringUtils.parseColorText;
            this._nameImg = this.getChild("nameImg").asLoader;
            this._imgUrl = null;

            this._skill1Text = this.getChild("skill1Text").asTextField;
            this._skill1Text.textParser = Core.StringUtils.parseColorText;
            this._skill1Bottom = this.getChild("skill1Bottom").asLoader;
            this._skill2Text = this.getChild("skill2Text").asTextField;
            this._skill2Text.textParser = Core.StringUtils.parseColorText;
            this._skill2Bottom = this.getChild("skill2Bottom").asLoader;
            this._skill3Text = this.getChild("skill3Text").asTextField;
            this._skill3Text.textParser = Core.StringUtils.parseColorText;
            this._skill3Bottom = this.getChild("skill3Bottom").asLoader;
            this._skill4Text = this.getChild("skill4Text").asTextField;
            this._skill4Text.textParser = Core.StringUtils.parseColorText;
            this._skill4Bottom = this.getChild("skill4Bottom").asLoader;

            let skillGroup = this.getChild("skillGroup").asGroup;
            this._skillStartPos = skillGroup.x;
            this._skillStartPosY = skillGroup.y;
            this._skillAreaWidth = skillGroup.width;
            this._skillAreaHeight = skillGroup.height;
            this._skillUnitWidth = this._skill1Bottom.width;
            this._skillUnitHeight = this._skill1Bottom.height;

            let equipBtn = this.getChild("equipBtn");
            if (equipBtn) {
                this._equipBtn = equipBtn.asButton;
                // let icon = this._equipBtn.getChild("icon").asLoader;
                // let mask = this._equipBtn.getChild("maskWnd").asLoader;
                // icon.displayObject.mask = mask.displayObject;
                // mask.alpha = 0;
                this._equipBtn.visible = Home.FunctionMgr.inst.isEquipOpen();
            }

            this._upNum = this.getChild("upNum").asCom;
            this._downNum = this.getChild("downNum").asCom;
            this._downNum.getChild("img").asLoader.rotation = 180;
            this._leftNum = this.getChild("leftNum").asCom;
            this._leftNum.getChild("img").asLoader.rotation = -90;
            this._rightNum = this.getChild("rightNum").asCom;
            this._rightNum.getChild("img").asLoader.rotation = 90;
            this._upNumOffset = this.getChild("upNumOffset").asTextField;
            this._downNumOffset = this.getChild("downNumOffset").asTextField;
            this._leftNumOffset = this.getChild("leftNumOffset").asTextField;
            this._rightNumOffset = this.getChild("rightNumOffset").asTextField;
            let _lightCircleCom = this.getChild("lightCircle");
            if (_lightCircleCom) {
                this._lightCircle = _lightCircleCom.asLoader;
                this._lightCircle.visible = false;
            }

            this._skill1Text.visible = false;
            this._skill1Bottom.visible = false;
            this._skill2Text.visible = false;
            this._skill2Bottom.visible = false;
            this._skill3Text.visible = false;
            this._skill3Bottom.visible = false;
            this._skill4Text.visible = false;
            this._skill4Bottom.visible = false;

            this._nameText.visible = false;
            this._upNum.visible = false;
            this._downNum.visible = false;
            this._leftNum.visible = false;
            this._rightNum.visible = false;
            this._upNumOffset.visible = false;
            this._downNumOffset.visible = false;
            this._leftNumOffset.visible = false;
            this._rightNumOffset.visible = false;

            if (this.getChild("rareCom")) {
                this._rareCom = this.getChild("rareCom").asCom as CardRareCom;
                this._rareCom.visible = false;
            } else {
                this._rareCom = null;
            }
            this._isBriefMode = false;
            this._isQualityMode = false;

            if (!LanguageMgr.inst.isChineseLocale()) {
                this._adjustWidgetByLocale();
            }
        }

        public get cardObj(): ICardObj {
            return this._cardObj;
        }
        public set cardObj(obj: ICardObj) {
            this._cardObj = obj;
        }

        public get inHandPoint(): egret.Point {
            return this._inHandPoint;
        }
        public set inHandPoint(p:egret.Point) {
            this._inHandPoint = p;
        }

        private _getFrontUrl(): string {
            let rare = this._cardObj.rare;
            if (this.packageItem.name == "smallCard") {
                return `cards_deck_s${rare}_png`;
            } else {
                return `cards_deck_m${rare}_png`;
            }
        }

        private _getNameImgUrl(): string {
            let rare = this._cardObj.rare;
            if (rare == CardQuality.LIMITED) {
                if (this.packageItem.name == "smallCard") {
                    return `cards_name_s_ex_png`;
                } else {
                    return `cards_name_m_ex_png`;
                }
            } else {
                if (this.packageItem.name == "smallCard") {
                    return `cards_name_s_png`;
                } else {
                    return `cards_name_m_png`;
                }
            }
        }

        private _setNameStyle() {
            this._nameImg.url = this._getNameImgUrl();
        }

        public setOppFront() {
            this._frontImg.visible = true;
            this._frontImg.url = this._getFrontUrl();
            this._nameImg.visible = true;
            this._setNameStyle();
        }

        public setOwnFront() {
            this._frontImg.visible = true;

            this._frontImg.url = this._getFrontUrl();
            this._nameImg.visible = true;
            this._setNameStyle();
        }

        public setOwnLockFront() {
            this._frontImg.visible = true;

            this._frontImg.url = this._getFrontUrl();
            this._nameImg.visible = true;
            this._setNameStyle();
        }

        public setOppBackground() {
            let rare = this._cardObj.rare;
            if (Home.FunctionMgr.inst.isEquipOpen()) {
                this._equipBtn.getChild("bg").asLoader.url = "equip_equipWndEnemy_png";
            }
            let _getBackImg = function(size: string) {
                if (rare == CardQuality.LIMITED) {
                    return `cards_base2_${size}_ex_png`;
                } else {
                    return `cards_base2_${size}_png`;
                }
            }
            if (this.packageItem.name == "smallCard") {
                this._baseImg.url = _getBackImg("s");
            } else if (this.packageItem.name == "middleCard") {
                this._baseImg.url = _getBackImg("m");
            } else if (this.packageItem.name == "middleCardBig") {
                this._baseImg.url = _getBackImg("b");
            } else if (this.packageItem.name == "bigCard") {
                this._baseImg.url = _getBackImg("b");
            }
        }

        public setOwnBackground() {
            let rare = this._cardObj.rare;
            if (Home.FunctionMgr.inst.isEquipOpen()) {
                this._equipBtn.getChild("bg").asLoader.url = "equip_equipWnd_png";
            }
            let _getBackImg = function(size: string) {
                if (rare == CardQuality.LIMITED) {
                    return `cards_base1_${size}_ex_png`;
                } else {
                    return `cards_base1_${size}_png`;
                }
            }
            if (this.packageItem.name == "smallCard") {
                this._baseImg.url = _getBackImg("s");
            } else if (this.packageItem.name == "middleCard") {
                this._baseImg.url = _getBackImg("m");
            } else if (this.packageItem.name == "middleCardBig") {
                this._baseImg.url = _getBackImg("b");
            } else if (this.packageItem.name == "bigCard") {
                this._baseImg.url = _getBackImg("b");
            }
        }

        public setDeskFront() {
            this._frontImg.visible = true;

            this._frontImg.url = this._getFrontUrl();
            this._nameImg.visible = true;
            this._setNameStyle();
        }

        public setDeskBackground() {
            let rare = this._cardObj.rare;
            let _getBackImg = function(size: string) {
                if (rare == CardQuality.LIMITED) {
                    return `cards_back_${size}_ex_png`;
                } else {
                    return `cards_back_${size}_png`;
                }
            }
            if (this.packageItem.name == "smallCard") {
                this._baseImg.url = _getBackImg("s");
            } else if (this.packageItem.name == "middleCard") {
                this._baseImg.url = _getBackImg("m");
            } else {
                this._baseImg.url = _getBackImg("b");
            }
        }

        public setBriefMode(b: boolean) {
            this._frontImg.visible = b;

            this._frontImg.url = this._getFrontUrl();
            this._nameImg.visible = b;
            this._setNameStyle();
            this._skill1Text.visible = !b;
            this._skill1Bottom.visible = !b;
            this._skill2Text.visible = !b;
            this._skill2Bottom.visible = !b;
            this._skill3Text.visible = !b;
            this._skill3Bottom.visible = !b;
            this._skill4Text.visible = !b;
            this._skill4Bottom.visible = !b;

            this._isBriefMode = b;
        }

        public setQualityMode(b: boolean) {
            this.setBriefMode(b);
            this.setNumText(!b);
            this.setNumOffsetText(!b);
            this.visibleRareStars(b);
            this._isQualityMode = b;
        }
        

        public hideFront() {
            this._frontImg.visible = false;
            this._nameImg.visible = false;
        }

        public setCardImg(isLocked:boolean = false) {           
            let cardImg = this._cardImg;
            let cardSize = null;
            if (this.packageItem.name == "smallCard") {
                cardSize = "m";
            } else if (this.packageItem.name == "middleCard") {
                cardSize = "m";
            } else if (this.packageItem.name == "middleCardBig") {
                cardSize = "b";
            } else if (this.packageItem.name == "bigCard") {
                cardSize = "b";
            }
            let width = cardImg.width;
            let height = cardImg.height;
            let obj = this;
            //console.log(`cardSize=${cardSize} ${this._cardObj.icon}`);
            CardImgTextureMgr.inst.fetchTexture(this._cardObj.icon, this._cardObj.skin, isLocked ? "u" : cardSize, (icon, texture, url)=>{
                if (obj._cardObj.icon != icon) {
                    return;
                }
                cardImg.texture = texture;
                cardImg.width = width;
                cardImg.height = height;
                obj._imgUrl = url;
            });
            this._cardImg.blendMode = egret.BlendMode.NORMAL;
        }

        public setEquip() {
            if (!this._equipBtn) {
                return;
            }
            if (!Home.FunctionMgr.inst.isEquipOpen()) {
                return;
            }
            if (this._cardObj.equip && this._cardObj.equip != "" ) {
                this._equipBtn.visible = true;
                this._equipBtn.getChild("icon").asLoader.url = Equip.EquipMgr.inst.getEquipData(this._cardObj.equip).equipIconSmall;
            } else {
                this._equipBtn.visible = false;
                this._equipBtn.icon = "";
            }
            // let icon = this._equipBtn.getChild("icon").asLoader;
            // let mask = this._equipBtn.getChild("maskWnd").asLoader;
            // icon.displayObject.mask = mask.displayObject;
            // mask.alpha = 0;
        }
        public showEquipBtn(bool: boolean) {
            if (!this._equipBtn) {
                return;
            }
            if (!Home.FunctionMgr.inst.isEquipOpen()) {
                return;
            }
            this._equipBtn.visible = bool;
        }

        public unloadCardImg() {
            if (this._imgUrl) {
                // console.log(`destroy texture ${this._imgUrl}`);
                RES.destroyRes(this._imgUrl)
                this._imgUrl = undefined;
                if (this._cardImg && this._cardImg.texture) {
                    this._cardImg.texture.dispose();
                    this._cardImg.texture = null;
                }
            }
        }

        public setLockCardImg() {
            this.setCardImg(true);
	        this._nameText.text = "?";
        }

        public setBackImg(resUrl:string="cards_opponent2_s_png") {
            let width = this._cardImg.width;
            let height = this._cardImg.height;
            RES.getResAsync(resUrl).then(texture => {
                this._cardImg.texture = texture;
                this._cardImg.width = width;
                this._cardImg.height = height;
            })
        }

        public setOwnBackImg() {
            this.setBackImg("cards_opponent1_s_png")
        }

        public setWhile() {
            if (this._blackMask && this._blackMask.parent) {
                this._blackMask.removeFromParent();
            }
            this._cardImg.filters = [];
            this._baseImg.filters = [];
        }

        public setGrey() {
            if (this._blackMask && this._blackMask.parent) {
                this._blackMask.removeFromParent();
            }
            let colorMatrix = [
                0.3,0.6,0,0,0,
                0.3,0.6,0,0,0,
                0.3,0.6,0,0,0,
                0,0,0,1,0
            ];
            let colorFlilter = new egret.ColorMatrixFilter(colorMatrix);
            this._cardImg.filters = [colorFlilter];
            //this._baseImg.filters = [colorFlilter];
        }

        public setBlack() {
            this._cardImg.filters = [];
            this._baseImg.filters = [];
            if (!this._blackMask) {
                this._blackMask = new fairygui.GGraph();
                this._blackMask.width = this.width;
                this._blackMask.height = this.height;
                this._blackMask.drawRect(0, Core.TextColors.black, 0, Core.TextColors.black, 0.5, [7]);
            }
            if (!this._blackMask.parent) {
                this.addChild(this._blackMask);
            }
        }

        public setNumText(visible: boolean = true) {
            if (this._isQualityMode) {
                visible = false;
            }
            if (visible) {
                this._upNum.getChild("value").asTextField.text = this._cardObj.upNum.toString();
                this._downNum.getChild("value").asTextField.text = this._cardObj.downNum.toString();
                this._leftNum.getChild("value").asTextField.text = this._cardObj.leftNum.toString();
                this._rightNum.getChild("value").asTextField.text = this._cardObj.rightNum.toString();
            }
            this._upNum.visible = visible;
            this._downNum.visible = visible;
            this._leftNum.visible = visible;
            this._rightNum.visible = visible;
        }

        private _setOneNumOffsetText(textField:fairygui.GTextField, value:number, isRight:boolean) {
            textField.visible = true;
            if (value <= 0) {
                textField.visible = false;
            } else if (value == 1) {
                textField.text = "+";
            } else if (isRight) {
                textField.text = value + "+";
            } else {
                textField.text = "+" + value;
            }
        }

        public setNumOffsetText(visible: boolean = true) {
            if (this._isQualityMode) {
                visible = false;
            }
            if (visible) {
                this._setOneNumOffsetText(this._upNumOffset, this._cardObj.upNumOffset, false);
                this._setOneNumOffsetText(this._downNumOffset, this._cardObj.downNumOffset, false);
                this._setOneNumOffsetText(this._leftNumOffset, this._cardObj.leftNumOffset, false);
                this._setOneNumOffsetText(this._rightNumOffset, this._cardObj.rightNumOffset, true);
            } else {
                this._upNumOffset.visible = false;
                this._downNumOffset.visible = false;
                this._leftNumOffset.visible = false;
                this._rightNumOffset.visible = false;
            }
        }

        public setName() {
            this._nameText.visible = true;
            this._nameText.text = this._cardObj.name;
            this._nameImg.visible = true;

            if (!LanguageMgr.inst.isChineseLocale()) {
                let wnd = this.getChild("levelFlagWnd");
                if (wnd) {
                    let flagWnd = wnd.asLoader;
                    flagWnd.visible = true;
                    flagWnd.alpha = 1;
                    let gcardId = this._cardObj.gcardId;
                    let conf = Data.pool.get(gcardId);
                    let level = conf.level;
                    let rare = this._cardObj.rare;
                    if (rare == CardQuality.LIMITED) {
                        flagWnd.url = "cards_levelFlagLimited_png";
                    } else {
                        flagWnd.url = `cards_levelFlag${level}_png`;
                    }
                }
            }
        }

        public hideName() {
            this._nameText.visible = false;
            this._nameImg.visible = false;
        }

        public setSkill() {
            this.setSkillByName(this._cardObj.skill1Name, this._cardObj.skill2Name,
                this._cardObj.skill3Name, this._cardObj.skill4Name);
        }

        public hideSkill() {
            this._skill1Text.visible = false;
            this._skill1Bottom.visible = false;
            this._skill2Text.visible = false;
            this._skill2Bottom.visible = false;
            this._skill3Text.visible = false;
            this._skill3Bottom.visible = false;
            this._skill4Text.visible = false;
            this._skill4Bottom.visible = false;
        }

        private _adjustWidgetByLocale() {
            if (LanguageMgr.inst.isChineseLocale()) {
                return;
            }

            // this._skill1Text.align = fairygui.AlignType.Left;
            // this._skill2Text.align = fairygui.AlignType.Left;
            // this._skill3Text.align = fairygui.AlignType.Left;
            // this._skill4Text.align = fairygui.AlignType.Left;

            // this._skill1Text.autoSize = fairygui.AutoSizeType.Shrink;
            // this._skill2Text.autoSize = fairygui.AutoSizeType.Shrink;
            // this._skill3Text.autoSize = fairygui.AutoSizeType.Shrink;
            // this._skill4Text.autoSize = fairygui.AutoSizeType.Shrink;

            // this._skill1Text.minShrinkSize = 8;
            // this._skill2Text.minShrinkSize = 8;
            // this._skill3Text.minShrinkSize = 8;
            // this._skill4Text.minShrinkSize = 8;

            let a = 0.65
            this._skill1Bottom.alpha = a;
            this._skill2Bottom.alpha = a;
            this._skill3Bottom.alpha = a;
            this._skill4Bottom.alpha = a;

            if (this.packageItem.name == "smallCard") {
                this._skill1Bottom.setSize(44, 18);
                this._skill2Bottom.setSize(44, 18);
                this._skill3Bottom.setSize(44, 18);
                this._skill4Bottom.setSize(44, 18);
                
                this._skill1Bottom.setXY(22, 21);
                this._skill2Bottom.setXY(22, 40);
                this._skill3Bottom.setXY(22, 59);
                this._skill4Bottom.setXY(22, 78);

                this._skill1Text.fontSize = 8;
                this._skill2Text.fontSize = 8;
                this._skill3Text.fontSize = 8;
                this._skill4Text.fontSize = 8;

                let skillGroup = this.getChild("skillGroup").asGroup;
                skillGroup.x = 22;
                skillGroup.y = 21;
                skillGroup.width = 44;
                skillGroup.height = 75;
                this._skillStartPos = skillGroup.x;
                this._skillStartPosY = skillGroup.y;
                this._skillAreaWidth = skillGroup.width;
                this._skillAreaHeight = skillGroup.height;
                this._skillUnitWidth = this._skill1Bottom.width;
                this._skillUnitHeight = this._skill1Bottom.height
                this._nameImg.visible = false;
                this._nameImg.alpha = 0;
                this._nameText.visible = false;
                this._nameText.alpha = 0;
            } else if (this.packageItem.name == "middleCard") {
                this._skill1Bottom.setSize(66, 20);
                this._skill2Bottom.setSize(66, 20);
                this._skill3Bottom.setSize(66, 20);
                this._skill4Bottom.setSize(66, 20);

                this._skill1Bottom.setXY(29, 49);
                this._skill2Bottom.setXY(29, 71);
                this._skill3Bottom.setXY(29, 93);
                this._skill4Bottom.setXY(29, 115);

                this._skill1Text.fontSize = 10;
                this._skill2Text.fontSize = 10;
                this._skill3Text.fontSize = 10;
                this._skill4Text.fontSize = 10;

                let skillGroup = this.getChild("skillGroup").asGroup;
                skillGroup.x = 29;
                skillGroup.y = 49;
                skillGroup.width = 66;
                skillGroup.height = 86;
                this._skillStartPos = skillGroup.x;
                this._skillStartPosY = skillGroup.y;
                this._skillAreaWidth = skillGroup.width;
                this._skillAreaHeight = skillGroup.height;
                this._skillUnitWidth = this._skill1Bottom.width;
                this._skillUnitHeight = this._skill1Bottom.height
                this._nameImg.visible = false;
                this._nameImg.alpha = 0;
                this._nameText.visible = false;
                this._nameText.alpha = 0;
            } else if (this.packageItem.name == "middleCardBig") {
                // this._skill1Bottom.setSize(96, 22);
                // this._skill2Bottom.setSize(96, 22);
                // this._skill3Bottom.setSize(96, 22);
                // this._skill4Bottom.setSize(96, 22);

                // this._skill1Bottom.setXY(48, 98);
                // this._skill2Bottom.setXY(48, 127);
                // this._skill3Bottom.setXY(48, 156);
                // this._skill4Bottom.setXY(48, 185);

                // this._skill1Text.fontSize = 10;
                // this._skill2Text.fontSize = 10;
                // this._skill3Text.fontSize = 10;
                // this._skill4Text.fontSize = 10;

                // let skillGroup = this.getChild("skillGroup").asGroup;
                // skillGroup.x = 48;
                // skillGroup.y = 98;
                // skillGroup.width = 96;
                // skillGroup.height = 109;
                // this._skillStartPos = skillGroup.x;
                // this._skillStartPosY = skillGroup.y;
                // this._skillAreaWidth = skillGroup.width;
                // this._skillAreaHeight = skillGroup.height;
                // this._skillUnitWidth = this._skill1Bottom.width;
                // this._skillUnitHeight = this._skill1Bottom.height;
                this._skill1Bottom.alpha = 0;
                this._skill2Bottom.alpha = 0;
                this._skill3Bottom.alpha = 0;
                this._skill4Bottom.alpha = 0;

                this._skill1Text.alpha = 0;
                this._skill2Text.alpha = 0;
                this._skill3Text.alpha = 0;
                this._skill4Text.alpha = 0;

                this._nameImg.visible = true;
                this._nameImg.alpha = 1;
                this._nameText.visible = true;
                this._nameText.alpha = 1;
                this._nameImg.setXY(39, 171);
                this._nameImg.setSize(114, 30);
                this._nameText.setXY(39, 171);
                this._nameText.setSize(114, 30);
                this._nameText.autoSize = fairygui.AutoSizeType.Shrink;
                // this._nameText.fontSize = 15;
                // this._nameText.setXY(120, 0);
                // this._nameText.setSize(72, 30);
            }
        }

        private _filterSkillNameByLocale(skillName: string): string {
            if (LanguageMgr.inst.isChineseLocale()) {
                return skillName;
            } else {
                return skillName; //skillName.substr(0, 4) + "...";
            }
        }

        public setSkillByName(skill1Name:string, skill2Name:string, skill3Name:string, skill4Name:string) {
            if (this._isBriefMode) {
                return;
            }
            let skillCnt = 0;
            let visibleSkill = function(skillText: fairygui.GTextField, skillBottom: fairygui.GLoader, visible: boolean) {
                skillText.visible = visible;
                skillBottom.visible = visible;
            }
            let handleSkill = (skillText: fairygui.GTextField, skillBottom: fairygui.GLoader, skillName: string) => {
                if (skillName && skillName != "") {
                    skillCnt += 1;
                    skillText.text = this._filterSkillNameByLocale(skillName);
                    visibleSkill(skillText, skillBottom, true);
                }
                else {
                    visibleSkill(skillText, skillBottom, false);
                }
            }
            let setSkillPos = function(skillBottom: fairygui.GLoader, x: number, y?: number) {
                skillBottom.x = Math.round(x);
                if (!isNaN(y)) {
                    skillBottom.y = Math.round(y);
                }
            }
            handleSkill(this._skill1Text, this._skill1Bottom, skill1Name);
            handleSkill(this._skill2Text, this._skill2Bottom, skill2Name);
            handleSkill(this._skill3Text, this._skill3Bottom, skill3Name);
            handleSkill(this._skill4Text, this._skill4Bottom, skill4Name);
            if (skillCnt == 1) {
                let x = 0;
                let y = NaN;
                if (LanguageMgr.inst.isChineseLocale()) {
                    x = (this._skillAreaWidth - this._skillUnitWidth) / 2 + this._skillStartPos;
                } else {
                    x = this._skillStartPos;
                    y = this._skillStartPosY + this._skillAreaHeight - this._skillUnitHeight;
                }
                setSkillPos(this._skill1Bottom, x, y);
            } else if (skillCnt == 2) {
                if (LanguageMgr.inst.isChineseLocale()) {
                    let gap = (this._skillAreaWidth - this._skillUnitWidth * 2) / 3;
                    setSkillPos(this._skill1Bottom, gap + this._skillStartPos);
                    setSkillPos(this._skill2Bottom, 2 * gap + this._skillUnitWidth + this._skillStartPos);
                } else {
                    let gapY = (this._skillAreaHeight - this._skillUnitHeight * 4)/3;
                    let x = this._skillStartPos;
                    let y = this._skillStartPosY + 2 * (this._skillUnitHeight + gapY);
                    setSkillPos(this._skill1Bottom, x, y);
                    setSkillPos(this._skill2Bottom, x, y + this._skillUnitHeight + gapY);
                }
            } else if (skillCnt == 3) {
                if (LanguageMgr.inst.isChineseLocale()) {
                    let gap = (this._skillAreaWidth - this._skillUnitWidth * 3) / 4;
                    setSkillPos(this._skill1Bottom, gap + this._skillStartPos);
                    setSkillPos(this._skill2Bottom, 2 * gap + this._skillUnitWidth + this._skillStartPos);
                    setSkillPos(this._skill3Bottom, 3 * gap + 2 * this._skillUnitWidth + this._skillStartPos);
                } else {
                    let gapY = (this._skillAreaHeight - this._skillUnitHeight * 4)/3;
                    let x = this._skillStartPos;
                    let y = this._skillStartPosY + (this._skillUnitHeight + gapY);
                    setSkillPos(this._skill1Bottom, x, y);
                    setSkillPos(this._skill2Bottom, x, y + gapY + this._skillUnitHeight);
                    setSkillPos(this._skill3Bottom, x, y + 2*(gapY + this._skillUnitHeight));
                }
            } else if (skillCnt == 4) {
                if (LanguageMgr.inst.isChineseLocale()) {
                    let gap = (this._skillAreaWidth - this._skillUnitWidth * 4) / 5;
                    setSkillPos(this._skill1Bottom, gap + this._skillStartPos);
                    setSkillPos(this._skill2Bottom, 2 * gap + this._skillUnitWidth + this._skillStartPos);
                    setSkillPos(this._skill3Bottom, 3 * gap + 2 * this._skillUnitWidth + this._skillStartPos);
                    setSkillPos(this._skill4Bottom, 4 * gap + 3 * this._skillUnitWidth + this._skillStartPos);
                } else {
                    let gapY = (this._skillAreaHeight - this._skillUnitHeight * 4)/3;
                    let x = this._skillStartPos;
                    let y = this._skillStartPosY;
                    setSkillPos(this._skill1Bottom, x, y);
                    setSkillPos(this._skill2Bottom, x, y + gapY + this._skillUnitHeight);
                    setSkillPos(this._skill3Bottom, x, y + 2*(gapY + this._skillUnitHeight));
                    setSkillPos(this._skill4Bottom, x, y + 3*(gapY + this._skillUnitHeight));
                }
            }
        }

        public setLockNameAndSkill(b: boolean) {
            this._nameText.visible = b;
            this._nameText.text = this._cardObj.name;
            this._skill1Text.visible = !b;
            this._skill1Bottom.visible = !b;
            this._skill2Text.visible = !b;
            this._skill2Bottom.visible = !b;
            this._skill3Text.visible = !b;
            this._skill3Bottom.visible = !b;
            this._skill4Text.visible = !b;
            this._skill4Bottom.visible = !b;
            //this._skill1Text.text = "?";
        }

        public visibleLightCircle(visible:boolean) {
            if (this._lightCircle) {
                this._lightCircle.visible = visible;
            }
        }

        public visibleRareStars(visible:boolean) {
            if (this._rareCom) {
                this._rareCom.visible = visible;
                this._rareCom.setRare(this._cardObj.rare);
            }
        }

        public watchProp(prop:string, callback:(value:any)=>void, thisArg:any) {
            let collectCardObj = this._cardObj.collectCard;
            if (!collectCardObj) {
                return;
            }
            if (this._cardObjWatchers.containsKey(prop)) {
                return;
            }
            this._cardObjWatchers.setValue( prop, Core.Binding.bindHandler(collectCardObj, [prop], callback, thisArg) )
        }

        public unwatchProp(prop:string) {
            let watcher = this._cardObjWatchers.getValue(prop);
            if (watcher) {
                watcher.unwatch();
                this._cardObjWatchers.remove(prop);
            }
        }

        public watchLevel() {
            this.watchProp(CardPool.Card.PropLevel, this._onPropLevelChange, this);
        }

        private _onPropLevelChange() {
            this.setName();
            this.setSkill();
            this.setNumText();
            this.setNumOffsetText();
        }

        public unwatchLevel() {
            this.unwatchProp(CardPool.Card.PropLevel);
        }

        public watchSkin() {
            this.watchProp(CardPool.Card.PropSkin, this._onPropSkinChange, this);
        }

        private _onPropSkinChange() {
            this.setCardImg();
        }

        public unwatchSkin() {
            this.unwatchProp(CardPool.Card.PropSkin);
        }

        public watchEquip() {
            this.watchProp(CardPool.Card.PropEquip, this._onPropEquipChange, this);
        }
        public unwatchEquip() {
            this.unwatchProp(CardPool.Card.PropEquip);
        }

        private _onPropEquipChange() {
            this.setEquip();
        }

        public watch() {
            this.watchLevel();
            this.watchSkin();
            this.watchEquip();
        }

        public unwatch() {
            this.unwatchLevel();
            this.unwatchSkin();
            this.unwatchEquip();
        }
    }

}
