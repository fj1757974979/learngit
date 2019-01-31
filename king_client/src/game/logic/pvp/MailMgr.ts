module Pvp {

    declare interface IMailProcessor {
        updateMailCom(mailData: pb.IMail, titleText: fairygui.GTextField, contentText: fairygui.GTextField);
    }

    class CustomMailProcessor implements IMailProcessor {
        public updateMailCom(mailData: pb.IMail, titleText: fairygui.GTextField, contentText: fairygui.GTextField) {
            titleText.text = mailData.Title;
            contentText.text = "\n" + mailData.Content;
        }
    }

    class PvpSeasonProcessor implements IMailProcessor {
        public updateMailCom(mailData: pb.IMail, titleText: fairygui.GTextField, contentText: fairygui.GTextField) {
            let pvpLevel = pb.MailSeasonPvpBeginArg.decode(mailData.Arg).PvpLevel;
            let labData = Data.mail_config.get(mailData.MailType);
            titleText.text = labData.title;
            contentText.text = Core.StringUtils.format(<string>(labData.content), Pvp.Config.inst.getPvpTitle(pvpLevel));
            // contentText.text = <string>(labData.content).replace("#(team)", Pvp.Config.inst.getPvpTitle(pvpLevel));           
            // contentText.text = "\n" + labData.content;          
        }
    }

    class PvpSeasonEndProcessor implements IMailProcessor {
        public updateMailCom(mailData: pb.IMail, titleText: fairygui.GTextField, contentText: fairygui.GTextField) {
            let pvpLevel = pb.MailSeasonPvpEndArg.decode(mailData.Arg).WinDiff;
            // let pvpWinDiff = pb.MailSeasonPvpEndArg.decode(mailData.Arg).WinDiff;
            let labData = Data.mail_config.get(mailData.MailType);
            titleText.text = labData.title;
            contentText.text = Core.StringUtils.format(<string>(labData.content), Pvp.Config.inst.getPvpTitle(pvpLevel));
            // contentText.text = "\n" + <string>(labData.content).replace("{0}", pvpWinDiff);
        }
    }

    class ConfigMailProcessor implements IMailProcessor {
        public updateMailCom(mailData: pb.IMail, titleText: fairygui.GTextField, contentText: fairygui.GTextField) {
            let labData = Data.mail_config.get(mailData.MailType);
            titleText.text = labData.title;
            contentText.text = "\n" + labData.content;
        }
    }
    
    class CampaignUnifiedProcessor implements IMailProcessor {
        public updateMailCom(mailData: pb.IMail, titleText: fairygui.GTextField, contentText: fairygui.GTextField) {
            let warData = pb.MailCampaignUnifiedArg.decode(mailData.Arg);
            let labData = Data.mail_config.get(mailData.MailType);
            titleText.text = labData.title;
            contentText.text = Core.StringUtils.format(labData.content, warData.YourMajestyName, warData.CountryName);
        }
    }

    export class MailMgr extends egret.EventDispatcher {
        private static _inst: MailMgr;

        private _hasMore: boolean;
        private _mailIDList: Array<number>;
        private _mailDataList: Collection.Dictionary<number, pb.IMail>;
        private _mailType2Processor: Collection.Dictionary<number, IMailProcessor>;
        private _configMailProcessor: IMailProcessor;

        public static MailRedDot = "MailRedDot";
        public static SetGetAllBtn = "SetGetAllBtn";

        public static get inst() {
            if(!MailMgr._inst) {
                MailMgr._inst = new MailMgr();
            }
            return MailMgr._inst;
        }

        constructor() {
            super();
            this._configMailProcessor = new ConfigMailProcessor();
            this._mailType2Processor = new Collection.Dictionary<number, IMailProcessor>();
            this._mailType2Processor.setValue(<number>pb.MailTypeEnum.CUSTOM, new CustomMailProcessor());
            this._mailType2Processor.setValue(<number>pb.MailTypeEnum.SeasonPvpBegin, new PvpSeasonProcessor());
            this._mailType2Processor.setValue(<number>pb.MailTypeEnum.SeasonPvpEnd, new PvpSeasonEndProcessor());
            this._mailType2Processor.setValue(<number>pb.MailTypeEnum.FbAdvert, new ConfigMailProcessor());
            this._mailType2Processor.setValue(<number>pb.MailTypeEnum.CampaignUnified, new CampaignUnifiedProcessor());
        }

        public mailDataInit(args: pb.MailList) {
            this._mailDataList = new Collection.Dictionary<number, pb.IMail>();
            this._mailIDList = new Array<number>();
            this.addMailData(args);
            
        }

        public getMailContentProcessor(mailType: pb.MailTypeEnum): IMailProcessor {
            let processor = this._mailType2Processor.getValue(<number>mailType);
            if (processor) {
                return processor;
            } else {
                return this._configMailProcessor;
            }
        }

        public addMailData(args: pb.MailList) {
            this._hasMore = args.HasMore;
            args.Mails.forEach((_value) => {
                this._mailIDList.push(_value.ID);
                this._mailDataList.setValue(_value.ID,_value);
            });
        }

        public get hasMore(): boolean {
            return this._hasMore;
        }

        public get mailNum(): number {
            return this._mailDataList.size();
        }

        public getMail(index: number) {
            if (this._mailIDList[index]) {
                return this._mailDataList.getValue(this._mailIDList[index]);
            }
        }

        public getReward(key: number, value: boolean) {
            if (this._mailDataList.containsKey(key)) {
                this._mailDataList.getValue(key).IsReward = value;
                this._mailDataList.getValue(key).IsRead = value;
            }
        }

        public haveNoRead() : boolean {
            let b = false;
            this._mailDataList.forEach((_k, _v) => {
                if (!_v.IsRead) {
                    b = true;
                }
            });
            return b;
        }

        public haveReward():boolean {
            let b = false;
            this._mailDataList.forEach((_k, _v) => {
                if (!_v.IsReward) {
                    b = true;
                }
            });
            return b;
        }
        /*
        public getAllReward() {
            let args = {Gold: 0 , Jade: 0, Cards: new Collection.Dictionary<number, number>()};
            this._mailDataList.forEach((_k, _v) => {
                if (!_v.IsReward) {
                    _v.IsReward = true;
                    _v.Rewards.forEach((_rewardData) => {
                        if (_rewardData.Type == pb.MailReward.RewardType.Gold) {
                            args.Gold += _rewardData.Amount;
                        } else if (_rewardData.Type == pb.MailReward.RewardType.Jade) {
                            args.Jade += _rewardData.Amount;
                        } else if (_rewardData.Type == pb.MailReward.RewardType.Card) {
                            let cardID = _rewardData.CardID;
                            if (args.Cards.containsKey(cardID)) {
                                let cardNum = args.Cards.getValue(cardID) + _rewardData.Amount;
                                args.Cards.setValue(cardID, cardNum);
                            } else {
                                args.Cards.setValue(_rewardData.CardID, _rewardData.Amount);
                            }
                        }
                    });
                }
            });
            //TODO:显示所有的奖励
        }*/

        public async getAllReward() {
            let result = await Net.rpcCall(pb.MessageID.C2S_GET_ALL_MAIL_REWARD, null);

            if (result.errcode == 0) {
                // let reply = pb.MailRewardReply.decode(result.payload);
                // let args = new GetRewardData();
                // args.gold = reply.Gold;
                // args.jade = reply.Jade;
                // reply.HeadFrames.forEach(headFrame => {
                //     args.addHeadFrame(headFrame);
                // })
                // reply.CardSkins.forEach(skinId => {
                //     args.addSkins(skinId);
                // })
                // reply.Cards.forEach((_value) => {
                //     args.addCards(_value.CardID, _value.Amount);
                // });
                // reply.TreasureRewards.forEach( treasure => {
                //     args.addTreasure(treasure);
                // })
                // Core.ViewManager.inst.open(ViewName.getRewardWnd,args);
                // this._mailDataList.forEach((_k, _v) => {
                // if (!_v.IsRead) {
                //     _v.IsRead = true;
                // }
                // if (!_v.IsReward) {
                //     _v.IsReward = true;
                // }
                // });
                MailMgr.inst.dispatchEventWith(MailMgr.SetGetAllBtn, false);
            }
        }
    }
}