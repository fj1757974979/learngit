module Core {

    export class MCFactory {
        private static _inst: MCFactory;

        private _factorys: Collection.MultiDictionary<string, EMovieClip>;
        private _maxId: number;
        private _mcFactorys: Collection.Dictionary<string, egret.MovieClipDataFactory>;

        public constructor() {
            this._factorys = new Collection.MultiDictionary<string, EMovieClip>();
            this._mcFactorys = new Collection.Dictionary<string, egret.MovieClipDataFactory>();
            this._maxId = 1;
        }

        public static get inst(): MCFactory {
            if (!MCFactory._inst) {
                MCFactory._inst = new MCFactory();
            }
            return MCFactory._inst;
        }

        /**
         * 获取序列帧动画
         * 注意事项：getMovieClip 获取的MovieClip在使用完成后需调用 revertMovieClip 归还，并需要在调用 revertMovieClip 以后将 MovieClip 变量赋值为null
         * @param mcFile    动画文件名前缀
         * @param mcName    动画名称
         */
        public getMovieClip(mcFile: string, mcName: string): EMovieClip {
            let key:string = `${mcFile}>${mcName}`;
            let mcList = this._factorys.getValue(key);
            if (mcList.length > 0) {
                let emc = mcList[0];
                this._factorys.remove(key, emc);
                return emc;
            } else {
                let factory: egret.MovieClipDataFactory = this._mcFactorys.getValue(mcFile);
                if (!factory) {
                    let jsonData: any = RES.getRes(`effect_${mcFile}_mc_json`);
                    let pngData: egret.Texture = RES.getRes(`effect_${mcFile}_tex_png`);
                    if (!jsonData || !pngData) {
                        return null;
                    }
                    factory = new egret.MovieClipDataFactory(jsonData, pngData);
                    //factory.enableCache = true;
                    //this._mcFactorys.setValue(mcFile, factory);
                }
                let mcData: egret.MovieClipData = factory.generateMovieClipData(mcName);
                if (mcData.mcData) {
                    let mc: egret.MovieClip = new egret.MovieClip(mcData);
                    //mc.gotoAndStop(1);
                    let emc = new EMovieClip(mc);
                    emc['key'] = key;
                    emc['_fid'] = this._maxId;
                    this._maxId++;
                    return emc;
                }
            }
            return null;
        }

        public revertMovieClip(emc: EMovieClip): void {
            if (emc) {
            //   let key:string = emc['key'];
               if (emc.parent) {
                   emc.parent.removeChild(emc);
               }
               let mc = <egret.MovieClip>emc.displayObject;
               mc.destroy();
          //     this._factorys.setValue(key, emc);
           }
        }

    }

}