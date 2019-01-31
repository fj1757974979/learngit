module War {
    
    //用于刷新地图判断
    export enum MapState {
        Normal,
        Transport,      //运输
        SelectMy,     //标记友军城池
        SelectEnemy,//标记敌军
        SurrenderCity,//投诚，投降城市
        SurrenderCamp,//投诚，投降国家
    }
    //国战状态
    export enum WarState {
        NormalState = 0,
        ReadyWar = 1,  // 战前准备
        InWar = 2,     // 国战期间
    }

    export class WarMgr extends BattleStatusDelegate {

        private static _inst: WarMgr;

        private _nowSelectCity: City;  
        private _hasCompleteMission: boolean;   //是否有任务完成
        private _hasNewNotice: boolean;         //是否有新消息
        // private _warState: WarState;    //当前状态：无、战前准备、国战期间
        private _mapState: MapState;            //地图状态
        private _citys: number[];         //
        
        private _warView: WarHomeView;
        
        public static ShowNotifyRedDot = "ShowNotifyRedDot";
        public static ShowMissionRedDot = "ShowMissionRedDot";
        public static RefreshCityInfo = "RefreshCityInfo";
        public static RefreshAppoint = "RefreshCityAppoint";
        public static KingDie = "KingDie";
        public static SelectCity = "SelectCity";
        public static RefreshShop = "RefreshShop";

        public static initialized: boolean = false;

        public static get inst(): WarMgr {
            if (!WarMgr._inst) {
                WarMgr._inst = new WarMgr();
            }
            return WarMgr._inst;
        }
        public constructor() {
            super();
            this.setDelegateHost(this);
            // this._warState = null;
            // this.
        }
        //
        public async joinSelectCityMode(bool: boolean, mode: MapState, citys?: number[]) {
            if (bool) {
                this._mapState = mode;
                this._citys = citys;
                if (this._citys && this._citys.length > 0) {
                    CityMgr.inst.setCitySelectMode(this._citys, true);
                }
            } else {
                this._mapState = MapState.Normal;
                if (this._citys && this._citys.length > 0) {
                    CityMgr.inst.setCitySelectMode(this._citys, false);
                }
            }
            
            let homeView = Core.ViewManager.inst.getView(ViewName.warHome) as WarHomeView;
            homeView.joinSelectMode(bool, mode);
        }
        //
        public async joinCity(cityID: number) {
            let result = await Net.rpcCall(pb.MessageID.C2S_SETTLE_CITY, pb.TargetCity.encode({CityID: cityID}));
            if (result.errcode == 0) {
                return true;
            } else {
                return false;
            }
        }
        //
        public async moveCity(cityID: number, gold: number) {
            let args = {CityID: cityID, Gold: gold};
            let result = await Net.rpcCall(pb.MessageID.C2S_MOVE_CITY, pb.MoveCityArg.encode(args));
            if (result.errcode == 0) {
                return true;
            } else {
                return false;
            }
        }
         public async fetchCityData(cityID: number) {
            let args = {CityID: cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CITY_DATA, pb.TargetCity.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CityData.decode(result.payload);
                this._nowSelectCity = CityMgr.inst.getCity(cityID);
                this._nowSelectCity.setCityData(reply);
                return true;
            }
            return false;
        }
        public async fetchCountryJobPlayer(country: Country) {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_COUNTRY_JOB_PLAYERS, null);
            if (result.errcode == 0) {
                let reply = pb.CampaignPlayerList.decode(result.payload);
                country.setCountryPlayers(reply.Players);
            }
        }
        //取属于该城的人
        public async fetchCityMember(cityID: number, page: number) {
            let args = {CityID: cityID, Page: page};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CITY_PLAYERS, pb.FetchCityPlayersArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CampaignPlayerList.decode(result.payload);
                return reply;
            } 
            return false;
        }
        //取在该城的人
        public async fetchInCityMember(cityID: number, page: number) {
            let args = {CityID: cityID, Page: page};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_IN_CITY_PLAYERS, pb.FetchCityPlayersArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CampaignPlayerList.decode(result.payload);
                return reply;
            } 
            return false;
        }
        //取本城的奴隶
        public async fetchCityCaptives(cityID: number, page: number) {
            let args = {CityID: cityID, Page: page};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CITY_CAPTIVES, pb.FetchCityPlayersArg.encode(args)); 
            if (result.errcode == 0) {
                let reply = pb.CampaignPlayerList.decode(result.payload);
                return reply;
            }
            return false;
        }
        public async fetchCountryMember(countryID: number, page: number) {
            let args = {CountryID: countryID, Page: page};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_COUNTRY_PLAYERS, pb.FetchCountryPlayersArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CampaignPlayerList.decode(result.payload);
                return reply;
            }
            return false;
        }
        //脱离
        public async quitCountry(uID?: number|Long) {
            let result = null;
            if (uID) {
                let args = {Uid: uID};
                result = await Net.rpcCall(pb.MessageID.C2S_QUIT_COUNTRY, pb.CampaignTargetPlayer.encode(args));
            } else  {
                result = await Net.rpcCall(pb.MessageID.C2S_QUIT_COUNTRY, null);
            }
            if (result.errcode == 0) {
                return true;
            }
            return false;
        }
        //任命
        public async appointJob(uID: number|Long, job: any, oldUid: number|Long) {
            let args = {Uid: uID, Job: job, OldUid: oldUid};
            let result = await Net.rpcCall(pb.MessageID.C2S_APPOINT_JOB, pb.AppointJobArg.encode(args));
            if (result.errcode == 0) {
                return true;
            }
            return false;
        }
        //罢免
        public async recallJob(uID: number|Long, job: any) {
            let args = {Uid: uID, Job: job};
            let result = await Net.rpcCall(pb.MessageID.C2S_RECALL_JOB, pb.RecallJobArg.encode(args));
            if (result.errcode == 0) {
                return true;
            }
            return false;
        }
        public async setForagePrice(price: number) {
            let args = {Price: price};
            let result = await Net.rpcCall(pb.MessageID.C2S_SET_FORAGE_PRICE, pb.SetForagePriceArg.encode(args));
            if (result.errcode == 0) {
                CityMgr.inst.getCity(MyWarPlayer.inst.cityID).foragePrice = price;
                return true;
            } else {
                return false;
            }
        }
        //发布任务
        public async publishMission(type: any, gold: number, cnt: number, tranType?: any, path?: number[]) {
            if (!WarMgr.inst.inStatus(BattleStatusName.ST_NORMAL)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70250));
                return false;
            }
            let args = null;
            // if (type == pb.CampaignMsType.Transport) {
            args = {Type: type, GoldReward: gold, Amount: cnt, TransportType: tranType, TransportCityPath: path};
            // } else {
                // args = {Type: type, GoldReward: gold, Amount: cnt};
            // }
            let result = await Net.rpcCall(pb.MessageID.C2S_CAMPAIGN_PUBLISH_MISSION, pb.CampaignPublishMissionArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CampaignPublishMissionReply.decode(result.payload);
                let view = Core.ViewManager.inst.getView(ViewName.cityManagePanel) as CityManageWnd;
                view.refreshMission(<pb.CampaignMissionInfo>reply.MissionInfo);
                let city = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
                if (city) {
                    city.forage = reply.Forage;
                    city.gold = reply.Gold;
                }
                return true;
            }
            return false;
        }
        //取军令
        public async fetchMilitaryOrders(city: City) {
            let args = {CityID: city.cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_MILITARY_ORDERS, pb.TargetCity.encode(args));
            if (result.errcode == 0) {
                let reply = pb.MilitaryOrderInfo.decode(result.payload);
                city.militaryOrderInfo = reply.Orders;
                return true;
            }
            return false;
        }
        //发布军令
        public async publishMilitaryOrders(city: City,type: number, food: number, amount: number, cityPath?: number[]) {
            if (!WarMgr.inst.inStatus(BattleStatusName.ST_DURING) && !WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70250));
                return false;
            }
            let args = {Type: type, Forage: food, Amount: amount, CityPath: cityPath};
            let result = await Net.rpcCall(pb.MessageID.C2S_PUBLISH_MILITARY_ORDERS, pb.PublishMilitaryOrderArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.PublishMilitaryOrderReply.decode(result.payload);
                city.militaryOrderInfo = reply.Orders;
                city.forage = reply.Forage;
                
                return true;
            }
            return false;
        }
        //接受军令
        public async acceptMilitaryOrder(type: number, cards: number[], cityID: number) {
            if (!WarMgr.inst.inStatus(BattleStatusName.ST_DURING) && !WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70321));
                return false;
            }
            let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
            if (city && city.inStatus(CityStatusName.ST_ATTACKED)) {
                if (type != pb.MilitaryOrderType.DefCityMT) {

                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70283));
                    return false;
                }
            }
            let args = {Type: type, CardIDs: cards, TargetCity: cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_ACCEPT_MILITARY_ORDER, pb.AcceptMilitaryOrderArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.AcceptMilitaryOrderReply.decode(result.payload);
                WarTeamMgr.inst.newMyTeam(<pb.TeamData>reply.Team);
                MyWarPlayer.inst.changeStatus(reply.State.State, -1, reply.State.Arg);
                return true;
            }
            return false;
        }
        public async surrender() {
            let result = await Net.rpcCall(pb.MessageID.C2S_CAMPAIGN_SURRENDER, null);
            if (result.errcode == 0) {
                //投降
                return true;
            }
            return false;
        }
        public async runAway() {
            let result = await Net.rpcCall(pb.MessageID.C2S_ESCAPED_FROM_JAIL, null);
            if (result.errcode == 0) {
                //逃跑
                let reply = pb.TargetCity.decode(result.payload);
                MyWarPlayer.inst.locationCityID = reply.CityID;
            } else if (result.errcode == 100) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70340));
            }
        }
        public async surrenderCity(campID: number) {
            let args = {CountryID: campID};
            let result = await Net.rpcCall(pb.MessageID.C2S_SURRENDER_CITY, pb.SurrenderCityArg.encode(args));
            if (result.errcode == 0) {
                return true;
            } else if (result.errcode == 12) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70341));
                return false;
            }
            return false;

        }
        public async autocephaly() {
            let result = await Net.rpcCall(pb.MessageID.C2S_AUTOCEPHALY, null);
                if (result.errcode == 0) {
                    return true;
                } else if (result.errcode == 12) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70341));
                    return false;
                }
                return false;
        }
        //国战兑换
        public async buyGoods(type: string, id: number) {
            let args = {Type: type, GoodsID: id};
            let result = await Net.rpcCall(pb.MessageID.C2S_CAMPAIGN_BUY_GOODS, pb.CampaignBuyGoodsArg.encode(args));
            if (result.errcode == 0) {
                Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshShop);
                return true;
            }
            return false;
        }
        //rpc
        //一个势力建立
        public async countryCreated(createData: pb.CountryCreatedArg) {
            CountryMgr.inst.addCountry(createData);
            CityMgr.inst.updateCityCamp(createData.CityID, createData.CountryID);
            CountryMgr.inst.countryAddCity(createData.CityID, createData.CountryID);
            CityMgr.inst.getCity(createData.CityID).yourMajesty = createData.YourMajesty;
            if (this._nowSelectCity && this._nowSelectCity.cityID && this._nowSelectCity.cityID == createData.CityID) {
                let ok = await this.fetchCityData(createData.CityID);
            }
        }
        //一个势力灭亡
        public async countryDestoryed(destoryData: pb.CountryDestoryed) {
            let country = CountryMgr.inst.getCountry(destoryData.CountryID);
            if (country) {
                country.changeStatus(CountryStatusName.ST_DEFEAT);
                CountryMgr.inst.removeCountry(destoryData);
            }
        }
        //一座城池被占领
        public async occupyCity(cityID: number, countryID: number) {
            //
            let city = CityMgr.inst.getCity(cityID);
            if (city.countryID != 0) {
                let oldCountry = CountryMgr.inst.getCountry(city.countryID);
                oldCountry.delCity(city);
            }
            let newCountry = CountryMgr.inst.getCountry(countryID);
            newCountry.addCity(city);
            city.countryID = countryID;
        }
        //一个势力改名//旗帜
        public async updateCountryName(countryID: number, name: string) {
            let country = CountryMgr.inst.getCountry(countryID);
            country.countryName = name;
        }
        public async updateCountryFlag(countryID: number, flag: string) {
            let country = CountryMgr.inst.getCountry(countryID);
            country.countryFlag = flag;
        }
        public async updateCityDefense() {

        }

        public get warView(): WarHomeView {
            return this._warView;
        }
        //view
        public async openWarHome() {

            this._mapState = MapState.Normal;
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CAMPAIGN_INFO, null);
            
            if (result.errcode == 0) {
                WarMgr.initialized = true;
                let reply = pb.CampaignInfo.decode(result.payload);
                // 初始化战场状态
                // reply.State.State = pb.CampaignState.StateEnum.Unified;
                this.updateState(<pb.CampaignState>reply.State);
                // 设置势力基本数据
                CountryMgr.inst.setAllCountry(reply.Countrys);
                // 初始化战场界面
                await Core.ViewManager.inst.open(ViewName.warHome);
                this._warView = <WarHomeView>Core.ViewManager.inst.getView(ViewName.warHome);
                // 设置城池基本数据
                await CityMgr.inst.setAllCity(reply.Citys);
                CityMgr.inst.setAllCityDefPlayers(<pb.CitysDefPlayerAmount>reply.DefPlayerAmounts);
                // 设置玩家数据
                await MyWarPlayer.inst.initByCampaignInfo(reply);
                
                if (reply.MyTeam) {
                   await WarTeamMgr.inst.newMyTeam(<pb.TeamData>reply.MyTeam);
                }
                this._warView.initMap();
                // 地图上所有队伍数据
                if (reply.Teams) {
                    for (let i = 0; i < reply.Teams.length; i++) {
                        let teamData = reply.Teams[i];
                        if (WarTeamMgr.inst.myTeam && WarTeamMgr.inst.myTeam.teamID == teamData.ID) {
                            break;
                        }
                        let team = new WarTeam(<pb.TeamData>teamData);
                        WarTeamMgr.inst.addOtherTeam(team);
                    }
                    // reply.Teams.forEach(teamData => {
                    //     if (WarTeamMgr.inst.myTeam && WarTeamMgr.inst.myTeam.teamID)
                        
                    // });
                }
                this._hasCompleteMission = reply.HasCompleteMission;
                this._hasNewNotice = reply.HasNewNotice;
                this._warView.refreshHomeView();
                if (!WarTeamMgr.inst.myTeam) {
                    if (reply.TeamDisappear) {
                        WarTeam.showTeamDisappearTips(reply.TeamDisappear);
                    }
                }
            }
        }

        public async updateState(state: pb.CampaignState) {
            let st = state.State;
            if (st == pb.CampaignState.StateEnum.Normal) {
                let data = pb.CaStateWarArg.decode(state.Arg);
                await this.changeStatus(BattleStatusName.ST_NORMAL, data.RemainTime);
            } else if (st == pb.CampaignState.StateEnum.ReadyWar) {
                let data = pb.CaStateWarArg.decode(state.Arg);
                await this.changeStatus(BattleStatusName.ST_PREPARE, data.RemainTime);
            } else if (st == pb.CampaignState.StateEnum.InWar) {
                let data = pb.CaStateWarArg.decode(state.Arg);
                await this.changeStatus(BattleStatusName.ST_DURING, data.RemainTime);
            } else if (st == pb.CampaignState.StateEnum.WarEnd) {
                let data = pb.CaStateWarEndArg.decode(state.Arg);
                await this.changeStatus(BattleStatusName.ST_END, data.NextWarRemainTime, data);
            } else if (st == pb.CampaignState.StateEnum.Unified) {
                let data = pb.CaStateUnifiedArg.decode(state.Arg);
                await this.changeStatus(BattleStatusName.ST_UNIFIED, -1, data);
            }
            
            // Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshWarHome);
        }

        public async openMyCityInfo() {
            this.openCityInfo(MyWarPlayer.inst.cityID);
        }
        public async openCityInfo(cityID: number) {
            let ok = await this.fetchCityData(cityID);
            if (ok) {
                Core.ViewManager.inst.open(ViewName.cityInfoPanel, cityID);
                // if (this._curStatusObj.name == BattleStatusName.ST_NORMAL) {
                //     Core.ViewManager.inst.open(ViewName.cityInfoPanel, cityID);
                // } else if (this._curStatusObj.name == BattleStatusName.ST_PREPARE) {
                //     Core.ViewManager.inst.open(ViewName.cityInfoWarPanel, cityID);
                // }
            }
        }
        public async openMyQuestInfo() {
            this.openQuestInfo(MyWarPlayer.inst.cityID);
        }
        public async openQuestInfo(cityID: number) {
            let args = {CityID: cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CAMPAIGN_MISSION_INFO, pb.TargetCity.encode(args));
            if (result.errcode == 0) {
                let reply = pb.CampaignMissionInfo.decode(result.payload);
                Core.ViewManager.inst.open(ViewName.warQuestPanel, cityID, reply);
            }
        }
        public async openCountryInfo(id: number) {

        }

        
        public async openCityManagePanel(cityID: number) {
            let args = {CityID: cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_PATROL_CITY, pb.TargetCity.encode(args));
            if (result.errcode == 0) {
                let reply = pb.PatrolCityReply.decode(result.payload);
                MyWarPlayer.inst.setInfoForPatrolCityReply(reply);
                Core.ViewManager.inst.open(ViewName.cityManagePanel, cityID);
            }
        }
        public async openSetFoodPriceWnd(city: City) {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_FORAGE_PRICE, null);
            if (result.errcode == 0) {
                let city = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
                let reply = pb.FetchForagePriceReply.decode(result.payload);
                city.forage = reply.ForageAmount;
                city.foragePrice = reply.Price;
                Core.ViewManager.inst.open(ViewName.setFoodPriceWnd, city);
            }
        }
        public async openCityListPanel() {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_ALL_CITY_PLAYER_AMOUNT, null);
            if (result.errcode == 0) {
                let reply = pb.AllCityPlayerAmount.decode(result.payload);
                //缓存国家人数
                // reply.PlayerAmounts.forEach( cityData => {
                //     CityMgr.inst.updateCityPlayerNum(cityData.CityID ,cityData.PlayerAmount);
                // })
                Core.ViewManager.inst.open(ViewName.allCityPanel, reply);
            }
        }
        public async openEmperorApply(cityID: number) {
            let args = {CityID: cityID};
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_APPLY_CREATE_COUNTRY_INFO, pb.TargetCity.encode(args));
            if (result.errcode == 0) {
                let reply = pb.ApplyCreateCountryData.decode(result.payload);
                Core.ViewManager.inst.open(ViewName.emperorApplyWnd, cityID, reply);
            }
        }

        public checkWarIsOver() {
            let b = WarMgr.inst.isWarOver;
            if (b) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70378));
            }
            return b;
        }

        // public get warState(): WarState {
        //     return this._warState;
        // }
        // public set warState(state: WarState) {
        //     this._warState = state;
        // }
        public get stateTime(): number {
            return this.getCurStatusRemainTime();
        }
        public get nowSelectCity() {
            return this._nowSelectCity;
        }
        public set nowSelectCity(city: City) {
            this._nowSelectCity = city;
        }
        public get hasCompleteMisson(): boolean {
            return this._hasCompleteMission;
        }
        public set hasCompleteMission(bool: boolean) {
            this._hasCompleteMission = bool;
        }
        public get hasNewNotice(): boolean {
            return this._hasNewNotice;
        }
        public set hasNewNotice(bool: boolean) {
            this._hasNewNotice = bool;
        }
        public set mapState(state: MapState) {
            this._mapState = state;
        }
        public get mapState(): MapState {
            return this._mapState;
        }

        public onDestroy() {
            this._nowSelectCity = null;
            WarTeamMgr.inst.onDestroy();
            CityMgr.inst.onDestroy();
            MyWarPlayer.inst.resetToNoneStatus();
            this.resetToNoneStatus();

            WarMgr.initialized = false;
        }
    }

    export function init() {
        initRpc();
        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;

        registerView(ViewName.warHome, () => {
            let warHomeView = createObject(PkgName.war, ViewName.warHome, WarHomeView) as WarHomeView;
            return warHomeView;
        })
        registerView(ViewName.cityInfoPanel, () => {
            let cityInfoPanel = new CityInfoWnd();
            cityInfoPanel.contentPane = createObject(PkgName.war, ViewName.cityInfoPanel).asCom;
            return cityInfoPanel;
        })
        registerView(ViewName.warQuestPanel, () => {
            let questPanel = new WarQuestWnd();
            questPanel.contentPane = createObject(PkgName.war, ViewName.warQuestPanel).asCom;
            return questPanel;
        })
        registerView(ViewName.cityManagePanel, () => {
            let cityManagePanel = new CityManageWnd();
            cityManagePanel.contentPane = createObject(PkgName.war, ViewName.cityManagePanel).asCom;
            return cityManagePanel;
        })
        registerView(ViewName.addGoldWnd, () => {
            let addGoldWnd = new AddGoldWnd();
            addGoldWnd.contentPane = createObject(PkgName.war, ViewName.addGoldWnd).asCom;
            return addGoldWnd;
        })
        registerView(ViewName.setFoodPriceWnd, () => {
            let setFoodPriceWnd = new SetFoodPriceWnd();
            setFoodPriceWnd.contentPane = createObject(PkgName.war, ViewName.setFoodPriceWnd) as AddGoldWnd;
            return setFoodPriceWnd;
        })
        registerView(ViewName.allMemberPanel, () => {
            let allMemberPanel = new AllMemberPanel();
            allMemberPanel.contentPane = createObject(PkgName.war, ViewName.allMemberPanel) as AllMemberPanel;
            return allMemberPanel;
        })
        registerView(ViewName.allCityPanel, () => {
            let allCityPanel = new AllCityPanel();
            allCityPanel.contentPane = createObject(PkgName.war, ViewName.allCityPanel) as AllCityPanel;
            return allCityPanel;
        })
        registerView(ViewName.warNoticePanel, () => {
            let warNoticePanel = new WarNoticePanel();
            warNoticePanel.contentPane = createObject(PkgName.war, ViewName.warNoticePanel) as WarNoticePanel;
            return warNoticePanel;
        })
        registerView(ViewName.questChooseCardWnd, () => {
            let questChooseCardWnd = new QuestChooseCardWnd();
            questChooseCardWnd.contentPane = createObject(PkgName.war, ViewName.questChooseCardWnd).asCom;
            return questChooseCardWnd;
        })
        registerView(ViewName.emperorApplyWnd, () => {
            let emperorApplyWnd = new EmperorApplyWnd();
            emperorApplyWnd.contentPane = createObject(PkgName.war, ViewName.emperorApplyWnd).asCom;
            return emperorApplyWnd;
        })
        registerView(ViewName.independentWnd, () => {
            let independentWnd = new IndependentWnd();
            independentWnd.contentPane = createObject(PkgName.war, ViewName.independentWnd).asCom;
            return independentWnd;
        })
        registerView(ViewName.appointChooseWnd, () => {
            let appointChooseWnd = new AppointChooseWnd();
            appointChooseWnd.contentPane = createObject(PkgName.war, ViewName.appointChooseWnd).asCom;
            return appointChooseWnd;
        })
        registerView(ViewName.questReleaseWnd, () => {
            let questReleaseWnd = new QuestReleaseWnd();
            questReleaseWnd.contentPane = createObject(PkgName.war, ViewName.questReleaseWnd).asCom;
            return questReleaseWnd;
        })
        registerView(ViewName.questTransReleaseWnd, () => {
            let questTransReleaseWnd = new QuestTransReleaseWnd();
            questTransReleaseWnd.contentPane = createObject(PkgName.war, ViewName.questTransReleaseWnd).asCom;
            return questTransReleaseWnd;
        })
        registerView(ViewName.modifyCampFlagWnd, () => {
            let modifyCampWnd = new ModifyCampFlagWnd();
            modifyCampWnd.contentPane = createObject(PkgName.war, ViewName.modifyCampFlagWnd).asCom;
            return modifyCampWnd;
        })
        
        registerView(ViewName.countryAppointPanel, () => {
            let countryAppointPanel = new CountryAppointWnd();
            countryAppointPanel.contentPane = createObject(PkgName.war, ViewName.countryAppointPanel).asCom;
            return countryAppointPanel;
        })
        registerView(ViewName.cityAppointPanel, () => {
            let cityAppointPanel = new CityAppointWnd();
            cityAppointPanel.contentPane = createObject(PkgName.war, ViewName.cityAppointPanel).asCom;
            return cityAppointPanel;
        })
        registerView(ViewName.addGoldRecordPanel, () => {
            let addGoldRecordPanel = new AddGoldRecordPanel();
            addGoldRecordPanel.contentPane = createObject(PkgName.war, ViewName.addGoldRecordPanel).asCom;
            return addGoldRecordPanel;
        })
        registerView(ViewName.cityNoticeWnd, () => {
            let cityNoticeWnd = new CityNoticeWnd();
            cityNoticeWnd.contentPane = createObject(PkgName.war, ViewName.cityNoticeWnd).asCom;
            return cityNoticeWnd;
        })
        registerView(ViewName.cityInfoWarPanel, () => {
            let cityInfoWarPanel = new WarCityInfoWnd();
            cityInfoWarPanel.contentPane = createObject(PkgName.war, ViewName.cityInfoWarPanel).asCom;
            return cityInfoWarPanel;
        })
        // registerView(ViewName.cityManageFightWnd, () => {
        //     let cityManageFightWnd = new CityManageFightWnd();
        //     cityManageFightWnd.contentPane = createObject(PkgName.war, ViewName.cityManageFightWnd).asCom;
        //     return cityManageFightWnd;
        // })
        registerView(ViewName.questAttackReleaseWnd, () => {
            let questAttackReleaseWnd = new QuestAttackReleaseWnd();
            questAttackReleaseWnd.contentPane = createObject(PkgName.war, ViewName.questAttackReleaseWnd).asCom;
            return questAttackReleaseWnd;
        })
        registerView(ViewName.questDefenseReleaseWnd, () => {
            let questDefenseReleaseWnd = new QuestDefenseReleaseWnd();
            questDefenseReleaseWnd.contentPane = createObject(PkgName.war, ViewName.questDefenseReleaseWnd).asCom;
            return questDefenseReleaseWnd;
        })
        registerView(ViewName.questMoveReleaseWnd, () => {
            let questMoveReleaseWnd = new QuestMoveReleaseWnd();
            questMoveReleaseWnd.contentPane = createObject(PkgName.war, ViewName.questMoveReleaseWnd).asCom;
            return questMoveReleaseWnd;
        })
        registerView(ViewName.questFightPanel, () => {
            let questFightPanel = new QuestFightPanel();
            questFightPanel.contentPane = createObject(PkgName.war, ViewName.questFightPanel).asCom;
            return questFightPanel;
        })
        registerView(ViewName.choiceFightCardWnd, () => {
            let choiceFightCardWnd = new ChoiceFightCardWnd();
            choiceFightCardWnd.contentPane = createObject(PkgName.war, ViewName.choiceFightCardWnd).asCom;
            return choiceFightCardWnd;
        });
        registerView(ViewName.questMigrateReleaseWnd, () => {
            let questMigrateReleaseWnd = new QuestMigrateReleaseWnd();
            questMigrateReleaseWnd.contentPane = createObject(PkgName.war, ViewName.questMigrateReleaseWnd).asCom;
            return questMigrateReleaseWnd;
        });
        registerView(ViewName.warShopView, () => {
            let warShopView = fairygui.UIPackage.createObject(PkgName.war, ViewName.warShopView, WarShopView) as WarShopView;
            return warShopView;
        });
        registerView(ViewName.battleEndView, () => {
            return fairygui.UIPackage.createObject(PkgName.war, ViewName.battleEndView, WarEndView) as WarEndView;
        });

        registerView(ViewName.battleUnifiedView, () => {
            return fairygui.UIPackage.createObject(PkgName.war, ViewName.battleUnifiedView, WarUnifiedView) as WarUnifiedView;
        });

        registerView(ViewName.enterWarAni, () => {
            return fairygui.UIPackage.createObject(PkgName.war, ViewName.enterWarAni, WarEnterAniView) as WarEnterAniView;
        })
    }
}
