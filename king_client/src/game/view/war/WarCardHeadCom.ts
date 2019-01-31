module War {

    export class WarCardHeadCom extends fairygui.GComponent {
        private _card: CardPool.Card;
        private _cardIcon: fairygui.GImage;
        private _cardPowerText: fairygui.GTextField;
        private _cardName: fairygui.GTextField;
        private _selectCtr: fairygui.Controller;
        private _disableCtr: fairygui.Controller;
        private _teamCtr: fairygui.Controller;
        private _power: number;
        private _nameBg: fairygui.GLoader;

         protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._cardIcon = this.getChild("headIcon").asImage;
            this._cardPowerText = this.getChild("value").asTextField;
            this._cardName = this.getChild("name").asTextField;
            this._selectCtr = this.getController("select");
            this._disableCtr = this.getController("disable");
            this._teamCtr = this.getController("team");
            this._nameBg = this.getChild("nameBg").asLoader;
            this._cardName.textParser = Core.StringUtils.parseColorText;
         }
         public async setInfo(cardID: number, type?: WarMsType) {
             let imgUrl = "";
             this._card = CardPool.CardPoolMgr.inst.getCollectCard(cardID);
             let skinID = this._card.skin;
             if (skinID == "" || skinID == undefined) {
                imgUrl = `avatar_${cardID}_png`;
             } else {
                imgUrl = `avatar_${Data.skin_config.get(skinID).head}_png`;
             }
             if (this._card.rare == 99) {
                 this._nameBg.url = "pvp_name_limited_png";
             } else {
                 this._nameBg.url = "pvp_name_normal_png";
             }
             this.getChild("n13").visible = false;
             Utils.setImageUrlPicture(this._cardIcon, imgUrl)
             this.setChoose(false);
             this.setClick(true);
             this.setPower(type);
             this._cardName.text = this._card.name.toString();
         }
         public async setChoose(bool: boolean) {
             if (bool) {
                 this._selectCtr.selectedIndex = 1;
             } else {
                this._selectCtr.selectedIndex = 0;
             }
         }
         public async setClick(bool: boolean) {
             this.touchable = bool;
             if (bool) {
                 this._disableCtr.selectedIndex = 0;
             } else {
                 this._disableCtr.selectedIndex = 1;
             }
            //  this.grayed = !bool;
         }
         public setInTeam(index: number) {
            //  this.touchable = !bool;
            this._teamCtr.selectedIndex = index;
         }
         public async setPower(type?: WarMsType) {
             if (type && type != WarMsType.Transport) {
                 let gcardID = this._card.gcardId;
                 this._cardPowerText.visible = true;
                 this._cardPowerText.text = `${this._card.getPower(type)}`;
                 //this._cardPowerText.text = `${this._card.getPower(type)}`;
                 this._power = this._card.getPower(type);
             } else {
                 this._power = 0;
                 this._cardPowerText.visible = false;
             }
         }
         public get cardID(): number {
             return this._card.cardId;
         }
         public get cardCamp(): Camp {
             return this._card.camp;
         }
         public get cardPower(): number {
             return this._power;
         }
    }
}