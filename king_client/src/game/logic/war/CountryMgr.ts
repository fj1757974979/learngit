module War {

    export class CountryMgr {
        private static _inst: CountryMgr;

        private _countryList: Collection.Dictionary<number, Country>;
        
        public static get inst(): CountryMgr {
            if (!CountryMgr._inst) {
                CountryMgr._inst = new CountryMgr();
                CountryMgr._inst.initCountryMgr();

            }
            return CountryMgr._inst;
        }
        public async initCountryMgr() {
            this._countryList = new Collection.Dictionary<number, Country>();
        }

        public setAllCountry(countrys: pb.ICountrySimpleData[]) {
            this._countryList.clear();
            countrys.forEach( countrySimpleData => {
                let country = new Country(countrySimpleData);
                this._countryList.setValue(country.countryID, country);
            })
        }
        public addCountry(createData: pb.CountryCreatedArg) {
            let country = new Country(createData);
            this._countryList.setValue(createData.CountryID, country);
        }
        public removeCountry(destoryData: pb.CountryDestoryed) {
            let countryID = destoryData.CountryID;
            if (this._countryList.containsKey(countryID)) {
                let country = this._countryList.getValue(countryID);
                country.cityList.forEach( (id, city) => {
                    if (city.countryID == countryID) {
                        CityMgr.inst.updateCityCamp(city.cityID, 0);
                    }
                })
                this._countryList.remove(destoryData.CountryID);
            }
        }
        public countryAddCity(cityID: number, countryID: number) {
            let city = CityMgr.inst.getCity(cityID);
            this._countryList.getValue(countryID).addCity(city);
        }
        
        public getCountryForCityID(id: number) {
            return this.getCountry(CityMgr.inst.getCity(id).countryID);
        }
        public getCountry(id: number) {
                return this._countryList.getValue(id);
        }
    }
    
}