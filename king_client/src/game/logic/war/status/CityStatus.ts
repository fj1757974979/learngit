// TypeScript file
module War {

    // export enum CityStatusName {
    //     ST_NORMAL = 0,         // 正常态
    //     ST_ATTACKED = 1,       // 被攻击
    //     ST_FALLEN = 2,         // 被攻陷
    // }

    export class CityStatusBase extends WarStatusBase {
        protected _city: City;

        public constructor(host: any) {
            super(host);
            this._city = <City>host;
        }

        public get host(): City {
            return this._city;
        }
    }

    export class CityNormal extends CityStatusBase {
        public get name(): number {
			return CityStatusName.ST_NORMAL;
		}

        public async enter(...param: any[]) {
            
        }
    }

    export class CityAttacked extends CityStatusBase {
        public get name(): number {
            return CityStatusName.ST_ATTACKED;
        }

        public async enter(...param: any[]) {
            this._city.cityCom.setCityInAttackedMode(true);
        }

        public async leave() {
            this._city.cityCom.setCityInAttackedMode(false);
        }
    }

    export class CityFallen extends CityStatusBase {
        public get name(): number {
            return CityStatusName.ST_FALLEN;
        }

        public async enter(...param: any[]) {
            let countryId = param[0];
            if (countryId) {
                let oldCountryId = this._city.countryID;
                let oldCountry = CountryMgr.inst.getCountry(oldCountryId);
                if (oldCountry) {
                    oldCountry.delCity(this._city);
                }
                this._city.countryID = countryId;
                let country = CountryMgr.inst.getCountry(countryId);
                country.addCity(this._city);
            }
            if (this._city.cityCom) {
                this._city.cityCom.setInFallenMode(true);
            }
        }
        public async leave() {
            if (this._city.cityCom) {
                this._city.cityCom.setInFallenMode(false);
            }
        }
    }

    export class CityStatusDelegate extends WarStatusDelegateBase {

        protected _city: City;

        public setDelegateHost(host: any) {
            this._city = <City>host;
            super.setDelegateHost(host);
        }

        protected initStatus() {
            this._statusObjs.setValue(CityStatusName.ST_NORMAL, new CityNormal(this._city));
            this._statusObjs.setValue(CityStatusName.ST_ATTACKED, new CityAttacked(this._city));
            this._statusObjs.setValue(CityStatusName.ST_FALLEN, new CityFallen(this._city));
        }

        public async changeStatus(stName: number, time: number = -1, ...param: any[]) {
            super.changeStatus(stName, time, ...param);
            // console.log(`City ${this._city.cityName} Status change to `, stName);
        }
    }
}