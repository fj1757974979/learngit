module War {

    export class WarShopWindow extends fairygui.GComponent {
        public static warShopType2Data(type: WarShopType) {
            switch(type) {
                case WarShopType.card:
                    return Data.war_shop_card;
                case WarShopType.skin:
                    return Data.war_shop_skin;
                case WarShopType.equip:
                    return Data.war_shop_equip;
                case WarShopType.res:
                    return Data.war_shop_res;
            }
        }

        private _warShopType: WarShopType;
        private _warShopData: any;

        private _shopList: fairygui.GList;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._warShopType = null;
            this._warShopData = null;

            this._shopList = this.getChild("list").asList;
            this._shopList.itemClass = WarShopItem;
            this._shopList.callbackThisObj = this;
        }

        public async setType(type: WarShopType) {
            this._warShopType = type;
            this._warShopData = WarShopWindow.warShopType2Data(this._warShopType);
        }
        public async refresh() {
            this._shopList.removeChildrenToPool();
            let keys = <number[]>this._warShopData.keys;
            keys.forEach( _key => {
                let _data = this._warShopData.get(_key);
                let com = this._shopList.addItemFromPool().asCom as WarShopItem;
                com.setType(this._warShopType, _data);
            })
            this.setShow(this._shopList.numItems > 0);
        }

        public setShow(b: boolean) {
            this.visible = b;
        }


    }
}