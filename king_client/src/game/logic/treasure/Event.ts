// TypeScript file
module Treasure {
    export class TreasureEvent extends egret.Event{
        private _treasureItem: TreasureItem;
        private _isInit: boolean;

        public get treasureItem(): TreasureItem {
            return this._treasureItem;
        }

        public set treasureItem(item: TreasureItem) {
            this._treasureItem = item;
        }

        public get isInit(): boolean {
            return this._isInit;
        }

        public set isInit(b: boolean) {
            this._isInit = b;
        }
    }
}