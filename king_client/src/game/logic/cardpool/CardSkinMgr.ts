module CardPool {

    export class CardSkinMgr {
        private static _inst: CardSkinMgr;
        
        private _allSkins: Collection.Dictionary<number, string[]>;
        private _mySkins: Collection.Dictionary<number, string[]>;

        private _allSkinArr: string[];

        public static get inst():CardSkinMgr {
            if (!CardSkinMgr._inst) {
                CardSkinMgr._inst = new CardSkinMgr();
            }
            return CardSkinMgr._inst;
        }

        constructor() {
            this._allSkins = new Collection.Dictionary<number, string[]>();
            this._mySkins = new Collection.Dictionary<number, string[]>();     
            this._init();
        }

        private _init() {
            if (window.gameGlobal.channel == "lzd_handjoy") {
                let skinKeys = Data.skin_config_handjoy.keys;
                skinKeys.forEach( _key => {
                let skinData =  Data.skin_config_handjoy.get(_key);
                let dicKey = skinData.general;
                if (!this._allSkins.containsKey(dicKey)) {
                        this._allSkins.setValue(dicKey, [""]);
                }
                this._allSkins.getValue(dicKey).push(_key.toString());
                });
            } else {
                let skinKeys = Data.skin_config.keys;
                skinKeys.forEach( _key => {
                let skinData =  Data.skin_config.get(_key);
                let dicKey = skinData.general;
                if (!this._allSkins.containsKey(dicKey)) {
                        this._allSkins.setValue(dicKey, [""]);
                }
                this._allSkins.getValue(dicKey).push(_key.toString());
                });
            }
            // this._allSkins.forEach((_key, _value) => {
            //     console.log(_key);
            //     console.log(_value.length);
            // })
        }

        private newSkins(dic: Collection.Dictionary<number, string[]>, cardId: number) {
            if (!dic.containsKey(cardId)) {
                dic.setValue(cardId, [""]);
            }
        }      

        public getSkinConf(key: string) {
            if (window.gameGlobal.channel == "lzd_handjoy") {
                return Data.skin_config_handjoy.get(key);
            } else {
                return Data.skin_config.get(key);
            }
        }
        public updateMySkins(skins: string[]) {
            this._allSkinArr = skins;
            skins.forEach( _key => {
                _key = _key.trim();
                if (_key != "") {
                    let skinData = this.getSkinConf(_key);
                    let dicKey = skinData.general;
                    this.newSkins(this._mySkins, dicKey);
                    this._mySkins.getValue(dicKey).push(_key.toString());

                    let card = CardPoolMgr.inst.getCollectCard(dicKey);
                    card.addSkin(_key);
                }
            })
        }
        public getAllSkins(cardID: number) {
            this.newSkins(this._allSkins, cardID);
            return this._allSkins.getValue(cardID);
        }
        public addMySkin(skin: string) {
            let skinData = this.getSkinConf(skin);
            let dicKey = skinData.general;
            this.newSkins(this._mySkins, dicKey);
            this._mySkins.getValue(dicKey).push(skin);
            let card = CardPoolMgr.inst.getCollectCard(dicKey);
            card.addSkin(skin);
        }
        public getMySkins(cardId: number) {
            this.newSkins(this._mySkins, cardId);
            return this._mySkins.getValue(cardId);
        }
        public hasSkin(cardId: number, skinId: string) {
            this.newSkins(this._mySkins, cardId);
            let has = false;
             this._mySkins.getValue(cardId).forEach(_skinId => {
                 if (_skinId == skinId) {
                     has = true;
                 }
             })
             return has;
        }
        public get mySkinIds(): string[] {
            return this._allSkinArr;
        }
    }
}