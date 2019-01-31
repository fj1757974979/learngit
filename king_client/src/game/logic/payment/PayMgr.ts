module Payment {

	export class PayMgr {

		private static _inst: PayMgr = null;
		private _curPayingPid: string = null;

		public static get inst(): PayMgr {
			if (!PayMgr._inst) {
				PayMgr._inst = new PayMgr();
			}
			return PayMgr._inst;
		}

		private _payment: IPayment;
		private _products: Collection.Dictionary<string, Product>;
		private _initialized: boolean;

		public constructor() {
			if (Core.DeviceUtils.isWXGame()) {
				this._payment = new WXPayment();
			} else if (Core.DeviceUtils.isAndroid()) {
				if (window.gameGlobal.isMultiLan) {
					egret.log("GooglePayment");
					this._payment = new GooglePayment();
				} else {
					egret.log("AndroidPayment");
					this._payment = new AndroidPayment();
				}
			} else if (Core.DeviceUtils.isiOS()) {
				// if (window.gameGlobal.isSDKPay) {
				// 	egret.log("iOSPaymentWithSDK");
				// 	this._payment = new iOSPaymentWithSDK();
				// } else {
					egret.log("AppstorePayment");
					Core.NativeMsgCenter.inst.addListener(Core.NativeMessage.FINISH_PAY, this._appStoreFinishPay, this);
					this._payment = new AppstorePayment();
				// }
			} else {
				this._payment = new DefaultPayment();
			}
			this._products = new Collection.Dictionary<string, Product>();
			this._initialized = false;
		}

		public async initMgr() {
			this._payment.init();
			let products: Product[] = await this._payment.getProducts();
			products.forEach(product => {
				this._products.setValue(product.id, product);
			});
			this._initialized = true;
		}

		public needSendBuyRpc(): boolean {
			return this._payment.needSendBuyRpc();
		}

		private async _appStoreFinishPay(param: any) {
			if (this._curPayingPid != null) {
				return;
			}
			if (!param["success"]) {
				return;
			}
			let productId: string = param["productId"];
			let receipt: string = param["receipt"];
			let prefixDiv = productId.indexOf(".");
			// 补单的情况
			let args = {
				GoodsID: productId.substr(prefixDiv + 1, productId.length - prefixDiv - 1),
				Receipt: receipt,
			}
			// TODO 区分宝玉和限定礼包购买。目前后者宝玉购买，暂不做判断
			let result = await Net.rpcCall(pb.MessageID.C2S_BUY_JADE, pb.BuyJadeArg.encode(args));
			if (result.errcode == 0) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60073));
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60116));
			}
		}

		public getProducts() {
			if (!this._initialized) {
				return null;
			}
			return this._products;
		}

		public async payProduct(productId: string, count: number = 1) {
			let product = this._products.getValue(productId);
			if (!product) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60132));
				return new PayResult(false, "");
			} else {
				this._curPayingPid = productId;
				let showMask = this._payment.shouldShowNetMask();
				if (showMask) {
					Core.MaskUtils.showNetMask();
				}
				let ret = await this._payment.payProduct(product, count);
				if (showMask) {
					Core.MaskUtils.hideNetMask();
				}
				this._curPayingPid = null;
				return ret;
			}
		}
	}

	export function init() {
		PayMgr.inst.initMgr();
		Payment.initRpc();
	}
}