module War {

    export class AllCityItem extends fairygui.GComponent {
        
        private _countryIcon: fairygui.GLoader;
        private _cityNameText: fairygui.GTextField;
        private _campNameText: fairygui.GTextField;
        private _cityGloryText: fairygui.GTextField;
        private _cityPlayerNumText: fairygui.GTextField;
        private _goldCntText: fairygui.GTextField;
        private _bounsCntText: fairygui.GTextField;
        private _cityNoticeBtn: fairygui.GButton;
        private _cityGloryIcon: fairygui.GLoader;
        private _cityPlayerNumIcon: fairygui.GLoader;
        private _showComCtr: fairygui.Controller;

        private _cityID: number;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._countryIcon = this.getChild("flag").asLoader;
            this._campNameText = this.getChild("campName").asTextField;
            this._cityNameText = this.getChild("cityName").asTextField;
            this._cityGloryText = this.getChild("honor").asTextField;
            this._cityPlayerNumText = this.getChild("playerCnt").asTextField;
            this._goldCntText = this.getChild("goldCnt").asTextField;
            this._bounsCntText = this.getChild("bounsCnt").asTextField;
            this._cityNoticeBtn = this.getChild("noticeBtn").asButton;
            this._showComCtr = this.getController("showCom");

            this._cityNoticeBtn.addClickListener(this._onNotice, this);

            this._cityGloryIcon = this.getChild("honorIcon").asLoader;
            this._cityPlayerNumIcon = this.getChild("playerCntIcon").asLoader;

            this.getChild("bg").asLoader.addClickListener(this._onCity, this);
            this._cityGloryIcon.addClickListener(() => {
                Core.ViewManager.inst.openPopup(ViewName.descTipsWnd, Utils.warResType2desc(WarResType.Glory));
            }, this);
            this._cityPlayerNumIcon.addClickListener(async () => {
                let memberList = await WarMgr.inst.fetchCityMember(this._cityID, 0);
                if (memberList) {
                    let city = CityMgr.inst.getCity(this._cityID);
                    Core.ViewManager.inst.open(ViewName.allMemberPanel, city, memberList);
                }
            }, this);
        }
        public setInfo(city: City,county:Country) {
            // this._countryIcon.url = WarMgr.inst.getCountry(city.countryID).countryFlagImg;
            this._cityNameText.text = city.cityName;
            this._campNameText.text = county.countryName;
            this._cityPlayerNumText.text = city.playerNum.toString();
            this._cityGloryText.text = (city.glory / 10).toString();
            //是否可以删除
            // if (WarMgr.inst.myCityJob 
        }
        public setReplyData(data: pb.ICityPlayerAmount, ctrPage: string) {
            this._cityID = data.CityID;
            this._cityNameText.text = CityMgr.inst.getCity(data.CityID).cityName;
            this._cityPlayerNumText.text = data.PlayerAmount.toString();
            this._cityGloryText.text = (data.Glory / 10).toString();
            // if (data.MaxApplyCountryGold <= 0) {
            //     this.getChild("price").asGroup.visible = false;
            // } else {
            //     this.getChild("price").asGroup.visible = true;
            //     this._goldCntText.text = data.MaxApplyCountryGold.toString();
            // }
            let city = CityMgr.inst.getCity(this._cityID);
            // console.log(city.cityID, city.countryID, city.cityName);
            if (city.countryID == 0) {
                if (data.MaxApplyCountryGold <= 0) {
                    this._showComCtr.selectedPage = "null";
                } else {
                    this._showComCtr.selectedPage = "apply";
                    this._goldCntText.text = data.MaxApplyCountryGold.toString();
                }
            } else {
                if (ctrPage == "bouns" && data.AvgMissionReward > 0) {
                    this._showComCtr.selectedPage = "reward";
                    this._bounsCntText.text = data.AvgMissionReward.toString();
                } else {
                    this._showComCtr.selectedPage = "notice";
                }
                
            }
            if (!city.countryID || city.countryID == 0) {
                this._countryIcon.url = "war_flag0_png";
                this._campNameText.text = "";
            } else {
                let county = CountryMgr.inst.getCountry(city.countryID);
                this._campNameText.text = county.countryName;
                this._countryIcon.url = county.countryFlag;
            }
        }
        private async _onNotice() {
            let args = {CityID: this._cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CITY_NOTICE, pb.TargetCity.encode(args));
            if (result.errcode == 0) {
                let str = pb.CityNotice.decode(result.payload).Notice;
                let can = (this._cityID == MyWarPlayer.inst.cityID && MyWarPlayer.inst.employee.canNotice());
                Core.ViewManager.inst.open(ViewName.cityNoticeWnd, str, can);
            }
        }
        private _onCity() {
            WarMgr.inst.openCityInfo(this._cityID);
        }
    }

    export class AllCityPanel extends Core.BaseWindow {
        private _cityList: fairygui.GList;
        private _nowPage: number;
        private _closeBtn: fairygui.GButton;

        private _filterCtrl: fairygui.Controller;
        private _allCityData: pb.AllCityPlayerAmount;
        private _orderCityData: Array<pb.CityPlayerAmount>;

        private _curFilterCond: string = "";

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;
            this._cityList = this.contentPane.getChild("playerList").asList;
            this._cityList.itemClass = AllCityItem;
            this._cityList.itemRenderer = this._renderCities;
            this._cityList.callbackThisObj = this;
            this._cityList.setVirtual();

            this._filterCtrl = this.contentPane.getController("filter");
            // this.cityList._scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._updatePlayers, this);

            this._orderCityData = [];
            this._curFilterCond = this._filterCtrl.selectedPage;

            this.contentPane.getChild("countryChk").asButton.addClickListener(this._refresh, this);
            this.contentPane.getChild("honorChk").asButton.addClickListener(this._refresh, this);
            this.contentPane.getChild("memberChk").asButton.addClickListener(this._refresh, this);
            this.contentPane.getChild("bounsBtn").asButton.addClickListener(this._refresh, this);
            
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._closeBtn.addClickListener(this._onCloseBtn, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            
            //从缓存中生成
            // let cityKeys = Data.city.keys;
            // cityKeys.forEach( key => {
            //     let city = WarMgr.inst.getCity(key);
            //     let com = this.cityList.addItemFromPool() as AllCityItem;
            //     com.setInfo(city);
            // })
            //从服务器数据生成
            this._allCityData = param[0];
            this._allCityData.PlayerAmounts.forEach( _data => {
                // let com = this._cityList.addItemFromPool() as AllCityItem;
                // com.setReplyData(_data);
                this._orderCityData.push(<pb.CityPlayerAmount>_data);
            });
            this._sortCityData();
            this._cityList.numItems = this._orderCityData.length;
        }

        private _refresh() {
            if (this._curFilterCond != this._filterCtrl.selectedPage) {
                this._curFilterCond = this._filterCtrl.selectedPage;
                this._sortCityData();
                this._cityList.numItems = 0;
                this._cityList.numItems = this._orderCityData.length;
            }
        }

        private _sortCityData() {
            this._orderCityData = this._orderCityData.sort((d1: pb.CityPlayerAmount, d2: pb.CityPlayerAmount) => {
                let v1 = 0;
                let v2 = 0;
                let cityId1 = d1.CityID;
                let cityId2 = d2.CityID;
                let city1 = CityMgr.inst.getCity(cityId1);
                let city2 = CityMgr.inst.getCity(cityId2);
                if (this._curFilterCond == "shili") {
                    // 势力
                    v1 = city1.countryID;
                    v2 = city2.countryID;
                    if (v2 == 0) {
                        return -1;
                    } else if (v1 == 0) {
                        return 1;
                    } else {
                        let country1 = CountryMgr.inst.getCountry(v1);
                        let country2 = CountryMgr.inst.getCountry(v2);
                        if (!country2) {
                            return -1;
                        }
                        if (!country1) {
                            return 1;
                        }
                        let cityNum1 = country1.cityList.size();
                        let cityNum2 = country2.cityList.size();
                        if (cityNum1 > cityNum2) {
                            return -1;
                        } else if (cityNum2 > cityNum1) {
                            return 1;
                        } else {
                            if (v1 != v2) {
                                return v1 - v2;
                            } else {
                                return d2.PlayerAmount - d1.PlayerAmount; 
                            }
                            
                        }
                    }
                } else if (this._curFilterCond == "rongyu") {
                    // 荣誉
                    v1 = d1.Glory;
                    v2 = d2.Glory;
                } else if (this._curFilterCond == "chengyuan") {
                    // 成员
                    v1 = d1.PlayerAmount;
                    v2 = d2.PlayerAmount;
                } else if (this._curFilterCond == "bouns") {
                    v1 = d1.AvgMissionReward;
                    v2 = d2.AvgMissionReward;
                }
                if (v1 > v2) {
                    return -1;
                } else if (v1 < v2) {
                    return 1;
                } else {
                    if (cityId1 > cityId2) {
                        return -1;
                    } else {
                        return 1;
                    }
                }
            });
        }

        private _renderCities(idx: number, item:fairygui.GObject) {
            let data = this._orderCityData[idx];
			let com = item as AllCityItem;
			com.setReplyData(data, this._curFilterCond);
        }

        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            this._cityList.numItems = 0;
            this._orderCityData = [];
            super.close(...param);
        }
    }
}