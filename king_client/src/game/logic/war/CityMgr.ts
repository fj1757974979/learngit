module War {

    export class CityMgr {
        private static _inst: CityMgr;
        private _myCity: City;
        private _cityList: Collection.Dictionary<number, City>; 
        private _myCityList: Collection.Dictionary<number, City>;
        private _enemyCityList: Collection.Dictionary<number, City>;

        private _reachableCityIds: Array<number>;
        private _adjacencyMatrix: Util.DjAdjacencyMatrix;
        private _dijkstraDistances: Collection.Dictionary<number, Array<Util.DjDistance>>;

        public static get inst(): CityMgr {
            if (!CityMgr._inst) {
                CityMgr._inst = new CityMgr();
                CityMgr._inst.initCityMgr();
            }
            return CityMgr._inst;
        }

        public constructor() {
            this._myCity = null;
            this._cityList = new Collection.Dictionary<number, City>();
            this._myCityList = new Collection.Dictionary<number, City>();
            this._enemyCityList = new Collection.Dictionary<number, City>();
            this._reachableCityIds = [];
        }

        public async initCityMgr() {
            if (!this._cityList.isEmpty()) {
                return;
            }
            let citys = Data.city.keys;
            this._cityList = new Collection.Dictionary<number, City>();
            this._adjacencyMatrix = new Util.DjAdjacencyMatrix(citys.length + 1);
			this._dijkstraDistances = new Collection.Dictionary<number, Array<Util.DjDistance>>();
            
            //初始化城市
            citys.forEach(cityID => {
                let cityObj = new City(cityID);
                this._cityList.setValue(cityID, cityObj);
            });
            // 建立相邻关系
            this._cityList.forEach((cityID, city) => {
                // 建立mate
                city.initMeta();
                let neighorIds = city.getNeighborIds();
                for (let id of neighorIds) {
                    let n = this._cityList.getValue(id);
                    city.addNeighbor(n);
                }
            });
        }
        //
        public setAllCity(citys: pb.ICitySimpleData[]) {
            let cityId2SimpleData = new Collection.Dictionary<number, pb.ICitySimpleData>();
            citys.forEach( citySimpleData => {
                cityId2SimpleData.setValue(citySimpleData.CityID, citySimpleData);
                // console.log("setCitySimpleData: ", citySimpleData.CityID);
                // let city = this._cityList.getValue(citySimpleData.CityID);
                // city.initCom();
                // city.setCitySimpleData(citySimpleData);
            })
            this._cityList.forEach((cityID, city) => {
                let data = cityId2SimpleData.getValue(cityID);
                if (data) {
                    city.setCitySimpleData(data);
                }
                // 检测与敌方相邻的城市
                city.checkBorderCity();
                city.initCom();
            })
        }
        public setAllCityDefPlayers(defPlayerAmount: pb.CitysDefPlayerAmount) {
            if (defPlayerAmount) {
                defPlayerAmount.Amounts.forEach(_data => {
                    let city = this.getCity(_data.CityID);
                    city.defPlayerNum = _data.Amount;
                })
            }
            
        }
        public getAllCities(): Array<City> {
            return this._cityList.values();
        }

        //城市国家变动
        public updateCityCamp(cityID: number, campID: number) {
            let city = this._cityList.getValue(cityID);
            city.countryID = campID;
            city.checkBorderCity();
            city.getNeighbors().forEach( _city => {
                _city.checkBorderCity();
            })
        }
        //城市更换国家

        //更新城市人数
        public updateCityPlayerNum(cityID: number, num: number) {
            this._cityList.getValue(cityID).playerNum = num;
        }
        
        /**
         * 按照势力寻路
         */
        public getShortestPathBetweenCityForBattle(from: City, to: City): Array<number> {
            let fromId = from.cityID;
			let toId = to.cityID;

			let availableCityIds = this.getReachableCityIds();
            this._adjacencyMatrix.reset();
			if (!this._adjacencyMatrix.initialized) {
				for (let cityId1 of availableCityIds) {
					let city1 = this.getCity(cityId1);
					for (let cityId2 of availableCityIds) {
						let city2 = this.getCity(cityId2);
						this._adjacencyMatrix.addAdjacentPoint(cityId1, cityId2, city1.getAdjCityDayno(city2));
					}
				}
			}

			if (!this._dijkstraDistances.containsKey(fromId)) {
				this._dijkstraDistances.setValue(fromId, Util.Dijkstra(this._adjacencyMatrix, fromId));
			}
			let distances = this._dijkstraDistances.getValue(fromId);
			if (distances[toId].value == Number.MAX_VALUE) {
				return [];
			} else {
				return distances[toId].path;
			}
        }

        /**
         * 运输路径，无视势力
         */
        public getShortestPathBetweenCityForTransport(from: City, to: City): Array<number> {
            let availableCityIds = this.getTransportCityIds();
			return this._getShortestPathBetweenCity(from, to, availableCityIds);
		}
        /**
         * 支援寻路
         */
        public getShortestPathBetweenCityForSupportFight(from: City, to: City): Array<number> {
            let path = [];
            if (from.countryID != 0) {
                let country = CountryMgr.inst.getCountry(from.countryID);
                if (country) {
                    let availableCityIds = country.cityList.keys();
                    path = this._getShortestPathBetweenCity(from, to, availableCityIds);
                }
            }
            return path;
        }
        /**
         * 进攻寻路
         * 进攻只能攻击周边城市，所以availableCityIds只有两个城市，减少计算
         */
        public getShortestPathBetweenCityForAttack(from: City, to: City) {
            let path = [];
            let availableCityIds = [from.cityID, to.cityID];
            path = this._getShortestPathBetweenCity(from, to, availableCityIds);
            return path;
        }
        private _getShortestPathBetweenCity(from: City, to: City, availableCityIds: Array<number>): Array<number> {
            let fromId = from.cityID;
			let toId = to.cityID;
            this._adjacencyMatrix.reset();
            this._dijkstraDistances.clear();
            if (!this._adjacencyMatrix.initialized) {
				for (let cityId1 of availableCityIds) {
					let city1 = this.getCity(cityId1);
					for (let cityId2 of availableCityIds) {
						let city2 = this.getCity(cityId2);
						this._adjacencyMatrix.addAdjacentPoint(cityId1, cityId2, city1.getAdjCityDayno(city2));
					}
				}
			}

			if (!this._dijkstraDistances.containsKey(fromId)) {
				this._dijkstraDistances.setValue(fromId, Util.Dijkstra(this._adjacencyMatrix, fromId));
			}
			let distances = this._dijkstraDistances.getValue(fromId);
			if (distances[toId].value == Number.MAX_VALUE) {
				return [];
			} else {
				return distances[toId].path;
			}
        }
        //按照势力算出可达到的城市
        public getReachableCityIds(): Array<number> {
			if (this._reachableCityIds.length <= 0) {
                let myCountry = CountryMgr.inst.getCountry(MyWarPlayer.inst.countryID);
				let ret = myCountry.cityList.keys();
				let enemyCityIds = new Collection.Dictionary<number, boolean>();
				for (let cid of ret) {
					let city = myCountry.cityList.getValue(cid);
                    // console.log("my country:",city.cityID, city.cityName);
					if (city && city.isBorderCity) {
						let neighbors = city.getNeighbors();
						for (let n of neighbors) {
							if (!n.isSameCamp(city)) {
                                // console.log(n.cityID,n.cityName);
								enemyCityIds.setValue(n.cityID, true);
							}
						}
					}
				}
				this._reachableCityIds = ret.concat(enemyCityIds.keys());
			}
            // console.log(this._reachableCityIds);
			return this._reachableCityIds;
		}
        //运粮
        public getTransportCityIds(): Array<number> {
            return this._cityList.keys();
		}
        
        public getCity(cityID: number) {
            return this._cityList.getValue(cityID);
        }
        public getToCityPoint(cityID: number) {
            if (!this._cityList.containsKey(cityID)) {
                cityID = 1;
            }
            return this._cityList.getValue(cityID).cityPoint;
        }
        public setCitySelectMode(citys: number[], bool: boolean) {
            citys.forEach( cityID => {
                this.getCity(cityID).cityCom.setCitySelectMode(bool);
            })
        }

        public onDestroy() {
            this._myCity = null;
            this._cityList.forEach((cityId, city) => {
                city.onDestroy();
            });
            this._myCityList.clear();
            this._enemyCityList.clear();
            this._reachableCityIds = [];
            this._adjacencyMatrix.reset();
            this._dijkstraDistances.clear();
        }
    }
    
}