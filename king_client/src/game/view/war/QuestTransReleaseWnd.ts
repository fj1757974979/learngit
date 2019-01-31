module War {

    export class QuestTransReleaseWnd extends Core.BaseWindow {

        private _goldConfirmBtn: fairygui.GButton;
        private _foodConfirmBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;
        private _goldBtn: fairygui.GButton;
        private _foodBtn: fairygui.GButton;
        private _cityLoader: fairygui.GLoader;
        private _cityNameText: fairygui.GTextField;
        private _dayCntText: fairygui.GTextField;
        private _goldMemberInput: fairygui.GTextField;
        private _foodMemberInput: fairygui.GTextField;
        private _goldInput: fairygui.GTextField;
        private _foodInput: fairygui.GTextField;
        private _goldDesc: fairygui.GTextField;
        private _foodDesc: fairygui.GTextField;
        private _goldCntDesc: fairygui.GTextField;
        private _foodCntDesc: fairygui.GTextField;
        private _goldMemberCnt: fairygui.GSlider;
        private _goldCnt: fairygui.GSlider;
        private _foodMemberCnt: fairygui.GSlider;
        private _foodCnt: fairygui.GSlider;

        private _goldResCom1: CityInfoCom;
        private _goldResCom2: CityInfoCom;
        private _foodResCom: CityInfoCom;
        private _typeCtr: fairygui.Controller;

        private _toCity: City;
        private _fromCity: City;
        private _cityPath: Array<number>;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._cityNameText = this.contentPane.getChild("cityName").asTextField;
            this._cityLoader = this.contentPane.getChild("n24").asLoader;
            this._dayCntText = this.contentPane.getChild("dayCnt").asTextField;
            this._goldMemberInput = this.contentPane.getChild("goldMemberInput").asTextField;
            this._goldInput = this.contentPane.getChild("goldInput").asTextField;
            this._goldDesc =this.contentPane.getChild("goldTxt2").asTextField;
            this._goldCntDesc =this.contentPane.getChild("goldTxt1").asTextField;
            this._foodMemberInput = this.contentPane.getChild("foodMemberInput").asTextField;
            this._foodInput = this.contentPane.getChild("foodInput").asTextField;
            this._foodDesc =this.contentPane.getChild("foodTxt2").asTextField;
            this._foodCntDesc =this.contentPane.getChild("foodTxt1").asTextField;
            this._typeCtr = this.contentPane.getController("resource");

                        
            this._goldMemberCnt = this.contentPane.getChild("goldMemberCnt").asSlider;
            this._goldMemberCnt.getChild("title").visible = false;
            this._goldCnt = this.contentPane.getChild("goldCnt").asSlider;
            this._goldCnt.getChild("title").visible = false;
            this._foodMemberCnt = this.contentPane.getChild("foodMemberCnt").asSlider;
            this._foodMemberCnt.getChild("title").visible = false;
            this._foodCnt = this.contentPane.getChild("foodCnt").asSlider;
            this._foodCnt.getChild("title").visible = false;


            this._goldResCom1 = this.contentPane.getChild("gold1").asCom as CityInfoCom;
            this._goldResCom2 = this.contentPane.getChild("gold2").asCom as CityInfoCom;
            this._foodResCom = this.contentPane.getChild("food").asCom as CityInfoCom;

            this._goldConfirmBtn = this.contentPane.getChild("goldConfirmBtn").asButton;
            this._foodConfirmBtn = this.contentPane.getChild("foodConfirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._goldBtn = this.contentPane.getChild("worldChk").asButton;
            this._foodBtn = this.contentPane.getChild("warChk").asButton;

            this._closeBtn.addClickListener(this._onClose, this);
            this._goldConfirmBtn.addClickListener(this._onGoldConfirm, this);
            this._foodConfirmBtn.addClickListener(this._onFoodConfirm, this);
            this._goldBtn.addClickListener(this._onGoldBtn, this);
            this._foodBtn.addClickListener(this._onFoodBtn, this);
            this._cityLoader.touchable = true;
            this._cityLoader.addClickListener(this._reSelect, this);

            // this._memberInput.addEventListener(fairygui.ItemEvent.FOCUS_OUT, this._memberInputChange, this);
            // this._goldInput.addEventListener(fairygui.ItemEvent.FOCUS_OUT, this._goldInputChange, this);
            this._goldMemberCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._goldMemberInputChange, this);
            this._goldCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._goldInputChange, this);
            this._foodMemberCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._foodMemberInputChange, this);
            this._foodCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._foodInputChange, this);
        }
        public async open(...param: any[]) {
            super.open(...param);
            this._cityPath = new Array<number>();
            this._fromCity = WarMgr.inst.nowSelectCity;
            
            this._foodResCom.setInfo(WarResType.Forage, this._fromCity.forage);
            this._goldResCom1.setInfo(WarResType.Gold, this._fromCity.gold);
            this._goldResCom2.setInfo(WarResType.Gold, this._fromCity.gold);
            this._typeCtr.selectedIndex = 0;
            this._refresh(param[0]);
        }

        private async _refresh(CityID: number) {
            this._toCity = CityMgr.inst.getCity(CityID);
            //let speed = Data.parameter.get("march_speed").para_value[0];
            let time = Data.parameter.get("transport_time").para_value[0];
            this._cityPath = CityMgr.inst.getShortestPathBetweenCityForTransport(this._fromCity, this._toCity);
            this._cityNameText.text = this._toCity.cityName;
            //this._dayCntText.text = `${(Road.countCityPathDistance(this._cityPath) / speed)}秒`;
            let roadDis = Road.countCityPathDistance(this._cityPath);
            // console.log(roadDis);
            let totalTime = time * roadDis;
            this._dayCntText.text = `${Core.StringUtils.secToString(totalTime, "hm")}`;
            this._goldInput.text = "0";
            this._goldMemberInput.text = "0";
            this._goldMemberCnt.value = 0;
            this._goldCnt.value = 0;
            this._foodInput.text = "0";
            this._foodMemberInput.text = "0";
            this._foodMemberCnt.value = 0;
            this._foodCnt.value = 0;
            let goldnum = Data.parameter.get("task_target_transport").para_value[0];
            let foodNum = Data.parameter.get("task_target_transport").para_value[1];
            if (this._fromCity.forage < foodNum) {
                this._foodMemberCnt.max = 1;
                this._foodMemberCnt.touchable = false;
                this._foodMemberCnt.grayed = true;
            } else {
                this._foodMemberCnt.max = Math.floor(this._fromCity.forage / foodNum);
                this._foodMemberCnt.touchable = true;
                this._foodMemberCnt.grayed = false;
            }
            if (this._fromCity.gold < goldnum) {
                this._goldMemberCnt.max = 1;
                this._goldMemberCnt.touchable = false;
                this._goldMemberCnt.grayed = true;
            } else {
                this._goldMemberCnt.max = Math.floor(this._fromCity.gold / goldnum);
                this._goldMemberCnt.touchable = true;
                this._goldMemberCnt.grayed = false;
            }
            if (this._fromCity.gold >= 0) {
                this._goldCnt.max = this._fromCity.gold;
                this._goldCnt.grayed = false;
                this._goldCnt.touchable = true;
            } else {
                this._goldCnt.max = 1;
                this._goldCnt.grayed = true;
                this._goldCnt.touchable = false;
            }
            
            this._foodConfirmBtn.touchable = false;
            this._foodConfirmBtn.grayed = true;
            this._goldConfirmBtn.touchable = false;
            this._goldConfirmBtn.grayed = true;
            

            this._goldInputChange();
            this._foodInputChange();
            this._goldMemberInputChange();
            this._foodMemberInputChange();
        }
        private async _goldMemberInputChange() {
            let num = 0;
            num = Data.parameter.get("task_target_transport").para_value[0];
            let curCut = this._goldMemberCnt.value;
            let curReward = this._goldCnt.value;
            this._goldMemberInput.text = `${curCut}`;
            let countCur = curCut;  //当次数为0时
            if (countCur == 0) {
                countCur = 1;
            }
            let maxReward = Math.min(10000,Math.floor((this._fromCity.gold - (curCut * num))/countCur));
            if (curReward > maxReward) {
                this._goldInput.text = maxReward.toString();
                this._goldCnt.value = maxReward;
            }
            if (maxReward <= 0) {
                this._goldCnt.max = 1;
                this._goldCnt.touchable = false;
                this._goldCnt.grayed = true;
            } else {
                this._goldCnt.max = maxReward;
                this._goldCnt.touchable = true;
                this._goldCnt.grayed = false;
            }
            
            this._countGold();
        }
        private async _goldInputChange() {
            this._goldInput.text = `${this._goldCnt.value}`;
            this._countGold();        
        }

        private async _foodMemberInputChange() {
            let num = 0;
            num = Data.parameter.get("task_target_transport").para_value[1];
            let curCut = this._foodMemberCnt.value;
            if (this._fromCity.forage < num) {
                this._foodMemberCnt.value = 0;
            } 
            this._foodMemberInput.text = `${this._foodMemberCnt.value}`;
            this._countFoodGold();
        }
        

        private async _foodInputChange() {
            this._foodInput.text = `${this._foodCnt.value}`;
            this._countFoodGold();        
        }
        private async _countGold() {
            let num = 0;
            num = Data.parameter.get("task_target_transport").para_value[0];
            //let cntNum = parseInt(this._goldMemberInput.text);
            //let goldNum = parseInt(this._goldInput.text);
            let cntNum = this._goldMemberCnt.value;
            let goldNum = this._goldCnt.value;
            let cntRes = cntNum * num;  //需要运输的资源
            let rewardGold = goldNum * cntNum;
                if (cntNum) {
                    this._goldCntDesc.text = Core.StringUtils.format(Core.StringUtils.TEXT(70290), cntRes);
                } else {
                    this._goldCntDesc.text = "";
                }
                if (cntRes + rewardGold > this._fromCity.gold || cntRes == 0) {
                    this._goldConfirmBtn.touchable = false;
                    this._goldConfirmBtn.grayed = true;
                } else {
                    this._goldConfirmBtn.touchable = true;
                    this._goldConfirmBtn.grayed = false;
                }
            if (goldNum) {
                this._goldDesc.text = Core.StringUtils.format(Core.StringUtils.TEXT(70289), goldNum); 
            } else {
                this._goldDesc.text = ""; 
            }
            this._goldResCom1.setInfo(WarResType.Gold, this._fromCity.gold - (cntRes + rewardGold));
        }

        private async _countFoodGold() {
            let num = 0;
            num = Data.parameter.get("task_target_transport").para_value[1];
            let cntNum = this._foodMemberCnt.value;
            let goldNum = this._foodCnt.value;
            let cntRes = cntNum * num;  //需要运输的资源
            let rewardGold = goldNum * cntNum;
            if (cntNum) {
                this._foodCntDesc.text = Core.StringUtils.format(Core.StringUtils.TEXT(70291), cntRes);;
            } else {
                this._foodCntDesc.text = "";
            }
            if (cntRes <= this._fromCity.forage && rewardGold <= this._fromCity.gold) {
                let newCnt = cntNum;
                if (newCnt == 0) {
                    newCnt = 1;
                }
                let maxReward = Math.min(10000,Math.floor(this._fromCity.gold / newCnt));
                if (goldNum > maxReward) {
                    goldNum = maxReward;
                    this._foodCnt.value = goldNum;
                }
                this._foodCnt.max = maxReward;
            } 
            if (cntNum == 0) {
                this._foodConfirmBtn.touchable = false;
                this._foodConfirmBtn.grayed = true;
            } else {
                this._foodConfirmBtn.touchable = true;
                this._foodConfirmBtn.grayed = false;
            }     
            
            if (goldNum) {
                this._foodDesc.text = Core.StringUtils.format(Core.StringUtils.TEXT(70288), goldNum); 
            } else {
                this._foodDesc.text = ""; 
            }
            this._goldResCom2.setInfo(WarResType.Gold, this._fromCity.gold - (goldNum * cntNum));
            this._foodResCom.setInfo(WarResType.Forage, this._fromCity.forage - cntRes);
        }
        
        private async _onClose() {
            Core.ViewManager.inst.closeView(this);
        }
        private async _onGoldConfirm() {
            let rewardGold = parseInt(this._goldInput.text);
            let cnt = parseInt(this._goldMemberInput.text);
            let tranType = pb.TransportTypeEnum.GoldTT;
             if (cnt <= 0) {
                 return;
             }
            let ok = await WarMgr.inst.publishMission(pb.CampaignMsType.Transport, rewardGold, cnt, tranType, this._cityPath);
            if (ok) {
                //  let num = 0;
                // num += (rewardGold + Data.parameter.get("task_target_transport").para_value[0]) * cnt ;
                // this._fromCity.gold -= num;
                Core.ViewManager.inst.closeView(this);
            }

        }
        private async _onFoodConfirm() {
            let rewardGold = this._foodCnt.value;
            let cnt = parseInt(this._foodMemberInput.text);
            let tranType = pb.TransportTypeEnum.ForageTT;
             
            let ok = await WarMgr.inst.publishMission(pb.CampaignMsType.Transport, rewardGold, cnt, tranType, this._cityPath);
            if (ok) {
                // let num = 0;
                // num += rewardGold * cnt;
                // this._fromCity.gold -= num;
                // this._fromCity.forage -= cnt * Data.parameter.get("task_target_transport").para_value[1];
                Core.ViewManager.inst.closeView(this);
            }

        }
        private _reCity(evt: egret.Event) {
            let cityID = evt.data;
            if (cityID) {
                this._refresh(cityID);
            }
            WarMgr.inst.joinSelectCityMode(false, MapState.Transport);
            Core.EventCenter.inst.removeEventListener(WarMgr.SelectCity, this._reCity, this);
        }
        private async _onGoldBtn() {
            this._countGold();
        }
        private async _onFoodBtn() {
            this._countFoodGold();
        }
        private async _reSelect() {
            WarMgr.inst.joinSelectCityMode(true, MapState.Transport);
            Core.EventCenter.inst.addEventListener(WarMgr.SelectCity, this._reCity, this);
            // Core.ViewManager.inst.closeView(this);
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}
