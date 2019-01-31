module WXGame {
	export class WXTreasureGetReward extends Core.BaseWindow {

		private _reward: Treasure.TreasureReward;
		private _hid: number;

		public async initUI() {
			super.initUI();
			this._myParent = Core.LayerManager.inst.maskLayer;
			
			this.center();
			this.modal = true;
			try {
				this.contentPane.getChild("getBtn").asButton.addClickListener(this._onClickGet, this);
			} catch (e) {
				console.log(e);
			}
		}

		private async _onClickGet() {
			// if (this._reward) {
			// 	Core.ViewManager.inst.open(ViewName.treasureRewardInfo, this._reward, new Treasure.TreasureItem(-1, "BX0303"));
			// }
			if (this._hid) {
				let args = {
					Hid: this._hid
				};
				let result = await Net.rpcCall(pb.MessageID.C2S_GET_SHARE_TREASURE_REWARD, pb.GetShareTreasureArg.encode(args));
				if (result.errcode == 0) {
					let reply = pb.OpenTreasureReply.decode(result.payload);
					let reward = new Treasure.TreasureReward();
					reward.setRewardForOpenReply(reply);
					Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, "BX0303"));
				} else {
					Core.TipsUtils.showTipsFromCenter("你已经领取过该类的限定宝箱啦");
				}
				Core.ViewManager.inst.closeView(this);
			}
		}

		public async open(...param: any[]) {
			super.open(...param);
			// this._reward = param[0];
			this._hid = param[0];
			let name = param[1];
			try {
				this.contentPane.getChild("txt2").asTextField.text = `<${name}>\n赠送给你的限定宝箱！\n记得也要回赠给好友哦。`
			} catch (e) {
				console.log(e);
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
		}
	}
}