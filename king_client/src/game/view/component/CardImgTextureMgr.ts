module UI {

    export class CardImgTextureMgr {
        private static _inst: CardImgTextureMgr;

        private _diyTextures: Collection.Dictionary<number, egret.Texture>;
        private _loading: Collection.Dictionary<number, Promise<void>>;

        constructor() {
            this._diyTextures = new Collection.Dictionary<number, egret.Texture>();
            this._loading = new Collection.Dictionary<number, Promise<void>>();
        }

        public static get inst(): CardImgTextureMgr {
            if (!CardImgTextureMgr._inst) {
                CardImgTextureMgr._inst = new CardImgTextureMgr();
            }
            return CardImgTextureMgr._inst;
        }

        private async _fetchDiyTexture(cardId:number): Promise<egret.Texture> {
            if (this._diyTextures.containsKey(cardId)) {
                return this._diyTextures.getValue(cardId);
            }

            if (this._loading.containsKey(cardId)) {
                await this._loading.getValue(cardId);
                return this._diyTextures.getValue(cardId);
            }

            let p = new Promise<void>(resolve => {
                Net.rpcCall(pb.MessageID.C2S_FETCH_DIY_CARD_IMG, pb.TargetCard.encode({"CardId": cardId}), false, false).then(result => {
                    //if (result.errcode != 0 || !result.payload.Img) {
                    // TODO
                    if (result) {
                        this._diyTextures.setValue(cardId, null);
                        this._loading.remove(cardId);
                        resolve();
                        return;
                    }
                    /*
                    let imgBytes = egret.Base64Util.decode(result.payload.Img);
                    egret.BitmapData.create("arraybuffer", imgBytes, (bitmapData:egret.BitmapData)=>{
                        let texr = new egret.Texture()
                        texr.bitmapData = bitmapData;
                        this._diyTextures.setValue(cardId, texr);
                        this._loading.remove(cardId);
                        resolve();
                    });
                    */
                });
            });

            this._loading.setValue(cardId, p);
            await p;
            return this._diyTextures.getValue(cardId);
        }

        /**
         * @param callback   (egret.Texture)=>void
         */
        public async fetchTexture(icon:number, skin:string, size:string, callback:Function) {
            let hasSkin = (skin != undefined && skin != "");
            let _texture: egret.Texture;
            if (Diy.DiyMgr.inst.isDiyCard(icon)) {
                _texture = this._diyTextures.getValue(icon);
                if (!_texture) {
                    callback( icon, RES.getRes(`card_${size}_999_png`) );
                    _texture = await this._fetchDiyTexture(icon);
                    if (_texture) {
                        callback( icon, _texture);
                    }
                } else {
                    callback(icon, _texture);
                }
                return;
            }            
            // if (skin) {
            //     let _url = `skin_${size}_${skin}_png`
            //     _texture = RES.getRes(_url);
            //     callback(_texture);
            //     return;
            // }


            let _textureSize = size;
            let _url = `card_${size}_${icon}_png`;
            if (hasSkin) {
                _url = `skin_${size}_${skin}_png`;
            }
            _texture = RES.getRes(_url);
            if (!_texture) {
                let sizeQueue: Array<string>;
                if (size == "s") {
                    sizeQueue = ["m", "b"];
                } else if (size == "m") {
                    sizeQueue = ["b", "s"];
                } else {
                    sizeQueue = ["m", "s"];
                }
                _textureSize = sizeQueue[0];
                if (hasSkin) {
                    _texture = RES.getRes(`skin_${sizeQueue[0]}_${skin}_png`);
                } else {
                    _texture = RES.getRes(`card_${sizeQueue[0]}_${icon}_png`);
                }
                if (!_texture) {
                    _textureSize = sizeQueue[1];
                    if (hasSkin) {
                        _texture = RES.getRes(`skin_${sizeQueue[0]}_${skin}_png`);
                    } else {
                        _texture = RES.getRes(`card_${sizeQueue[1]}_${icon}_png`);
                    }
                    
                }
            }

            if (!_texture) {
                _texture = RES.getRes(`card_${size}_999_png`);
            }

            //console.log(`${_url}`);
            if (_textureSize != size) {
                callback(icon, _texture);
                try {
                    _texture = await RES.getResAsync(_url);
                } catch(e) {
                    console.debug(e);
                }
            }
            callback(icon, _texture, _url);
        }
    }

}