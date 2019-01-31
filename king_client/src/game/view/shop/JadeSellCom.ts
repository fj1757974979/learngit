module Shop {
	export class JadeSellCom extends fairygui.GComponent {

		private _list: fairygui.GList;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._list = this.getChild("list").asList;
		}

		public setJadeProducts(products: Array<Payment.JadeProduct>) {
			this._list.removeChildren(0, -1, true);
			products.forEach(product => {
				let com = fairygui.UIPackage.createObject(PkgName.shop, "jadeItem").asCom as JadeItemCom;
				com.setProduct(product);
				this._list.addChild(com);
			});
			if (products.length > 3) {
				let more = products.length - 3;
				this._list.height += 220 * Math.ceil(more / 3);
				this.height += 220 * Math.ceil(more / 3);
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
			this._list.removeChildren(0, -1, true);
		}
	}
}