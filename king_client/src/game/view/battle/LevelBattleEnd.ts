module Battle {

    class LevelRewardCardItem extends RewardCardItem {
        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this.visibleEnergyProgress(false);
        }
    }

    export class LevelBattleEnd extends BaseBattleEnd {
        private _cardList: fairygui.GList;
        private _noRewardTips: fairygui.GTextField;
        private _rewardTitle: fairygui.GTextField;

        public initUI() {
            super.initUI();
            this._cardList = this.getChild("cardList").asList;
            this._cardList.itemClass = LevelRewardCardItem;
            this._noRewardTips = this.getChild("noRewardTips").asTextField;
            let rewardTitle = this.getChild("rewardTitle");
            if (rewardTitle) {
                this._rewardTitle = rewardTitle.asTextField;
            }
        }

        public async open(...param:any[]) {
            let isWin = param[0].WinUid == Player.inst.uid;
            this._resultCtrl.selectedPage = isWin ? "win" : "lose";
            if (isWin) {
                if (this._rewardTitle) {
                    this._rewardTitle.visible = false;
                }
                this.setRewardResBar(param[0].Res);
                if (this._hasNewCard(param[0].ChangeCards)) {
                    this._visibleRewardResBar(false);
                }
            } else if (this._rewardTitle) {
                this._rewardTitle.visible = false;
            }
            this._noRewardTips.visible = false;
            await super.open(isWin);
            Core.MaskUtils.showTransMask();
            Level.LevelMgr.inst.onEnterLevel();
            if (!isWin) {
                Core.MaskUtils.hideTransMask();
                this.touchable = true;
                return;
            }
            fairygui.GTimers.inst.callLater(this._showReward, this, param[0]);
        }

        public async close(...param:any[]) {
            await super.close(...param);
            this._cardList.removeChildren();
        }

        private _visibleRewardResBar(visible:boolean) {
            let rewardResBg = this.getChild("rewardResBg");
            let rewardResBar = this.getChild("rewardResBar");
            if (rewardResBg) {
                rewardResBg.visible = visible;
            }
            if (rewardResBar) {
                rewardResBar.visible = visible;
            }
        }

        private async _showReward(battleResult:any) {
            await fairygui.GTimers.inst.waitTime(300);
            Core.MaskUtils.hideTransMask();
            if (!this.isShow()) {
                return;
            }

            let hasOldCard = await this._showNewCard(battleResult.ChangeCards);
            if (!this.isShow()) {
                return;
            }

            if (battleResult.Res && battleResult.Res.length > 0) {
                this._visibleRewardResBar(true);
            }

            this.touchable = true;
            let hasCardChange = battleResult.ChangeCards && battleResult.ChangeCards.length > 0;
            //if (!hasOldCard && hasCardChange) {
            //    Core.ViewManager.inst.closeView(this);
            //    return;
            //}

            if (hasCardChange) {
                this.cardListDoAnimation(this._cardList, battleResult.ChangeCards);
            } else if (!battleResult.Res || battleResult.Res.length <= 0) {
                this._showNoRewardTips();
            }
        }

        private _showNoRewardTips() {
            this._noRewardTips.visible = true;
            this._noRewardTips.alpha = 0;
            egret.Tween.get(this._noRewardTips).to({alpha:1}, 600);
        }

        private _hasNewCard(changeCards:Array<any>): boolean {
            if (!changeCards) {
                return false;
            }
            for (let changeData of changeCards) {
                if (changeData.Old) {
                    continue;
                }
                return true;
            }
            return false;
        }

        private async _showNewCard(changeCards:Array<any>): Promise<boolean> {
            if (!changeCards) {
                return false;
            }
            let newCardPanel: RewardNewCard;
            this._cardList.visible = false;
            let hasOldCard = false;
            for (let changeData of changeCards) {
                if (changeData.Old) {
                    hasOldCard = true;
                    continue;
                }
                let newCardObj = new CardPool.Card(CardPool.CardPoolMgr.inst.getCardData(changeData.New.CardId, changeData.New.Level));
                newCardObj.init(changeData.New);
                if (!newCardPanel) {
                    newCardPanel = fairygui.UIPackage.createObject(PkgName.battle, "rewardNewCard", RewardNewCard) as RewardNewCard;
                }
 
                await newCardPanel.show(newCardObj);
                if (!this.isShow()) {
                    newCardPanel.hide();
                    return hasOldCard;
                }
            }
            
            if (newCardPanel) {
                newCardPanel.hide();
            }
            return hasOldCard
        }
    }

}