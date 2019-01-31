module Pvp {
    

    export class MailWnd extends Core.BaseWindow {

        private _mailList: fairygui.GList;
        private _allGetBtn: fairygui.GButton;
        

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._mailList = this.getChild("mailList").asList;
            //this._mailList.setVirtual();
            this._mailList.scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE, this._getMail, this);
            // this._mailList.itemRenderer = this._updateMailItem;
            this._mailList.addEventListener(fairygui.ItemEvent.CLICK, this._onMail, this);


            this._allGetBtn = this.getChild("getBtn").asButton;

            this.getChild("closeBtn").asButton.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            },this);

            this._allGetBtn.addClickListener(this._onGetAll, this);

            MailMgr.inst.addEventListener(MailMgr.SetGetAllBtn, this._setGetAllBtn, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
             this._mailList.numItems = 0;

             MailMgr.inst.mailDataInit(param[0]);
            //  this._mailList.numItems = MailMgr.init.mailNum;

             this.getChild("emptyHintText").visible = (MailMgr.inst.mailNum <= 0);

             this._allGetBtn.visible = false;
            //  this._allGetBtn.visible = MailMgr.init.haveReward();
            this._refreshMailList();
            if (MailMgr.inst.mailNum > 0) {
                this._mailList.scrollToView(0);
            }
        }

        private _refreshMailList() {
            this._mailList.removeChildrenToPool();
            for (let i = 0; i < MailMgr.inst.mailNum; i++) {
                let _obj = this._mailList.addItemFromPool();
                this._updateMailItem(i, _obj.asCom);
            }
        }

        private _updateMailItem(index: number, obj: fairygui.GComponent) {
            let mailData = MailMgr.inst.getMail(index);
            let processor = MailMgr.inst.getMailContentProcessor(mailData.MailType);
            if (processor) {
                processor.updateMailCom(mailData, obj.getChild("title").asTextField, obj.getChild("text").asTextField);
            }
            // if (mailData.MailType == pb.MailTypeEnum.CUSTOM) {
            //     obj.getChild("title").asTextField.text = mailData.Title;
            //     obj.getChild("text").asTextField.text = mailData.Content;
            // } else if (mailData.MailType == pb.MailTypeEnum.SeasonPvpBegin) {
            //     let pvpLevel = pb.MailSeasonPvpBeginArg.decode(mailData.Arg).PvpLevel;
            //     let labData = Data.mail_config.get(mailData.MailType);
            //     obj.getChild("title").asTextField.text = labData.title;
            //     obj.getChild("text").asTextField.text = <string>(labData.content).replace("#(team)", Pvp.Config.inst.getPvpTeamName(pvpLevel));
            // } else if (mailData.MailType == pb.MailTypeEnum.SeasonPvpEnd) {
            //     let pvpLevel = pb.MailSeasonPvpEndArg.decode(mailData.Arg).PvpLevel;
            //     let labData = Data.mail_config.get(mailData.MailType);
            //     obj.getChild("title").asTextField.text = labData.title;
            //     obj.getChild("text").asTextField.text = <string>(labData.content).replace("#(team)", Pvp.Config.inst.getPvpTeamName(pvpLevel));
            // } else if (mailData.MailType == pb.MailTypeEnum.FbAdvert) {

            // }

            obj.getChild("time").asTextField.text = Core.StringUtils.format(Core.StringUtils.TEXT(60051), Core.StringUtils.secToString(Math.floor(Date.now()/1000 - mailData.Time), "dhm"));
            if (mailData.IsRead) {
                obj.getController("c1").selectedIndex = 1;
            } else {
                obj.getController("c1").selectedIndex = 0;
            }
        }

        private async _getMail() {
            if (MailMgr.inst.hasMore) {
                let args = {MinMailID: MailMgr.inst.mailNum};
                let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_MAIL_LIST, pb.FetchMailListArg.encode(args));
                if (result.errcode == 0) {
                    MailMgr.inst.addMailData(pb.MailList.decode(result.payload));
                    this._mailList.numItems = MailMgr.inst.mailNum;
                }
                this._refreshMailList();
            }
        }

        private _onMail(evt: fairygui.ItemEvent) {
            let _index = this._mailList.getChildIndex(evt.itemObject);
            _index = this._mailList.childIndexToItemIndex(_index);

            Core.ViewManager.inst.open(ViewName.mailInfo,_index);
        }

        private async _onGetAll() {
            MailMgr.inst.getAllReward();
        }
        //判断是否有邮件未读或未领取
        private _setGetAllBtn() {
            // this._allGetBtn.visible = MailMgr.init.haveReward();
            // if (!MailMgr.inst.haveNoRead()) { //
            //     MailMgr.inst.dispatchEventWith(MailMgr.MailRedDot, false, false);
            // }
            let hasNoread = MailMgr.inst.haveNoRead();
            MailMgr.inst.dispatchEventWith(MailMgr.MailRedDot, false, hasNoread);
            this._refreshMailList();
        }

        public async close(...param: any[]) {
            super.close(...param);
            // this._setGetAllBtn();
        }
    }

    export class MailInfoItem extends fairygui.GComponent {
        
        private _rewardType: pb.MailRewardType;
        private _rewardId: any;
        private _cardId: any;
        private _treasure: Treasure.DailyTreasureItem;

        constructFromXML(xml: any): void { 
            super.constructFromXML(xml);
            this.addClickListener(this._onClick, this);
        }

        public async setRewawrd(rewardData: pb.IMailReward) {
            this._rewardType = rewardData.Type;
            this._cardId = rewardData.CardID;
            this._rewardId = rewardData.ItemID;

            let param = null;
            let icon = null;
            // pb.MailRewardType.
            if (this._rewardType == pb.MailRewardType.MrtCard) {
                param = rewardData.CardID;
            } else if (this._rewardType == pb.MailRewardType.MrtHeadFrame) {
                param = rewardData.ItemID;
            } else if (this._rewardType == pb.MailRewardType.MrtCardSkin) {
                let skindata = CardPool.CardSkinMgr.inst.getSkinConf(rewardData.ItemID);
                param = skindata.head;
            } else if (this._rewardType == pb.MailRewardType.MrtTreasure) {
                let treasuredata = Data.treasure_config.get(rewardData.ItemID);
                param = treasuredata.rare;
            } else if (this._rewardType == pb.MailRewardType.MrtEmoji) {
                param = rewardData.EmojiTeam;
            } else if (this._rewardType == pb.MailRewardType.MrtEquip) {
                 param = rewardData.ItemID;
            }
            icon = Reward.RewardMgr.inst.getRewardIcon(this._rewardType, Reward.RewardIconSize.T_NORMAL, param);
            this.getChild("rewardIcon1").asLoader.url = icon;
            this.getChild("cnt1").asTextField.text = rewardData.Amount.toString();
        }

        private _onClick() {
            if (this._rewardType == pb.MailRewardType.MrtCardSkin) {
                let skinData = CardPool.CardSkinMgr.inst.getSkinConf(this._rewardId);
                let card = CardPool.CardPoolMgr.inst.getCollectCard(skinData.general);
                Core.ViewManager.inst.open(ViewName.skinView, card, this._rewardId);
            } else if (this._rewardType == pb.MailRewardType.MrtTreasure) {
                let treasureData = Data.treasure_config.get(this._rewardId);
                if (treasureData.jadeMin <= 0) {
                    let treasure1 = new Treasure.TreasureItem(-1, this._rewardId);
                    this._treasure = treasure1 as Treasure.DailyTreasureItem;
                    Core.ViewManager.inst.open(ViewName.dailyTreasureInfo, this);
                } else  {
                    let treasureData2 = new SeasonTreasureInfo(treasureData);
                    Core.ViewManager.inst.open(ViewName.rankSeasonTreasureInfo, this, treasureData2);
                }
            } else if (this._rewardType == pb.MailRewardType.MrtCard) {
                let cardData = CardPool.CardPoolMgr.inst.getCardData(this._cardId, 1);
                let cardObj = new CardPool.Card(cardData);   
                Core.ViewManager.inst.open(ViewName.cardInfoOther, cardObj);
            }
        }
        public get treasure(): Treasure.DailyTreasureItem {
			return this._treasure;
		}
    }

    export class MailInfoWnd extends Core.BaseWindow {

        private _rewardList: fairygui.GList;
        private _mailTitle: fairygui.GTextField;
        private _mailText: fairygui.GTextField;
        private _getBtn: fairygui.GButton;

        private _index: number;
        private _mailData: pb.IMail;
        private _rewardData: GetRewardData;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._rewardList = this.getChild("rewardList").asList;
            this._mailTitle = this.getChild("mailTitle").asTextField;
            this._mailText = this.getChild("mailList").asList.getChildAt(0).asCom.getChild("mailText").asTextField;
            this._mailText.funcParser = Core.StringUtils.parseFuncText;
            this._getBtn = this.getChild("getBtn").asButton;

            this.getChild("backBtn").asButton.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            },this);
            this.getChild("closeBtn").asButton.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
                Core.ViewManager.inst.close(ViewName.mail);
            },this);
            this._getBtn.addClickListener(this._onGetBtn, this);
            this._getBtn.touchable = true;
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._rewardList.removeChildrenToPool();
            this._rewardData = new GetRewardData();

            this._index = param[0];

            this._mailData = MailMgr.inst.getMail(this._index);

            let processor = MailMgr.inst.getMailContentProcessor(this._mailData.MailType);
            if (processor) {
                processor.updateMailCom(this._mailData, this._mailTitle, this._mailText);
            }
            // if (this._mailData.MailType == pb.MailTypeEnum.CUSTOM) {
            //     this._mailTitle.text = this._mailData.Title;
            //     this._mailText.text = this._mailData.Content;
            // } else if (this._mailData.MailType == pb.MailTypeEnum.SeasonPvpBegin) {
            //     let pvpLevel = pb.MailSeasonPvpBeginArg.decode(this._mailData.Arg).PvpLevel;
            //     let labData = Data.mail_config.get(this._mailData.MailType);
            //     this._mailTitle.text = labData.title;
            //     this._mailText.text = <string>(labData.content).replace("#(team)", Pvp.Config.inst.getPvpTitle(pvpLevel));
            // } else if (this._mailData.MailType == pb.MailTypeEnum.SeasonPvpEnd) {
            //     let pvpLevel = pb.MailSeasonPvpEndArg.decode(this._mailData.Arg).PvpLevel;
            //     let labData = Data.mail_config.get(this._mailData.MailType);
            //     this._mailTitle.text = labData.title;
            //     this._mailText.text = <string>(labData.content).replace("#(team)", Pvp.Config.inst.getPvpTitle(pvpLevel));
            // }

            this._mailData.Rewards.forEach((_value) => {
                let rewardItem = this._rewardList.addItemFromPool().asCom as MailInfoItem;
                rewardItem.setRewawrd(_value);
                if (_value.Type == pb.MailRewardType.MrtTreasure) {
                    this._rewardData.addTreasureId(_value.ItemID);
                }
            })
            //设置list 高度
            if (this._mailData.Rewards.length > 0) {
                this.getChild("mailList").height = 250;
            } else {
                this.getChild("mailList").height = 330;
            }

            if (!this._mailData.IsRead) { //未读
                if(!(this._mailData.Rewards.length > 0 && !this._mailData.IsReward)) { //!有奖励且没有领取
                    let args = {ID: this._mailData.ID};
                    await Net.rpcCall(pb.MessageID.C2S_READ_MAIL, pb.ReadMailArg.encode(args));
                    this._mailData.IsRead = true;
                    MailMgr.inst.dispatchEventWith(MailMgr.SetGetAllBtn);
                }
            }
            this._setGetBtn();
        }

        public async close(...param: any[]) {
            super.close(...param);
            // MailMgr.inst.dispatchEventWith(MailMgr.SetGetAllBtn);
            this._rewardList.removeChildrenToPool();
            this._rewardData = null;
        }

        private _setGetBtn() {
            let lineCom = this.getChild("line");
            let flagCom = this.getChild("recievedFlag");
            lineCom.visible = true;
            flagCom.visible = false;
            this._getBtn.visible = true;
            if (this._mailData.Rewards == null || this._mailData.Rewards.length == 0) {
                this._getBtn.text = Core.StringUtils.TEXT(60024);
                lineCom.visible = false;
            } else {
                let _b = this._mailData.IsReward;
                if(_b) {
                    this._getBtn.visible = false;
                    flagCom.visible = true;
                } else {
                    this._getBtn.text = Core.StringUtils.TEXT(60022);
                }
            }
        }

        private async _onGetBtn() {
            if (this._mailData.Rewards == null || this._mailData.Rewards.length == 0) {
                Core.ViewManager.inst.closeView(this);
            } else {
                this._onGetReward();
            }
        }

        private async _onGetReward() {
            let args = {ID: this._mailData.ID};
            let result = await Net.rpcCall(pb.MessageID.C2S_GET_MAIL_REWARD, pb.GetMailRewardArg.encode(args));
            if (result.errcode == 0) {
                MailMgr.inst.getReward(this._mailData.ID, true);
                MailMgr.inst.dispatchEventWith(MailMgr.SetGetAllBtn);
                this._setGetBtn();
                let reply = pb.MailRewardReply.decode(result.payload);
                reply.AmountRewards.forEach( _data => {
                    this._rewardData.addRewardToType(_data.Type, _data.Amount);
                })
                reply.ItemRewards.forEach(_data => {
                    this._rewardData.addRewardToType(_data.Type, _data.ItemID);
                })
                reply.Cards.forEach((_card) => {
                    this._rewardData.addRewardToType(Reward.RewardType.T_CARD, _card);
                })
                reply.TreasureRewards.forEach( _treasure => {
                    this._rewardData.addRewardToType(Reward.RewardType.T_TREASURE, _treasure);
                })
                Core.ViewManager.inst.open(ViewName.getRewardWnd, this._rewardData);
            }
        }
    }
}
