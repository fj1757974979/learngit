module War {
	export class WarEnterAniView extends Core.BaseView {

		private _aniClose: fairygui.Transition;
		private _aniOpen: fairygui.Transition;

		public initUI() {
			super.initUI();

			this._aniClose = this.getTransition("t0");
			this._aniOpen = this.getTransition("t1");

			this.adjust(this.getChild("bg"));

			// this._parent = Core.LayerManager.inst.topLayer;
			this.toTopLayer();
		}

		public async open(...param: any[]) {
			this.visible = true;
			await super.open(...param);
			await new Promise<void>(resolve => {
				this._aniClose.play(() => {
					resolve();
				}, null, null, 1);
			});
		}

		public async dismiss() {
			await new Promise<void>(resolve => {
				this._aniOpen.play(() => {
					resolve();
				}, null, null, 1);
			});
		}

		public async close (...param: any[]) {
			await super.close(...param);
			console.log("close warani")
			this.visible = false;
		}
	}
}