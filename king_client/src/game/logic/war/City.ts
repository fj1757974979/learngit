module War {

    export class CityType {
		public static CAPITAL: number = 1;	// 都城
		public static CITY: number = 2;	// 城市
		public static PORT: number = 3;		// 港口
		public static BARRIER: number = 4;	// 关卡
		public static STRONGHOLD: number = 5; // 据点
	}

    export class CityMeta {
		private _id: number;
		private _conf: any;
		private _x: number;
		private _y: number;
		private _type: CityType;
		private _roads: Collection.Dictionary<number, Road>;

		public constructor(id: number) {
			this._id = id;
			this._conf = Data.city.get(id);
			this._type = parseInt(this._conf.type);
			this._initCoord();
		}

		public get id(): number {
			return this._id;
		}

		public get x(): number {
			return this._x;
		}

		public get y(): number {
			return this._y;
		}

		public get type(): CityType {
			return this._type;
		}

		public get roads(): Collection.Dictionary<number, Road> {
			return this._roads;
		}

		private _initCoord() {
			let coordStr = <string>this._conf.coord;
			let coordStrs = coordStr.split(":");
			this._x = parseInt(coordStrs[0]);
			this._y = parseInt(coordStrs[1]);
		}

		public initRoads() {
			this._roads = new Collection.Dictionary<number, Road>();
			let roads = Road.genRoadsByCity(this._id);
			if (roads) {
				roads.forEach(road => {
					this._roads.setValue(road.toCityId, road);
				});
			} else {
                console.error("initRoads no road for city ", this._id);
            }
		}
	}

    export class City extends CityStatusDelegate {
        //
        public static PropGold = "gold";
        public static PropForage = "forage";
        public static PropGlory = "glory";
        public static PropAgriculture = "agriculture";
        public static PropDefence = "defence";
        public static PropBusiness = "business";
        public static PropPlayers = "players";
        public static PropApplyPlayer = "applyPlayers";
        public static PropCountry = "countryID";
        public static PropPlayerNum = "playerNum";
        public static PropDefPlayerNum = "defPlayerNum";
        public static PropMilitaryOrderInfo = "militaryOrderInfo";
        public static PropYouMajesty = "yourMajesty";

        //data
        private _countryID: number;
        private _country: Country;
        private _playerNum: number;
        private _defPlayerNum: number;
        private _inCityPlayerNum: number;
        private _agriculture: number;   //农业
        private _business: number;      //商业
        private _defence: number = 0;   //城防
        private _forage: number;         //粮草
        private _gold: number;          //金币
        private _glory: number;        //荣誉
        private _players: CampaignPlayer[];  //官员名单
        private _applyPlayers: pb.IApplyCreateCountryPlayer[]; //竞价人员名单
        private _foragePrice: number;
        private _yourMajesty: pb.ICampaignSimplePlayer;
        private _militaryOrderInfo: pb.IMilitaryOrder[];
        //base
        private _cityID: number;
        private _cityName: string;
        private _defenceMax: number;
        private _agricultureMax: number;
        private _businessMax: number;
        private _cityPoint: egret.Point;
        private _cityMeta: CityMeta;
        private _citySkill: number;
        // private _cityType: CityType;
        private _cityCom: CityCom;
        //status
        private _isBeAttack: boolean;   //是否被攻击
        private _createTime: number;    //建国倒计时

        private _isBorderCity: boolean; // 是否与敌方相邻
		private _neighbors: Collection.Dictionary<number, City>;


        public constructor(cityID: number) {
            super();
            this.setDelegateHost(this);
            this._cityID = cityID;
            let cityData = Data.city.get(cityID);
            this._cityName = cityData.name;
            this._defenceMax = cityData.defense_max;
            this._agricultureMax = cityData.agriculture_max;
            this._businessMax = cityData.business_max;
            this._citySkill = cityData.castle[0];
            let xy = (<string>(cityData.coord)).split(",");
			let apoint = new egret.Point(parseInt(xy[0]), parseInt(xy[1]));
            this._cityPoint = apoint;
            this._countryID = 0;
            this._defPlayerNum = 0;
            this._inCityPlayerNum = 0;
            this._militaryOrderInfo = [];
        }
        public initMeta() {
            this._neighbors = new Collection.Dictionary<number, City>();
            this._cityMeta = new CityMeta(this._cityID);
            this._cityMeta.initRoads();
        }

        public initCom() {
            let cityCom = fairygui.UIPackage.createObject(PkgName.war, "cityItem").asCom as CityCom;
            WarMgr.inst.warView.map.addChild(cityCom);
            this._cityCom = cityCom;
            this._cityCom.setCity(this);
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING)) {
                // 处于国战状态
                this._cityCom.setCityInWarMode(true);
            }
        }

        public async setCitySimpleData(city: pb.ICitySimpleData) {
            this.countryID = city.CountryID;
            this.defence = city.Defense;
            await this.updateStatus(city.State);
            let country = CountryMgr.inst.getCountry(city.CountryID);
            country.addCity(this);
        }

        public async updateStatus(state: pb.CityState, ...param: any[]) {
            if (state == pb.CityState.NormalCS) {
                await this.changeStatus(CityStatusName.ST_NORMAL, -1, ...param);
            } else if (state == pb.CityState.BeAttackCS) {
                await this.changeStatus(CityStatusName.ST_ATTACKED, -1, ...param);
            } else if (state == pb.CityState.BeOccupyCS) {
                await this.changeStatus(CityStatusName.ST_FALLEN, -1, ...param);
            }
        }

        public setCityData(cityData: pb.CityData) {
            this._players = new Array<CampaignPlayer>();
            this._applyPlayers = new Array<pb.IApplyCreateCountryPlayer>();
            this.countryID = cityData.CountryID;
            this._country = CountryMgr.inst.getCountry(this._countryID);
            this.playerNum = cityData.PlayerAmount;
            this.agriculture = cityData.Agriculture;
            this.business = cityData.Business;
            this.defence = cityData.Defense;
            this.forage = cityData.Forage;
            this.gold = cityData.Gold;
            this.glory = cityData.Glory;
            this.yourMajesty = cityData.YourMajesty;
            this._createTime = 0;
            this._inCityPlayerNum = cityData.InCityPlayerAmount;

            if (cityData.ApplyCreateCountry) {
                this._createTime = cityData.ApplyCreateCountry.RemainTime;
                cityData.ApplyCreateCountry.Players.forEach(playerInfo => {
                    this._applyPlayers.push(playerInfo);
                })
            }
            cityData.Players.forEach(playerInfo => {
                let player = new CampaignPlayer(playerInfo);
                this._players.push(player);
            })
            
            //官职按城池官职从大到小排序
            this._playersSort();
        }
        private _playersSort() {
            this._players.sort((a, b) => {
                if (a.employee.cityJob.isSameJob(Job.UnknowJob)) {
                    return 1;
                }
                return a.employee.cityJob.type - b.employee.cityJob.type;
            })
        }
        public checkBorderCity(): boolean {
			let neighbors = this.getNeighbors();
			for (let n of neighbors) {
				if (!this.isSameCamp(n)) {
					this._isBorderCity = true;
					return true;
				}
			}
			this._isBorderCity = false;
			return false;
		}
        public getNeighborIds(): Array<number> {
			return this._cityMeta.roads.keys();
		}
        public getNeighbors(): Array<City> {
			return this._neighbors.values();
		}
        public getNeighborDic() {
            return this._neighbors;
        }
        /**
         * 获取相邻未被攻陷的敌方城市
         */
        public getNeighborEnemyCity() {
            let cityIDs = [];
            this._neighbors.forEach((cityID, _city) => {
                if (this._countryID != _city.countryID && !_city.inStatus(CityStatusName.ST_FALLEN)) {
                    cityIDs.push(cityID);
                }
            })
            return cityIDs;
        }
        public addNeighbor(city: City) {
			this._neighbors.setValue(city.cityID, city);
		}
        public isSameCamp(city: City): boolean {
			return this._countryID == city._countryID;
		}
        public getAdjCityDayno(city: City): number {
			let cityId = city.cityID;
            
			if (!this._cityMeta.roads.containsKey(cityId)) {
				return Number.MAX_VALUE;
			} else {
				let road = this._cityMeta.roads.getValue(cityId);
				return road.dayno;
			}
		}
        public hasCounty() {
            if (this._countryID && this._countryID != 0) {
                return true;
            } else {
                return false;
            }
        }
        public getLord() {
            for(let i = 0; i < this._players.length; i++) {
                if (this._players[i].employee.hasSameJob(Job.Prefect)) {
                    return this._players[i];
                }
                return false;
            }
        }
        //替换官员
        public updatePlayer(player: CampaignPlayer, oldID: number|Long) {            
            this.removePlayer(oldID);
            this.addPlayer(player);
        }
        public addPlayer(player: CampaignPlayer) {
            let players = this._players;
            
            for (let i = 0; i < players.length; i++) {
                if (players[i].uID == player.uID) {
                    players.splice(i, 1);
                    break;
                }
            }
            players.push(player);
            this.players = players;
        }
        public removePlayer(uID: number|Long) {
            let players = this.players;
            for (let i = 0; i < players.length; i++) {
                if (players[i].uID == uID) {
                    players.splice(i, 1);
                }
            }
            this.players = players;
        }
        public getMsRes (type: WarMsType) {
            switch(type) {
                case WarMsType.Build:
                    return this._defence;
                case WarMsType.Trade:
                    return this._business;
                case WarMsType.Irrigation:
                    return this._agriculture;
                default :
                    return 0;
            }
        }
        public getMsResMax (type: WarMsType) {
            switch(type) {
                case WarMsType.Build:
                    return this._defenceMax;
                case WarMsType.Trade:
                    return this._businessMax;
                case WarMsType.Irrigation:
                    return this._agricultureMax;
                default :
                    return 0;
            }
        }
        public getRoad(to: City): Road {
			let roads = this._cityMeta.roads;
			return roads.getValue(to.cityID);
		}
        public setHead(bool: boolean) {
            this._cityCom.setHead(bool);
        }
        public get cityCom(): CityCom {
            return this._cityCom;
        }
        public get cityID(): number {
            return this._cityID;
        }
        public get cityName(): string {
            return this._cityName;
        }
        public get cityPoint(): egret.Point {
            return this._cityPoint;
        }
        public get countryID(): number {
            return this._countryID;
        }
        public set countryID(ID: number) {
            this._countryID = ID;
        }
        public get country() {
            return this._country;
        }
        public get defenceMax() : number {
            return this._defenceMax;
        }
        public get businessMax() : number {
            return this._businessMax;
        }
        public get agricultureMax(): number {
            return this._agricultureMax;
        }
        public set playerNum(num: number) {
            this._playerNum = num;
        }
        public get playerNum(): number {
            return this._playerNum;
        }
        public set defPlayerNum(num: number) {
            this._defPlayerNum = num;
        }
        public get defPlayerNum(): number {
            return this._defPlayerNum;
        }
        public set inCityPlayerNum(num: number) {
            this._inCityPlayerNum = num;
        }
        public get inCityPlayerNum(): number {
            return this._inCityPlayerNum;
        }
        public get defence(): number {
            return this._defence;
        }
        public set defence(num: number) {
            this._defence = num;
        }
        public get business(): number {
            return this._business;
        }
        public set business(num: number) {
            this._business = num;
        }
        public get agriculture(): number {
            return this._agriculture;
        }
        public set agriculture(num: number) {
            this._agriculture = num;
        }
        public get glory(): number {
            return this._glory;
        }
        public set glory(num: number) {
            this._glory = num;
        }
        public get forage(): number {
            return this._forage;
        }
        public set forage(num: number) {
            this._forage = num;
        }
        public get foragePrice(): number {
            return this._foragePrice;
        }
        public set foragePrice(num: number) {
            this._foragePrice = num;
        }
        public get isBeAttack(): boolean {
            return  this._isBeAttack;
        }
        public set isBeAttack(bool: boolean) {
            this._isBeAttack = bool;
        }
        public get gold(): number {
            return this._gold;
        }
        public set gold(num: number) {
            this._gold = num;
        }
        public get players() {
            return this._players;
        }
        public set players(players: CampaignPlayer[]) {
            this._players = players;
        }
        public get applyPlayers() {
            return this._applyPlayers;
        }
        public set applyPlayers(players: pb.IApplyCreateCountryPlayer[]) {
            this._applyPlayers = players;
        }
        public get isBorderCity() {
            return this._isBorderCity;
        }
        public set createTime(num: number) {
            this._createTime = num;
        }
        public get createTime() {
            return this._createTime;
        }
        public get skillName() {
            return Data.skill.get(this._citySkill).name;
        }
        public get skillDesc() {
            let str = parse2html(Data.skill.get(this._citySkill).desTra).toString();
            if (str && str != "") {
                return str;
            }
            return "";
        }
        public get skillLinkText() {
            let txt = `<a href="event:skill,${this._citySkill}"><u>${Data.skill.get(this._citySkill).name}</u></a>`;
            return txt;
        }
        /**
         * 点开城市信息获得的主公信息
         */
        public get yourMajesty() {
            return this._yourMajesty;
        }
        public set yourMajesty(yourMajesty: pb.ICampaignSimplePlayer) {
            this._yourMajesty = yourMajesty;
        }
        public get militaryOrderInfo() {
            return this._militaryOrderInfo;
        }
        public set militaryOrderInfo(orders: pb.IMilitaryOrder[]) {
            this._militaryOrderInfo = orders;
        }

        public onDestroy() {
            if (this._cityCom) {
                this._cityCom.onDestroy();
                this._cityCom = null;
            }
            this.resetToNoneStatus();
        }
    }
}