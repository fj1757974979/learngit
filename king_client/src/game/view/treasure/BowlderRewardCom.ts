module Treasure {
	export class BowlderRewardCom extends fairygui.GComponent {
		
		private _countText: fairygui.GTextField;
		private _count: number;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._countText = this.getChild("title").asTextField;
		}

		public get count() {
			return this._count;
		}

		public set count(cnt: number) {
			this._count = cnt;
			this._countText.text = `x${this._count}`;
		}

		public setNoGoldHint(txt: string) {
			this._countText.text = txt;
		}

		public async playTrans() {
			await new Promise<void>(resolve => {
				this.getTransition("t0").play(() => {
					resolve();
				});
            });
		}
	}
}