module War {

    export class CityJobItem extends fairygui.GComponent {

        private _cityID: number;
        private _city: City;
        private _country: Country;
        private _job: Job;
        private _jobType: JobType;
        private _tip: fairygui.GTextField;
        private _nowPlayer: CampaignPlayer;
        private _comCtr: fairygui.Controller;
        private _emperorHeadCom: Social.HeadCom;
        private _emperorNameText: fairygui.GTextField;
        private _offBtn: fairygui.GButton;

        private _battlePointIcon: fairygui.GLoader;
        private _goldIcon: fairygui.GLoader;

        protected constructFromXML(xml: any): void {
            this._comCtr = this.getController("c1");
            this._emperorHeadCom = this.getChild("emperorHead").asCom as Social.HeadCom;
            this._emperorNameText = this.getChild("emperorName").asTextField;
            this._emperorNameText.textParser = Core.StringUtils.parseColorText;
            this._offBtn = this.getChild("offBtn").asButton;
            this._tip = this.getChild("tip").asTextField;

            this._battlePointIcon = this.getChild("battlePointIcon").asLoader;
            this._goldIcon = this.getChild("goldIcon").asLoader;

            this.getChild("n3").asLoader.addClickListener(this._setJob, this);
            this._emperorHeadCom.addClickListener(this._setJob, this);
            this._offBtn.addClickListener(this._onOffBtn, this);

            this._battlePointIcon.addClickListener(() => {
                Core.ViewManager.inst.openPopup(ViewName.descTipsWnd, Const.job2BattleRwdDesc(this._job));
            }, this);

            this._goldIcon.addClickListener(() => {
                Core.ViewManager.inst.openPopup(ViewName.descTipsWnd, Const.job2GoldRwdDesc(this._job));
            }, this);
        }
        public setCurJob(job: Job) {
            this._job = job;
            // this._jobDesc.text = Const.job2Desc(job);
            this._jobType = Utils.job2Type(job);
            if (this._job == Job.UnknowJob) {
                this._battlePointIcon.visible = false;
                this._goldIcon.visible = false;
            } else {
                this._battlePointIcon.visible = true;
                this._goldIcon.visible = true;
            }
        }
        public setPlayer(player: CampaignPlayer) {
            this._nowPlayer = player;
            this._comCtr.selectedIndex = 1;
            this._emperorHeadCom.setAll(player.headImg, player.headFrame);
            this._emperorNameText.text = player.name;
            if (player.uID == Player.inst.uid && this._job != Job.YourMajesty) {
                this._offBtn.visible = true;
            } else {
                this._offBtn.visible = false;
            }
        }
        //重置控件并绑定城市ID
        public refreshCom(cityID: number) {
            this._cityID = cityID;
            this._city = CityMgr.inst.getCity(cityID);
            this._nowPlayer = null;
            this._comCtr.selectedIndex = 0;
            this._offBtn.visible = false;
            this._emperorHeadCom.setAll("", "");
            this._emperorNameText.text = "";
            if (this._job == Job.Prefect) {
                if (MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty)) {
                    this._tip.text = Core.StringUtils.TEXT(70223);
                }  else {
                    this._tip.text = Core.StringUtils.TEXT(70224);
                }
            } else {
                if (MyWarPlayer.inst.isMyCity(this._city.cityID) && MyWarPlayer.inst.employee.hasSameJob(Job.Prefect)) {
                    this._tip.text = Core.StringUtils.TEXT(70223);
                } else {
                    this._tip.text = Core.StringUtils.TEXT(70225);
                }
            }
        }

        public refeshCampCom(country: Country) {
            this._cityID = 0;
            this._country = country;
            this._nowPlayer = null;
            this._comCtr.selectedIndex = 0;
            this._offBtn.visible = false;
            this._emperorHeadCom.setAll("", "");
            this._emperorNameText.text = "";
            if (MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty)) {
                this._tip.text = Core.StringUtils.TEXT(70223);
            }  else {
                this._tip.text = Core.StringUtils.TEXT(70224);
            }
        }
        public canSetPlayer() {
            return this._comCtr.selectedIndex == 0;
        }
        private async _setJob() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            //设置国家职位
            if (this._jobType == JobType.CountryJob && MyWarPlayer.inst.employee.hasSameJob(Job.YourMajesty)) {
                // if (this._job == Job.YourMajesty) {
                    // Core.TipsUtils.showTipsFromCenter("脱离势力才能转让主公之位");
                    // return;
                // }
                let playerList = await WarMgr.inst.fetchCountryMember(MyWarPlayer.inst.countryID, 0);
                if (playerList) {
                    Core.ViewManager.inst.open(ViewName.appointChooseWnd, MyWarPlayer.inst.countryID, this._job, playerList, this._nowPlayer);
                }
            } else if (this._jobType == JobType.CityJob) {    //设置城市职位                
                let can = false;
                //设置太守
                if (this._job == Job.Prefect && MyWarPlayer.inst.employee.canSetPrefect()) {
                    can = true;
                } else if (this._job != Job.Prefect && MyWarPlayer.inst.employee.canSetOtherCityJob() && MyWarPlayer.inst.isMyCity(this._city.cityID)) {
                    can = true;
                }
                if (can) {
                    let playerList = await WarMgr.inst.fetchCityMember(this._cityID, 0);
                    if (playerList) {
                        Core.ViewManager.inst.open(ViewName.appointChooseWnd, this._cityID, this._job, playerList, this._nowPlayer);
                    }
                }
                
            }
        }
        private async _onOffBtn() {
            if (WarMgr.inst.checkWarIsOver()) {
                return;
            }
            Core.TipsUtils.confirm(Core.StringUtils.format(Core.StringUtils.TEXT(70226), Utils.job2Text(this._job, true)), this._onOffJob, null, this);
        }
        private async _onOffJob() {
            let jobType = Utils.job2Type(this._job);
            let ok = await WarMgr.inst.recallJob(Player.inst.uid, this._job);
            if (ok) {
                if (jobType == JobType.CityJob) {
                    this._city.removePlayer(Player.inst.uid);
                } else if(jobType == JobType.CountryJob) {
                    this._country.removePlayer(Player.inst.uid);
                }
                Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshAppoint);
            } 
        }
    }

    export class CityAppointCom extends fairygui.GComponent {
        private _city: City;
        private _country: Country;

        private _lordCom: CityJobItem;
        private _adjutantList: Array<CityJobItem>;
        private _adjutantCom1: CityJobItem;
        private _adjutantCom2: CityJobItem;
        private _captainList: Array<CityJobItem>;
        private _captainCom1: CityJobItem;
        private _captainCom2: CityJobItem;
        private _captainCom3: CityJobItem;
        private _captainCom4: CityJobItem;
        private _captainCom5: CityJobItem;
        private _comList: Array<CityJobItem>;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._comList = new Array<CityJobItem>();
            this._adjutantList = new Array<CityJobItem>();
            this._captainList = new Array<CityJobItem>();

            this._lordCom = this.getChild("lord").asCom as CityJobItem;
            this._lordCom.setCurJob(Job.Prefect);
            this._adjutantCom1 = this.getChild("adjutant1").asCom as CityJobItem;
            this._adjutantCom2 = this.getChild("adjutant2").asCom as CityJobItem;  
            this._adjutantCom1.setCurJob(Job.DuWei);
            this._adjutantCom2.setCurJob(Job.DuWei);          
            this._adjutantList.push(this._adjutantCom1, this._adjutantCom2);
            this._captainCom1 = this.getChild("captain1").asCom as CityJobItem;
            this._captainCom2 = this.getChild("captain2").asCom as CityJobItem;
            this._captainCom3 = this.getChild("captain3").asCom as CityJobItem;
            this._captainCom4 = this.getChild("captain4").asCom as CityJobItem;
            this._captainCom5 = this.getChild("captain5").asCom as CityJobItem;
            this._captainCom1.setCurJob(Job.FieldOfficer);
            this._captainCom2.setCurJob(Job.FieldOfficer);
            this._captainCom3.setCurJob(Job.FieldOfficer);
            this._captainCom4.setCurJob(Job.FieldOfficer);
            this._captainCom5.setCurJob(Job.FieldOfficer);
            this._captainList.push(this._captainCom1, this._captainCom2, this._captainCom3, this._captainCom4, this._captainCom5);

            this._comList.push(this._lordCom);
            this._comList = this._comList.concat(this._adjutantList, this._captainList);
        }

        public async refreshCityJob(cityID: number) {
            this._comList.forEach(com => {
                com.refreshCom(cityID);
            })
            this._city = CityMgr.inst.getCity(cityID);

            let cityPlayer = this._city.players;
            cityPlayer.forEach(player => {
                this._setCityPlayer(player);
            })
        }

        private async _setCityPlayer(player: CampaignPlayer) {
            if (player.employee.hasSameJob(Job.Prefect)) {
                this._lordCom.setPlayer(player);
            } else if (player.employee.hasSameJob(Job.DuWei)) {
                for (let i = 0; i < this._adjutantList.length; i++) {
                    let com = this._adjutantList[i];
                    if (com.canSetPlayer()) {
                        com.setPlayer(player);
                        return;
                    }
                }
            } else if (player.employee.hasSameJob(Job.FieldOfficer)) {
                for (let i = 0; i < this._captainList.length; i++) {
                    let com = this._captainList[i];
                    if (com.canSetPlayer()) {
                        com.setPlayer(player);
                        return;
                    }
                }
            }
        }
    }
}