// TypeScript file
module Payment {
    export interface IPayment {
        getProducts(): Promise<Array<Product>>
        payProduct(product: Product, count: number): Promise<PayResult>
        shouldShowNetMask(): boolean;
        needSendBuyRpc(): boolean;
        init();
    }

    export class PaymentBase {
        public needSendBuyRpc(): boolean {
            return false;
        }

        protected getGiftProductConf(isIos: boolean): any {
            if (window.gameGlobal.channel == "lzd_handjoy") {
                if (isIos) {
                    return Data.ios_limit_gift_lzd_handjoy;
                } else {
                    return Data.android_limit_gift_handjoy;
                }
            } else {
                if (isIos) {
                    return Data.ios_limit_gift;
                } else {
                    return Data.android_limit_gift;
                }
            }
        }

        public init() {
            return;
        }
    }

    export class PayResult {
        public success: boolean;
        public result: string;
        public param: any;

        public constructor(success: boolean, result: string, param?: any) {
            this.success = success;
            this.result = result;
            this.param = param;
        }
    }

    export class AppstorePayment extends PaymentBase implements IPayment {
        private _getAllProductIds(): Array<string> {
            let ret: Array<string> = [];
            Data.ios_recharge.keys.forEach(k => {
                ret.push(`${k}`);
            });
            this.getGiftProductConf(true).keys.forEach(k => {
                ret.push(`${k}`);
            });
            return ret;
        }

        public init() {
            Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.INIT_APPSTORE_PAY);
        }

        public shouldShowNetMask(): boolean {
            return true;
        }

        public needSendBuyRpc(): boolean {
            return true;
        }

        public async getProducts(): Promise<Array<Product>> {
            let productIds = this._getAllProductIds();
            let reqIds = [];
            productIds.forEach(pid => {
                reqIds.push(window.gameGlobal.channel + "." + pid);
            });
            let result = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(
                Core.NativeMessage.APPSTORE_REQ_PRODUCTS, 
                Core.NativeMessage.APPSTORE_GET_PRODUCTS,
                {
                    productIds: reqIds
                }
            );

            let confData = this.getGiftProductConf(true);
            if (result.success) {
                let ret = [];
                let infos: any[] = result.info;
                infos.forEach(info => {
                    let productId:string = info[0];
                    if (productId) {
                        let realProductId = productId.split(".")[1];
                        let conf = Data.ios_recharge.get(realProductId);
                        if (!conf && !GiftProduct.isNotMoneyPay()) {
                            conf = confData.get(realProductId);   
                        }
                        if (conf) {
                            let product = Product.newProduct(realProductId, conf);
                            product.localizedPrice = info[2];
                            ret.push(product);
                        }
                    }
                });
                if (GiftProduct.isNotMoneyPay()) {
                    // 限定礼包改为宝玉购买，不用拉苹果商城的配置
                    confData.keys.forEach(productId => {
                        let conf = confData.get(productId);
                        if (conf) {
                            let product = Product.newProduct(`${productId}`, conf);
                            product.localizedPrice = `¥${product.price}`;
                            ret.push(product);
                        }
                    });
                }
                
                return ret;
            } else {
                return null;
            }
        }

        public async payProduct(product: Product, count: number): Promise<PayResult> {
            let productId = window.gameGlobal.channel + "." + product.id;
            let args = {
                GoodsID: productId
            }
            Net.rpcPush(pb.MessageID.C2S_IOS_PRE_PAY, pb.IosPrePayArg.encode(args));
            let result = await platform.pay(productId, product.price, count, false);
            if (!result) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60119));
                return new PayResult(false, "");
            } else {
                if (result.success) {
                    let productId = result.productId;
                    let receipt = result.receipt;
                    return new PayResult(true, receipt);
                } else {
                    Core.TipsUtils.showTipsFromCenter(result.reason);
                    return new PayResult(false, "");
                }
            }
        }
    }

    export class iOSPaymentWithSDK extends PaymentBase implements IPayment {
        private _payResolve: any;

        public async getProducts(): Promise<Array<Product>> {
            let ret = [];
            Data.ios_recharge.keys.forEach(productId => {
                let conf = Data.ios_recharge.get(productId);
                if (conf) {
                    let product = Product.newProduct(`${productId}`, conf);
                    product.localizedPrice = `¥${product.price}`;
                    ret.push(product);
                }
            });
            let confData = this.getGiftProductConf(true);
            confData.keys.forEach(productId => {
                let conf = confData.get(productId);
                if (conf) {
                    let product = Product.newProduct(`${productId}`, conf);
                    product.localizedPrice = `¥${product.price}`;
                    ret.push(product);
                }
            });
            return ret;
        }

        public async payProduct(product: Product, count: number): Promise<PayResult> {
            let productId = window.gameGlobal.channel + "." + product.id;
            let args = {
                GoodsID: product.id
            }
            let result1 = await Net.rpcCall(pb.MessageID.C2S_SDK_CREATE_ORDER, pb.SdkCreateOrderArg.encode(args), false);
            if (result1.errcode != 0) {
                return new PayResult(false, Core.StringUtils.TEXT(60117));
            }
            let orderId = pb.SdkCreateOrderReply.decode(result1.payload).OrderID;
            egret.log("payProduct orderId: ", orderId);
            let result = await platform.pay(productId, product.price, count, true, product.desc, orderId);
            if (!result) {
                return new PayResult(false, Core.StringUtils.TEXT(60119));
            } else {
                if (result.success) {
                    return new Promise<PayResult>((resolve) => {
                        this._payResolve = resolve;
                        Core.EventCenter.inst.addEventListener(GameEvent.SDKRechargeSuccessEv, this._onRechargeSuccess, this);
                    });
                } else {
                    return new PayResult(false, result.reason);
                }
            }
        }

        private _onRechargeSuccess(ev: egret.Event) {
            Core.EventCenter.inst.removeEventListener(GameEvent.SDKRechargeSuccessEv, this._onRechargeSuccess, this);
            if (!this._payResolve) {
                return;
            }
            let result = <pb.SdkRechargeResult>ev.data;
            if (result.Errcode == pb.SdkRechargeResult.RechargeErr.Success) {
                this._payResolve(new PayResult(true, "", result));
            } else {
                this._payResolve(new PayResult(false, Core.StringUtils.TEXT(60116)));
            }
            this._payResolve = null;
        }

        public shouldShowNetMask(): boolean {
            return true;
        }
    }

    export class AndroidPayment extends PaymentBase implements IPayment {
        public async getProducts(): Promise<Array<Product>> {
            let ret = [];
            Data.android_recharge.keys.forEach(productId => {
                let conf = Data.android_recharge.get(productId);
                if (conf) {
                    let product = Product.newProduct(`${productId}`, conf);
                    product.localizedPrice = `¥${product.price}`;
                    ret.push(product);
                }
            });
            let confData = this.getGiftProductConf(false);
            confData.keys.forEach(productId => {
                let conf = confData.get(productId);
                if (conf) {
                    let product = Product.newProduct(`${productId}`, conf);
                    product.localizedPrice = `¥${product.price}`;
                    ret.push(product);
                }
            });
            return ret;
        }

        public async payProduct(product: Product, count: number): Promise<PayResult> {
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60119));
            return new PayResult(false, "");
        }

        public shouldShowNetMask(): boolean {
            return true;
        }
    }

    export class GooglePayment extends AndroidPayment {
        private _getAllProductIds(): Array<string> {
            let ret: Array<string> = [];
            Data.android_recharge.keys.forEach(k => {
                ret.push(`${k}`);
            });
            this.getGiftProductConf(false).keys.forEach(k => {
                ret.push(`${k}`);
            });
            return ret;
        }

        public async getProducts(): Promise<Array<Product>> {
            let productIds = this._getAllProductIds();
            let result = await Core.NativeMsgCenter.inst.sendAndWaitNativeMessage(
                Core.NativeMessage.GOOGLEPLAY_REQ_PRODUCTS, 
                Core.NativeMessage.GOOGLEPLAY_GET_PRODUCTS,
                {
                    productIds: productIds
                }
            );
            if (result.success) {
                let ret = [];
                let infos: any[] = result.info;
                infos.forEach(info => {
                    let productId:string = info[0];
                    if (productId) {
                        let conf = Data.android_recharge.get(productId);
                        if (!conf && !GiftProduct.isNotMoneyPay()) {
                            conf = this.getGiftProductConf(false).get(productId);   
                        }
                        if (conf) {
                            let product = Product.newProduct(productId, conf);
                            product.localizedPrice = info[1];
                            product.currency = info[2];
                            product.localizedPriceAmount = parseInt(info[3]);
                            ret.push(product);
                        }
                    }
                });
                if (GiftProduct.isNotMoneyPay()) {
                    let confData = this.getGiftProductConf(false);
                    // 限定礼包改为宝玉购买，不用拉Googleplay的配置
                    confData.keys.forEach(productId => {
                        let conf = confData.get(productId);
                        if (conf) {
                            let product = Product.newProduct(`${productId}`, conf);
                            // product.localizedPrice = `¥${product.price}`;
                            ret.push(product);
                        }
                    });
                }
                return ret;
            } else {
                return null;
            }
        }

        public async payProduct(product: Product, count: number): Promise<PayResult> {
            let productId = product.id;
            let args = {
                GoodsID: productId
            }
            let result1 = await Net.rpcCall(pb.MessageID.C2S_SDK_CREATE_ORDER, pb.SdkCreateOrderArg.encode(args), false);
            if (result1.errcode != 0) {
                return new PayResult(false, Core.StringUtils.TEXT(60117));
            }
            let orderId = pb.SdkCreateOrderReply.decode(result1.payload).OrderID;
            // egret.log("payProduct orderId: ", orderId);
            let result = await platform.pay(productId, product.price, count, true, product.desc, orderId);
            if (!result) {
                return new PayResult(false, Core.StringUtils.TEXT(60119));
            } else {
                if (result.success) {
                    let payResult = result.payResult;
                    let inappPurchaseData = payResult.googlePayData;
                    let inappDataSignature = payResult.paySign;
                    let money = product.localizedPriceAmount;
                    let currency = product.currency;
                    let args2 = {
                        GoodsID: productId,
                        InappPurchaseData: JSON.stringify(inappPurchaseData),
                        InappDataSignature: inappDataSignature,
                        Money: money,
                        Currency: currency
                    };
                    let result2 = await Net.rpcCall(pb.MessageID.C2S_GOOGLE_PLAY_RECHARGE, pb.GooglePlayRechargeArg.encode(args2));
                    if (result2.errcode == 0) {
                        let rpcResult = pb.SdkRechargeResult.decode(result2.payload);
                        return new PayResult(true, "", rpcResult);
                    } else {
                        return new PayResult(false, Core.StringUtils.TEXT(60116));
                    }
                } else {
                    return new PayResult(false, result.reason);
                }
            }
        }
    }

    export class WXPayment extends PaymentBase implements IPayment {

        private _payResolve: any;

        public constructor() {
            super();
        }

        private get _callbackUrl(): string {
            if (Player.inst.isNewVersionPlayer()) {
                return WXGame.WXGameMgr.inst.wxConfig.recharge_cb;
            } else {
                return WXGame.WXGameMgr.inst.wxConfig.old_recharge_cb;
            }
        }

        public async getProducts(): Promise<Array<Product>> {
            let ret = [];
            Data.wxgame_recharge.keys.forEach(productId => {
                let conf = Data.wxgame_recharge.get(productId);
                if (conf) {
                    let product = Product.newProduct(`${productId}`, conf);
                    product.localizedPrice = `¥${product.price}`;
                    ret.push(product);
                }
            });
            Data.wxgame_limit_gift.keys.forEach(productId => {
                let conf = Data.wxgame_limit_gift.get(productId);
                if (conf) {
                    let product = Product.newProduct(`${productId}`, conf);
                    product.localizedPrice = `¥${product.price}`;
                    ret.push(product);
                }
            });
            return ret;
        }

        public shouldShowNetMask(): boolean {
            return WXGame.WXGameMgr.inst.platform == "android";
        }

        public async payProduct(product: Product, count: number): Promise<PayResult> {
            if (WXGame.WXGameMgr.inst.platform != "android") {
                if (!WXGame.WXGameMgr.inst.isInHuoshuWhiteList) {
                    return new PayResult(false, Core.StringUtils.TEXT(60119));
                }
            }
            let args = {
                GoodsID: product.id
            }
            let result1 = await Net.rpcCall(pb.MessageID.C2S_SDK_CREATE_ORDER, pb.SdkCreateOrderArg.encode(args), false);
            if (result1.errcode != 0) {
                return new PayResult(false, Core.StringUtils.TEXT(60117));
            }
            let orderId = pb.SdkCreateOrderReply.decode(result1.payload).OrderID;
            console.log("payProduct orderId: ", orderId);
            let result = await platform.pay(product.id, product.price, count, true, product.desc, orderId, this._callbackUrl);
            if (!result) {
                return new PayResult(false, Core.StringUtils.TEXT(60119));
            } else {
                if (result.success) {
                    return new Promise<PayResult>((resolve) => {
                        this._payResolve = resolve;
                        Core.EventCenter.inst.addEventListener(GameEvent.SDKRechargeSuccessEv, this._onWXRechargeSuccess, this);
                    });
                } else {
                    return new PayResult(false, result.reason);
                }
            }
        }

        private _onWXRechargeSuccess(ev: egret.Event) {
            Core.EventCenter.inst.removeEventListener(GameEvent.SDKRechargeSuccessEv, this._onWXRechargeSuccess, this);
            if (!this._payResolve) {
                return;
            }
            let result = <pb.SdkRechargeResult>ev.data;
            if (result.Errcode == pb.SdkRechargeResult.RechargeErr.Success) {
                this._payResolve(new PayResult(true, "", result));
            } else {
                this._payResolve(new PayResult(false, Core.StringUtils.TEXT(60116)));
            }
            this._payResolve = null;
        }
    }

    export class DefaultPayment extends AndroidPayment {

    }

}