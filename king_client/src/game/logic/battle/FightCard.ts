module Battle {

    // 幕僚、大雾
    var unBlinkSkills = [1191, 1192, 1194, 1195, 1453];

    export class SkillGroup {
        private _group: string;
        private _name: string;
        private _desc: string;
        private _isEquip: boolean;
        private _ownerLevel: number;
        private _skills: Collection.Dictionary<number, boolean>;

        constructor(group:string, isEquip:boolean, ownerLevel:number) {
            this._group = group;
            this._isEquip = isEquip;
            this._ownerLevel = ownerLevel;
            this._skills = new Collection.Dictionary<number, boolean>();
            if (group != "") {
                let groupSkillDatas = BattleMgr.inst.getGroupSkills(group);
                for (let skillData of groupSkillDatas) {
                    if (skillData.name && skillData.name != "") {
                        this._name = skillData.name;
                    }
                    if (this._isEquip && skillData.desTra && skillData.desTra != "") {
                        this._desc = CardPool.CardPoolMgr.inst.formatSkillDesc(skillData, ownerLevel);
                    }
                    this.setSkillEffective(skillData.__id__, false);
                }
            }
        }

        public static getGroupsFromSkillIDs(skills:Array<number>, isEquip:boolean, ownerLevel:number):Array<SkillGroup> {
            if (!skills) {
                return [];
            }

            let groups:Array<SkillGroup> = [];
            skills.forEach(skillID => {
                let skillData = Data.skill.get(skillID);
                if (!skillData) {
                    return;
                }

                for( let skGroup of groups) {
                    if (skGroup.isSkillInGroup(skillID)) {
                        skGroup.setSkillEffective(skillID, true);
                        return;
                    }
                }

                let skGroup = new SkillGroup(skillData.skillGroup, isEquip, ownerLevel);
                skGroup.setSkillEffective(skillID, true);
                groups.push(skGroup);
            });
            return groups;
        }

        public get name(): string {
            return this._name;
        }

        public get desc(): string {
            if (this.isEffective) {
                return this._desc;
            } else {
                return "";
            }
        }

        public get isEffective(): boolean {
            if (!this._name || this._name == "") {
                return false;
            }
            let isAllNoEffect = false;
            this._skills.forEach((_:number, isEffect:boolean) => {
                if (!isAllNoEffect && isEffect) {
                    isAllNoEffect = isEffect;
                }
            });
            return isAllNoEffect;
        }

        public setSkillEffective(skillID: number, val: boolean) {
            if (val && (!this._name || this._name == "")) {
                let skillData = Data.skill.get(skillID);
                if (skillData) {
                    this._name = skillData.name;
                    if (this._isEquip && skillData.desTra && skillData.desTra != "") {
                        this._desc = "<font strokecolor=0x000000 stroke=2><b><i>" + skillData.name + ":</i> </b></font>" + parse2html(skillData.desTra, 1);
                    }
                }
            }
            this._skills.setValue(skillID, val);
        }

        public setAllSkillUnEffective() {
            this._skills.keys().forEach(skillID => {
                this._skills.setValue(skillID, false);
            });
        }

        public isSkillInGroup(skillID:number): boolean {
            return this._skills.containsKey(skillID);
        }
    }

    export class FightCard implements UI.ICardObj, IBattleObj {
        private _upNum: number;
        private _downNum: number;
        private _leftNum: number;
        private _rightNum: number;
        private _baseCardObj: UI.ICardObj;
        private _objId: number;
        private _owner: Fighter;
        private _gridObj: GridObj;
        private _view: FightCardView;
        private _gcardId: number;
        private _name :string;
        private _skin: string;
        private _skill1Name: string;
        private _skill2Name: string;
        private _skill3Name: string;
        private _skill4Name: string;
        private _skillDesc: string;
        private _weaponRedFrame: number;
        private _weaponSound: string;
        private _initEffects: Array<pb.IMovieEffect>;
        private _isShadow: boolean;
        private _initOwner: Fighter;
        private _skills: Array<SkillGroup>;
        private _isPublicEnemy: boolean;
        private _isInFog: boolean;
        private _equip:Equip;
        private _level: number;

        constructor(data:pb.ICard, owner:Fighter) {
            this._initEffects = data.Effect;
            this._level = 1;
            if (Diy.DiyMgr.inst.isDiyCard(data.Id)) {
                let diyCard = Diy.DiyMgr.inst.getDiyCard(data.Id);
                this._baseCardObj = diyCard ? diyCard : new Diy.DiyCard(data.DiyInfo);
            } else {
                let _resData = Data.pool.get(data.Id);
                if (!_resData) {
                    return;
                }
                this._skin = data.Skin;
                let collectCard = CardPool.CardPoolMgr.inst.getCollectCard(_resData.cardId);
                if (owner.uid == Player.inst.uid && !CardPool.CardPoolMgr.inst.isSystemCard(_resData) && 
                    collectCard && collectCard.gcardId == data.Id) {
                    this._baseCardObj = collectCard;
                    this._level = collectCard.level;
                } else {
                    let card = new CardPool.BaseCard(_resData);
                    this._baseCardObj = card;
                    this._level = card.level;
                }
            }
            
            this._gcardId = this._baseCardObj.gcardId;
            this._name = this._baseCardObj.name;
            this._skill1Name = this._baseCardObj.skill1Name;
            this._skill2Name = this._baseCardObj.skill2Name;
            this._skill3Name = this._baseCardObj.skill3Name;
            this._skill4Name = this._baseCardObj.skill4Name;
            this._skillDesc = this._baseCardObj.skillDesc;
            this._owner = owner;
            this._initOwner = owner;
            this._objId = data.ObjId;
            this._upNum = data.Up;
            this._downNum = data.Down;
            this._leftNum = data.Left;
            this._rightNum = data.Right;
            this._isInFog = data.IsInFog;
            this._isPublicEnemy = data.IsPublicEnemy;
            this._skills = SkillGroup.getGroupsFromSkillIDs(data.Skills, false, this._level);
            if (data.Equip) {
                this._equip = new Equip(data.Equip, this);
            }
        }

        public get initEffects(): Array<pb.IMovieEffect> {
            return this._initEffects;
        }

        public clearInitEffects() {
            this._initEffects = null;
        }

        public get objId(): number {
            return this._objId;
        }

        public playEffect(effectId:string | number, playType:number, visible:boolean=true, targetCount?:number, value?:number): Promise<void> {
            return this._view.playEffect(effectId, playType, visible, targetCount, value);
        }

        public get side(): Side {
            let battle = BattleMgr.inst.battle;
            return battle && this._owner.uid == battle.getOwnFighter().uid ? Side.OWN : Side.ENEMY;
        }

        public set owner(o:Fighter) {
            this._owner = o;
        }
        public get owner():Fighter {
            return this._owner;
        }

        public get initOwner():Fighter {
            return this._initOwner;
        }

        public get collectCard(): CardPool.Card | Diy.DiyCard {
            return this._baseCardObj.collectCard;
        }

        public get upNum(): number {
            return this._upNum;
        }
        public set upNum(val:number) {
            this._upNum = val;
        }

        public get downNum(): number {
            return this._downNum;
        }
        public set downNum(val:number) {
            this._downNum = val;
        }

        public get leftNum(): number {
            return this._leftNum;
        }
        public set leftNum(val:number) {
            this._leftNum = val;
        }

        public get rightNum(): number {
            return this._rightNum;
        }
        public set rightNum(val:number) {
            this._rightNum = val;
        }

        public get cardId():number {
            return this._baseCardObj.cardId;
        }

        public get gcardId(): number {
            return this._gcardId;
        }

        public get state(): CardPool.CardState {
            return this._baseCardObj.state;
        }

        public get amount():number {
            return this._baseCardObj.amount;
        }

        public get maxAmount():number {
            return this._baseCardObj.maxAmount;
        }

        public get energy():number {
            return this._baseCardObj.energy;
        }

        public get maxEnergy():number {
            return this._baseCardObj.energy;
        }

        public get name(): string {
            return this._name;
        }

        public get rare(): CardQuality {
            return this._baseCardObj.rare;
        }

        public get skill1Name(): string {
            return this._skill1Name;
        }

        public get skill2Name(): string {
            return this._skill2Name;
        }

        public get skill3Name(): string {
            return this._skill3Name;
        }

        public get skill4Name(): string {
            return this._skill4Name;
        }

        public get skillDesc(): string {
            return this._skillDesc;
        }

        public get skillIds(): Array<number> {
            return this._baseCardObj.skillIds;
        }

        public get icon():number {
            let battle = BattleMgr.inst.battle;
            if (this.isShowFogUI()) {
                return 311;
            } else {
                return this._baseCardObj.icon;
            }
        }

        public get skin(): string {
            let battle = BattleMgr.inst.battle;
            if (this.isShowFogUI()) {
                return null;
            }
            return this._skin;
        }

        public get equip(): string {
            let battle = BattleMgr.inst.battle;
            if (!this._equip || (this.isShowFogUI())) {
                return null;
            } else {
                return this._equip.equipID;
            }
        }

        public get upNumOffset(): number {
            return 0;
        }

        public get downNumOffset(): number {
            return 0;
        }

        public get leftNumOffset(): number {
            return 0;
        }

        public get rightNumOffset(): number {
            return 0;
        }

        public get isNew(): boolean {
            return false;
        }

        public get weapon(): string {
            let skin = this.skin;
            if (skin) {
                let skinData = CardPool.CardSkinMgr.inst.getSkinConf(skin);
                if (skinData && skinData.weapon && skinData.weapon != "") {
                    return skinData.weapon;
                }
            }
            return this._baseCardObj.weapon;
        }
        
        public get sound(): string {
            return this._baseCardObj.sound;
        }

        public get weaponRedFrame(): number {
            if (!this._weaponRedFrame) {
                this._weaponRedFrame = 2;
                let weapon = this.weapon;
                for (let k of Data.redframe.keys) {
                    let weaponData = Data.redframe.get(k);
                    if (weaponData.weapon == weapon) {
                        this._weaponRedFrame = weaponData.frame;
                        this._weaponRedFrame = this._weaponRedFrame <= 1 ? 2 : this._weaponRedFrame;
                        break;
                    }
                }
            }
            return this._weaponRedFrame;
        }

        public get weaponSound(): string {
            if (!this._weaponSound) {
                let weapon = this.weapon;
                this._weaponSound = `${weapon}_mp3`;
                for (let k of Data.redframe.keys) {
                    let weaponData = Data.redframe.get(k);
                    if (weaponData.weapon == weapon) {
                        this._weaponSound = `${weaponData.sound}_mp3`;
                        break;
                    }
                }
            }
            return this._weaponSound;
        }

        public get view(): FightCardView {
            return this._view;
        }
        public set view(v:FightCardView) {
            this._view = v;
        }

        public get gridObj(): GridObj {
            return this._gridObj;
        }
        public set gridObj(g:GridObj) {
            this._gridObj = g;
        }

        public get isShadow(): boolean {
            return this._isShadow;
        }
        public set isShadow(val:boolean) {
            this._isShadow = val;
        }

        public get isPublicEnemy(): boolean {
            return this._isPublicEnemy;
        }
        public set isPublicEnemy(val:boolean) {
            this._isPublicEnemy = val;
        }

        public get isInFog(): boolean {
            return this._isInFog;
        }
        public set isInFog(val:boolean) {
            this._isInFog = val;
        }

        public get isEnemy(): boolean {
            return this.side != Side.OWN || this._isPublicEnemy;
        }

        public get equipment(): Equip {
            return this._equip;
        }

        public get level(): number {
            return this._level;
        }

        public get isInCampaignMission(): boolean {
            return this._baseCardObj.isInCampaignMission;
        }

        public getEffectiveSkill(): Array<SkillGroup> {
            let skills: Array<SkillGroup> = [];
            this._skills.forEach(skill => {
                if (skill.isEffective) {
                    skills.push(skill);
                }
            });
            return skills;
        }

        public async triggerSkill(skillID: number, isEquip: boolean) {
            for (let skID of unBlinkSkills) {
                if (skillID == skID) {
                    return;
                }
            }

            if (isEquip) {
                if (this._equip) {
                    await this._equip.triggerSkill(skillID);
                }
                return;
            }

            for (let skill of this._skills) {
                if (skill.isEffective && skill.isSkillInGroup(skillID)) {
                    await this._view.skillBlink(skill.name);
                    return;
                }
            }
        }

        public addSkill(skillID: number) {
            let skillData = Data.skill.get(skillID);
            if (!skillData) {
                return;
            }

            for (let skill of this._skills) {
                if (skill.isSkillInGroup(skillID)) {
                    skill.setSkillEffective(skillID, true);
                    return;
                }
            }

            let skill = new SkillGroup(skillData.skillGroup, false, this._level);
            skill.setSkillEffective(skillID, true);
            this._skills.push(skill);
        }

        public delSkill(skillID: number, isEquip:boolean) {
            if (isEquip) {
                return;
            }

            for (let skill of this._skills) {
                if (skillID < 0) {
                    skill.setAllSkillUnEffective();
                } else {
                    if (skill.isSkillInGroup(skillID)) {
                        skill.setSkillEffective(skillID, false);
                        return;
                    }
                }
            }
        }

        public async playCard(gridObj: GridObj, needTalk: boolean) {
            this._moveToGrid(gridObj);
            let ok = this._owner.delHandCard(this);
            if (!ok) {
                BattleMgr.inst.battle.getOtherFighter(this._owner.uid).delHandCard(this);
            }
            await this._view.moveAndAddToGrid(gridObj.view, needTalk);
        }

        public _moveToGrid(grid:GridObj) {
            if (grid) {
                if (this._gridObj) {
                    this._gridObj.inGridCard = null;
                }
                this._gridObj = grid;
                grid.inGridCard = this;
            }
        }

        public async moveToGrid(targetGrid:GridObj, moveEffectId:string, movePos:CardNumPos) {
            this._moveToGrid(targetGrid);
            let targetGridView: GridView;
            if (targetGrid) {
                targetGridView = targetGrid.view;
            }
            await this._view.moveToGrid(targetGridView, moveEffectId, movePos);
        }

        public async attackAndMoveTarget(beAttackCard:FightCard, winPos:CardNumPos, losePos:CardNumPos, moveCard?:FightCard, 
            moveGrid?:GridObj, moveEffectId?:string, movePos?:CardNumPos, isGuide?:boolean, isArrow?:boolean) {

            if (moveCard && moveGrid) {
                moveCard._moveToGrid(moveGrid);
            }
            let moveGridView: GridView;
            let moveCardView: FightCardView;
            if (moveGrid) {
                moveGridView = moveGrid.view;
            }
            if (moveCard) {
                moveCardView = moveCard.view;
            }
            await this._view.attackAndMoveTarget(beAttackCard.view, winPos, losePos, moveCardView, 
                moveGridView, moveEffectId, movePos, isGuide, isArrow);
        }

        public async changeSide() {
            let fighter1 = BattleMgr.inst.battle.fighter1;
            if (fighter1.uid == this._owner.uid) {
                this._owner = BattleMgr.inst.battle.fighter2;
            } else {
                this._owner = fighter1;
            }
            await this._view.changeSide();
        }

        public modifyValue(modify:number, modifyType:number) {
            let pos = 0;
            if (modifyType == 1) {
                // 只有最小点数加
                pos = 1
                let min = this.upNum;
                if (this.downNum < min) {
                    pos = 2;
                    min = this.downNum;
                }
                if (this.leftNum < min) {
                    pos = 3;
                    min = this.leftNum;
                }
                if (this.rightNum < min) {
                    pos = 4;
                    min = this.rightNum;
                }
            }

            if (pos == 0 || pos == 1) {
                let upNum = 0;
                if (modifyType == 2) {
                    upNum = modify
                } else {
                    upNum = this.upNum + modify;
                }
                upNum = upNum < 0 ? 0 : upNum;
                this.upNum = upNum;
            }
            if (pos == 0 || pos == 2) {
                let downNum = 0;
                if (modifyType == 2) {
                    downNum = modify
                } else {
                    downNum = this.downNum + modify;
                }
                downNum = downNum < 0 ? 0 : downNum;
                this.downNum = downNum;
            }
            if (pos == 0 || pos == 3) {
                let leftNum = 0;
                if (modifyType == 2) {
                    leftNum = modify
                } else {
                    leftNum = this.leftNum + modify;
                }
                leftNum = leftNum < 0 ? 0 : leftNum;
                this.leftNum = leftNum;
            }
            if (pos == 0 || pos == 4) {
                let rightNum = 0;
                if (modifyType == 2) {
                    rightNum = modify
                } else {
                    rightNum = this.rightNum + modify;
                }
                rightNum = rightNum < 0 ? 0 : rightNum;
                this.rightNum = rightNum;
            }
            this._view.setNumText();
        }

        public async switchPos(target:FightCard) {
            let myGrid = this.gridObj;
            let p1 = this.moveToGrid(target.gridObj, "", CardNumPos.NONE);
            let p2 = target.moveToGrid(myGrid, "", CardNumPos.NONE);
            target.gridObj.inGridCard = target;
            this.gridObj.inGridCard = this;
            await p1;
            await p2;
        }

        public async toBeCopy(copyCard:pb.Card, ownerUid: Long) {
            let card = new FightCard(copyCard, BattleMgr.inst.battle.getFighter(ownerUid));
            BattleMgr.inst.battle.addBattleObj(card);
            if (this._gridObj) {
                await this._view.blink(Core.TextColors.white);
                this._view.toBeCopy(card);
                this._gridObj.inGridCardToBeCopy(card);
                card.gridObj = this._gridObj;
                this._view.setFrontSkin();
            } else {
                this.owner.handCardToBeCopy(card);
            }
        }

        public enterFog(isPublicEnemy:boolean) {
            this._isInFog = true;
            this._isPublicEnemy = isPublicEnemy;
            if (this.gridObj) {
                this.view.setFrontSkin();
            } else {
                this.view.hand.refresh(true);
            }
            if (this.view.effectPlayer && this.isEnemy) {
                this.view.effectPlayer.setVisible(false);
            }
        }

        public async leaveFog() {
            this._isInFog = false;
            if (this.gridObj) {
                await this.view.leaveFog();
            } else {
                this.view.hand.refresh(true);
            }
            if (this.view.effectPlayer) {
                this.view.effectPlayer.setVisible(true);
            }
        }

        public isShowFogUI(): boolean {
            let battle = BattleMgr.inst.battle;
            return this.isInFog && this.isEnemy && battle && battle.battleType != BattleType.VIDEO;
        }
    }

}
