module Huodong {
	export class HuodongMgr {
		public static HuodongBeginEvt = "HuodongBeginEvt";
		public static HuodongEndEvt = "HuodongEndEvt";
		private static _inst: HuodongMgr = null;
		public static get inst(): HuodongMgr {
			if (HuodongMgr._inst == null) {
				HuodongMgr._inst = new HuodongMgr();
			}
			return HuodongMgr._inst;
		}

		private _huodongs: Collection.Dictionary<HuodongType, Huodong>;

		public constructor() {
			this._huodongs = new Collection.Dictionary<HuodongType, Huodong>();
		}

		public initHuodong(protos: Array<pb.IHuodongData>) {
			protos.forEach(proto => {
				let huodong = genHuodong(<pb.HuodongData>proto);
				if (huodong) {
					this._huodongs.setValue(huodong.type, huodong);
				}
			});
		}

		public getHuodong(t: HuodongType) {
			return this._huodongs.getValue(t);
		}

		public onHuodongBegin(data: pb.HuodongData) {
			let huodong = genHuodong(data);
			if (huodong) {
				this._huodongs.setValue(huodong.type, huodong);
				huodong.onStart();
			}
		}

		public onHuodongEnd(t: HuodongType) {
			if (this._huodongs.containsKey(t)) {
				let huodong = this._huodongs.getValue(t);
				huodong.onStop();
				this._huodongs.remove(t);
			}
		}

		public heartbeat() {
			this._huodongs.forEach((t, h) => {
				h.heartbeat();
			})
		}
	}

	export function init() {
		initRpc();

		let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;

		registerView(ViewName.exchangeHuodongView, () => {
            return createObject(PkgName.pvp, ViewName.exchangeHuodongView, ExchangeView);
        });
	}
}