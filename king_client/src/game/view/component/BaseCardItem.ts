module UI {

    export class BaseCardItem extends fairygui.GComponent implements IHandItem {
        public static NormalState = "normal";
        public static ForbidState = "forbid";
        public static GuardState = "guard";
        public static AttackState = "attack";
        public static HideState = "hide";
        public static campaignBanState = "campaignBan";

        protected _card: CardCom;
        protected _expProgressBar: MaskProgressBar;
        protected _progressText: fairygui.GTextField;
        //protected _energyProgressBar: MaskProgressBar;
        protected _stateCtrl: fairygui.Controller;
        protected _selectCtrl: fairygui.Controller;
        protected _campignUnlockText: fairygui.GTextField;
        
        protected _selected: boolean
        protected _cardObj: ICardObj;
        private _energyProgressX: number;
        private _energyProgressY: number;
        private _expProgressX: number;
        private _expProgressY: number;
        private _initHeight: number;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._card = this.getChild("card").asCom as CardCom;
            this._expProgressBar = this.getChild("expProgressBar").asCom as MaskProgressBar;
            this._progressText = this.getChild("progressText").asTextField;
            //this._energyProgressBar = this.getChild("energyProgressBar").asCom as MaskProgressBar;
            //this._energyProgressBar.bar.url = "cards_energyBarImg_png";
            this._stateCtrl = this.getController("state");
            this._selectCtrl = this.getController("select");
            this._campignUnlockText = this.getChild("campignUnlockHintText").asTextField;
            this._campignUnlockText.visible = false;
            this.selected = false;
            //this._energyProgressX = this._energyProgressBar.x;
            //this._energyProgressY = this._energyProgressBar.y;
            this._expProgressX = this._expProgressBar.x;
            this._expProgressY = this._expProgressBar.y;
            this._initHeight = this.height;
        }

        public get cardObj(): ICardObj {
            return this._cardObj;
        }
        public set cardObj(obj:ICardObj) {
            this._cardObj = obj;
            this._card.cardObj = obj;
        }

        public get inHandPoint(): egret.Point {
            return this._card.inHandPoint;
        }
        public set inHandPoint(p:egret.Point) {
            this._card.inHandPoint = p;
        }

        public get energyProgressBar(): MaskProgressBar {
            return null;
            //return this._energyProgressBar;
        }

        public get selected(): boolean {
            return this._selected;
        }

        protected setSelected(value:boolean) {
            this._selected = value;
            this._selectCtrl.selectedPage = value ? "selected" : "normal";
            this._card.visibleLightCircle(value);
        }

        public set selected(value:boolean) {
            this.setSelected(value);
        }

        public set state(state:string) {
            this._stateCtrl.selectedPage = state;
        }
        public get state(): string {
            return this._stateCtrl.selectedPage;
        }

        public visibleEnergyProgress(visible:boolean) {
            /*
            if (visible) {
                if (this._energyProgressBar.parent != this) {
                    this.addChild(this._energyProgressBar);
                    this._energyProgressBar.x = this._energyProgressX;
                    this._energyProgressBar.y = this._energyProgressY;
                    this.height = this._initHeight;
                }
            } else {
                if (this._energyProgressBar.parent == this) {
                    this.removeChild(this._energyProgressBar);
                    this.height = this._initHeight - this._energyProgressBar.height;
                }
            }
            */
            return;
        }

        public visibleExpProgress(visible:boolean) {
            if (visible) {
                if (this._expProgressBar.parent != this) {
                    this.addChild(this._expProgressBar);
                    this._expProgressBar.x = this._expProgressX;
                    this._expProgressBar.y = this._expProgressY;
                    this.height += this._expProgressBar.height;
                } 
            } else {
                if (this._expProgressBar.parent == this) {
                    this.removeChild(this._expProgressBar);
                    this.height -= this._expProgressBar.height;
                }
            }
            this.addChild(this._progressText);
            this._progressText.visible = visible;
        }

        private _updateProgressText() {
            if (this._cardObj.maxAmount <= 0) {
                this._progressText.text = `${this._cardObj.amount}/`+Core.StringUtils.TEXT(60030);
            } else {
                this._progressText.text = `${this._cardObj.amount}/${this._cardObj.maxAmount}`;
            }
        }

        public setProgress() {
            //this._energyProgressBar.setProgress(this._cardObj.energy, this._cardObj.maxEnergy);
            this._expProgressBar.setProgress(this._cardObj.amount, this._cardObj.maxAmount);
            this._updateProgressText();
        }

        public watchLevel() {
            this._card.watchLevel();
        }

        public unwatchLevel() {
            this._card.unwatchLevel();
        }

        public watchSkin() {
            this._card.watchSkin();
        }

        public unwatchSkin() {
            this._card.unwatchSkin();
        }
        public watchEquip() {
            this._card.watchEquip();
        }
        public unwatchEquip() {
            this._card.unwatchEquip();
        }

        public watchAmount() {
            this._card.watchProp(CardPool.Card.PropAmount, this._onPropAmountChange, this);
        }

        public unwatchAmount() {
            this._card.unwatchProp(CardPool.Card.PropAmount);
        }

        protected _onPropAmountChange() {
            this._expProgressBar.setProgress(this._cardObj.amount, this._cardObj.maxAmount);
            this._updateProgressText();
        }

        public watchEnergy() {
            this._card.watchProp(CardPool.Card.PropEnergy, this._onPropEnergyChange, this);
        }

        public unwatchEnergy() {
            this._card.unwatchProp(CardPool.Card.PropEnergy);
        }

        protected _onPropEnergyChange() {
            //this._energyProgressBar.setProgress(this._cardObj.energy, this._cardObj.maxEnergy);
        }

        public watch() {
            this.watchAmount();
            this.watchEnergy();
            this._card.watchLevel();
            this._card.watchSkin();
        }

        public unwatch() {
            this.unwatchAmount();
            this.unwatchEnergy();
            this._card.unwatchLevel();
            this._card.unwatchSkin();
        }
    }

}