module War {
    
    export class Country extends CountryStatusDelegate {
        public static PropFlag = "countryFlag";
        public static PropCampName = "countryName";
        public static PropPlayers = "players";

        private _countryID: number;
        private _countryName: string;
        private _countryFlagUrl: string;
        private _players: CampaignPlayer[];  //官员名单
        private _cityList: Collection.Dictionary<number, City>;
        //pb.ICountrySimpleData,pb.CountryCreatedArg
        public constructor(country: any) {
            super();
            this.setDelegateHost(this);
            this._countryID = country.CountryID;
            this._countryName = country.Name;
            this._countryFlagUrl = country.Flag;
            this._cityList = new Collection.Dictionary<number, City>();
            this._players = new Array<CampaignPlayer>();
        }
        public setCountryPlayers(players: pb.ICampaignPlayer[]) {
            this._players = new Array<CampaignPlayer>();
            players.forEach(player => {
                let campPlayer = new CampaignPlayer(player);
                this._players.push(campPlayer);
            })
            this._playersSort();
        }
        private _playersSort() {
            this._players.sort((a, b) => {
                if (a.employee.countryJob.isSameJob(Job.UnknowJob)) {
                    return 1;
                }
                return a.employee.countryJob.type - b.employee.countryJob.type;
            })
        }
        public async getMaster() {
            for(let i = 0; i < this._players.length; i++) {
                if (this._players[i].employee.hasSameJob(Job.YourMajesty)) {
                    return this._players[i];
                }
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
            let players = this._players;
            for (let i = 0; i < players.length; i++) {
                if (players[i].uID == uID) {
                    players.splice(i, 1);
                }
            }
            this.players = players;
        }
        public set countryID(id: number) {
            this._countryID = id;
        }
        public get countryID(): number {
            return this._countryID;
        }
        public set countryName(name: string) {
            this._countryName = name;
        }
        public get countryName(): string {
            return this._countryName;
        }
        public set countryFlag(ID: string) {
            this._countryFlagUrl = ID;
        }
        public get countryFlagID(): string {
            return this._countryFlagUrl;
        }
        public get countryFlag(): string {
            if (!this._countryFlagUrl || this._countryFlagUrl == "" ) {
                this._countryFlagUrl = "0";
            }
            return `war_flag${this._countryFlagUrl}_png`;
        }

        public get players() {
            return this._players;
        }
        public set players(players: CampaignPlayer[]) {
            this._players = players;
        }
        public get cityList() {
            return this._cityList;
        }
        public addCity(city: City) {
            this._cityList.setValue(city.cityID, city);
        }
        public addCityID(cityID: number) {
            let city = CityMgr.inst.getCity(cityID);
            this.addCity(city);
        }
        public delCity(city: City) {
            if (this._cityList.containsKey(city.cityID)) {
                this._cityList.remove(city.cityID);
            }
        }

    }
}