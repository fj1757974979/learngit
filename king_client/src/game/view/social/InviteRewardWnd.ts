module Social {

    export class InviteRewardWnd extends Core.BaseWindow {

        private _memberNum: number;

        private _memberList: fairygui.GList;
        private _rewardList: fairygui.GList;

        private _rewardDataList: Collection.Dictionary<number, pb.IWxInviteReward>;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;

            this._memberList = this.getChild("memberList").asList;
            this._rewardList = this.getChild("rewardList").asList;

            //this._memberList.setVirtual();
            this._memberList.scrollPane.addEventListener(fairygui.ScrollPane.PULL_UP_RELEASE,this._memberUpdate,this) ;
            this._memberList.itemRenderer = this._memberItemUpdate;

            this.getChild("closeBtn").asButton.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            },this);

            this.getChild("inviteBtn").asButton.addClickListener(() => {
                WXGame.WXShareMgr.inst.wechatInvite();
            },this);
        }

        public async open(...param: any[]) {
            super.open(...param);

            this._memberNum = 0;
            this._memberList.numItems = 0;
            
            this._rewardDataList = new Collection.Dictionary<number, pb.IWxInviteReward>();
            InviteDataMgr.init.memberDataInit();
            this._memberList.removeChildrenToPool();
            this._rewardList.removeChildrenToPool();
            
            let _allData = param[0] as pb.WxInviteFriendsReply;
            _allData.Friends.forEach((_value) => {
                InviteDataMgr.init.addMember(_value);
            });
            InviteDataMgr.init.memberSort();

            _allData.Rewards.forEach((_value) => {
                this._rewardDataList.setValue(_value.ID,_value);
            });
            this._memberNum = 20;
            this._memberList.numItems = 20;
            this._updateRewards();
        }

        public async close(...param: any[]) {
            super.close(...param);
        }

        private _memberItemUpdate(index: number, obj: fairygui.GObject) {
            let arrNum = InviteDataMgr.init.num;
            let _obj = obj as InviteMemberItem;
            if (index < arrNum) {
                _obj.setMember(InviteDataMgr.init.getMember(index));
            } else {
                _obj.setMember();
            }
        }

        private async _memberUpdate() {
            let arrNum = InviteDataMgr.init.num;
            if (this._memberNum >= arrNum) {
                return;
            } else if (arrNum - this._memberNum > 20) {
                this._memberNum += 20;
            } else {
                this._memberNum = arrNum;
            }
            this._memberList.numItems = this._memberNum;
        }

        private _updateRewards() {
            let _keys = Data.invite_reward.keys;
            _keys.forEach((_key) => {
                let rewardItem = this._rewardList.addItemFromPool() as InviteRewardItem;
                if (this._rewardDataList.containsKey(_key)) {
                    rewardItem.setReward(_key, this._rewardDataList.getValue(_key));
                } else {
                    rewardItem.setReward(_key);
                }
            });
        }
    }

    export class InviteMemberItem extends fairygui.GComponent {
        private _levelText: fairygui.GTextField;
        private _headIcom: fairygui.GImage;

        protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
		}

        public setMember(member?: pb.IWxInviteFriend) {
            if (member) {
                this.getChild("n13").text = Pvp.Config.inst.getPvpTitle(member.PvpLevel);
                this.getChild("headIcon").visible = true;
                Utils.setImageUrlPicture(this.getChild("headIcon").asImage, member.HeadImgUrl);
            } else {
                this.getChild("n13").text = "";
                this.getChild("headIcon").visible = false;
            }
        }
    }

    export class InviteRewardItem extends fairygui.GComponent {
        private _rewardID: number;
        
        protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
		}
        public setReward(_key: number, rewardData?: pb.IWxInviteReward) {
            this._rewardID = _key;
            let _data = Data.invite_reward.get(_key);
            let _conNum = 1;
            if ( _conNum <= 2 && _data.goldReward > 0) {
                this.getChild("rewardIcon" + _conNum).asLoader.url = "common_goldIcon_png";
                this.getChild("cnt" + _conNum).text = "x" + _data.goldReward;
                _conNum += 1;
            }
            if (_conNum <= 2 && _data.jadeReward > 0) {
                this.getChild("rewardIcon" + _conNum).asLoader.url = "common_jadeIcon_png";
                this.getChild("cnt" + _conNum).text = "x" + _data.jadeReward;
                _conNum += 1;
            }

            this.getChild("conditionTxt").text = Core.StringUtils.format(Core.StringUtils.TEXT(60048), Pvp.Config.inst.getPvpTitle(_data.pvpLevel));

            let _curCnt = 0;
            let _rewardCnt = 0;
            if (rewardData) {
                _curCnt = rewardData.CurCnt;
                _rewardCnt =rewardData.RewardCnt;
            }

            if(_rewardCnt < _data.cnt) {
                this.getChild("processTxt").text = `(${_curCnt}/${_data.cnt})`;
                if (_rewardCnt >= _curCnt) {
                    this.getController("c1").selectedIndex = 0;
                } else {
                    this.getController("c1").selectedIndex = 1;
                    InviteDataMgr.init.rewardNum += 1;
                    this.getChild("btnReceive").asButton.title = Core.StringUtils.format(Core.StringUtils.TEXT(70116), _curCnt - _rewardCnt);
                    this.getChild("btnReceive").asButton.addClickListener(this._onReward,this);
                }
            } else {
                // this.getChild("processTxt").text = `(${_data.cnt}/${_data.cnt})`;
                this.getChild("processTxt").text = `(${_curCnt}/${_data.cnt})`;
                this.getController("c1").selectedIndex = 2;
            }
        }

        private async _onReward() {
            let args = {ID: this._rewardID};
            let result = await Net.rpcCall(pb.MessageID.C2S_GET_WX_INVITE_REWARD,pb.GetWxInviteRewardArg.encode(args));
            if (result.errcode == 0) {
                let reply = pb.GetWxInviteRewardReply.decode(result.payload);
                let rewardData = new Pvp.GetRewardData();
                rewardData.gold = reply.Gold;
                rewardData.jade = reply.Jade;
                if (reply.Cards) {
                    let cardID = Data.invite_reward.get(this._rewardID).cardReward as Array<number>;
                    if (cardID.length > 0) {
                        for (let i = 0; i < cardID.length; i++) {
                            rewardData.addCards(cardID[i], reply.Cards[i]);
                        }
                    }
                }
                Core.ViewManager.inst.open(ViewName.getRewardWnd,rewardData);
                this.getController("c1").selectedIndex = 2;
                InviteDataMgr.init.rewardNum -= 1;
                if (InviteDataMgr.init.rewardNum <= 0) {
                    Core.EventCenter.inst.dispatchEventWith(InviteDataMgr.UpdateInviteHit, false, false);
                }
            }
        }
    }

    export class InviteDataMgr {
        private static _init: InviteDataMgr;
        private _memberDataList: Array<pb.IWxInviteFriend>;

        private _rewardNum: number;

        public static UpdateInviteHit = "UpdateInviteHit";

        public static get init() {
            if(!InviteDataMgr._init) {
                InviteDataMgr._init = new InviteDataMgr();
            }
            return InviteDataMgr._init;
        }
        public constructor() {
		}
        public memberDataInit() {
            this._memberDataList = new Array<pb.IWxInviteFriend>();
            this._rewardNum = 0;
        }
        public addMember(member: pb.IWxInviteFriend) {
            this._memberDataList.push(member);
        }

        public memberSort() {
            this._memberDataList.sort((a, b)=> {
                if (a.PvpLevel > b.PvpLevel) {
                    return -1;
                } else if (a.PvpLevel < b.PvpLevel) {
                    return 1;
                } else {
                    return 0;
                }
            });
        }

        public get num() {
            return this._memberDataList.length;
        }

        public set rewardNum(n: number) {
            this._rewardNum = n;
        }

        public get rewardNum(): number {
            return this._rewardNum;
        }

        public getMember(key: number) {
            if(key >= 0 && this._memberDataList.length > key) {
                return this._memberDataList[key];
            }
        }
    }
}