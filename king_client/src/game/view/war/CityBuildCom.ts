module War {

    export class CityBuildItem extends fairygui.GComponent {
        private _titleText: fairygui.GTextField;
        private _stopBtn: fairygui.GButton;
        private _newBtn: fairygui.GButton;
        private _cntText: fairygui.GTextField;
        private _progressBar: CityInfoBar;
        private _bg: fairygui.GLoader;
        private _textImg: fairygui.GLoader;

        private _msType: WarMsType;
        private _mission: pb.ICampaignMission;
        private _city: City;
        private _toCity: City;
        
        protected constructFromXML(xml: any): void {
            this._titleText = this.getChild("title").asTextField;
            this._stopBtn = this.getChild("stopBtn").asButton;
            this._newBtn = this.getChild("newBtn").asButton;
            this._cntText = this.getChild("Budget").asTextField;
            this._progressBar = this.getChild("progress").asCom as CityInfoBar;
            this._bg = this.getChild("bg").asLoader;
            this._textImg = this.getChild("textImg").asLoader;

            this._newBtn.addClickListener(this._onNewBtn, this);
            this._stopBtn.addClickListener(this._onStopBtn, this);
        }
        public setCom(type: WarMsType, city: City) {
            this._msType = type;
            this._city = city;
            this._clearCom();
        }
        private _clearCom() {
            this._titleText.text = Utils.warMsType2text(this._msType);
            this._progressBar.setIconUrl(Utils.warMsType2Url(this._msType));
            this._bg.url = Utils.warMsBgType2Url(this._msType).toString();
            this._textImg.url = Utils.warMsTextType2Url(this._msType).toString();
            let res = this._city.getMsRes(this._msType);
            let resMax = this._city.getMsResMax(this._msType);
            this._progressBar.setProgress(res, resMax);
            this._progressBar.setProgress2(res, resMax);
            this._cntText.text = "";
            this._newBtn.text = "发布任务";
            this.getChild("n75").asTextField.visible = false;
            this._stopBtn.visible = false;
        }
        public setMission(mission: pb.ICampaignMission) {
            this._mission = mission;
            //设置Icon
            // this._cntIcon
            //this._cntText.text = (mission.GoldReward * mission.Amount).toString();
            this._cntText.text =  `${mission.MaxAmount-mission.Amount}/${mission.MaxAmount}`; 
            this.getChild("n75").asTextField.visible = true;
            if (mission.Type == pb.CampaignMsType.Transport) {
                //这是个运输任务
                this._msType = WarMsType.Transport;
                this._bg.url = Utils.warMsBgType2Url(this._msType).toString();
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70232), Utils.warTranType2text(mission.TransportType), CityMgr.inst.getCity(mission.TransportTargetCity).cityName);
                this._textImg.visible = false;
                this._newBtn.visible = false;
                this._stopBtn.visible = true;
                if (mission.TransportType == pb.TransportTypeEnum.ForageTT) {
                    this._progressBar.setIconUrl(Utils.warResType2Url(WarResType.Forage));
                } else if (mission.TransportType == pb.TransportTypeEnum.GoldTT) {
                    this._progressBar.setIconUrl(Utils.warResType2Url(WarResType.Gold));
                }
                this._progressBar.setProgress(mission.MaxAmount - mission.Amount, mission.MaxAmount);
                this._progressBar.setProgress2(mission.MaxAmount - mission.Amount, mission.MaxAmount);
            } else if (mission.Type == pb.CampaignMsType.Dispatch) {
                this._msType = WarMsType.Transport;
                this._bg.url = Utils.warMsBgType2Url(this._msType).toString();
                this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70233), CityMgr.inst.getCity(mission.TransportTargetCity).cityName);
                this._textImg.visible = false;
                this._newBtn.visible = false;
                this._stopBtn.visible = true;
                this._progressBar.setProgress(mission.MaxAmount - mission.Amount, mission.MaxAmount);
                this._progressBar.setProgress2(mission.MaxAmount - mission.Amount, mission.MaxAmount);
            } else {
                let res = this._city.getMsRes(this._msType);
                let resMax = this._city.getMsResMax(this._msType);
                this._bg.url = Utils.warMsBgType2Url(this._msType).toString();
                this._textImg.visible = true;
                this._textImg.url = Utils.warMsTextType2Url(this._msType).toString();
                this._progressBar.setProgress(res, resMax);
                this._progressBar.setProgress2(res + mission.Amount * WarQuest.warMsType2reward(this._msType), resMax);
                this._newBtn.text = Core.StringUtils.TEXT(70234);
                this._newBtn.visible = !(res == resMax);
                if (mission.Amount > 0) {
                    this._stopBtn.visible = true;
                } else {
                    this._stopBtn.visible = false;
                }
            }

        }

        private async _onNewBtn() {
           Core.ViewManager.inst.open(ViewName.questReleaseWnd, this._msType, this._city, this._mission);
        }
        private async _onStopBtn() {
            let args = {Type: this._mission.Type, TransportTargetCity: this._mission.TransportTargetCity};
            let result = await Net.rpcCall(pb.MessageID.C2S_CANCEL_PUBLISH_MISSION, pb.CancelPublishMissionArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CancelPublishMissionReply.decode(result.payload);
                if (this._msType != WarMsType.Transport) {
                    this._clearCom();
                } else {
                    this.visible = false;
                }
                this._city.gold = reply.Gold;
                this._city.forage = reply.Forage;
            }
        }
    }

    export class CityBuildCom extends fairygui.GComponent {
        private _buildList: fairygui.GList;

        private _irrigationCom: CityBuildItem;
        private _tradeCom: CityBuildItem;
        private _buildCom: CityBuildItem;
        private _transportComList: Array<CityBuildItem>;
        private _transportMgrBtn: fairygui.GButton;
        private _migrateBtn: fairygui.GButton;

        private _city: City;

        // private _missionList
        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._buildList = this.getChild("buildList").asList;
            this._buildList.foldInvisibleItems = true;
            this._transportComList = new Array<CityBuildItem>();
            this._irrigationCom = this._buildList.getChild("Irrigation").asCom as CityBuildItem;
            this._tradeCom = this._buildList.getChild("Trade").asCom as CityBuildItem;
            this._buildCom = this._buildList.getChild("Build").asCom as CityBuildItem;
            this._transportMgrBtn = this._buildList.getChild("Transport").asButton;
            this._migrateBtn = this._buildList.getChild("migrate").asButton;

            this._migrateBtn.addClickListener(this._onMigrateBtn, this);
            this._transportMgrBtn.addClickListener(this._onTransportBtn, this);
        }
        private async _resCom() {
            this._irrigationCom.setCom(WarMsType.Irrigation, this._city);
            this._tradeCom.setCom(WarMsType.Trade, this._city);
            this._buildCom.setCom(WarMsType.Build, this._city);
            this._transportComList.forEach( com =>{
                com.visible = false;
            })
        } 

        public async refreshMission(missions: pb.ICampaignMissionInfo, city: City) {
            if (city) {
                this._city = city;
            }
            this._resCom();
            missions.Missions.forEach( mission => {
                if (mission.Type == pb.CampaignMsType.Irrigation) {
                    this._irrigationCom.setMission(mission);
                } else if(mission.Type == pb.CampaignMsType.Trade) {
                    this._tradeCom.setMission(mission);
                } else if(mission.Type == pb.CampaignMsType.Build) {
                    this._buildCom.setMission(mission);
                } else if(mission.Type == pb.CampaignMsType.Transport) {
                    this._setTransportMission(mission);
                } else if(mission.Type == pb.CampaignMsType.Dispatch) {
                    this._setTransportMission(mission);
                }
            })
        }
        private async _setTransportMission(mission: pb.ICampaignMission) {
            for (let i = 0; i < this._transportComList.length; i++) {
                let com = this._transportComList[i];
                if(com.visible == false) {
                    com.visible = true;
                    com.setCom(WarMsType.Transport, this._city);
                    com.setMission(mission);
                    this._buildList.setChildIndex(com, this._buildList.numItems - 3);
                    return;
                }
            }
            let com = fairygui.UIPackage.createObject(PkgName.war, "cityBuildItem").asCom as CityBuildItem;
            com.setCom(WarMsType.Transport, this._city);
            com.setMission(mission);
            com.visible = true;
            this._transportComList.push(com);
            this._buildList.addChild(com);
            this._buildList.setChildIndex(com, this._buildList.numItems - 3);
        }
        private async _onTransportBtn() {
            WarMgr.inst.joinSelectCityMode(true, MapState.Transport);
            Core.EventCenter.inst.addEventListener(WarMgr.SelectCity, this._openSetTransport, this);
        }

        private async _openSetTransport(evt: egret.Event) {
            Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._openSetTransport, this);
            if (!this._parent.visible) {
                return;
            }
            WarMgr.inst.joinSelectCityMode(false, MapState.Transport);
            let cityID = evt.data;
            if (cityID) {
                Core.ViewManager.inst.open(ViewName.questTransReleaseWnd, cityID);
            }
        }
        private async _onMigrateBtn() {
            let country = CountryMgr.inst.getCountry(this._city.countryID);
            if (country) {
                let citys = country.cityList.keys();
                let index = citys.indexOf(this._city.cityID);
                citys.splice(index, 1);
                if (citys.length <= 0) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70235)));
                    return;
                }
                WarMgr.inst.joinSelectCityMode(true, MapState.SelectMy, citys);
                Core.EventCenter.inst.addEventListener(WarMgr.SelectCity, this._openMigrate, this);
            }
        }
        private async _openMigrate(evt: egret.Event) {
            let cityID = evt.data;
            if (cityID) {
                let country = CountryMgr.inst.getCountry(this._city.countryID);
                if (country) {
                    let citys = country.cityList.keys();
                    if (citys.indexOf(cityID) >= 0) {
                        Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._openMigrate, this);
                        WarMgr.inst.joinSelectCityMode(false, MapState.Transport);
                        Core.ViewManager.inst.open(ViewName.questMigrateReleaseWnd, cityID);
                    }
                }
            } else {
                WarMgr.inst.joinSelectCityMode(false, MapState.Transport);
                Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._openMigrate, this);
            }
        }
    }
}