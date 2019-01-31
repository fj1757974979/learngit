module Pvp {
    export class GetRewardWnd extends Core.BaseWindow {

        private _icon: fairygui.GLoader;
        private _num: fairygui.GTextField;
        private _nameText: fairygui.GTextField;
        private _tipText: fairygui.GTextField;
        private _treasureIcon: fairygui.GLoader;

        private _typeCtr: fairygui.Controller;

        private _rewardData: GetRewardData;
        private _reward: Treasure.TreasureReward;
        private _treasureItem: Treasure.TreasureItem;

        private _callback: () => void;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;

            this._icon = this.getChild("resource1").asLoader;
            this._num = this.getChild("cardRemaining").asTextField;
            this._nameText = this.getChild("name").asTextField;
            this._tipText = this.getChild("tip").asTextField;
            this._treasureIcon = this.getChild("treausre").asLoader;
            this._typeCtr = this.getController("type");

            this.adjust(this.getChild("bg"));
            this.getChild("bg").addClickListener(this._play,this);

            this._callback = null;

        }

        public async open(...param: any[]) {
            super.open(...param);

            this._rewardData = param[0] as GetRewardData;

            this._callback = param[1];
            this._play();
        }

        private _play() {
            this.getTransition("t0").play();
            if (this._reward) {
                Core.ViewManager.inst.open(ViewName.treasureRewardInfo, this._reward,this._treasureItem);
                this._reward = null;
            }
            if (this._rewardData.gold > 0) {
                this._typeCtr.selectedIndex = 0;
                this._icon.url = `common_goldIconBig_png`;
                this._num.text = this._rewardData.gold.toString();
                this._rewardData.gold = 0;
            } else if (this._rewardData.jade > 0) {
                this._typeCtr.selectedIndex = 0;
                this._icon.url = `common_jadeIconBig_png`;
                this._num.text = this._rewardData.jade.toString();
                this._rewardData.jade = 0;
            } else if (this._rewardData.bowlder > 0) {
                this._typeCtr.selectedIndex = 0;
                this._icon.url = `common_bowlderIconBig_png`;
                this._num.text = this._rewardData.bowlder.toString();
                this._rewardData.bowlder = 0;
            } else if (this._rewardData.feat > 0) {
                this._typeCtr.selectedIndex = 0;
                this._icon.url = `common_honorIconBig_png`;
                this._num.text = this._rewardData.feat.toString();
                this._rewardData.feat = 0;
            } else if (this._rewardData.fame > 0) {
                this._typeCtr.selectedIndex = 0;
                this._icon.url = `common_fameIconBig_png`;
                this._num.text = this._rewardData.fame.toString();
                this._rewardData.fame = 0;
            } else if (this._rewardData.contribution > 0) {
                this._typeCtr.selectedIndex = 0;
                this._icon.url = `war_fightIcon_png`;
                this._num.text = this._rewardData.contribution.toString();
                this._rewardData.contribution = 0;
            } else if (this._rewardData.cardKeys.length > 0) {
                this._typeCtr.selectedIndex = 1;
                let theKey = this._rewardData.cardKeys.shift();
                let resData = CardPool.CardPoolMgr.inst.getCardData(theKey, 1);
                if (resData) {
                    let cardObj = new CardPool.Card(resData);
                    cardObj.amount = 1;
                    let cardCom = this.getChild("card") as Treasure.CardRewardCom;
                    cardCom.count = this._rewardData.cards.getValue(theKey);
                    cardCom.setCardObj(cardObj);
                    cardCom.enableClick(true);
                }
            } else if (this._rewardData.skins.length > 0) {
                this._typeCtr.selectedIndex = 2;
                let skinId = this._rewardData.skins.shift();
                let skinData = CardPool.CardSkinMgr.inst.getSkinConf(skinId);
                let heroID = skinData.general;
                // let resData = CardPool.CardPoolMgr.inst.getCardData(heroID, 1);
                let card = CardPool.CardPoolMgr.inst.getCollectCard(heroID);

                if (card) {
                    let skinCom = this.getChild("skin").asCom;
                    skinCom.getChild("nameText").asTextField.text = skinData.name;
                    Utils.setImageUrlPicture(skinCom.getChild("cardImg").asImage, `skin_m_${skinId}_png`); 
                    skinCom.addClickListener(() => {
                        Core.ViewManager.inst.open(ViewName.skinView, card, skinId);
                    }, this);
                }
            } else if (this._rewardData.headFrame.length > 0) {
                this._typeCtr.selectedIndex = 3;
                let headCom = this.getChild("headFrame").asCom;
                let headID = this._rewardData.headFrame.shift();
                Utils.setImageUrlPicture(headCom.getChild("headFrame").asImage, `headframe_${headID}_png`); 
                headCom.getChild("newHint").visible = false;

            } else if (this._rewardData.other.length > 0) {
                this._typeCtr.selectedIndex = 4;
                let other = this._rewardData.other.shift();
                this._treasureIcon.url = other.url;
                this._nameText.text = other.name;
                if (other.desc) {
                   this._tipText.text = other.desc;
                } else {
                    this._tipText.text = "";
                }
            } else if (this._rewardData.treasures.length > 0) {
                this._typeCtr.selectedIndex = 4;
                let treasureReply = this._rewardData.treasures.shift();
                let treasureId = this._rewardData.treasureIds.shift();
                let treasureData = Data.treasure_config.get(treasureId);
                this._nameText.text = treasureData.title;
                this._tipText.text = "";
                this._treasureIcon.url = `treasure_box${treasureData.rare}_png`;

                this._reward = new Treasure.TreasureReward();
                this._treasureItem = new Treasure.TreasureItem(-1,treasureId);
                this._reward.gold = treasureReply.GoldAmount;
                this._reward.jade = treasureReply.Jade;
                treasureReply.CardIDs.forEach(cardID => {
                    this._reward.addCardId(cardID);
                })
                this._reward.shareId = treasureReply.ShareHid;
                // Core.ViewManager.inst.open(ViewName.treasureRewardInfo, this._reward,this._treasureItem);
            } else {
                Core.ViewManager.inst.closeView(this);
            }

        }

        public async close(...param: any[]) {
			super.close(...param);
            if (this._callback) {
                this._callback();
                this._callback = null;
            }
		}
    }

    export class OtherData {
        private _name: string;
        private _url: string;
        private _desc: string;

        constructor(name: string, url: string, desc: string ) {
            this._name = name;
            this._url = url;
            if (desc) {
                this._desc = desc;
            }
        }

        public set name(n: string) {
            this._name = n;
        }
        public get name(): string {
            return this._name;
        }
        public set url(u: string) {
            this._url = u;
        }
        public get url(): string {
            return this._url;
        }
        public set desc(desc: string) {
            this._desc = desc;
        }
        public get desc(): string {
            return this._desc;
        }
    }

    export class GetRewardData {
        private _jade: number;
        private _gold: number;
        private _bowlder: number; // 玉石
        private _feat: number;  //荣誉
        private _fame: number;  //名望
        private _contribution: number; //战功
        private _cardKeys: Array<number>;
        private _cards: Collection.Dictionary<number, number>;
        private _treasures: Array<any>;
        private _treasureIds: Array<any>;
        private _skins: Array<string>;
        private _headFrames: Array<any>;
        private _other: Array<OtherData>;


        constructor() {
            this._jade = 0;
            this._gold = 0;
            this._bowlder = 0;
            this._feat = 0;
            this._fame = 0;
            this._contribution = 0;
            this._cardKeys = new Array<number>();
            this._cards = new Collection.Dictionary<number, number>();
            this._treasures = new Array<any>();
            this._skins = new Array<any>();
            this._headFrames = new Array<any>();
            this._treasureIds = new Array<any>();
            this._other = new Array<OtherData>();
        }
        public set jade(j: number) {
            this._jade = j;
        }
        public get jade():number {
            return this._jade;
        }
        public addJade(j: number) {
            this._jade += j;
        }
        public set bowlder(b: number) {
            this._bowlder = b;
        }
        public get bowlder(): number {
            return this._bowlder;
        }
        public addBowlder(b: number) {
            this._bowlder += b;
        }
        public set gold(g: number) {
            this._gold = g;
        }
        public get gold():number {
            return this._gold;
        }
        public addGold(g: number) {
            this._gold += g;
        }
        public set feat(f: number) {
            this._feat = f;
        }
        public get feat(): number {
            return this._feat;
        }
        public addFeat(f: number) {
            this._feat += f;
        }
        public set fame(f: number) {
            this._fame = f;
        }
        public get fame() {
            return this._fame;
        }
        public addFame(f: number) {
            this._fame += f;
        }
        public set contribution(f: number) {
            this._contribution = f;
        }
        public get contribution() {
            return this._contribution;
        }
        public addContribution(c: number) {
            this._contribution += c;
        }
        public addOther(name: string,url: string, desc?: string) {
            let other = new OtherData(name, url, desc);
            this._other.push(other);
        }
        public get other(): Array<OtherData> {
            return this._other;
        }
        public addCards (id: number, num: number) {
            this._cardKeys.push(id);
            this._cards.setValue(id, num);
        }
        public get cardKeys(): Array<number> {
            return this._cardKeys;
        }
        public get cards (): Collection.Dictionary<number, number> {
            return this._cards;
        }
        public addTreasureId(treasureID: any) {
            this._treasureIds.push(treasureID);
        }
        public get treasureIds() {
            return this._treasureIds;
        }
        public addTreasure(treasure: any) {
            this._treasures.push(treasure);
        }
        public get treasures(): any[] {
            return this._treasures;
        }
        public addSkins(s: string) {
            this._skins.push(s);
        }
        public get skins(): any[] {
            return this._skins;
        }
        public addHeadFrame(h: any) {
            this._headFrames.push(h);
        }
        public get headFrame(): any[] {
            return this._headFrames;
        }
        public addRewardToType(t: Reward.RewardType, rewardData: any) {
            if (t == Reward.RewardType.T_GOLD) {
                this.addGold(rewardData);
            } else if (t == Reward.RewardType.T_JADE) {
                this.addJade(rewardData);
            } else if (t == Reward.RewardType.T_CARD) {
                this.addCards(rewardData.CardID, rewardData.Amount);
            } else if (t == Reward.RewardType.T_TREASURE) {
                this.addTreasure(rewardData);
            } else if (t == Reward.RewardType.T_CARD_SKIN) {
                this.addSkins(rewardData);
            } else if (t == Reward.RewardType.T_HEAD_FRAME) {
                this.addHeadFrame(rewardData);
            } else if (t == Reward.RewardType.T_FEATS) {
                this.addFeat(rewardData);
            } else if (t == Reward.RewardType.T_PRESTIGE) {
                this.addFame(rewardData);
            } else if (t == Reward.RewardType.T_EQUIP) {
                let equipData = Equip.EquipMgr.inst.getEquipData(rewardData);
                this.addOther(equipData.equipName , equipData.equipIcon);
            } else if (t == Reward.RewardType.T_EMOJI) {
                let emojiTeam = Social.EmojiMgr.inst.getEmojiTeam(rewardData);
                this.addOther(emojiTeam.icon, emojiTeam.name);
            } else if (t == Reward.RewardType.T_CONTRIBUTION) {
                this.addContribution(rewardData);
            } else if (t == Reward.RewardType.T_BOWLDER) {
                this.addBowlder(rewardData);
            } 
        }
    }
}