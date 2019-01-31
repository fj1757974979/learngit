module War {

    export class MyWarPlayer extends PlayerStatusDelegate {
        public static PropCity = "cityID";
        public static PropLocationCity = "locationCityID";
        public static PropCountry = "countryID";
        public static PropContribution = "contribution";
        public static PropForage = "forage";
        private static _inst: MyWarPlayer;
        private _cityID: number;                //所属城市
        private _locationCityID: number;        //所在城市
        private _countryID: number;             //
        private _lastCountryID: number;         //
        private _forage: number;                //
        private _contribution: number;          //战功
        private _contributionMax: number;       //最高战功
        private _salary: number;                //俸禄
        private _isCaptive: boolean;            //是否是俘虏
        private _isKickOut: boolean;            //是否被驱逐
        private _canAttackCitys: number[]       //可以攻打的城市列表
        private _supportCards: number[];        //支援期间的卡
        private _employee: NationalEmployee;

        public static get inst(): MyWarPlayer {
            if (!MyWarPlayer._inst) {
                MyWarPlayer._inst = new MyWarPlayer();
            }
            return MyWarPlayer._inst;
        }

        public constructor() {
            super();
            this.setDelegateHost(this);
            this._employee = new NationalEmployee();
        }

        public get employee(): NationalEmployee {
            return this._employee;
        }

        public async initByCampaignInfo(info: pb.CampaignInfo) {
            this._cityID = info.MyCityID;
            this._locationCityID = info.MyLocationCityID;
            this._countryID = info.MyCountryID;
            this._lastCountryID = info.LastCountryID;
            this._employee.setCountryJob(<number>info.MyCountryJob);
            this._employee.setCityJob(<number>info.MyCityJob);
            this._forage = info.Forage;
            this.contribution = info.Contribution;
            this._contributionMax = info.MaxContribution;
            this.supportCards = info.SupportCards;
            await this.changeStatus(info.MyState.State, -1, info.MyState.Arg);
            if (this._locationCityID != 0) {
                let city = CityMgr.inst.getCity(this._locationCityID);
                city.setHead(true);
            }
        }

        public setInfoForPatrolCityReply(info: pb.IPatrolCityReply) {
            this._contribution = info.Contribution;
            this._salary = info.Salary;
        }
        //职位
        public isMyCity(cityID: number) {
            if (this._cityID == 0) {
                return false;
            } else {
                return this._cityID == cityID;
            }
        }
        public isMyLocationCity(cityID: number) {
            if (this._locationCityID == 0) {
                return false;
            } else {
                return this._locationCityID == cityID;
            }
        }
        public isMyCountry(countryID: number) {
            if (this._countryID == 0) {
                return false;
            } else {
                return this._countryID == countryID;
            }
        }
        public isMyCountryCity(cityID: number) {
            if (this._countryID == 0) {
                return false;
            } else {
                return CityMgr.inst.getCity(cityID).countryID == this._countryID;
            }
        }
        /**
         * 判断自己是否可以设置city的攻击开关
         * 0.不可控制，1.可以攻击，2.不可攻击
         */
        // public isMyAttackCity(cityID: number) {
        //     if (this._cityID != 0 && this._cityJob == Job.Prefect) {
        //         let city = CityMgr.inst.getCity(this._cityID);
        //         if (city.getNeighborIds().indexOf(cityID) != -1 ) {
        //            if (this._canAttackCitys.indexOf(cityID) != -1) {
        //                return 1;
        //            } else {
        //                return 2;
        //            }
        //         } else {
        //             return 0;
        //         }
        //     } else {
        //         return 0;
        //     }

        // }
        public canAttack(cityID: number) {
            if (this._locationCityID != 0) {
                return (this._canAttackCitys.indexOf(cityID) != -1);
            }
            return false;
        }
        public get cityID() {
            return this._cityID;
        }
        public set cityID(cityID: number) {
            this._cityID = cityID;
        }
        public get locationCityID() {
            return this._locationCityID;
        }
        public set locationCityID(locationCityID: number) {
            //关闭所在城市头像
            if (this._locationCityID != 0) {
                let city = CityMgr.inst.getCity(this._locationCityID);
                city.setHead(false);
            }
            this._locationCityID = locationCityID;
            //开启新城市头像
            if (this._locationCityID != 0) {
                let city = CityMgr.inst.getCity(this._locationCityID);
                city.setHead(true);
            }
        }
        public get countryID() {
            return this._countryID;
        }
        public set countryID(countryID: number) {
            this._countryID = countryID;
        }
        public get lastCountryID() {
            return this._lastCountryID;
        }
        public set lastCountryID(lastCountryID: number) {
            this._lastCountryID = lastCountryID;
        }

        public get cityJobObj(): BaseJob {
            return this._employee.cityJob;
        }

        public get countryJobObj(): BaseJob {
            return this._employee.countryJob;
        }
        public get forage(): number {
            return this._forage;
        }
        public set forage(forage: number) {
            this._forage = forage;
        }
        public get contribution(): number {
            return this._contribution;
        }
        public set contribution(num: number) {
            this._contribution = num;
        }
        public get contributionMax(): number {
            return this._contributionMax;
        }
        public set contributionMax(max: number) {
            this._contributionMax = max;
        }
        public get salary(): number {
            return this._salary;
        }
        public set salary(num: number) {
            this._salary = num;
        }
        public get isCaptive(): boolean {
            return this._isCaptive;
        }
        public set isCaptive(bool: boolean) {
            this._isCaptive = bool;
        }
        public get isKickOut(): boolean {
            return this._isKickOut;
        }
        public set isKickOut(bool: boolean) {
            this._isKickOut = bool;
        }
        public get supportCards() {
            return this._supportCards;
        }
        public set supportCards(cards: number[]) {
            this._supportCards = cards;
        }
        public get hasCity(): boolean {
            if (this._cityID) {
                return true;
            } else {
                return false;
            }
        }
        public getOffContribution(num: number) {
            if (this._contributionMax) {
                return Math.ceil(MyWarPlayer.inst.contributionMax * num);
            }
            return 0;
        }
    }

    export class CampaignPlayer {

        private _uID: Long;
        private _name: string;
        private _headImg: string;
        private _headFrame: string;
        // private _cityJob: Job;
        // private _countryJob: Job;
        private _kickOutTime: number;
        private _pvpScore: number;
        private _contribution: number;
        private _employee: NationalEmployee;

        public constructor(playerInfo: pb.ICampaignPlayer) {
            this._employee = new NationalEmployee();
            this._uID = <Long>playerInfo.Uid;
            this._name = playerInfo.Name;
            this._headImg = playerInfo.HeadImg;
            this._headFrame = playerInfo.HeadFrame;
            // this._cityJob = <number>playerInfo.CityJob;
            // this._countryJob = <number>playerInfo.CountryJob;
            this._employee.setCityJob(<number>playerInfo.CityJob);
            this._employee.setCountryJob(<number>playerInfo.CountryJob);
            if (playerInfo.State.State == pb.CampaignPlayerState.StateEnum.KickOut) {
                this._kickOutTime = pb.CpStateKickOutArg.decode(playerInfo.State.Arg).RemainTime;
            } else {
                this._kickOutTime = null;
            }
            // this._kickOutTime = playerInfo.KickOutTime;
            this._pvpScore = playerInfo.PvpScore;
            this._contribution = playerInfo.Contribution;
        }

        public get uID() {
            return this._uID;
        }
        public get name() {
            return this._name;
        }
        public get headImg() {
            return this._headImg;
        }
        public get headFrame() {
            return this._headFrame;
        }
        public get pvpScore() {
            return this._pvpScore;
        }
        public get contribution () {
            return this._contribution;
        }
        public get pvpTeamIcon() {
            let pvpLv = Pvp.PvpMgr.inst.getPvpLevel(this._pvpScore);
            let pvpTeam = Pvp.Config.inst.getPvpTeam(pvpLv);
            return `common_rank${pvpTeam}_png`;
        }
        public get pvpLvTitle() {
            let pvpLv = Pvp.PvpMgr.inst.getPvpLevel(this._pvpScore);
            return Pvp.Config.inst.getPvpTitle(pvpLv);
        }
        public get kickOutTime() {
            return this._kickOutTime;
        }
        public set kickOutTime(time: number) {
            this._kickOutTime = time;
        }
        public get employee(): NationalEmployee {
            return this._employee;
        }
    }
}
