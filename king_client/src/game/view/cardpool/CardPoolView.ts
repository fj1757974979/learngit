module CardPool {

    export class CardPoolView extends Core.BaseView {
        private _backBtn: fairygui.GButton;
        private _weiPool: fairygui.GList;
        private _shuPool: fairygui.GList;
        private _wuPool: fairygui.GList;
        private _qunPool: fairygui.GList;
        private _campTapCtrl: fairygui.Controller;
        //private _tapList: fairygui.GList;
        private _listx: number;
        private _listy: number;

        private _weiTapBtn: fairygui.GButton;
        private _shuTapBtn: fairygui.GButton;
        private _wuTapBtn: fairygui.GButton;
        private _qunTapBtn: fairygui.GButton;
        private _skillFaqBtn: fairygui.GButton;
        private _equipBagBtn: fairygui.GButton;
        private _pvpLevel: number;
        private _cardItems: Array<CardItem>;

        private _poolRenderExecutor: Core.FrameExecutor;

        public initUI() {
            super.initUI();
            // this.y += Utils.getResolutionDistance() * 0.3;
            this.height += Utils.getResolutionDistance();
            //this.adjust(this.getChild("bg"));
/*            let cardInfoWnd = new CardInfoWnd();
            cardInfoWnd.contentPane = fairygui.UIPackage.createObject(PkgName.cardpool, ViewName.cardInfo).asCom;
            Core.ViewManager.inst.register(ViewName.cardInfo, cardInfoWnd);*/

            //this._backBtn = this.getChild("backBtn").asButton;
            //let tapList = this.getChild("tapList").asList;
            this._weiPool = this.getChild("wei").asCom.getChild("cardList").asList;
            this._shuPool = this.getChild("shu").asCom.getChild("cardList").asList;
            this._wuPool = this.getChild("wu").asCom.getChild("cardList").asList;
            this._weiPool.height += Utils.getResolutionDistance();
            this._shuPool.height += Utils.getResolutionDistance();
            this._wuPool.height += Utils.getResolutionDistance();

            let _qunTapItem = this.getChild("qun").asCom;
            this._qunPool = _qunTapItem.getChild("cardList").asList;
            // this._qunPool.height += Utils.getResolutionDistance();

            _qunTapItem.getChild("qunTips").visible = true;
            this._campTapCtrl = this.getController("campTap");
            //this._tapList = this.getChild("tapList").asList;
            this._listx = this.getChild("wei").asCom.x;
            this._listy = this.getChild("wei").asCom.y;

            this._weiPool.scrollItemToViewOnClick = true;
            this._shuPool.scrollItemToViewOnClick = true;
            this._wuPool.scrollItemToViewOnClick = true;
            this._qunPool.scrollItemToViewOnClick = true;

            //this._weiPool.setVirtual();
            //this._shuPool.setVirtual();
            //this._wuPool.setVirtual();
            //this._qunPool.setVirtual();

            this._weiPool.itemClass = CardItem;
            // this._weiPool.itemRenderer = this._weiRenderList;
            // this._weiPool.callbackThisObj = this;
            this._shuPool.itemClass = CardItem;
            // this._shuPool.itemRenderer = this._shuRenderList;
            // this._shuPool.callbackThisObj = this;
            this._wuPool.itemClass = CardItem;
            // this._wuPool.itemRenderer = this._wuRenderList;
            // this._wuPool.callbackThisObj = this;
            this._qunPool.itemClass = CardItem;
            // this._qunPool.itemRenderer = this._qunRenderList;
            // this._qunPool.callbackThisObj = this;

            this._weiTapBtn = this.getChild("weiTapBtn").asButton;
            (<CardPool.CardNumHintCom>this._weiTapBtn.getChild("cardNumHint").asCom).observeCampCardNum(Camp.WEI);
            this._shuTapBtn = this.getChild("shuTapBtn").asButton;
            (<CardPool.CardNumHintCom>this._shuTapBtn.getChild("cardNumHint").asCom).observeCampCardNum(Camp.SHU);
            this._wuTapBtn = this.getChild("wuTapBtn").asButton;
            (<CardPool.CardNumHintCom>this._wuTapBtn.getChild("cardNumHint").asCom).observeCampCardNum(Camp.WU);
            this._qunTapBtn = this.getChild("qunTapBtn").asButton;
            (<CardPool.CardNumHintCom>this._qunTapBtn.getChild("cardNumHint").asCom).observeCampCardNum(Camp.HEROS);
            this._skillFaqBtn = this.getChild("faqBtn").asButton;
            this._skillFaqBtn.addClickListener(() => {
                Core.ViewManager.inst.open(ViewName.skillFaq);
            }, this);
            this._skillFaqBtn.visible = Home.FunctionMgr.inst.isSkillInstructionOpen();
            this._equipBagBtn = this.getChild("equipBtn").asButton;
            this._equipBagBtn.addClickListener(() => {
                Equip.EquipMgr.inst.openEquipBagWnd();
            }, this);
            this._equipBagBtn.visible = Home.FunctionMgr.inst.isEquipOpen();

            //this._backBtn.addClickListener(this._backOnClick, this);
            this._weiPool.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardItem, this);
            this._shuPool.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardItem, this);
            this._wuPool.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardItem, this);
            this._qunPool.addEventListener(fairygui.ItemEvent.CLICK, this._onClickCardItem, this);

            this._weiTapBtn.addClickListener(this._onSelectWeiCampTap, this);
            this._shuTapBtn.addClickListener(this._onSelectShuCampTap, this);
            this._wuTapBtn.addClickListener(this._onSelectWuCampTap, this);
            this._qunTapBtn.addClickListener(this._onSelectQunCampTap, this);

            this._campTapCtrl.addAction(SoundMgr.inst.playSoundAction("page_mp3", true));

            Player.inst.addEventListener(Player.ResUpdateEvt, this._onPlayerResUpdate, this);
            this._pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
            this._cardItems = [];

            Core.EventCenter.inst.addEventListener(GameEvent.AddLimitedCardEv, this._refCampList, this);
        }

        private _onPlayerResUpdate() {
            let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
            if (pvpLevel != this._pvpLevel) {
                // 刷新所有卡对象
                for (let i=0; i<this._cardItems.length; i++) {
                    this._cardItems[i].update();
                }
                this._pvpLevel = pvpLevel;
            }
        }

        public async open(...param:any[]) {
            super.open();

            let self = this;
            let _render = function(list:fairygui.GList, camp:Camp) {
                // list.numItems = CardPoolMgr.inst.getCollectCardsByCamp(camp, false).length;
                let cards = CardPoolMgr.inst.getCollectCardsByCamp(camp, false);
                for (let i = 0; i < cards.length; ++ i) {
                    this._poolRenderExecutor.regist((card: Card) => {
                        // let cardItem = fairygui.UIPackage.createObject(PkgName.cards, "cardItem", CardItem).asCom as CardItem;
                        let cardItem = list.addItemFromPool().asCom as CardItem;
                        this._cardItems.push(cardItem);
                        cardItem.setData(card, true);
                        cardItem.watchIsNew();
                        list.addChild(cardItem);
                    }, this, cards[i]);
                }
            //     let card = cards[idx];
            // let cardItem = item as CardItem;
	        // this._cardItems.push(cardItem);
            // cardItem.setData(card, true);
            // cardItem.watchIsNew();
            }

            this._poolRenderExecutor = new Core.FrameExecutor();
            let selectedCamp = parseInt(this._campTapCtrl.selectedPage);
            this._poolRenderExecutor.regist(_render, this, this._getCardListByCamp(selectedCamp), selectedCamp);
            for(let camp of [Camp.WEI, Camp.SHU, Camp.WU, Camp.HEROS]) {
                if (camp != selectedCamp) {
                    this._poolRenderExecutor.regist(_render, this, this._getCardListByCamp(camp), camp);
                }
            }
            this._poolRenderExecutor.execute();
        }

        private async _refCampList(evt: egret.Event) {
            let camp = <Camp>evt.data;
            let list = this._getCardListByCamp(camp);
            if (list) {
                // list.numItems = 0;
                // list.numItems = CardPoolMgr.inst.getCollectCardsByCamp(camp, false).length;
                list.removeChildrenToPool();
                let cards = CardPoolMgr.inst.getCollectCardsByCamp(camp, false);
                for (let i = 0; i < cards.length; ++ i) {
                    this._poolRenderExecutor.regist((card: Card) => {
                        let cardItem = list.addItemFromPool().asCom as CardItem;
                        this._cardItems.push(cardItem);
                        cardItem.setData(card, true);
                        cardItem.watchIsNew();
                        list.addChild(cardItem);
                    }, this, cards[i]);
                }
                this._poolRenderExecutor.execute();
            }
        }

        public async close(...param:any[]) {
            super.close();
            if (this._poolRenderExecutor) {
                this._poolRenderExecutor.cancel();
                this._poolRenderExecutor = null;
            }
            // this._weiPool.numItems = 0;
            // this._shuPool.numItems = 0;
            // this._wuPool.numItems = 0;
            // this._qunPool.numItems = 0;
            this._weiPool.removeChildren();
            this._shuPool.removeChildren();
            this._wuPool.removeChildren();
            this._qunPool.removeChildren();
        }

        private _onSelectWeiCampTap() {
            //this._campTapCtrl.setSelectedPage("wei");
            //CardPoolMgr.inst.clearCardHintNumData(Camp.WEI);
        }

        private _onSelectShuCampTap() {
            //this._campTapCtrl.setSelectedPage("shu");
            //CardPoolMgr.inst.clearCardHintNumData(Camp.SHU);
        }

        private _onSelectWuCampTap() {
            //this._campTapCtrl.setSelectedPage("wu");
            //CardPoolMgr.inst.clearCardHintNumData(Camp.WU);
        }

        private _onSelectQunCampTap() {
            //CardPoolMgr.inst.clearCardHintNumData(Camp.HEROS);
        }

        public openPrevInfo(index:number) {
            //console.log("open prev");
            let cardItem = this._cardItems[index - 1];
            if (cardItem) {
                if (cardItem.cardObj.amount == 0) this.openPrevInfo(index - 1);
                else {
                    let view = Core.ViewManager.inst.getView(ViewName.cardInfo);
                    if (view) view.open(cardItem.cardObj, index - 1, true);
                }
            }
        }

        public openNextInfo(index:number) {
            //console.log("open next");
            let cardItem = this._cardItems[index + 1];
            if (cardItem) {
                if (cardItem.cardObj.amount == 0)
                    this.openNextInfo(index + 1);
                else {
                    let view = Core.ViewManager.inst.getView(ViewName.cardInfo);
                    if (view) view.open(cardItem.cardObj, index + 1, true);
                }
            }
        }

        private _onClickCardItem(evt:fairygui.ItemEvent) {
            let cardItem = evt.itemObject as CardItem;
            cardItem.cardObj.isNew = false;
            let i = this._cardItems.indexOf(cardItem);
            Core.ViewManager.inst.open(ViewName.cardInfo, cardItem.cardObj, i);
        }

        private _renderPool(camp:Camp, idx:number, item:fairygui.GObject) {
            let cards = CardPoolMgr.inst.getCollectCardsByCamp(camp, false);
            if (idx < 0 || idx >= cards.length) {
                console.debug("_renderPool error idx=%d", idx);
                return;
            }
            let card = cards[idx];
            let cardItem = item as CardItem;
	        this._cardItems.push(cardItem);
            cardItem.setData(card, true);
            cardItem.watchIsNew();
        }

        private _weiRenderList(idx:number, item:fairygui.GObject) {
            this._renderPool(Camp.WEI, idx, item);
        }

        private _shuRenderList(idx:number, item:fairygui.GObject) {
            this._renderPool(Camp.SHU, idx, item);
        }

        private _wuRenderList(idx:number, item:fairygui.GObject) {
            this._renderPool(Camp.WU, idx, item);
        }

        private _qunRenderList(idx:number, item:fairygui.GObject) {
            this._renderPool(Camp.HEROS, idx, item);
        }

        private _backOnClick() {
            Core.ViewManager.inst.open(ViewName.home);
            Core.ViewManager.inst.closeView(this);
        }

        private _getCardListByCamp(camp:Camp) {
            switch(camp) {
            case Camp.WEI:
                return this._weiPool;
            case Camp.SHU:
                return this._shuPool;
            case Camp.WU:
                return this._wuPool;
            case Camp.HEROS:
                return this._qunPool;
            default:
                return null;
            }
        }

        public getNode(nodeName:string): fairygui.GObject {
            let nameArgs = nodeName.split(":");
            if (nameArgs[0] == "cardPoolItem") {
                let cardList = this._getCardListByCamp( parseInt(this._campTapCtrl.selectedPage) );
                if (cardList) {
                    let cardItem = cardList.getChildAt(parseInt(nameArgs[1]));
                    let node = new fairygui.GGraph();
                    node.width = cardItem.width;
                    node.height = cardItem.height;
                    node.drawRect(0, Core.TextColors.white, 0, Core.TextColors.white, 0);
                    //node.x = cardItem.x + this._tapList.x + 5;
                    node.x = cardItem.x + this._listx + 5;
                    //node.y = cardItem.y + this._tapList.y;
                    node.y = cardItem.y + this._listy;
                    //this._tapList.parent.addChildAt(node, 0);
                    this.addChildAt(node, 0);

                    node.once(egret.TouchEvent.TOUCH_TAP, ()=>{
                        node.removeFromParent();
                        cardItem.dispatchEventWith(egret.TouchEvent.TOUCH_TAP);
                    }, this);
                    return node;
                }
                return null
            } else {
                return super.getNode(nodeName);
            }
        }
    }

}
