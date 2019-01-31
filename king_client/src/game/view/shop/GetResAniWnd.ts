module Shop {
	export class GetResAniWnd extends Core.BaseView {

		private _goldAni: fairygui.Transition;
		private _jadeAni: fairygui.Transition;
		private _resImg: Array<fairygui.GLoader>;
		private _originY: number;

		public initUI() {
			super.initUI();

			this.adjust(this.getChild("bg"), Core.AdjustType.EXCEPT_MARGIN);
			this.y += window.support.topMargin;
			this._goldAni = this.getTransition("goldAni");
			this._jadeAni = this.getTransition("jadeAni");
			this._resImg = [];
			for (let i = 1; i <= 1000; i ++) {
				let loader = this.getChild(`resource${i}`);
				if (loader) {
					this._resImg.push(loader.asLoader);
				} else {
					break;
				}
			}
			this._originY = this.y;
		}

		public async open(...param: any[]) {
			super.open(...param);

			let resType: ResType = param[0];
			if (resType == ResType.T_GOLD) {
				this._resImg.forEach(img => {
					img.url = "common_goldIcon_png";
				});
				this._goldAni.play(() => {
					Core.ViewManager.inst.closeView(this);
				}, this);
			} else if (resType == ResType.T_JADE) {
				this._resImg.forEach(img => {
					img.url = "common_jadeIcon_png";
				});
				this._jadeAni.play(() => {
					Core.ViewManager.inst.closeView(this);
				}, this);
			} else {
				Core.ViewManager.inst.closeView(this);
			}
			let offsety = param[1];
			if (offsety) {
				this.y = this._originY + offsety;
			}
		}

		public async close(...param: any[]) {
			super.close(...param);
		}
	}
}