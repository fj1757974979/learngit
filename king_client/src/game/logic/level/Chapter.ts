module Level {

    export enum ChapterState {
        Lock = 1,
        UnLock = 2,
    }

    export class Chapter {
        private _id: number;
        private _name: string;
        private _levelObjs: Array<Level>;
        public state: ChapterState;

        constructor(chapterData:Array<number>) {
            this._id = chapterData[0];
            this._name = Core.StringUtils.TEXT(chapterData[1]);
            this._levelObjs = [];
            if (this._id == 2) {
                this.state = ChapterState.Lock;
            } else {
                this.state = ChapterState.UnLock;
            }
        }

        public get id():number {
            return this._id;
        }

        public get name():string {
            return this._name;
        }

        public get levelObjs():Array<Level> {
            return this._levelObjs;
        }

        public addLevel(levelObj: Level) {
            this._levelObjs.push(levelObj);
        }

        public isClear(): boolean {
            for (let level of this._levelObjs) {
                if (level.state != LevelState.Clear) {
                    return false;
                }
            }
            return true;
        }
    }

}
