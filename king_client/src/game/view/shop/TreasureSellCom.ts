module Shop {
	export class TreasureSellCom extends fairygui.GComponent {

		private _tipTimeText: fairygui.GTextField;
		private _tipTimeBg: fairygui.GGraph;
		private _list: fairygui.GList;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._tipTimeBg = this.getChild("tipBg").asGraph;
			this._tipTimeText = this.getChild("tipTime").asTextField;
			this._list = this.getChild("list").asList;

			this.setCanBuyMode(true);

			// Core.EventCenter.inst.addEventListener(GameEvent.RefreshSoldTreasureEv, (evt: egret.Event) => {
			// 	let cd = <number>evt.data;
			// 	if (cd > 0) {
			// 		this.setCanBuyMode(false, cd);
			// 	}
			// }, this);
		}

		public setTreasureProducts(products: Array<Payment.TreasureProduct>) {
			this._list.removeChildren(0, -1, true);
			products.forEach(product => {
				let com = fairygui.UIPackage.createObject(PkgName.shop, "treasureItem", TreasureItemCom).asCom as TreasureItemCom;
				com.setTreasureProduct(product);
				this._list.addChild(com);
			});
		}

		public setCanBuyMode(canBuy: boolean, cd?: number) {
			this._tipTimeBg.visible = !canBuy;
			this._tipTimeText.visible = !canBuy;
			this._tipTimeBg.touchable = !canBuy;

			if (cd) {
				let sec = cd;
				let hours = Math.round((sec - 30 * 60) / (60 * 60));
				let minutes = Math.round((sec - 30) / 60) % 60;
				if (hours > 0) {
					this._tipTimeText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60153), hours);
				} else if (minutes > 0) {
					this._tipTimeText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60150), minutes);
				} else {
					this._tipTimeText.text = Core.StringUtils.TEXT(60141);
				}
			}
		}
		
		public async playTrans() {
			await new Promise<void>(resolve => {
				this.getTransition("t0").play(() => {
					resolve();
				});
            });
		}

		public onDestroy() {
			this._list.removeChildren(0, -1, true)
		}
	}
}