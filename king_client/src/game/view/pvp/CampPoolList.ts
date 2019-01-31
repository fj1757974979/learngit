module Pvp {

    export class CampPoolList implements UI.IHandItemBuilder {
        private _poolList: fairygui.GList;
        private _poolCtrl: fairygui.Controller;
        private _oldfightPool: FightCardPool;
        private _renderExecutor: Core.FrameExecutor;

        constructor(list:fairygui.GList, ctrl:fairygui.Controller) {
            this._poolList = list;
            this._poolCtrl = ctrl;
            this._poolCtrl.addAction(SoundMgr.inst.playSoundAction("page_mp3", true));
        }

        public get oldfightPool(): FightCardPool {
            return this._oldfightPool;
        }
        public set oldfightPool(pool:FightCardPool) {
            this._oldfightPool = pool;
        }

        public getCurFightPool(): FightCardPool {
            let hand = this._poolList.getChildAt(this._poolCtrl.selectedIndex).asCom as UI.HandCardGrid;
            return hand.dataProvider as FightCardPool;
        }
 
        public buildHandItem(idx:number, cardObj: UI.ICardObj): UI.IHandItem {
            if (!cardObj)  {
                return null;
            }
            let cardCom = fairygui.UIPackage.createObject(PkgName.cards, "smallCard").asCom as UI.CardCom;
            cardCom.displayObject.cacheAsBitmap = false;
            cardCom.cardObj = cardObj;
            cardCom.setNumText();
            cardCom.setName();
            cardCom.setSkill();
            cardCom.setCardImg();
            cardCom.setEquip();
            cardCom.setNumText();
            cardCom.setNumOffsetText();
            cardCom.setOwnFront();
            cardCom.setDeskBackground();
            cardCom.touchable = false;
            cardCom.displayObject.cacheAsBitmap = true;
            return cardCom;
        }

        public refresh(pools:Array<FightCardPool>) {
            let fightHand: UI.HandCardGrid;
            let allHands: Array<UI.HandCardGrid> = [];
            for (let i=0; i<this._poolList.numItems; i++) {
                let handCardGrid = this._poolList.getChildAt(i).asCom as UI.HandCardGrid;
                handCardGrid.itemBuilder = this;
                let pool = pools[i];
                handCardGrid.dataProvider = pool;
                handCardGrid.choiceCardCtrl = new FightPoolChoiceCardCtrl(pool);
                if (pool.isFight) {
                    fightHand = handCardGrid;
                    this._poolCtrl.selectedIndex = i;
                    this._oldfightPool = pool;
                } else {
                    allHands.push(handCardGrid);
                }
                handCardGrid.refresh();
                
            }

            this._renderExecutor = new Core.FrameExecutor();
            if (fightHand) {
                this._renderExecutor.regist(fightHand.refresh, fightHand);
            }
            for (let hand of allHands) {
                this._renderExecutor.regist(hand.refresh, hand);
            }
            this._renderExecutor.execute();
        }

        public clear() {
            if (this._renderExecutor) {
                this._renderExecutor.cancel();
                this._renderExecutor = null;
            }
            for (let i=0; i<this._poolList.numItems; i++) {
                let handCardGrid = this._poolList.getChildAt(i).asCom as UI.HandCardGrid;
                handCardGrid.clear();
                handCardGrid.dataProvider = null;
            }
            this._oldfightPool = null;
        }

        public fireClick() {
            let hand = this._poolList.getChildAt(this._poolCtrl.selectedIndex).asCom as UI.HandCardGrid;
            hand.fireClick();
        }

        public prePool() {
            let idx = this._poolCtrl.selectedIndex - 1;
            idx = idx < 0 ? 0 : idx;
            this._poolCtrl.selectedIndex =  idx;
        }

        public nextPool() {
            let idx = this._poolCtrl.selectedIndex + 1;
            idx = idx > this._poolCtrl.pageCount - 1 ? this._poolCtrl.pageCount - 1 : idx;
            this._poolCtrl.selectedIndex =  idx;
        }
    }

}
