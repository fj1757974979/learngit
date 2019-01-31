module Diy {

    export class DiyMgr {
        private static _inst: DiyMgr

        private _allDiySkills: Collection.MultiDictionary<number, any>;
        private _maxLevel: number;
        private _id2DiyCards: Collection.Dictionary<number, DiyCard>;
        private _allDiyCards: Array<DiyCard>;

        constructor() {
            this.initData();
        }

        public initData() {
            this._allDiySkills = new Collection.MultiDictionary<number, any>();
            this._id2DiyCards = new Collection.Dictionary<number, DiyCard>();
            this._allDiyCards = [];
            this._maxLevel = 0;
            Data.diy.keys.forEach(k => {
                let _data = Data.diy.get(k);
                if (_data == null) {
                    return;
                }

                let _level = _data.level;
                if (_level > this._maxLevel) {
                    this._maxLevel = _level;
                }
                this._allDiySkills.setValue(_level, _data);
            });

            this._allDiyCards.sort((card1:DiyCard, card2:DiyCard):number => {
                return card1.cardId - card2.cardId;
            })
        }

        public static get inst(): DiyMgr {
            if (!DiyMgr._inst) {
                DiyMgr._inst = new DiyMgr();
            }
            return DiyMgr._inst;
        }

        public onLogin(diyCardDatas:Array<any>) {
            if (!diyCardDatas) {
                return;
            }
            diyCardDatas.forEach(data => {
                let card = new DiyCard(data);
                this._id2DiyCards.setValue(card.cardId, card);
                this._allDiyCards.push(card);
            });
        }

        public getDiyCard(cardId:number): DiyCard {
            return this._id2DiyCards.getValue(cardId);
        }

        public getAllCards():Array<DiyCard> {
            return this._allDiyCards;
        }

        public isDiyCard(cardId:number):boolean {
            return cardId >= 1000000;
        }

        public updateDiyCards(diyCardDatas:Array<any>) {
            if (!diyCardDatas) {
                return;
            }
            diyCardDatas.forEach(data => {
                let oldCard = this._id2DiyCards.getValue(data.CardId);
                if (oldCard) {
                    if (!data.DiySkillId1 || data.DiySkillId1 <= 0) {
                        // del
                        this._id2DiyCards.remove(data.CardId);
                        Collection.remove(this._allDiyCards, oldCard);
                    } else {
                        oldCard.update(data);
                    }
                } else {
                    let card = new DiyCard(data);
                    this._id2DiyCards.setValue(card.cardId, card);
                    this._allDiyCards.push(card);
                }
            });
        }

        get maxLevel() {
            return this._maxLevel;
        }

        public getLevelDiySkills(level:number): Array<any> {
            return this._allDiySkills.getValue(level);
        }

        public getDiySkillName(diySkillId:number): string {
            let diySkillData = Data.diy.get(diySkillId);
            if (!diySkillData) {
                return "";
            }
            let skillDatas: Array<any> = [];
            for (let i=0; i < diySkillData.skill.length; i++) {
                let skData = Data.skill.get(diySkillData.skill[i]);
                if (skData && skData.name) {
                    return skData.name;
                }
            }
            return "";
        }

        public getDiySkillDesc(diySkillId:number): string {
            let diySkillData = Data.diy.get(diySkillId);
            if (!diySkillData) {
                return "";
            }
            let skillDatas: Array<any> = [];
            for (let i=0; i < diySkillData.skill.length; i++) {
                let skData = Data.skill.get(diySkillData.skill[i]);
                if (skData && skData.desTra) {
                    return skData.desTra;
                }
            }
            return "";
        }

        public async doDiy(name:string, diySkillId1:number, diySkillId2:number, weapon:string, imgData:string) {
            let result = await Net.rpcCall(pb.MessageID.C2S_DIY_CARD, pb.DiyCardArg.encode({"Name":name, "DiySkillId1":diySkillId1, 
                "DiySkillId2":diySkillId2, "Weapon":weapon, "Img":imgData}));
            if (result.errcode != 0) {
                return null;
            } 
            return pb.DiyCardReply.decode(result.payload);
        }

        public async doAgainDiy(cardId:number): Promise<any> {
            let result = await Net.rpcCall(pb.MessageID.C2S_DIY_CARD_AGAIN, pb.TargetCard.encode({"CardId":cardId}));
            if (result.errcode != 0) {
                return null;
            } 

            return pb.DiyCardReply.decode(result.payload);
        }
    }

    function onLogout() {
        DiyMgr.inst.initData();
    }

    export function init() {
        // Player.inst.addEventListener(Player.LogoutEvt, onLogout, null);

        let diyView = fairygui.UIPackage.createObject(PkgName.diy, ViewName.diy, DiyView) as DiyView;
        Core.ViewManager.inst.register(ViewName.diy, diyView);
        let diySkillPanel = fairygui.UIPackage.createObject(PkgName.diy, ViewName.diySkillPanel, DiySkillPanel) as DiySkillPanel;
        Core.ViewManager.inst.register(ViewName.diySkillPanel, diySkillPanel);
    }

}