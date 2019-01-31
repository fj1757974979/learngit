module WXGame {

	class AdvertIconType {
		public static T_PREVIEW = 1;
		public static T_NAV = 2;
	}

	export class WXAdvertIconCom extends fairygui.GComponent {

		private _image: fairygui.GImage;
		private _data: any;
		private _type: AdvertIconType;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._image = this.getChild("advert").asImage;

			this.addClickListener(this._onClick, this);
		}

		private _onClick() {
			if (this._type == AdvertIconType.T_PREVIEW) {
				let url = this._data.wx_code_image;
				wx.previewImage({
					urls: [url]
				});
			} else {
				/*
				wx.navigateToMiniProgram({
					appId:this._data.wx_app_id,
					path:this._data.wx_path
				});
				*/
			}
		}

		public setData(data: any) {
			this._data = data;
			this._type = data.ad_type;
			this.alpha = 1;
			Utils.setImageUrlPicture(this._image, data.icon);
		}
	}
}
