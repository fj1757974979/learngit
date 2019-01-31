module War {

    export class CountryAppointCom extends fairygui.GComponent {
        private _country: Country;

        private _kingCom: CityJobItem;
        private _adviserCom: CityJobItem;
        private _generalList: Array<CityJobItem>;
        private _generalCom1: CityJobItem;
        private _generalCom2: CityJobItem;

        private _comList: Array<CityJobItem>;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._comList = new Array<CityJobItem>();
            this._generalList = new Array<CityJobItem>();


            this._kingCom = this.getChild("king").asCom as CityJobItem;
            this._kingCom.setCurJob(Job.YourMajesty);
            this._kingCom.getChild("bg2").asLoader.url = "war_jobBg3_png"; 
            this._adviserCom = this.getChild("adviser").asCom as CityJobItem;
            this._adviserCom.setCurJob(Job.Counsellor);
            this._adviserCom.getChild("bg2").asLoader.url = "war_jobBg3_png"; 
            this._generalCom1 = this.getChild("general1").asCom as CityJobItem;
            this._generalCom1.getChild("bg2").asLoader.url = "war_jobBg3_png"; 
            this._generalCom2 = this.getChild("general2").asCom as CityJobItem;
            this._generalCom2.getChild("bg2").asLoader.url = "war_jobBg3_png"; 
            this._generalCom1.setCurJob(Job.General);
            this._generalCom2.setCurJob(Job.General);
            this._generalList.push(this._generalCom1, this._generalCom2);

            this._comList.push(this._kingCom, this._adviserCom);
            this._comList = this._comList.concat(this._generalList);
        }

        public async refreshJob(country: Country) {
            this._country = country;
            this._comList.forEach(com => {
                com.refeshCampCom(this._country);
            })

            let players = this._country.players;
            players.forEach(player => {
                // console.log(player.name, player.employee.countryJob.name)
                this._setCountryPlayer(player);
            })

        }

        private async _setCountryPlayer(player: CampaignPlayer) {
            if (player.employee.hasSameJob(Job.YourMajesty)) {
                this._kingCom.setPlayer(player);
            } else if (player.employee.hasSameJob(Job.Counsellor)) {
                this._adviserCom.setPlayer(player)
            } else if (player.employee.hasSameJob(Job.General)) {
                for (let i = 0; i < this._generalList.length; i++) {
                    let com = this._generalList[i];
                    if (com.canSetPlayer()) {
                        com.setPlayer(player);
                        return;
                    }
                }
            }
        }

        }
    }