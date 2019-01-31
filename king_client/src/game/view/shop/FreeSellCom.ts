module Shop {
	export class FreeSellCom extends fairygui.GComponent {

		private _list: fairygui.GList;
		private _freeTypeToItem: Collection.Dictionary<number, FreeItemComBase>;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._list = this.getChild("list").asList;
			this._freeTypeToItem = new Collection.Dictionary<number, FreeItemComBase>();
		}

		public setFreeSellData(datas: Array<pb.ShopFreeAds>) {
			this._list.removeChildren(0, -1, true);
			this._freeTypeToItem.clear();
			datas.sort((a,b) => {
				return a.Type - b.Type;
			})
			datas.forEach(data => {
				let type = data.Type;
				let com: FreeItemComBase = null;
				if (type == pb.ShopFreeAdsType.GoldAds) {
					com = fairygui.UIPackage.createObject(PkgName.shop, "freeGold").asCom as FreeGoldItemCom;
				} else if (type == pb.ShopFreeAdsType.TreasureAds) {
					com = fairygui.UIPackage.createObject(PkgName.shop, "freeTreasure").asCom as FreeTreasureItemCom;
				} else if (type == pb.ShopFreeAdsType.JadeAds) {
					com = fairygui.UIPackage.createObject(PkgName.shop, "freeTreasure").asCom as FreeTreasureItemCom;
					// com = fairygui.UIPackage.createObject(PkgName.shop, "freeJade").asCom as FreeJadeItemCom;
				}
				if (com) {
					com.setData(data);
					com.host = this;
					this._list.addChild(com);
					this._freeTypeToItem.setValue(<number>type, com);
				}
			});
		}

		public updateFreeItemCanGetState(freeId: number, freeType: number) {
			let item = this._freeTypeToItem.getValue(freeType);
			if (item) {
				// console.log("updateFreeItemCanGetState --> true");
				item.canGetForShare = true;
			}
		}

		public async playTrans() {
			await new Promise<void>(resolve => {
				this.getTransition("t0").play(() => {
					resolve();
				});
            });
		}

		public onFreeBuy() {
			let hasFree = false;
			this._freeTypeToItem.forEach((_, com) => {
				if (com.remainTime <= 0) {
					hasFree = true;
				}
			});
			if (!hasFree) {
				Core.EventCenter.inst.dispatchEventWith(GameEvent.ShopFreeUnavailableEv);
			}
		}

		public onDestroy() {
			this._list.removeChildren(0, -1, true);
		}
	}
}