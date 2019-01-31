module Quest {
    export class QuestData  {
        private _missionID: number;
        private _curCnt: number;
        private _isReward: boolean;
        private _ID: number;
        private _data: any;

        constructor(questData:any) {
            this._missionID = questData.MissionID;
            this._curCnt = questData.CurCnt;
            this._isReward = questData.IsReward;
            this._ID = questData.ID;
        }

        get getMissionID() {
            return  this._missionID;
        }

        get getID() {
            return  this._ID;
        }

        get getIsReward() {
            return  this._isReward;
        }
        set setIsReward(bl: boolean) {
            this._isReward = bl;
        }
        get getCurCnt () {
            return  this._curCnt;
        }

        public get type(): MissionType {
            let data = this.data;
            if (data) {
                return data.type;
            }
            return 0;
        }

        public get data(): any {
            if (!this._data) {
                this._data = Data.quest_config.get(this.getMissionID);
            }
            return this._data;
        }

        public isComplete(): boolean {
            let data = this.data;
            if (data) {
                return this._curCnt >= data.process;
            } else {
                return false;
            }
        }
    }
}
