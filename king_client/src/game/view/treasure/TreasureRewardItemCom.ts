module Treasure {
	export class TreasureRewardItemCom extends fairygui.GComponent {

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
		}

		public setRewardInfo(t: Reward.RewardType, minCnt: number, maxCnt?: number) {
			let icon = Reward.RewardMgr.inst.getRewardIcon(t);
			this.getChild("rewardIcon").asLoader.url = icon;

			if (maxCnt && maxCnt > 0 && minCnt != maxCnt) {
				this.getChild("cnt").asTextField.text = `x${minCnt}~${maxCnt}`;
			} else {
				this.getChild("cnt").asTextField.text = `x${minCnt}`;
			}
		}
	}
}