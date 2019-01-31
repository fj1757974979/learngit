module Equip {

    export class EquipData {
        private _equipID: string;
        private _ownerCardID: number;
        private _hasEquip: boolean;
        private _equipData: any;
        private _skillArray: number[];
        private _skillDescArray: string[];
        private _skillNameArray: string[];

         constructor(id: string) {
             this._equipID = id;
             this._ownerCardID = 0;
             this._hasEquip = false;
             this.setEquip(id);
         }         
         public setEquip(id: string) {
             this._equipData = Data.item.get(id);
             this._skillArray = this._equipData.skill as number[];
             this._skillDescArray = new Array<string> ();
             this._skillNameArray = new Array<string> ();
             this._skillArray.forEach(_data => {
                 let data = Data.skill.get(_data);
                 if (data.name) {
                     this._skillNameArray.push(data.name);
                 }
                 if (data.desTra) {
                      this._skillDescArray.push(data.desTra);
                 }
             })
         }
         public get equipID(): string {
             return this._equipID;
         }
         public set ownerCardID(id: number) {
             this._ownerCardID = id;
         }
         public get ownerCardID(): number {
             return this._ownerCardID;
         }
         public get equipName(): string {
             return this._equipData.name;
         }
         public get equipIcon(): string {
             return `equip_${this._equipData.icon}_png`;
         }
         public get equipIconSmall(): string {
             return `equip_${this._equipData.iconSmall}_png`;
         }
         public get skillName(): string[] {
             return this._skillNameArray;
         }
         public get skillDescs(): string[] {
             return  this._skillDescArray;
         }
         public get skillDesc(): string {
             let desc = "";
            this._skillDescArray.forEach((_desc) => {
                desc += _desc;
            }) 
            return desc;
         }
         public getSkillDesc(): string {
            let str = parse2html(this.skillDesc).toString();
            if (str && str != "") {
                return str;
            }
            return "";
        }
         public get hasEquip(): boolean {
             return this._hasEquip;
         }
         public set hasEquip(bool: boolean) {
             this._hasEquip = true;
         }
    }

    export class EquipMgr {

        private static _inst: EquipMgr;

        private _equipList: Collection.Dictionary<string, Equip.EquipData>;
        private _myequipList: Collection.Dictionary<string, Equip.EquipData>;
        private _myequipIds: Array<string>;

        public static get inst(): EquipMgr {
            if (!EquipMgr._inst) {
                EquipMgr._inst = new EquipMgr();
                EquipMgr._inst.initEquip();
            }
            return EquipMgr._inst;
        }

        public initEquip() {
            this._equipList = new Collection.Dictionary<string, EquipData>();
            let equipKeys = Data.item.keys;
            equipKeys.forEach( _key => {
                let key = _key.toString();
                let equipData = new EquipData(key.toString());
                this._equipList.setValue(key, equipData);
            }, this);
        }
        public async openEquipSwitchWnd(cardobj: UI.ICardObj) {
            let ok = await this.fetchEquip();
            if (ok) {
                Core.ViewManager.inst.open(ViewName.equipPanel, cardobj.equip, cardobj.cardId);
            }
        }
        public async openEquipBagWnd() {
            let ok = await this.fetchEquip();
            if (ok) {
                Core.ViewManager.inst.open(ViewName.equipBag);
            }
        }
        public async fetchEquip(): Promise<boolean> {
            if (this._myequipList) {
                return true;
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_EQUIP, null);
            if (result.errcode == 0) {
                let reply = pb.EquipData.decode(result.payload);
                this._myequipList = new Collection.Dictionary<string, EquipData>();
                this._myequipIds = new Array<string>();
                reply.Equips.forEach(_equip => {
                    let equipData = this._equipList.getValue(_equip.EquipID);
                    this._myequipIds.push(_equip.EquipID);
                    equipData.hasEquip = true;
                    equipData.ownerCardID = _equip.OwnerCardID;
                    this._myequipList.setValue(_equip.EquipID, equipData);
                });
                return true;
            }
            return false;
        }

        public async addEquip(equipID: string) {
            let ok = await this.fetchEquip();
            if (ok) {
                if (this._equipList.containsKey(equipID) && !this._myequipList.containsKey(equipID)) {
                    let equipData = this._equipList.getValue(equipID);
                    equipData.hasEquip = true;
                    this._myequipIds.push(equipID);
                    this._myequipList.setValue(equipID, equipData);
                }
            }
        }

        public hasEquip(equipID: string) {
            return this._myequipList.containsKey(equipID);
        }

        public getEquipData(equipID: string) {
            if (!this._equipList.containsKey(equipID)) {
                return null;
            }
            return this._equipList.getValue(equipID);
        }
        public get allEquip() {
            return this._equipList;
        }
        public get myEquip() {
            return this._myequipList;
        }
        public get myEquipIds() {
            this._myequipIds.sort((a,b) => {
                let aEquip = this._myequipList.getValue(a);
                let bEquip = this._myequipList.getValue(b);
                if (aEquip.ownerCardID == 0 ) {
                    if (bEquip.ownerCardID != 0) {
                        return -1;
                    } else {
                        if (a > b) {
                            return 1;
                        } else {
                            return -1;
                        }
                    }
                } else {
                    if (bEquip.ownerCardID != 0) {
                        if (a > b) {
                            return 1;
                        } else {
                            return -1;
                        }
                    } else {
                        return 1;
                    }
                }
                
            });
            return this._myequipIds;
        }
    }

    function onCardDel(ev:egret.Event) {
        let card = ev.data as CardPool.Card;
        let equipID = card.equip;
        if (equipID && equipID != "") {
            let equipData = EquipMgr.inst.getEquipData(equipID);
            if (equipData) {
                equipData.ownerCardID = 0;
            }
        }
    }

    export function init() {

        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;

        registerView(ViewName.equipBag, () => {
            let equipBagWnd = new EquipBagWnd();
            equipBagWnd.contentPane = createObject(PkgName.equip, ViewName.equipBag).asCom;
            return equipBagWnd;
        })
        registerView(ViewName.equipItemWnd, () => {
            let equipItemWnd = new EquipItemWnd();
            equipItemWnd.contentPane = createObject(PkgName.equip, ViewName.equipItemWnd).asCom;
            return equipItemWnd;
        })
        registerView(ViewName.equipPanel, () => {
            let equipPanel = new EquipSwitchWnd();
            equipPanel.contentPane = createObject(PkgName.equip, ViewName.equipPanel).asCom;
            return equipPanel;
        })

        // EquipMgr.inst.initEquip();
        Core.EventCenter.inst.addEventListener(GameEvent.CardDelEv, onCardDel, null);
    }
}