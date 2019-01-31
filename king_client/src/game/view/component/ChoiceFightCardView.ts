module UI {

    /**
     *  卡组： 阵营 + 群雄 + diy  死灰，diy无条
     *  关卡： 所有阵营  死灰，非提供黑，无精力条
     *  战役： 阵营 + 群雄 - 死 - 非当前阵营出征 - 非当前阵营守将
     */

    export interface IChoiceCardCtrl {
        getCamps(): Array<Camp>
        getTitleCamps(): Array<Camp>
        needDiyCard(): boolean
        //getForbidCards(): Collection.Set<number> // {cardId, ...}
        getChoiceCard(): Array<ICardObj>  // [null, null, card, null, card]
        //getProviderCard(): Collection.Dictionary<number, ICardObj>  // {cardId: ICardObj}
        getMinAmount(): number
        getMaxAmount(): number
        visableCampaign(): boolean
        needEnergyProgress(): boolean
        needExpProgress(): boolean
        getCardState(ICardObj): string   // normal, forbid, guard, attack, hide
        onConfirm(choiceCard: Array<ICardObj>, forageAmount:number): Promise<boolean>
    }

    export class ChoiceFightCardView extends Core.BaseView {
        private _cardList: fairygui.GList;
        private _forAmountLabel: fairygui.GLabel;
        private _forSubBtn: fairygui.GButton;
        private _forAddBtn: fairygui.GButton;
        private _title: fairygui.GTextField;

        private _text1: fairygui.GTextField;
        private _text2: fairygui.GTextField;
        private _text3: fairygui.GTextField;
        private _img1: fairygui.GLoader;
        private _text4: fairygui.GTextField;

        private _choiceCardCtrl: IChoiceCardCtrl;
        private _choiceCard: Array<ICardObj>;
        private _oldChoiceCards: Array<ICardObj>;
        private _handCardGrid: HandCardGrid;
        private _forAmount: number;

        private _renderCardExecutor: Core.FrameExecutor;

        public initUI(): void {
            super.initUI();
            this.adjust(this.getChild("bg"), Core.AdjustType.EXCEPT_MARGIN);
            this.y += window.support.topMargin;

            this._forAmount = 0;
            this._choiceCard = [null, null, null, null, null];
            this._cardList = this.getChild("cardList").asList;
            this._cardList.itemClass = ChoiceCardItem;
            this._cardList.removeItemCallback = this._onRemoveCardItem;
            this._forAmountLabel = this.getChild("forAmountLabel").asLabel;
            this._forAmountLabel.visible = false;
            this._forAmountLabel.getChild("title").asTextField.textParser = Core.StringUtils.parseColorText;
            this._forAmountLabel.title = this._forAmount.toString();
            this._title = this.getChild("title").asTextField;
            this._title.textParser = Core.StringUtils.parseColorText;
            this._forSubBtn = this.getChild("forSubBtn").asButton;
            this._forAddBtn = this.getChild("forAddBtn").asButton;
            this._text1 = this.getChild("text1").asTextField;
            this._text2 = this.getChild("text2").asTextField;
            this._text3 = this.getChild("text3").asTextField;
            this._img1 = this.getChild("img1").asLoader;
            this._text4 = this.getChild("text4").asTextField;

            this.getChild("backBtn").asButton.addClickListener(this._onBack, this);
            this.getChild("confirmBtn").asButton.addClickListener(this._onConfirm, this);
            this._cardList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickItem, this);
            this._forAddBtn.addClickListener(this._onAddFor, this);
            this._forSubBtn.addClickListener(this._onSubFor, this);
        }

        public async open(...param:any[]) {
            super.open(...param);
            this._choiceCardCtrl = param[0];
            if (param.length > 1) {
                this._handCardGrid = param[1];
            } else {
                this._handCardGrid = null;
            }
            this._visableCampaign( this._choiceCardCtrl.visableCampaign() );
            this._updateForAmountLabel();
            this._oldChoiceCards = this._choiceCardCtrl.getChoiceCard();
            this._choiceCard = this._oldChoiceCards.concat();
            this._setTitle();
            this._renderCardList( this._getAllCardObjs() );
        }

        public async close(...param:any[]) {
            super.close(...param);
            this._renderCardExecutor.cancel();
            this._renderCardExecutor = null;
            this._cardList.removeChildrenToPool();
            this._choiceCardCtrl = null;
            this._choiceCard = null;
            this._oldChoiceCards = null;
            this._handCardGrid = null;
        }

        private _setTitle() {
            let campsText = "";
            let campColor = new Collection.Dictionary<Camp, string>();
            campColor.setValue(Camp.WEI, "0000ff");
            campColor.setValue(Camp.SHU, "cc0000");
            campColor.setValue(Camp.WU, "006633");
            campColor.setValue(Camp.HEROS, "6633ff");
            this._choiceCardCtrl.getTitleCamps().forEach(c => {
                if (campsText != "") {
                    if (LanguageMgr.inst.isChineseLocale()) {
                        campsText += Core.StringUtils.TEXT(60007);
                    } else {
                        campsText +=  " " + Core.StringUtils.TEXT(60007) + " ";
                    }
                } 
                campsText += `#c${campColor.getValue(c)}${Utils.camp2Text(c)}#n`;
            })
            this._title.text = Core.StringUtils.format(Core.StringUtils.TEXT(60187), campsText, this._getChoiceCardAmount(), this._choiceCardCtrl.getMaxAmount());
        }

        private _getAllCardObjs(): Array<ICardObj> {
            let camps = this._choiceCardCtrl.getCamps();
            let campsCardObjs: Array<ICardObj> = [];
            camps.forEach(c => {
                let cardObjs = CardPool.CardPoolMgr.inst.getCollectCardsByCamp(c);
                for (let obj of cardObjs) {
                    if (obj.state == CardPool.CardState.Lock || obj.state == CardPool.CardState.Unlock) {
                        continue;
                    }
                    let _state = this._choiceCardCtrl.getCardState(obj);
                    if (_state == BaseCardItem.HideState) {
                        continue;
                    }
                    campsCardObjs.push(obj);
                }
                //campsCardObjs.push(...CardPool.CardPoolMgr.inst.getCollectCardsByCamp(c));
            });
            if (this._choiceCardCtrl.needDiyCard()) {
                campsCardObjs.push( ...Diy.DiyMgr.inst.getAllCards() );
            }
            
            campsCardObjs.sort((a, b):number => {
                let p1 = this._getCardStatePriority(a);
                let p2 = this._getCardStatePriority(b);
                if (p1 == p2) {
                    let aCardData = CardPool.CardPoolMgr.inst.getCardData(a.cardId, 1);
                    let bCardData = CardPool.CardPoolMgr.inst.getCardData(b.cardId, 1);
                    if (!aCardData || !bCardData) {
                        return a.cardId > b.cardId? 1 : -1;
                    }
                    if (aCardData.camp == bCardData.camp) {
                        return aCardData.cardOrder > bCardData.cardOrder? 1 : -1;
                    }
                    return aCardData.camp > bCardData.camp? 1 : -1;
                } else {
                    return p1 > p2 ? 1 : -1;
                }
            })
            return campsCardObjs;
        }

        private _renderCardFrame(cardObjs:Array<ICardObj>) {
            cardObjs.forEach(obj => {
                let _state = this._choiceCardCtrl.getCardState(obj);
                let cardItem = this._cardList.addItemFromPool() as ChoiceCardItem;
                cardItem.state = _state;
                cardItem.setData(obj, this._choiceCardCtrl.needEnergyProgress(), this._choiceCardCtrl.needExpProgress());
                cardItem.watch();
                cardItem.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchItem, this);
                let idx = this._oldChoiceCards.indexOf(obj);
                if (idx >= 0) {
                    cardItem.selected = true;
                } else {
                    cardItem.selected = false;
                }
            })
        }

        private _renderCardList(allCardObjs:Array<ICardObj>) {
            this._renderCardExecutor = new Core.FrameExecutor();
            let index = 0;
            let step = 5;
            while (allCardObjs.length > index) {
                let cardObjs = allCardObjs.slice(index, index + step);
                this._renderCardExecutor.regist(this._renderCardFrame, this, cardObjs);
                index += step;
            }
            this._renderCardExecutor.execute();
        }

        private _getCardStatePriority(cardObj:ICardObj): number {
            if (this._oldChoiceCards.indexOf(cardObj) >= 0) {
                return 0;
            }
            if (cardObj.state == CardPool.CardState.Dead) {
                return 5;
            }
            let _state = this._choiceCardCtrl.getCardState(cardObj);
            switch (_state) {
            case BaseCardItem.NormalState:
                return 1;
            case BaseCardItem.ForbidState:
                return 2;
            case BaseCardItem.AttackState:
                return 3;
            case BaseCardItem.GuardState:
                return 4;
            default:
                return 5;
            }
        }

        private _onRemoveCardItem(cardItem:fairygui.GObject) {
            if (cardItem instanceof ChoiceCardItem) {
                let item = cardItem as ChoiceCardItem;
                item.unwatch();
                item.removeEventListener(egret.TouchEvent.TOUCH_BEGIN, this._onTouchItem, this);
            }
        }

        private _onAddFor() {
            this._forAmount += 1;
            this._updateForAmountLabel();
        }

        private _onSubFor() {
            if (this._forAmount <= 0) {
                return;
            }
            this._forAmount -= 1;
            this._updateForAmountLabel();
        }

        private _updateForAmountLabel() {
            if (this._forAmount <= 0) {
                this._forAmountLabel.title = `#cr0#n/${Player.inst.getResource(ResType.T_FORAGE)}`;
            } else {
                this._forAmountLabel.title = `${this._forAmount}/${Player.inst.getResource(ResType.T_FORAGE)}`;
            }
        }

        private _getChoiceCardAmount(): number {
            let n = 0;
            this._choiceCard.forEach(c => {
                if (c) {
                    n++;
                }
            })
            return n;
        }

        private _onTouchItem(evt: egret.TouchEvent) {
            let item = evt.target as ChoiceCardItem;
            item["$touchBegin"] = true;
            let x = fairygui.GRoot.mouseX;
            let y = fairygui.GRoot.mouseY;
            fairygui.GTimers.inst.callDelay(600, ()=>{
                if (Math.abs(fairygui.GRoot.mouseX - x) > 15 || Math.abs(fairygui.GRoot.mouseY - y) > 20) {
                    return;
                }
                if (item["$touchBegin"]) {
                    Core.ViewManager.inst.open(ViewName.cardInfo, item.cardObj.collectCard);
                }
            }, this);
        }

        private _onClickItem(evt:fairygui.ItemEvent) {
            let item = evt.itemObject as ChoiceCardItem;
            item["$touchBegin"] = null;
            if (Core.ViewManager.inst.getView(ViewName.cardInfo) && Core.ViewManager.inst.getView(ViewName.cardInfo).isShow()) {
                return;
            }

            if (item.cardObj.state == CardPool.CardState.Dead || item.state != BaseCardItem.NormalState) {
                return;
            }

            let selected = !item.selected;
            if (selected) {
                if (this._choiceCard.indexOf(item.cardObj) < 0 && this._getChoiceCardAmount() < this._choiceCardCtrl.getMaxAmount()) {
                    for (let i=0; i<this._choiceCard.length; i++) {
                        if (!this._choiceCard[i]) {
                            this._choiceCard[i] = item.cardObj;
                            this._setTitle();
                            item.selected = selected;
                            break;
                        }
                    }
                }
            } else {
                for (let i=0; i<this._choiceCard.length; i++) {
                    if (this._choiceCard[i] == item.cardObj) {
                        this._choiceCard[i] = null;
                        item.selected = selected;
                        this._setTitle();
                        break;
                    }
                }
            }
        }

        private _visableCampaign(visable:boolean) {
            this._forAmountLabel.visible = visable;
            this._forSubBtn.visible = visable;
            this._forAddBtn.visible = visable;
            this._text1.visible = visable;
            this._text2.visible = visable;
            this._text3.visible = visable;
            this._img1.visible = visable;
            this._text4.visible = !visable;

            if (visable && this._forAmount <= 0) {
                this._forAmount = 3;
                this._updateForAmountLabel();
            }
        }

        private _onBack() {
            Core.ViewManager.inst.closeView(this);
        }

        private async _onConfirm() {
            if (this._getChoiceCardAmount() < this._choiceCardCtrl.getMinAmount()) {
                let hint = Core.StringUtils.format(Core.StringUtils.TEXT(60158), this._choiceCardCtrl.getMinAmount())
                Core.TipsUtils.showTipsFromCenter(hint);
                return;
            }

            if (this._choiceCardCtrl.visableCampaign() && this._forAmount > Player.inst.getResource(ResType.T_FORAGE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60148));
                return;
            }

            let isChoiceChange = false;
            for (let i=0; i<this._choiceCard.length; i++) {
                if (this._choiceCard[i] != this._oldChoiceCards[i]) {
                    isChoiceChange = true;
                    break;
                }
            }

            if (isChoiceChange) {
                let ok = await this._choiceCardCtrl.onConfirm(this._choiceCard, this._forAmount);
                if (!ok) {
                    return;
                } else {
                    if(this._handCardGrid) {
                        this._handCardGrid.refresh();
                    }
                }
            } else {
                let ok = await this._choiceCardCtrl.onConfirm(this._choiceCard, this._forAmount);
                if(!ok) {
                    return;
                }
            }
            Core.ViewManager.inst.closeView(this);
        }

        public getNode(nodeName:string): fairygui.GObject {
            let nameArgs = nodeName.split(":");
            if (nameArgs[0] == "cardEnergyBar") {
                if (this._cardList) {
                    let cardItem = this._cardList.getChildAt(parseInt(nameArgs[1]));
                    if (cardItem && cardItem instanceof ChoiceCardItem) {
                        this._cardList.ensureBoundsCorrect();
                        return (<ChoiceCardItem>cardItem).energyProgressBar;
                    }
                }
                return null
            } else if (nameArgs[0] == "cardItem") {
                let cardItem = this._cardList.getChildAt(parseInt(nameArgs[1]));
                this._cardList.ensureBoundsCorrect();
                let node = new fairygui.GGraph();
                node.width = cardItem.width;
                node.height = cardItem.height;
                node.drawRect(0, Core.TextColors.white, 0, Core.TextColors.white, 0);
                node.x = cardItem.x + this._cardList.x + 5;
                node.y = cardItem.y + this._cardList.y;
                this.addChildAt(node, 0);

                node.once(egret.TouchEvent.TOUCH_TAP, ()=>{
                    node.removeFromParent();
                    cardItem.dispatchEventWith(egret.TouchEvent.TOUCH_TAP);
                }, this);
                return node;
            } else {
                return super.getNode(nodeName);
            }
        }
    }

}
