module Pvp {

    export class RankHandWnd extends Core.BaseWindow {
        
        private _titleText: fairygui.GTextField;
        private _titleText2: fairygui.GTextField;
        private _titleText3: fairygui.GTextField;
        private _rankHand: RankHand;

        public initUI() {
            super.initUI();

            this.center();
            this.modal = true;
            this.adjust(this.contentPane.getChild("closeBg"));

            this.contentPane.getChild("closeBg").addClickListener(() => {
                
                Core.ViewManager.inst.closeView(this);
            }, this);
            this._titleText = this.contentPane.getChild("txt").asTextField;
            this._titleText2 = this.contentPane.getChild("txt2").asTextField;
            this._titleText3 = this.contentPane.getChild("txt3").asTextField;
            this._rankHand = this.contentPane.getChild("handCard") as RankHand;
        }

        public async open(...param: any[]) {
            super.open(...param);
            await this._rankHand.delAllCard();
            let replyData = param[0] as pb.FetchSeasonHandCardReply;
            let titleText = Utils.rankChangeType2Text(replyData.ChangeType);
            this._titleText.text = Core.StringUtils.format(Core.StringUtils.TEXT(titleText[1]), replyData.ChangeCurPro, replyData.ChangeMaxPro);
            this._titleText2.text = `${Core.StringUtils.TEXT(70026)}：${replyData.WinCnt}`;
            // this._titleText2.text = Core.StringUtils.format(Core.StringUtils.TEXT(titleText[0]), Player.inst.rankHandCardPro.Max);
            this._setCards(replyData.CardIDs);
        }

        private async _setCards(cardIds: number[]) {
            for (let i = 0; i < cardIds.length; i++) {
                let cardId = cardIds[i];
                let card = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
                this._rankHand.addCard(card);
            }
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}