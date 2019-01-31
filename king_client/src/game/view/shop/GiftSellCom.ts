module Shop {
	export class GiftSellCom extends fairygui.GComponent {

		private _list: fairygui.GList;
		private _curListIndex: number;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._list = this.getChild("list").asList;

			// Core.EventCenter.inst.addEventListener(GameEvent.RefreshLimitGiftEv, (evt: egret.Event) => {
			// 	let product = <Payment.GiftProduct>evt.data;
			// 	this.setGiftProducts([product]);
			// }, this);
		}

		public setGiftProducts(products: Array<Payment.GiftProduct>) {
			this._list.removeChildren(0, -1, true);
			products.forEach(product => {
				if (product.isVipCard()) {
					let com = fairygui.UIPackage.createObject(PkgName.shop, "advipItem").asCom as GiftVipCom;
					com.setProduct(product);
					this._list.addChild(com);
				} else if (product.isMiniVipCard()) {
					let com = fairygui.UIPackage.createObject(PkgName.shop, "minivipItem").asCom as GiftVipCom;
					com.setProduct(product);
					this._list.addChild(com);
				} else {
					let com = fairygui.UIPackage.createObject(PkgName.shop, "purchaseItem").asCom as GiftItemCom;
					com.setProduct(product);
					this._list.addChild(com);
				}
			});
		}

		public async playTrans() {
			await new Promise<void>(resolve => {
				this.getTransition("t0").play(() => {
					resolve();
				});
            });
		}

		public onDestroy() {
			this._list.removeChildren(0, -1, true);
		}
	}
}