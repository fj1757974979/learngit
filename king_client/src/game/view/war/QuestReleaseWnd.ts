module War {

    export class QuestReleaseWnd extends Core.BaseWindow {
        private _cityInfobar: CityInfoBar;
        private _titleText: fairygui.GTextField;
        private _memberInput: fairygui.GTextField;
        private _goldInput: fairygui.GTextField;
        private _goldIcon: fairygui.GLoader;
        private _missionDesc: fairygui.GTextField;
        private _rewardDesc: fairygui.GTextField;
        private _resCom: CityInfoCom;
        private _confirmBtn: fairygui.GButton;
        private _closeBtn: fairygui.GButton;
        private _city: City;
        private _type: WarMsType;
        private _callBack: any;
        private _mission: pb.ICampaignMission;
        private _memberCnt: fairygui.GSlider;
        private _goldCnt: fairygui.GSlider;
        private _totlaGold: fairygui.GTextField;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._cityInfobar = this.contentPane.getChild("nongyeProgress").asCom as CityInfoBar;
            this._titleText = this.contentPane.getChild("n1").asTextField;
            this._memberInput = this.contentPane.getChild("memberInput").asTextField;
            this._goldInput = this.contentPane.getChild("goldInput").asTextField;
            this._goldIcon = this.contentPane.getChild("n11").asLoader;
            this._missionDesc = this.contentPane.getChild("txt1").asTextField;
            this._rewardDesc = this.contentPane.getChild("txt2").asTextField;
            this._resCom = this.contentPane.getChild("res").asCom as CityInfoCom;
            this._confirmBtn = this.contentPane.getChild("confirmBtn").asButton;
            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._memberCnt = this.contentPane.getChild("memberCnt").asSlider;
            this._memberCnt.getChild("title").visible = false;
            this._goldCnt = this.contentPane.getChild("goldCnt").asSlider;
            this._goldCnt.getChild("title").visible = false;
            this._totlaGold = this.contentPane.getChild("totalGold").asTextField;

            this._closeBtn.addClickListener(this._onCloseBtn, this);
            this._confirmBtn.addClickListener(this._onConfirmBtn, this);

            //this._memberInput.addEventListener(fairygui.ItemEvent.FOCUS_OUT, this._memberInputChange, this);
            this._memberCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._memberInputChange, this);
            this._goldCnt.addEventListener(fairygui.StateChangeEvent.CHANGED, this._goldInputChange, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            // this._callBack = param[0];
            this._type = param[0];
            this._city = param[1];
            this._mission = param[2];

            this._refresh();
        }
        private _refresh() {
            this._titleText.text = `${Utils.warMsType2text(this._type)}`;
            this._cityInfobar.setProgress(this._city.getMsRes(this._type), this._city.getMsResMax(this._type));
            this._cityInfobar.setProgress2(this._city.getMsRes(this._type), this._city.getMsResMax(this._type));
            this._cityInfobar.setIconUrl(Utils.warMsType2Url(this._type));
            let resType = Utils.warMsType2WarResType(this._type);
            if (resType) {
                this._cityInfobar.openClick(resType);
            }
            this._resCom.setInfo(WarResType.Gold, this._city.gold);
            this._goldInput.text = "0";
            this._memberInput.text = "0";
            this._totlaGold.text = "0";
            this._memberCnt.value = 0;
            this._goldCnt.value = 0;
            //已满的情况
            if (Math.ceil((this._city.getMsResMax(this._type) - this._city.getMsRes(this._type))/ WarQuest.warMsType2reward(this._type)) == 0) {
                this._memberCnt.grayed = true;
                this._memberCnt.touchable = false;
            } else {
                this._memberCnt.grayed = false;
                this._memberCnt.touchable = true;
                this._memberCnt.max = Math.ceil((this._city.getMsResMax(this._type) - this._city.getMsRes(this._type))/ WarQuest.warMsType2reward(this._type));
            }
            let maxReward = 0;
            maxReward = Math.floor(this._city.gold / this._memberCnt.max);
            //没钱的情况
            if (this._city.gold > 0) {
                if (maxReward >= 10000) {
                    this._goldCnt.max = 10000;
                } else {
                    this._goldCnt.max = this._city.gold;
                }
                this._goldCnt.grayed = false;
                this._goldCnt.touchable = true;
            } else {
                this._goldCnt.max = 1;
                this._goldCnt.grayed = true;
                this._goldCnt.touchable = false;
            }
            this._confirmBtn.touchable = false;
            this._confirmBtn.grayed = true;
            this._goldCnt.value = 0;
            this._cityInfobar.setProgress2(this._city.getMsRes(this._type)  + this._memberCnt.max, this._city.getMsResMax(this._type));
            this._goldInputChange();
            this._memberInputChange();

        }
        private async _memberInputChange() {
            let curCnt = this._memberCnt.value;
            let curReward = this._goldCnt.value;
            this._memberInput.text = `${curCnt}`;
            this._cityInfobar.setProgress2(this._city.getMsRes(this._type) + curCnt * WarQuest.warMsType2reward(this._type), this._city.getMsResMax(this._type));
            this._cityInfobar.setText(this._city.getMsRes(this._type),this._city.getMsResMax(this._type),curCnt * WarQuest.warMsType2reward(this._type));
            let maxReward = 0;
            if (curCnt == 0) {
                maxReward = Math.min(10000,this._city.gold);
            } else {
                maxReward = Math.min(10000,Math.floor(this._city.gold / curCnt));
            }
            
            if (curReward > maxReward) {
                this._goldInput.text = maxReward.toString();
                this._goldCnt.value = maxReward;
            }
            if (maxReward <= 0) {
                this._goldCnt.max = 1;
                this._goldCnt.grayed = true;
                this._goldCnt.touchable = false;
            } else {
                this._goldCnt.max = maxReward;
                this._goldCnt.grayed = false;
                this._goldCnt.touchable = true;
            }
            // this._goldCnt.max = maxReward;
            this._countGold();
        }
        private async _goldInputChange() {
            this._goldInput.text = `${this._goldCnt.value}`;
            this._countGold();        
        }
        private async _countGold() {
            let num = 0;
            
            let cntNum = this._memberCnt.value;
            let goldNum = this._goldCnt.value;
            let cntGold = cntNum * num;
            let rewardGold = goldNum * cntNum;

            if (goldNum){
                this._rewardDesc.text = Core.StringUtils.format(Core.StringUtils.TEXT(70288), goldNum); 
            } else {
                this._rewardDesc.text = "";
            }

            if (cntNum) {
                this._missionDesc.text = Core.StringUtils.format(Core.StringUtils.TEXT(70289), cntNum * WarQuest.warMsType2reward(this._type));
            } else {
                this._missionDesc.text = "";
            }
            this._resCom.setInfo(WarResType.Gold, this._city.gold - (this._goldCnt.value * this._memberCnt.value));
            this._totlaGold.text = `${this._goldCnt.value * this._memberCnt.value}`;
            if (cntNum > 0 && rewardGold<= this._city.gold) {
                this._confirmBtn.touchable = true;
                this._confirmBtn.grayed = false;
            } else {
                this._confirmBtn.touchable = false;
                this._confirmBtn.grayed = true;
            }

        }
        private async _onConfirmBtn() {
            let rewardGold = parseInt(this._goldInput.text);
            // let cnt = parseInt(this._memberInput.text);
            let cnt = this._memberCnt.value;
            
            let ok = await WarMgr.inst.publishMission(this._type,rewardGold, cnt);
            if (ok) {
                // Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshCityInfo);
                this._onCloseBtn();
            }
        }
        private async _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}