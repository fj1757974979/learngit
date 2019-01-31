module Huodong {
	export class ExchangeView extends Core.BaseView {

		private _closeBtn: fairygui.GButton;
		private _list: fairygui.GList;
		private _coms: Array<ExchangeItemCom>;

		public initUI() {
			super.initUI();
			this.adjust(this.getChild("bg"));
			this._closeBtn = this.getChild("btnClose").asButton;
			this._list = this.getChild("list").asList;

			this._coms = [];

			this._closeBtn.addClickListener(this._onClose, this);
		}

		public async open(...param: any[]) {
			super.open(...param);

			// TODO
			let huodong = <SpringExchangeHuodong>HuodongMgr.inst.getHuodong(HuodongType.T_SPRING_EXCHANGE);
			let confs = huodong.getConf();
			let keys: number[] = confs.keys;
			for (let i = 0; i < keys.length; ++ i) {
				let goodsId = keys[i];
				let conf = confs.get(goodsId);
				let com = fairygui.UIPackage.createObject(PkgName.pvp, "eventRewardItem", ExchangeItemCom).asCom as ExchangeItemCom;
				await com.setExchangeData(goodsId, huodong, conf);
				com.host = this;
				this._list.addChild(com);
				this._coms.push(com);
			}
		}

		public refreshList() {
			this._coms.forEach(com => {
				com.refresh();
			});
		}

		private async _onClose() {
			Core.ViewManager.inst.closeView(this);
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._list.removeChildren(0, -1, true);
			this._coms = [];
		}
	}
}