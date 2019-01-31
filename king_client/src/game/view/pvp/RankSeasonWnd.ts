module Pvp {

    export class RankSeasonWnd extends Core.BaseWindow {

        private _closeBtn: fairygui.GButton;
        private _wnd: fairygui.GComponent;

        private _timeText: fairygui.GTextField;
        private _totalCnt: fairygui.GTextField;
        private _winCnt: fairygui.GTextField;
        private _offensiveRate: fairygui.GTextField;
        private _defensiveRate: fairygui.GTextField;

        private _treasureName: fairygui.GTextField;
        private _treasureBox: fairygui.GLoader;
        private _treasureBox1: fairygui.GLoader;
        private _treasureData: SeasonTreasureInfo;
        private _treasure: Treasure.DailyTreasureItem;

        private _skinReward: fairygui.GComponent;
        private _skinDesc: fairygui.GTextField;
        private _cardId: number;
        private _skinId: string;
        private _seasonStarNum: fairygui.GTextField;

        private _headFrame: fairygui.GComponent;
        private _headName: fairygui.GTextField;
        private _headFrameDesc: fairygui.GTextField;

        private _time: number;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"), Core.AdjustType.EXCEPT_MARGIN);
			this.y += window.support.topMargin;

            this._wnd =  this.getChild("resultList").asList.addItemFromPool().asCom;

            this._timeText = this._wnd.getChild("time").asTextField;
            this._totalCnt = this._wnd.getChild("totalCnt").asTextField;
            this._winCnt = this._wnd.getChild("winCnt").asTextField;
            this._offensiveRate = this._wnd.getChild("offensiveRate").asTextField;
            this._defensiveRate = this._wnd.getChild("defensiveRate").asTextField;
            this._treasureName = this._wnd.getChild("treasureName").asTextField;
            this._seasonStarNum = this._wnd.getChild("title").asTextField;
            this._treasureBox = this._wnd.getChild("n22").asLoader;
            this._treasureBox.addClickListener(this._onTreasure, this);
            this._treasureBox1 = this._wnd.getChild("n35").asLoader;
            this._treasureBox1.addClickListener(() => {
                Core.ViewManager.inst.open(ViewName.dailyTreasureInfo, this);
            }, this);

            this._skinReward = this._wnd.getChild("skinReward").asCom;
            this._skinDesc = this._wnd.getChild("skinDesc").asTextField;

            this._headFrame = this._wnd.getChild("headFrame").asCom;
            //this._headName = this._wnd.getChild("headFrameName").asTextField;
            this._headFrameDesc = this._wnd.getChild("headFrameDesc").asTextField;

            this._closeBtn = this.getChild("btnClose").asButton;

            this._closeBtn.addClickListener(this._onCloseBtn, this);

            this._wnd.getController("c1").setSelectedIndex(1);
        }

        public async open(...param: any[]) {
            super.open(...param);

            let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel();
            let pvpTeam = Pvp.Config.inst.getPvpTeam(pvpLevel);

            this._skinId = Data.season_reward.get(2).skin;
            let skinData = CardPool.CardSkinMgr.inst.getSkinConf(this._skinId);
            if (skinData) {
                this._cardId = skinData.general;
                this._skinReward.getChild("nameText").asTextField.text = skinData.name;
                this._skinReward.getChild("nameText").visible = true;
                this._skinDesc.text = skinData.desc;

                Utils.setImageUrlPicture(this._skinReward.getChild("cardImg").asImage, `skin_m_${this._skinId}_png`);
                this._skinReward.addClickListener(this._onSkinBtn, this);
            }
            
            // let headData = Data.headFrame_config.get("4");
            // // this._headName.text = headData.name;
            // this._headFrameDesc.text = headData.desc;
            // Utils.setImageUrlPicture(this._headFrame.getChild("headFrame").asImage, "headframe_4_png");
            // Utils.setImageUrlPicture(this._wnd.getChild("headIcon").asImage, Player.inst.avatarUrl);
            // this._headFrame.getChild("newHint").visible = false;
            //设置赛季分和当前奖励
            this._wnd.getChild("rankLevel").asTextField.text = Pvp.Config.inst.getPvpTitle(pvpLevel);
            this._wnd.getChild("rankIcon").asLoader.url = `common_rank${pvpTeam}_png`;
            this._seasonStarNum.text = Player.inst.getResource(ResType.SeasonWinDiff).toString();

            let reply = param[0] as pb.SeasonPvpInfo;

            this._time = reply.LimitTime;
            if (this._time && this._time > 0) {
                fairygui.GTimers.inst.remove(this._updateTime, this);
                fairygui.GTimers.inst.add(1000, this._time, this._updateTime, this);
            }

            this._totalCnt.text = (reply.FirstHandAmount + reply.BackHandAmount).toString();
            this._winCnt.text = (reply.FirstHandWinAmount + reply.BackHandWinAmount).toString();
            if (reply.FirstHandAmount == 0) {
                this._offensiveRate.text = Core.StringUtils.TEXT(70112);
            } else {
                this._offensiveRate.text =`${Math.round(reply.FirstHandWinAmount / reply.FirstHandAmount * 100)}%`;
            }
            if (reply.BackHandAmount == 0) {
                this._defensiveRate.text = Core.StringUtils.TEXT(70112);
            } else {
                this._defensiveRate.text =`${Math.round(reply.BackHandWinAmount / reply.BackHandAmount * 100)}%`;
            }
            let rewardKeys = Data.season_reward.keys;
            //根据赛季分设置宝箱
            let starNum = Player.inst.getResource(ResType.SeasonWinDiff);
            for (let i = rewardKeys.length - 1; i >= 0; i--) {
                let rewardData = Data.season_reward.get(rewardKeys[i]);
                if (rewardData.team > 0 && starNum >= rewardData.winFlag) {
                    this._treasureData = new SeasonTreasureInfo(Data.treasure_config.get(rewardData.treasure));
                    this._treasureBox.url = `treasure_box${this._treasureData.rare}_png`;
                    this._treasureName.text = this._treasureData.title;
                    this._treasureBox.data = this._treasureData;
                    break;
                }
            }
            //根据段位设置宝箱
            // rewardKeys.forEach((_value) => {
            //     let teamReward = Data.season_reward.get(_value);
            //     if (teamReward.team == pvpTeam) {
            //         //设置当前段位宝箱
            //         this._treasureData = new SeasonTreasureInfo(Data.treasure_config.get(teamReward.treasure));
            //         this._treasureBox.url = `treasure_box${this._treasureData.rare}_png`;
            //         this._treasureName.text = this._treasureData.title;
            //         this._treasureBox.data = this._treasureData;
            //     }
            // })
            //直接设置新宝箱
            let treasure1 = new Treasure.TreasureItem(-1, Data.season_reward.get(5).treasure);
            this._treasure = treasure1 as Treasure.DailyTreasureItem;
        }

        private async _onSkinBtn() {
            let card = CardPool.CardPoolMgr.inst.getCollectCard(this._cardId);
            Core.ViewManager.inst.open(ViewName.skinView, card, this._skinId);
        }

        private _onTreasure(evt: egret.TouchEvent) {
            let com = evt.target as fairygui.GComponent;
            // console.log(com.data.treasureId);
            Core.ViewManager.inst.open(ViewName.rankSeasonTreasureInfo, this, com.data);
        }

        private _onCloseBtn() {
            Core.ViewManager.inst.closeView(this);
        }

        public async close(...param:any[]) {
            super.close(...param);
        }

         private _updateTime() {
            this._timeText.text = `${Core.StringUtils.secToString(this._time, "dhms")}`;
            this._time -= 1;
            if (this._time <= 0) {
                this._timeText.text = Core.StringUtils.TEXT(70120);
                fairygui.GTimers.inst.remove(this._updateTime, this);
            }
        }
        public get treasure(): Treasure.DailyTreasureItem {
			return this._treasure;
		}
    }

    export class SeasonTreasureInfo {

        private _treasureData: any;

        public constructor (treasureData: any) {
            this._treasureData = treasureData;
        }

        public get rare(): any {
            return this._treasureData.rare;
        }
        public get title(): any {
            return this._treasureData.title;
        }
        public getName(): string {
			return this._treasureData.title;
		}

		public getMinGoldCnt(): number {
			return this._treasureData.goldMin;
		}

		public getMaxGoldCnt(): number {
			return this._treasureData.goldMax;
		}

		public getMinJadeCnt(): number {
			return this._treasureData.jadeMin;
		}

		public getMaxJadeCnt(): number {
			return this._treasureData.jadeMax;
		}

		public getCardNum(): number {
			return this._treasureData.cardCnt;
		}
        public getRareCardNum(): number {
			let rareCard = 0
			rareCard = this._treasureData.cardStar5 + this._treasureData.cardStar4 + this._treasureData.cardStar3;
			return rareCard;
		}
        public getRareType(): number {
			return this._treasureData.rare;
		}

    }
}
