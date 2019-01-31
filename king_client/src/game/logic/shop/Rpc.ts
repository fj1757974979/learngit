// TypeScript file
module Shop {

    function rpc_TriggerShopAddGoldAds(_:Net.RemoteProxy, payload: Uint8Array) {
        Core.EventCenter.inst.dispatchEventWith(GameEvent.ShopFreeAvailableEv);
    }
    
    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_TRIGGER_SHOP_ADD_GOLD_ADS, rpc_TriggerShopAddGoldAds);
    }
}