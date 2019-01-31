module Level {

    export enum LevelState {
        Lock = 1,
        UnLock = 2,
        Clear = 3,
    }

    export class Level {
        private _data: any;
        private _state: LevelState;
        private _help: boolean;
        private _chapter: number;

        constructor(levelData:any, chapter:number) {
            this._data = levelData;
            this._state = LevelState.Lock;
            this._chapter = chapter;
            this._help = false;
        }

        get state() {
            return this._state;
        }
        set state(s:LevelState) {
            this._state = s;
        }

        get id():number {
            return this._data.__id__;
        }

        get name():string {
            return this._data.name;
        }

        get data() {
            return this._data;
        }

        get help(): boolean {
            return this._help;
        }

        set help(b: boolean) {
            this._help = b;
        }

        public get chapter():number {
            return this._chapter;
        }

        public get unlockPvpLevel(): number {
            return this._data.rankCondition;
        }
    }

}