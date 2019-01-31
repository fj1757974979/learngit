module Pvp {
    export class DiscussData {
        private _videoID: Long;
        private _discussID: number;
        private _userName: string;
        private _content: string;
        private _like: number;
        private _isLike: boolean;
        private _time: number;
        private _headImage: string;
        private _frameImage: string;
        private _uid: Long;

        constructor(videoID: Long, disData: pb.IVideoComments) {
            this._videoID = videoID;
            this._discussID = disData.ID;
            this._userName = disData.Name;
            this._content = disData.Content;
            this._like = disData.Like;
            this._isLike = disData.IsLike;
            this._time = disData.Time;
            this._headImage = disData.HeadImgUrl;
            this._frameImage = disData.HeadFrame;
            this._uid = disData.Uid as Long;
        }

        public get videoID(): Long {
            return this._videoID;
        }
        public get discussID(): number {
            return this._discussID;
        }
        public get userName(): string {
            return this._userName;
        }
        public get content(): string {
            return this._content;
        }
        public get likeNum(): number {
            return this._like;
        }
        public set likeNum(num: number) {
            this._like = num;
        }
        public get isLike(): boolean {
            return this._isLike;
        }
        public set isLike(il: boolean) {
            this._isLike = il;
        }
        public get headImage(): string {
            return this._headImage;
        }
        public get frameImage(): string {
            if (!this._frameImage || this._frameImage == "") {
                return `headframe_1_png`;
            } else {
                return `headframe_${this._frameImage}_png`;
            }
            
        }
        public get time(): number {
            return this._time;
        }
        public get uid(): Long {
            return this._uid;
        }
    }

    export class DiscussDataMgr {
        private static _inst: DiscussDataMgr = null;
        private _discussDataList: Collection.Dictionary<number, DiscussData>;
        private _discussIndexList : Array<number>;

        public static get inst(): DiscussDataMgr {
            if(!DiscussDataMgr._inst) {
                DiscussDataMgr._inst = new DiscussDataMgr();
            }
            return DiscussDataMgr._inst;
        }

        public reDisussDataMgr() {
            this._discussDataList = new Collection.Dictionary<number, DiscussData>();
            this._discussIndexList = new Array<number>();
        }

        public async addDisussData(disData: DiscussData) {
            this._discussDataList.setValue(disData.discussID, disData);
            this._discussIndexList.push(disData.discussID);
            this._discussIndexList.sort((a,b) => {
                if(a > b) {
                    return -1;
                } else if(a < b) {
                    return 1;
                } else {
                    return 0;
                }
            });
            
        }

        public get discussNum(): number {
            return this._discussDataList.size();
        }

        public getDiscussData4Key(_key: number): DiscussData {
            let ok = this._discussDataList.containsKey(_key);
            if(!ok) {
                console.log("没有找到id为" + _key + "的数据");
                return;
            }
            return this._discussDataList.getValue(_key);
        }

        public getDiscussData4Index(_index: number) {
            let _key = this._discussIndexList[_index];
            return this.getDiscussData4Key(_key);
        }
    }
}