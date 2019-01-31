module Shop {
	export class JadeCntCom extends fairygui.GComponent {

		private _cardImg: fairygui.GLoader;
		private _titleText: fairygui.GTextField;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._cardImg = this.getChild("cardImg").asLoader;
			this._titleText = this.getChild("title").asTextField;
			this.touchable = false;
		}

		public setJadeInfo(count: number) {
			this._titleText.text = `x${count}`;

			// TODO 数量决定图片
		}
	}
}