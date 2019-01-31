// TypeScript file
module Payment {
    function rpc_SdkRechargeResult(_:Net.RemoteProxy, payload: Uint8Array) {
        let result = pb.SdkRechargeResult.decode(payload);
        Core.EventCenter.inst.dispatchEventWith(GameEvent.SDKRechargeSuccessEv, false, result);
    }
    
    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_NOTIFY_SDK_RECHARGE_RESULT, rpc_SdkRechargeResult);
    }
}