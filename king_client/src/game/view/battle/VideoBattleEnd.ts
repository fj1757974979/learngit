module Battle {

    export class VideoBattleEnd extends BaseBattleEnd {
        private _cardList: fairygui.GList;

        public initUI() {
            super.initUI();
            this._cardList = this.getChild("cardList").asList;
            this._cardList.itemClass = RewardCardItem;
        }

        public async open(...param:any[]) {
            let isWin = param[0].IsWin;
            this._resultCtrl.selectedPage = isWin ? "win" : "lose";
            await super.open(isWin);
            //Campign.CampignMgr.inst.onEnterCampign();
            this.cardListDoAnimation(this._cardList, param[0].ChangeCards);
        }
    }

}