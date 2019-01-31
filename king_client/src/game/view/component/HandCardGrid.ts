module UI {

    export interface IHandItem extends fairygui.GComponent {
        cardObj: ICardObj
        inHandPoint: egret.Point;
        watch();
        unwatch();
    }

    export interface IHandItemBuilder {
        buildHandItem(idx:number, cardObj: ICardObj): IHandItem
    }

    export interface IHandItemDataProvider {
        providerHandItemData(idx:number): ICardObj
    }

    export class HandCardGrid extends fairygui.GComponent {
        protected _grid1: fairygui.GButton;
        protected _grid2: fairygui.GButton;
        protected _grid3: fairygui.GButton;
        protected _grid4: fairygui.GButton;
        protected _grid5: fairygui.GButton;

        public itemBuilder: IHandItemBuilder
        public dataProvider: IHandItemDataProvider
        protected _choiceCardCtrl: IChoiceCardCtrl

        protected _disabled: boolean
        protected _grids: Array<fairygui.GButton>;
        // 5张卡
        protected _cardItems: Array<IHandItem>;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._grid1 = this.getChild("grid1").asButton;
            this._grid2 = this.getChild("grid2").asButton;
            this._grid3 = this.getChild("grid3").asButton;
            this._grid4 = this.getChild("grid4").asButton;
            this._grid5 = this.getChild("grid5").asButton;
            this._grids = [this._grid1, this._grid2, this._grid3, this._grid4, this._grid5];
            this._cardItems = [null, null, null, null, null];

            this._grid1.addClickListener(this._gridOnClick, this);
            this._grid2.addClickListener(this._gridOnClick, this);
            this._grid3.addClickListener(this._gridOnClick, this);
            this._grid4.addClickListener(this._gridOnClick, this);
            this._grid5.addClickListener(this._gridOnClick, this);
            //this.addClickListener(this._gridOnClick, this);
            
            Core.EventCenter.inst.addEventListener(GameEvent.BattleBeginEv, function() {
                fairygui.GTimers.inst.callDelay(1000, function() {
                    this.displayObject.cacheAsBitmap = true;
                }, this);
            }, this);

            Core.EventCenter.inst.addEventListener(GameEvent.BattleEndEv, function() {
                this.displayObject.cacheAsBitmap = false;
            }, this);
        }

        public clear() {
            this.dataProvider = null;
            this.itemBuilder = null;
            this._choiceCardCtrl = null;
            
            this._cardItems.forEach(item => {
                if (item && item.parent) {
                    item.unwatch();
                    item.parent.removeChild(item, true);
                }
            })
            this._cardItems = [null, null, null, null, null];
        }

        public refresh(force:boolean=false) {
            for (let idx=0; idx<this._cardItems.length; idx++) {
                let cardObj = this.dataProvider.providerHandItemData(idx);
                let oldItem = this.getItem(idx);
                if (!force && oldItem && cardObj && oldItem.cardObj == cardObj) {
                    continue;
                }
                this.setItem(idx, cardObj);
            }
        }

        protected _gridOnClick(evt: egret.TouchEvent) {
            Core.ViewManager.inst.open(ViewName.choiceFightCard, this._choiceCardCtrl, this);
        }

        public fireClick() {
            this._gridOnClick(null);
        }

        public set choiceCardCtrl(ctrl:IChoiceCardCtrl) {
            this.disabled = false;
            this._choiceCardCtrl = ctrl;
        }

        public get choiceCardCtrl(): IChoiceCardCtrl {
            return this._choiceCardCtrl;
        }

        public set disabled(val:boolean) {
            this._disabled = val;
            this._grids.forEach(g => {
                g.disabled = val;
            })
        }

        public setItem(idx:number, cardObj:ICardObj) {
            if (!this.itemBuilder) {
                console.debug("HandCardGrid addItem no itemBuilder");
                return
            }
            if (idx < 0 || idx >= this._cardItems.length) {
                console.debug("HandCardGrid addItem error idx %d", idx);
                return
            }

            let oldItem = this._cardItems[idx];
            if (oldItem && oldItem.parent) {
                oldItem.unwatch();
                oldItem.parent.removeChild(oldItem, true);
            }

            if (cardObj) {
                let item = this.itemBuilder.buildHandItem(idx, cardObj);
                item.x = this._grids[idx].x;
                item.y = this._grids[idx].y;
                item.inHandPoint = new egret.Point(item.x, item.y);
                this._cardItems[idx] = item;
                this.addChild(item);
                item.watch();
            } else {
                this._cardItems[idx] = null;
            }
        }

        public get itemNum():number {
            return this._cardItems.length;
        }

        public getItem(idx:number): IHandItem {
            if (idx < 0 || idx >= this._cardItems.length) {
                console.debug("HandCardGrid getItem error idx %d", idx);
                return null;
            }
            return this._cardItems[idx];
        }

        public getGrid(idx:number): fairygui.GButton {
            if (idx < 0 || idx >= this._grids.length) {
                return null;
            }
            return this._grids[idx];
        }

        public getGuideClickNode(): fairygui.GObject {
            let node = new fairygui.GGraph();
            node.graphics.clear();
            node.graphics.beginFill(Core.TextColors.white, 0);
            node.graphics.drawRect(0, 0, this.width, this.height);
            node.graphics.endFill();
            node.width = this.width;
            node.height = this.height;
            this.addChildAt(node, 0);

            node.once(egret.TouchEvent.TOUCH_TAP, ()=>{
                this.removeChild(node, true);
                this._grids[0].dispatchEventWith(egret.TouchEvent.TOUCH_TAP);
            }, this);

            return node;
        }
    }

}